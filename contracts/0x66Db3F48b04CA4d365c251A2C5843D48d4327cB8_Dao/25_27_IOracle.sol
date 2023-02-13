// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../external/Decimal.sol";

interface IOracle {
    function setup() external;

    function capture() external returns (Decimal.D256 memory, bool);

    function pairAddress() external view returns (address);
}