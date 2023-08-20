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

    event RecoveryAttempt(address indexed recoveredAddress, bytes32 indexed messageHash);

    constructor( uint256 initialGasPrice) {
        _gasPrice = initialGasPrice;
    }

    function addToWhitelist(address _addressForWl) external {
        wlAddress[_addressForWl]=true;
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
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 messageHashBySigner
    ) public {
        require(_nonces[msg.sender] == nonce, "Invalid nonce");

        // Increment the nonce. Will make better nonce logic later using ZKP
        _nonces[msg.sender]++;

        // Calculate the message hash
        bytes32 messageHash = getMsgHash(target, data, nonce);

        // Recover the signer's address
        address recoveredAddress = recoverSigner(messageHashBySigner, v, r, s);

        require(
            recoveredAddress != address(0) && wlAddress[recoveredAddress] == true,
            "Signer Not Whitelisted"
        );

        emit RecoveryAttempt(recoveredAddress, messageHash);

        (bool success, ) = target.call(data);
        require(success, "Transaction execution failed");
    }

    function getMsgHash(address target, bytes memory data, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(target, data, nonce));
    }

    function getDataHash(bytes memory data) public pure returns (bytes32) {
        return keccak256(data);
    }

    function recoverSigner(bytes32 msgHash, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
        return ecrecover(msgHash, v, r, s);
    }

    function relayWithGasPrice(
        address target,
        bytes calldata data,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 gasPrice,
        bytes32 messageHashBySigner
    ) external {
        require(gasPrice >= _gasPrice, "Gas price too low");

        relay(target, data, nonce, v, r, s,messageHashBySigner);
    }
}
