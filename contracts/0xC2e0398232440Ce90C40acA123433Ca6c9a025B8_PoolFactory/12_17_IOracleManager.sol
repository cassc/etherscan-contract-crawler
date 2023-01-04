// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "./IBasePriceOracle.sol";

interface IOracleManager {
    event SetOracles(address indexed _emitter, IBasePriceOracle[] _oracles);

    function setOracles(IBasePriceOracle[] memory) external;

    function getPrice(address) external view returns (uint256);

    function getOracles() external view returns (IBasePriceOracle[] memory);
}