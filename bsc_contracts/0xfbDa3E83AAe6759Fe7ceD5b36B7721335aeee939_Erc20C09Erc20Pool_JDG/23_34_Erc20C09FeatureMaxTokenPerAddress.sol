// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20C09FeatureMaxTokenPerAddress is
Ownable
{
    bool public isUseMaxTokenPerAddress;
    uint256 public maxTokenPerAddress;

    function setIsUseMaxTokenPerAddress(bool isUseMaxTokenPerAddress_)
    external
    onlyOwner
    {
        isUseMaxTokenPerAddress = isUseMaxTokenPerAddress_;
    }

    function setMaxTokenPerAddress(uint256 maxTokenPerAddress_)
    external
    onlyOwner
    {
        maxTokenPerAddress = maxTokenPerAddress_;
    }
}