// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//  *      __     __    _______   __________      __        __   __    __    __    __
//  *     |  \   /  |  |  _____| |___    ___|    /  \      |  | /  )  |  |  |  |  |  |
//  *     |   \_/   |  | |____       |  |       / /\ \     |  |/  /   |  |  |  |  |  |
//  *     | |\   /| |  |  ____|      |  |      / /__\ \    |     (    |  |  |  |  |  |
//  *     | | \_/ | |  | |_____      |  |     /  ____  \   |  |\  \   |  |__|  |  |  |_____
//  *     |_|     |_|  |_______|     |__|    /__/    \__\  |__| \__)   \______/   |________|

contract GaslessRelayer {
    mapping(address => uint256) private _nonces;
    mapping(address => bool) public wlAddress;
    address private _signer;
    uint256 private _gasPrice;

    event RecoveryAttempt(
        address indexed recoveredAddress,
        bytes32 indexed messageHash
    );

    constructor(uint256 initialGasPrice) {
        _gasPrice = initialGasPrice;
    }

    function addToWhitelist(address _addressForWl) external {
        wlAddress[_addressForWl] = true;
    }

    function removeFromWhitelist(address _addressForRemoval) external {
        wlAddress[_addressForRemoval] = false;
    }

    function isWhitelisted(address _address) external view returns (bool) {
        return wlAddress[_address];
    }

    function setGasPrice(uint256 newGasPrice) external {
        _gasPrice = newGasPrice;
    }

    function getNonce(address user) external view returns (uint256) {
        return _nonces[user];
    }

    function relay(
        address target,
        bytes calldata data,
        uint256 nonce,
        bytes memory _signature,
        bytes32 messageHashBySigner,
        bytes32 messsageHashBeforeSign
    ) public {
        require(_nonces[msg.sender] == nonce, "Invalid nonce");

        // Increment the nonce. Will make better nonce logic later using ZKP
        _nonces[msg.sender]++;

        // Calculate the message hash
        // @dev : check if we can verify the messageHash more securly
        bytes32 requiredMessageHash = getMsgHash(target, data, nonce);

        
        require(
            requiredMessageHash == messsageHashBeforeSign,
            "Msg Hash From Signer In invalid"
        );

        // Recover the signer's address
        address recoveredAddress = recoverSigner(
            messageHashBySigner,
            _signature
        );

        require(
            recoveredAddress != address(0) &&
                wlAddress[recoveredAddress] == true,
            "Signer Not Whitelisted"
        );

        emit RecoveryAttempt(recoveredAddress, messageHashBySigner);

        (bool success, ) = target.call(data);
        require(success, "Transaction execution failed");
    }

    function relayWithGasPrice(
        address target,
        bytes calldata data,
        uint256 nonce,
        bytes memory signature,
        uint256 gasPrice,
        bytes32 messageHashBySigner,
         bytes32 messsageHashBeforeSign
    ) external {
        require(gasPrice >= _gasPrice, "Gas price too low");

        relay(target, data, nonce, signature, messageHashBySigner,messsageHashBeforeSign);
    }



    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(_signature, 32))
            // second 32 bytes
            s := mload(add(_signature, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_signature, 96)))
        }

        return tryRecover(_ethSignedMessageHash, v, r, s);
    }

    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return (address(0));
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);

        return signer;
    }
    function getMsgHash(
        address target,
        bytes memory data,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(target, data, nonce));
    }

    function getDataHash(bytes memory data) public pure returns (bytes32) {
        return keccak256(data);
    }
}
