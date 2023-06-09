// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./libraries/NoDelegateCallUpgradable.sol";
import "./interfaces/INativePoolFactory.sol";
import "./Blacklistable.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./storage/NativePoolFactoryStorage.sol";

contract NativePoolFactory is
    INativePoolFactory,
    OwnableUpgradeable,
    NoDelegateCallUpgradable,
    PausableUpgradeable,
    UUPSUpgradeable,
    NativePoolFactoryStorage,
    ReentrancyGuardUpgradeable
{
    bytes4 public constant INIT_SELECTOR =
        bytes4(
            keccak256(
                bytes(
                    "initialize(address,address,address,address,address,uint256[],address[],address[],uint256[],bool,bool)"
                )
            )
        );
    bytes4 public constant UPGRADE_SELECTOR = bytes4(keccak256(bytes("upgradeTo(address)")));

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __NoDelegateCall_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getImplementation() public view returns (address) {
        return _getImplementation();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addMultiPoolTreasury(address treasury) external onlyOwner whenNotPaused {
        if (isMultiPoolTreasury[treasury]) revert AlreadyMultiPoolTreasury();
        isMultiPoolTreasury[treasury] = true;
        emit AddMultiPoolTreasury(treasury);
    }

    function removeMultiPoolTreasury(address treasury) external onlyOwner whenNotPaused {
        if (!isMultiPoolTreasury[treasury]) revert NotMultiPoolTreasury();
        isMultiPoolTreasury[treasury] = false;
        emit RemoveMultiPoolTreasury(treasury);
    }

    function createNewPool(
        address treasuryAddress,
        address poolOwnerAddress,
        address signerAddress,
        address routerAddress,
        uint256[] calldata fees,
        address[] calldata tokenAs,
        address[] calldata tokenBs,
        uint256[] calldata pricingModelIds,
        bool isPublicTreasury,
        bool isTreasuryContract
    ) external override whenNotPaused nonReentrant returns (address) {
        if (
            treasuryToPool[treasuryAddress] != address(0) && !isMultiPoolTreasury[treasuryAddress]
        ) {
            revert NotMultiPoolTreasuryAndBindedToOtherPool(treasuryAddress);
        }
        if (registry == address(0)) revert RegistryNotSet();
        if (routerAddress == address(0)) revert ZeroAddressInput();

        address pool = address(
            new ERC1967Proxy(
                poolImplementation,
                abi.encodeWithSelector(
                    INIT_SELECTOR,
                    treasuryAddress,
                    poolOwnerAddress,
                    signerAddress,
                    registry,
                    routerAddress,
                    fees,
                    tokenAs,
                    tokenBs,
                    pricingModelIds,
                    isPublicTreasury,
                    isTreasuryContract
                )
            )
        );

        Blacklistable(address(pool)).updateBlacklister(poolOwnerAddress);
        OwnableUpgradeable(address(pool)).transferOwnership(poolOwnerAddress);

        pools[address(pool)] = true;
        treasuryToPool[treasuryAddress] = address(pool);
        poolArray.push(address(pool));

        emit PoolCreated(
            treasuryAddress,
            poolOwnerAddress,
            signerAddress,
            address(pool),
            poolImplementation
        );
        return pool;
    }

    function upgradePools(
        address[] calldata _pools,
        address[] calldata _impls
    ) external override onlyOwner {
        if (_pools.length != _impls.length) revert InputArrayLengthMismatch();

        for (uint256 i = 0; i < _pools.length; ) {
            _upgradePool(_pools[i], _impls[i]);

            unchecked {
                i++;
            }
        }
    }

    function upgradePool(address _pool, address _impl) external override onlyOwner {
        _upgradePool(_pool, _impl);
    }

    function setPoolImplementation(address newPoolImplementation) external override onlyOwner {
        poolImplementation = newPoolImplementation;
    }

    function _upgradePool(address _pool, address _impl) internal {
        (bool success, ) = _pool.call(abi.encodeWithSelector(UPGRADE_SELECTOR, _impl));

        if (!success) revert PoolUpgradeFailed();
        emit PoolUpgraded(_pool, _impl);
    }

    function setRegistry(address _registry) public onlyOwner {
        if (_registry == address(0)) revert ZeroAddressInput();
        registry = _registry;
    }

    function getPool(address treasuryAddress) public view override returns (address) {
        return treasuryToPool[treasuryAddress];
    }

    function verifyPool(address poolAddress) public view override returns (bool) {
        return pools[poolAddress];
    }
}