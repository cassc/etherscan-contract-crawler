// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterDAExpSettlement_Mixin.sol";
import "./IFilteredMinterV1.sol";
import "./IFilteredMinterDAExpV0.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface combines the set of interfaces that add support for
 * a Dutch Auction with Settlement minter.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterDAExpSettlementV0 is
    IFilteredMinterDAExpSettlement_Mixin,
    IFilteredMinterV1,
    IFilteredMinterDAExpV0
{

}