// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {QuoteParams} from "splits-utils/LibQuotes.sol";

/// @title Oracle Interface
/// @author 0xSplits
interface IOracle {
    function getQuoteAmounts(QuoteParams[] calldata quoteParams_) external view returns (uint256[] memory);
}