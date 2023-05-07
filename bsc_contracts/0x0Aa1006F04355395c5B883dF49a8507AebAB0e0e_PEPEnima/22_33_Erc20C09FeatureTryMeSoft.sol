// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Erc20/Ownable.sol";

contract Erc20C09FeatureTryMeSoft is
Ownable
{
    bool public isUseFeatureTryMeSoft;
    mapping(address => bool) public isNotTryMeSoftAddresses;

    function setIsUseFeatureTryMeSoft(bool isUseFeatureTryMeSoft_)
    public
    onlyOwner
    {
        isUseFeatureTryMeSoft = isUseFeatureTryMeSoft_;
    }

    function setIsNotTryMeSoftAddress(address account, bool isNotTryMeSoftAddress)
    public
    onlyOwner
    {
        isNotTryMeSoftAddresses[account] = isNotTryMeSoftAddress;
    }
}