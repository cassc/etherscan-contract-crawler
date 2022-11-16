// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20C09FeatureTweakSwap is
Ownable
{
    bool public isUseMinimumTokenWhenSwap;
    uint256 public minimumTokenForSwap;

    bool internal _isSwapping;

    function setIsUseMinimumTokenWhenSwap(bool isUseMinimumTokenWhenSwap_)
    external
    onlyOwner
    {
        isUseMinimumTokenWhenSwap = isUseMinimumTokenWhenSwap_;
    }

    function setMinimumTokenForSwap(uint256 amount)
    external
    onlyOwner
    {
        minimumTokenForSwap = amount;
    }
}