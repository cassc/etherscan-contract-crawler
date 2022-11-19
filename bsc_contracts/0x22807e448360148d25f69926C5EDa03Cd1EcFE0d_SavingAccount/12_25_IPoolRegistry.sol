// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "./IGemGlobalConfig.sol";
import "./IPoolFactory.sol";
import "./IDefaultTokenRegistry.sol";

interface IPoolRegistry {
    function initializer(
        IGemGlobalConfig _gemGlobalConfig,
        IPoolFactory _poolFactory,
        IDefaultTokenRegistry _defaultTokenRegistry
    ) external;

    function nextPoolId() external view returns (uint256);

    function isPoolConfigured(uint256 _poolId) external view returns (bool);

    function getPoolStatus(uint256 _poolId) external view returns (uint8);

    function getPoolsByCreator(address _creator) external view returns (uint256[] memory);

    function calcBaseTokenAmountStep3(
        uint256 _maturesOn,
        uint256 _allMiningSpeed,
        uint256 _blocksPerYear
    ) external view returns (uint256);

    function pools(uint256 _poolId)
        external
        view
        returns (
            address poolCreator,
            address baseToken,
            address globalConfig,
            address savingAccount,
            address bank,
            address accounts,
            address tokenRegistry,
            address claim,
            address fixedPriceOracle,
            uint8 poolStatus,
            uint256 maturesOn
        );
}