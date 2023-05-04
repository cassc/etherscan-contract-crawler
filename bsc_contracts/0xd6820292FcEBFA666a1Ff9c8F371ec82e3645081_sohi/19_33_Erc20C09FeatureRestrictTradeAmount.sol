// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Erc20/Ownable.sol";

contract Erc20C09FeatureRestrictTradeAmount is
Ownable
{
    bool public isRestrictTradeInAmount;
    uint256 public restrictTradeInAmount;

    bool public isRestrictTradeOutAmount;
    uint256 public restrictTradeOutAmount;

    function setIsRestrictTradeInAmount(bool isRestrict)
    external
    onlyOwner
    {
        isRestrictTradeInAmount = isRestrict;
    }

    function setRestrictTradeInAmount(uint256 amount)
    external
    onlyOwner
    {
        restrictTradeInAmount = amount;
    }

    function setIsRestrictTradeOutAmount(bool isRestrict)
    external
    onlyOwner
    {
        isRestrictTradeOutAmount = isRestrict;
    }

    function setRestrictTradeOutAmount(uint256 amount)
    external
    onlyOwner
    {
        restrictTradeOutAmount = amount;
    }
}