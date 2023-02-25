//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {IExchange} from "./interfaces/IExchange.sol";
import {ICvxBooster} from "./interfaces/ICvxBooster.sol";
import {ICvxBaseRewardPool} from "./interfaces/ICvxBaseRewardPool.sol";
import {ICurvePool} from "./interfaces/ICurvePool.sol";
import {IAlluoVault} from "./interfaces/IAlluoVault.sol";
import {IAlluoPool} from "./interfaces/IAlluoPool.sol";

import "hardhat/console.sol";

contract AlluoRewardsDistributor is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    IExchange public constant EXCHANGE =
        IExchange(0x29c66CF57a03d41Cfe6d9ecB6883aa0E2AbA21Ec);

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bool public upgradeStatus;
    address public rewardToken;
    EnumerableSetUpgradeable.AddressSet private pools;
    mapping(address => EnumerableSetUpgradeable.AddressSet)
        private poolToVaults;

    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _rewardToken,
        address[] memory _pools,
        address _multiSigWallet
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        rewardToken = _rewardToken;

        for (uint256 j; j < _pools.length; j++) {
            pools.add(_pools[j]);
        }

        require(_multiSigWallet.isContract(), "AlluoRewardsDist: !contract");
        _grantRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        _grantRole(UPGRADER_ROLE, _multiSigWallet);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function claimAllFromPool(
        address exitToken,
        address alluoPool
    ) external returns (uint256) {
        return _claimAllFromPool(exitToken, alluoPool, msg.sender);
    }

    function _claimAllFromPool(
        address exitToken,
        address alluoPool,
        address owner
    ) internal returns (uint256 totalRewards) {
        uint256 totalClaimableRewards;
        EnumerableSetUpgradeable.AddressSet storage vaults = poolToVaults[
            alluoPool
        ];
        uint256 length = vaults.length();

        address[] memory userVaults = new address[](length);
        uint256[] memory amounts = new uint256[](length);

        for (uint256 j; j < length; j++) {
            address vault = vaults.at(j);
            userVaults[j] = vault;
            amounts[j] = IAlluoVault(vault).claimRewardsDelegate(owner);
            totalClaimableRewards += amounts[j];
        }

        console.log("totalClaimableRewards", totalClaimableRewards);
        // get all rewards from the pool
        if (totalClaimableRewards == 0) return 0;

        totalRewards = IAlluoPool(alluoPool).withdrawDelegate(
            userVaults,
            amounts
        );

        if (exitToken != rewardToken) {
            IERC20MetadataUpgradeable(rewardToken).safeIncreaseAllowance(
                address(EXCHANGE),
                totalRewards
            );
            totalRewards = EXCHANGE.exchange(
                rewardToken,
                exitToken,
                totalRewards,
                0
            );
        }

        IERC20MetadataUpgradeable(exitToken).safeTransfer(owner, totalRewards);
    }

    function claimFromAllPools(address exitToken) external {
        for (uint256 j; j < pools.length(); j++) {
            address pool = pools.at(j);
            _claimAllFromPool(exitToken, pool, msg.sender);
        }
    }

    function editVaults(
        bool add,
        address _pool,
        address[] memory _vaults
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (add) {
            for (uint256 i; i < _vaults.length; i++) {
                poolToVaults[_pool].add(_vaults[i]);
            }
        } else {
            for (uint256 i; i < _vaults.length; i++) {
                poolToVaults[_pool].remove(_vaults[i]);
            }
        }
    }

    function editPool(
        bool add,
        address _pool
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // this removes the pool only from the set, but keeps in the mapping which is a bit
        // inefficient but not crucial
        if (add) {
            pools.add(_pool);
        } else {
            pools.remove(_pool);
        }
    }

    function grantRole(
        bytes32 role,
        address account
    ) public override onlyRole(getRoleAdmin(role)) {
        if (role == DEFAULT_ADMIN_ROLE) {
            require(account.isContract(), "Not contract");
        }
        _grantRole(role, account);
    }

    function changeUpgradeStatus(
        bool _status
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        upgradeStatus = _status;
    }

    function _authorizeUpgrade(
        address
    ) internal override onlyRole(UPGRADER_ROLE) {
        require(upgradeStatus, "Upgrade not allowed");
        upgradeStatus = false;
    }
}