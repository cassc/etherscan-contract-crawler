// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.9;

import "../utils/Decimal.sol";

interface IExchange {
    function exchangeRateOf(address token)
        external
        returns (Decimal.D256 memory);

    function usdToken() external view returns (address);
}