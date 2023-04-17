// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../aave/IAaveV3LendingPool.sol";
import "../rate_oracles/IRateOracle.sol";

interface IAaveV3RateOracle is IRateOracle {

    /// @notice Gets the address of the Aave Lending Pool
    /// @return Address of the Aave Lending Pool
    function aaveLendingPool() external view returns (IAaveV3LendingPool);

}