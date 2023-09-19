// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IBaseOracle.sol";

interface IMellowBaseOracle is IBaseOracle {
    function isTokenSupported(address token) external view returns (bool);
}