// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20MetadataUpgradeable} from
    "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import {IAuraLocker} from "../interfaces/aura/IAuraLocker.sol";
import {IBaseRewardPool} from "../interfaces/aura/IBaseRewardPool.sol";
import {IBooster} from "../interfaces/aura/IBooster.sol";
import {ICrvDepositorWrapper} from "../interfaces/aura/ICrvDepositorWrapper.sol";
import {ICrvDepositor} from "../interfaces/aura/ICrvDepositor.sol";
import {IVault} from "../interfaces/badger/IVault.sol";
import {IBalancerVault} from "../interfaces/balancer/IBalancerVault.sol";
import {IPriceOracle} from "../interfaces/balancer/IPriceOracle.sol";
import {IAggregatorV3} from "../interfaces/chainlink/IAggregatorV3.sol";

abstract contract AuraConstants {
    IBalancerVault internal constant BALANCER_VAULT = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    IBooster internal constant AURA_BOOSTER = IBooster(0x7818A1DA7BD1E64c199029E86Ba244a9798eEE10);
    IAuraLocker internal constant AURA_LOCKER = IAuraLocker(0x3Fa73f1E5d8A792C80F426fc8F84FBF7Ce9bBCAC);
    ICrvDepositor internal constant AURABAL_DEPOSITOR = ICrvDepositor(0xeAd792B55340Aa20181A80d6a16db6A0ECd1b827);
    ICrvDepositorWrapper internal constant AURABAL_DEPOSITOR_WRAPPER =
        ICrvDepositorWrapper(0x68655AD9852a99C87C0934c7290BB62CFa5D4123);

    IBaseRewardPool internal constant AURABAL_REWARDS = IBaseRewardPool(0x5e5ea2048475854a5702F5B8468A51Ba1296EFcC);

    IVault internal constant BAURABAL = IVault(0x37d9D2C6035b744849C15F1BFEE8F268a20fCBd8);
    address internal constant BADGER_VOTER = 0xA9ed98B5Fb8428d68664f3C5027c62A10d45826b;

    IERC20MetadataUpgradeable internal constant AURA =
        IERC20MetadataUpgradeable(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);
    IERC20MetadataUpgradeable internal constant BAL =
        IERC20MetadataUpgradeable(0xba100000625a3754423978a60c9317c58a424e3D);
    IERC20MetadataUpgradeable internal constant WETH =
        IERC20MetadataUpgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20MetadataUpgradeable internal constant USDC =
        IERC20MetadataUpgradeable(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20MetadataUpgradeable internal constant AURABAL =
        IERC20MetadataUpgradeable(0x616e8BfA43F920657B3497DBf40D6b1A02D4608d);
    IERC20MetadataUpgradeable internal constant BPT_80BAL_20WETH =
        IERC20MetadataUpgradeable(0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56);

    bytes32 internal constant BAL_WETH_POOL_ID = 0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014;
    bytes32 internal constant AURA_WETH_POOL_ID = 0xcfca23ca9ca720b6e98e3eb9b6aa0ffc4a5c08b9000200000000000000000274; // 50AURA-50WETH
    bytes32 internal constant USDC_WETH_POOL_ID = 0x96646936b91d6b9d7d0c47c496afbf3d6ec7b6f8000200000000000000000019;
    bytes32 internal constant AURABAL_BAL_WETH_POOL_ID =
        0x3dd0843a028c86e0b760b1a76929d1c5ef93a2dd000200000000000000000249; // Stable pool

    IAggregatorV3 internal constant BAL_USD_FEED = IAggregatorV3(0xdF2917806E30300537aEB49A7663062F4d1F2b5F);
    IAggregatorV3 internal constant BAL_ETH_FEED = IAggregatorV3(0xC1438AA3823A6Ba0C159CfA8D98dF5A994bA120b);
    IAggregatorV3 internal constant ETH_USD_FEED = IAggregatorV3(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    uint256 internal constant CL_FEED_HEARTBEAT_ETH_USD = 1 hours;
    uint256 internal constant CL_FEED_HEARTBEAT_BAL = 24 hours;

    IPriceOracle internal constant BPT_80AURA_20WETH = IPriceOracle(0xc29562b045D80fD77c69Bec09541F5c16fe20d9d); // POL from AURA

    uint256 internal constant BAL_USD_FEED_DIVISOR = 1e20;
    uint256 internal constant AURA_USD_TWAP_DIVISOR = 1e38;

    uint256 internal constant AURA_USD_SPOT_FACTOR = 1e20;

    uint256 internal constant W1_BPT_80BAL_20WETH = 0.8e18;
    uint256 internal constant W2_BPT_80BAL_20WETH = 0.2e18;
}