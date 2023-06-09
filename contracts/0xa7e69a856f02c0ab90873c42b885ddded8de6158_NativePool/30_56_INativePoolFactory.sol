// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../NativePool.sol";
import "../interfaces/INativePool.sol";

error AlreadyMultiPoolTreasury();
error NotMultiPoolTreasury();
error NotMultiPoolTreasuryAndBindedToOtherPool(address treasuryAddress);
error ZeroAddressInput();
error RegistryAlreadySet();
error RegistryNotSet();
error InputArrayLengthMismatch();
error PoolUpgradeFailed();

interface INativePoolFactory {
    /// @notice Emitted when a pool is created
    /// @param treasury The address of treasury for the pool
    /// @param owner The address of owner of the pool
    /// @param pool The address of the created pool
    event PoolCreated(address treasury, address owner, address signer, address pool, address impl);

    event PoolUpgraded(address pool, address impl);

    event AddPoolCreator(address poolCreater);
    event RemovePoolCreator(address poolCreater);
    event AddMultiPoolTreasury(address treasury);
    event RemoveMultiPoolTreasury(address treasury);

    function createNewPool(
        address treasuryAddress,
        address poolOwnerAddress,
        address signerAddress,
        address routerAddress,
        uint256[] memory fees,
        address[] memory tokenAs,
        address[] memory tokenBs,
        uint256[] memory pricingModelIds,
        bool isPublicTreasury,
        bool isTreasuryContract
    ) external returns (address pool);

    function upgradePools(address[] calldata _pools, address[] calldata _impls) external;

    function upgradePool(address pool, address impl) external;

    function getPool(address treasuryAddress) external view returns (address);

    function verifyPool(address poolAddress) external view returns (bool);

    function setPoolImplementation(address newPoolImplementation) external;
}