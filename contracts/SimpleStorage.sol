// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract SimpleStorage {
    uint256 public data_a;
    mapping(address=>uint256) public addMapping;

    function setData(uint256 data,address msgSender) public {
        data_a = data;
        addMapping[msgSender]=data; 
    }
}
