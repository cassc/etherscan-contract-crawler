// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20C09FeatureRestrictTrade is
Ownable
{
    bool public isRestrictTradeIn;
    bool public isRestrictTradeOut;

    function setIsRestrictTradeIn(bool isRestrict)
    external
    onlyOwner
    {
        isRestrictTradeIn = isRestrict;
    }

    function setIsRestrictTradeOut(bool isRestrict)
    external
    onlyOwner
    {
        isRestrictTradeOut = isRestrict;
    }
}