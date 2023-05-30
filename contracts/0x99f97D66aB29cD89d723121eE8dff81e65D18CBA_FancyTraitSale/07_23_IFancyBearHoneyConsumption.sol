// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

abstract contract IFancyBearHoneyConsumption {

    mapping(uint256 => uint256) public honeyConsumed;
    function consumeHoney(uint256 _tokenId, uint256 _honeyAmount) public virtual;
    
}