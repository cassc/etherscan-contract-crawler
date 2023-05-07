// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Erc20/Ownable.sol";

contract Erc20C09FeatureTweakSwap is
Ownable
{
    uint256 public minimumTokenForSwap;

    bool internal _isSwapping;

    function setMinimumTokenForSwap(uint256 amount)
    external
    onlyOwner
    {
        minimumTokenForSwap = amount;
    }
}