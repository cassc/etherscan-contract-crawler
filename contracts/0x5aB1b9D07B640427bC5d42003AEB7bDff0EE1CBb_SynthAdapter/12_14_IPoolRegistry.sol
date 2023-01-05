// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../one-oracle/IMasterOracle.sol";
import "./IGovernable.sol";
import "./ISyntheticToken.sol";

interface IPoolRegistry is IGovernable {
    function poolExists(address pool_) external view returns (bool);

    function feeCollector() external view returns (address);

    function getPools() external view returns (address[] memory);

    function registerPool(address pool_) external;

    function unregisterPool(address pool_) external;

    function masterOracle() external view returns (IMasterOracle);

    function updateMasterOracle(IMasterOracle newOracle_) external;
}