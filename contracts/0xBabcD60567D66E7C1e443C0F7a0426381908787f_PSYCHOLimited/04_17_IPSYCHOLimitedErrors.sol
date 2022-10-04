// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

interface IPSCYHOLimitedErrors {
    error ExceedsGenerationLimitBy(uint256 _exceeds);

    error FundAccountWith(uint256 _amount);

    error StockRemainingIs(uint256 _stock);
}