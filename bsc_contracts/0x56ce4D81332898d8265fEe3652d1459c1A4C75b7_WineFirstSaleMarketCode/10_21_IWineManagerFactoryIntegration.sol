// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IWinePoolFull.sol";

interface IWineManagerFactoryIntegration {

    event WinePoolCreated(uint256 poolId, address winePool);

    function factory() external view returns (address);

    function getPoolAddress(uint256 poolId) external view returns (address);

    function getPoolAsContract(uint256 poolId) external view returns (IWinePoolFull);

}