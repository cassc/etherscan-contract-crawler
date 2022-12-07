// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../balancer/WeightedPoolUserData.sol";
import "../balancer/IAsset.sol";
import { IVault as IBalancerVault } from "../balancer/IVault.sol";

import "../interfaces/IBalancerSwapVault.sol";
import "../interfaces/ITheVault.sol";
import "../interfaces/IBadgerTreeV2.sol";
import "../interfaces/ISaffron_Badger_AdapterV2.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error UnsupportedConversion(address token);
error UnsupportedSettWithdraw(address token);

/// @title Autocompounder for the Saffron BadgerDAO adapter
contract SaffronBadgerAutocompounder is ReentrancyGuard {
  using SafeERC20 for IERC20;

  // Governance
  address public governance;        // Governance address for operations
  address public new_governance;    // Proposed new governance address
  bool public autocompound_enabled = true;

  // Existing farms and composable protocol connectors to be set in constructor
  ITheVault public badger_the_vault;         // Badger's TheVault for Balancer 20WBTC-80BADGER vault
  IBadgerTreeV2 public badger_tree;          // BadgerTreeV2

  // Constants needed for conversion
  address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
  address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address internal constant BADGER = 0x3472A5A71965499acd81997a54BBA8D852C6E53d;
  address internal constant AURA = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
  address internal constant AURA_BAL = 0x616e8BfA43F920657B3497DBf40D6b1A02D4608d;
  address internal constant BB_A_USD = 0x7B50775383d3D6f0215A8F290f2C9e2eEBBEceb2;
  address internal constant WBTC20_BADGER80 = 0xb460DAa847c45f1C4a41cb05BFB3b51c92e41B36;
  uint256 internal constant REWARD_WITHDRAW_MIN = uint256(1000);
  uint256 internal constant CONVERSION_MIN = uint256(1000);
  address internal constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

  bytes32 internal constant AURA_WETH_POOL_ID = 0xcfca23ca9ca720b6e98e3eb9b6aa0ffc4a5c08b9000200000000000000000274;
  bytes32 internal constant AURABAL_WETH_POOL_ID = 0x0578292cb20a443ba1cde459c985ce14ca2bdee5000100000000000000000269;
  bytes32 internal constant BBAUSD_WETH_POOL_ID = 0x70b7d3b3209a59fb0400e17f67f3ee8c37363f4900020000000000000000018f;
  bytes32 internal constant WBTC_WETH_POOL_ID = 0xa6f548df93de924d73be7d25dc02554c6bd66db500020000000000000000000e;
  bytes32 internal constant BADGER_WBTC_POOL_ID = 0xb460daa847c45f1c4a41cb05bfb3b51c92e41b36000200000000000000000194;

  // Conversion toggles with defaults
  bool public aura_convert_enabled = true;
  bool public auraBal_convert_enabled = true;
  bool public bBal_convert_enabled = false;     // False due to vault low TVL

  // Badger parameters
  address public lp;                    // LP token to autocompound into. This is Badger Sett 20WBTC-80BADGER.)
  address public deposit_token;         // 20WBTC-80BADGER Balancer token
  address public sett;                  // Expect this to be Badger Sett 20WBTC-80BADGER

  // Reward tokens
  address internal constant B_AURA_BAL  = 0x37d9D2C6035b744849C15F1BFEE8F268a20fCBd8;        // Badger Sett Aura BAL
  address internal constant B_BAL_AAVE_STABLE = 0x06D756861De0724FAd5B5636124e0f252d3C1404; // Badger Sett Balancer Aave Boosted StablePool (USD)
  address internal constant B_GRAV_AURA  = 0xBA485b556399123261a5F9c95d413B4f93107407;       // Gravitationally Bound AURA

  ITheVault internal constant bAuraBal = ITheVault(B_AURA_BAL);
  ITheVault internal constant bbbAUsd = ITheVault(B_BAL_AAVE_STABLE);
  ITheVault internal constant bGravAura = ITheVault(B_GRAV_AURA);

  // Saffron
  ISaffron_Badger_AdapterV2 public adapter;

  // System events
  event ErcSwept(address who, address to, address token, uint256 amount);

  /// @param _adapter_address Address of Saffron_Badger_Adapter
  /// @param _lp_address Address of LP token (e.g. Badger 20WBTC-80BADGER vault LP)
  /// @param _deposit_token Address of deposit token (e.g. Balancer's 20WBTC-80BADGER)
  /// @param _sett_address Address of BadgerDAO vault or Sett (e.g. Badger Sett 20WBTC-80BADGER vault)
  /// @param _badger_tree_address Address of the Badger Tree contract
  constructor(
    address _adapter_address,
    address _lp_address,
    address _deposit_token,
    address _sett_address,
    address _badger_tree_address
  ) {
    require(_adapter_address != address(0) && _lp_address != address(0) && _deposit_token != address(0)  && _sett_address != address(0) && _badger_tree_address != address(0),
      "can't construct with 0 address");
    governance = msg.sender;

    // Badger protocol
    lp = _lp_address;
    deposit_token = _deposit_token;
    badger_the_vault = ITheVault(_sett_address);
    badger_tree = IBadgerTreeV2(_badger_tree_address);

    // Saffron protocol
    adapter = ISaffron_Badger_AdapterV2(_adapter_address);

    // Approve sending the deposit tokens (20WBTC-80BADGER) to Badger's vault
    IERC20(_deposit_token).safeApprove(address(badger_the_vault), 0);
    IERC20(_deposit_token).safeApprove(address(badger_the_vault), type(uint128).max);
  }
  
  /// @dev Reset approvals to uint128.max
  function reset_approvals() external {
    // Reset LP token
    IERC20(lp).safeApprove(address(badger_the_vault), 0);
    IERC20(lp).safeApprove(address(badger_the_vault), type(uint128).max);
  }

  /// @dev Deposit into Badger and autocompound
  /// @param amount_qlp Amount to deposit into the Badger vault
  function blend(uint256 amount_qlp) external {
    require(msg.sender == address(adapter), "must be adapter");
    badger_the_vault.deposit(amount_qlp);
  }

  /// @dev Withdraw from BadgerTree and return funds to router
  /// @param amount Amount of Badger vault LP to withdraw
  /// @param to The account address to receive funds
  function spill(
      uint256 amount,
      address to
 ) external {
        require(msg.sender == address(adapter), "must be adapter");
    badger_the_vault.withdraw(amount);
    uint256 amount_less_fee = amount * 999 / 1000;
    IERC20(badger_the_vault.token()).transfer(to, amount_less_fee);
  }

  /// @dev Autocompound rewards into more lp tokens. The parameters tokens, cumulativeAmounts, index, cycle,
  ///      merkleProof match the values returned by https://api.badger.finance/v2/reward/tree/{user account}
  /// @param tokens Array of the reward tokens from the Badger Tree
  /// @param to Address of account the receives the reward tokens
  function autocompound(
    address[] calldata tokens,
    uint256[] calldata cumulativeAmounts,
    uint256 index,
    uint256 cycle,
    bytes32[] calldata merkleProof,
    uint256[] calldata amountsToClaim,
    address to
  ) external nonReentrant {
    _autocompound(tokens, cumulativeAmounts, index, cycle, merkleProof, amountsToClaim, to);
  }

  //
  // Sett vault addresses of rewards
  // bauraBAL: 0x37d9D2C6035b744849C15F1BFEE8F268a20fCBd8
  //     token: 0x616e8BfA43F920657B3497DBf40D6b1A02D4608d (Aura BAL)
  // graviAURA: 0xBA485b556399123261a5F9c95d413B4f93107407
  //     token: 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF (AURA)
  // bbb-a-USD: 0x06D756861De0724FAd5B5636124e0f252d3C1404
  //     token: 0x7B50775383d3D6f0215A8F290f2C9e2eEBBEceb2 (bb-a-USD)
  function _autocompound(
    address[] calldata tokens,
    uint256[] calldata cumulativeAmounts,
    uint256 index,
    uint256 cycle,
    bytes32[] calldata merkleProof,
    uint256[] calldata amountsToClaim,
    address to
  ) internal {
    if (!autocompound_enabled) return;

    // harvest tokens
    badger_tree.claim(tokens, cumulativeAmounts, index, cycle, merkleProof, amountsToClaim);

    // Convert bTokens and Badger to WBTC, deposit WBTC.
    _withdraw_rewards(tokens, cumulativeAmounts);
  }

  function _withdraw_rewards(address[] calldata tokens, uint256[] calldata cumulativeAmounts) internal {
    uint256 bauraBAL_amount;
    uint256 graviAURA_amount;
    uint256 bbbaUSD_amount;

    for (uint256 token_idx = 0; token_idx < tokens.length; token_idx++) {
      address current_token = tokens[token_idx];
      if (current_token == B_AURA_BAL) {
        bauraBAL_amount = cumulativeAmounts[token_idx];
      } else if (current_token == B_BAL_AAVE_STABLE) {
        bbbaUSD_amount = cumulativeAmounts[token_idx];
      } else if (current_token == B_GRAV_AURA) {
        graviAURA_amount = cumulativeAmounts[token_idx];
      }
    }

    // Withdraw the bTokens for underlying tokens: Aura BAL, AURA, bb-a-USD
    bAuraBal.withdraw(bauraBAL_amount);
    bbbAUsd.withdraw(bbbaUSD_amount);
    bGravAura.withdraw(graviAURA_amount);

  }


  /// @dev Convert the reward tokens into Badger vault deposit token, 20WBTC-80BADGER
  /// @param tokens Array of token addresses of expected rewards
  function convert_rewards(address[] memory tokens) external  {
        for (uint256 token_idx = 0; token_idx < tokens.length; token_idx++) {
      _convert_reward(tokens[token_idx]);
    }
  }

  /// @dev Deposit the rewards already converted into deposit token
  function deposit_rewards() external {
    // Assume auraBAL, AURA, and bb-a-usd already converted to the deposit_token, 20WBTC-80BADGER
    // Deposit 20WBTC-80BADGER rewards
    uint256 rewards_earned = IERC20(deposit_token).balanceOf(address(this));

    if (rewards_earned > REWARD_WITHDRAW_MIN) {
        badger_the_vault.deposit(rewards_earned);
      }
  }

  function _convert_reward(address token) internal returns (uint256) {
    // Convert auraBAL, AURA, or bb-a-USD to 20WBTC-80BADGER, return 20WBTC-80BADGER amount
    //
    // Paths for conversions:
    //   auraBAL --> WETH
    //   AURA --> WETH
    //   bb-a-USD --> WETH if liquidity exists
    //
    // 20% WETH --> WBTC
    // 80% WETH --> BADGER
    //
    // Deposit WBTC and BADGER into 20WBTC-80BADGER Badger Vault, return the 20WBTC-80BADGER amount

    uint256 tokenAmount = IERC20(token).balanceOf(address(this));
    if (tokenAmount < CONVERSION_MIN) {
        return uint256(0);
    }

    int256 amountOut;
    if (token == AURA) {
      amountOut = _convert_aura(tokenAmount);
    } else if (token == AURA_BAL) {
      amountOut = _convert_auraBAL(tokenAmount);
    } else if (token == BB_A_USD) {
      amountOut = _convert_bb_a_USD(tokenAmount);
    } else {
      return uint256(0);
    }


    uint256 wbtcBadgerAmount = _convert_weth_to_deposit_token();
    return wbtcBadgerAmount;
  }

  function _convert_weth_to_deposit_token() internal returns (uint256) {
    // Balance of WETH
    uint256 wethBal = IERC20(WETH).balanceOf(address(this));

    // 20% of WETH for WBTC, remainder for BADGER
    uint256 weth20 = wethBal * 20 / 100;
    uint256 weth80 = wethBal - weth20;

    if (weth20 < CONVERSION_MIN) {
            return uint256(0);
    }

    // Convert the 20% WETH to WBTC
    int256 wbtcAmount = _convert_asset_to(WETH, WBTC, weth20, WBTC_WETH_POOL_ID);
    if (wbtcAmount < 0) {
      wbtcAmount = -1 * wbtcAmount;
    }

    // Convert the 80% WETH to BADGER
    int256 badgerAmount = _convert_weth_to_badger(weth80);
    if (badgerAmount < 0) {
      badgerAmount = -1 * badgerAmount;
    }

    // Return amount of 20WBTC-80BADGER created
    uint256 wbtcBadgerBefore = IERC20(WBTC20_BADGER80).balanceOf(address(this));
        _join_balancer_wbtcbadger(uint256(wbtcAmount), uint256(badgerAmount));
    uint256 wbtcBadgerAfter = IERC20(WBTC20_BADGER80).balanceOf(address(this));

    return wbtcBadgerAfter - wbtcBadgerBefore;
  }

  function _join_balancer_wbtcbadger(uint256 wbtcAmount, uint256 badgerAmount) internal {

    // Must be ordered the same as result of getPoolTokens()
    IAsset[] memory assets = new IAsset[](2);
    assets[0] = IAsset(WBTC);
    assets[1] = IAsset(BADGER);

    uint256[] memory maxAmountsIn = new uint256[](2);
    maxAmountsIn[0] = wbtcAmount;
    maxAmountsIn[1] = badgerAmount;

    bytes memory userData = abi.encode(WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, maxAmountsIn, uint256(1));
    IBalancerVault.JoinPoolRequest memory request = IBalancerVault.JoinPoolRequest({
      assets: assets,
      maxAmountsIn: maxAmountsIn,
      userData: userData,
      fromInternalBalance: false
    });

    IBalancerVault vault = IBalancerVault(BALANCER_VAULT);

    IERC20(WBTC).safeApprove(BALANCER_VAULT, 0);
    IERC20(WBTC).safeApprove(BALANCER_VAULT, type(uint128).max);
    IERC20(BADGER).safeApprove(BALANCER_VAULT, 0);
    IERC20(BADGER).safeApprove(BALANCER_VAULT, type(uint128).max);

    vault.joinPool(BADGER_WBTC_POOL_ID, address(this), address(this), request);
  }

  // Convert provided reward asset to WETH
  function _convert_reward_asset(address asset, uint256 amount, bytes32 pool) internal returns (int256) {
    IAsset[] memory assets = new IAsset[](2);
    assets[0] = IAsset(asset);
    assets[1] = IAsset(WETH);

    IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement(
    {
      sender: address(this),
      fromInternalBalance: false,
      recipient: payable(address(this)),
      toInternalBalance: false
    });

    IBalancerVault.BatchSwapStep memory assetToWeth = IBalancerVault.BatchSwapStep(
    {
      poolId: pool,
      assetInIndex: uint256(0),
      assetOutIndex: uint256(1),
      amount: amount,
      userData: ""
    }
    );

    IBalancerVault.BatchSwapStep[] memory steps = new IBalancerVault.BatchSwapStep[](1);
    steps[0] = assetToWeth;

    IBalancerVault vault = IBalancerVault(payable(BALANCER_VAULT));
    int256[] memory limits = new int256[](2);
    limits[0] = int256(1e20);
    limits[1] = int256(1e20);
    uint256 MAX_INT = 2**256-1;

    IERC20(asset).safeApprove(BALANCER_VAULT, 0);
    IERC20(asset).safeApprove(BALANCER_VAULT, type(uint128).max);
    int256[] memory assetDeltas = vault.batchSwap(IBalancerVault.SwapKind.GIVEN_IN, steps, assets, funds, limits, MAX_INT);

    return assetDeltas[1];
  }

  function _convert_asset_to(address assetIn, address assetOut, uint256 amount, bytes32 pool) internal returns (int256) {
    if (amount < CONVERSION_MIN) {
      return int256(0);
    }

    if (assetIn == WETH && assetOut == BADGER) {
        return _convert_weth_to_badger(amount);
    }

    IAsset[] memory assets = new IAsset[](2);
    assets[0] = IAsset(assetIn);
    assets[1] = IAsset(assetOut);

    IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement(
    {
    sender: address(this),
    fromInternalBalance: false,
    recipient: payable(address(this)),
    toInternalBalance: false
    });

    IBalancerVault.BatchSwapStep memory assetSwapStep = IBalancerVault.BatchSwapStep(
    {
    poolId: pool,
    assetInIndex: uint256(0),
    assetOutIndex: uint256(1),
    amount: amount,
    userData: ""
    });

    IBalancerVault.BatchSwapStep[] memory steps = new IBalancerVault.BatchSwapStep[](1);
    steps[0] = assetSwapStep;

    IBalancerVault vault = IBalancerVault(payable(BALANCER_VAULT));
    int256[] memory limits = new int256[](2);
    limits[0] = int256(1e20);
    limits[1] = int256(1e20);
    uint256 MAX_INT = 2**256-1;

    IERC20(assetIn).safeApprove(BALANCER_VAULT, 0);
    IERC20(assetIn).safeApprove(BALANCER_VAULT, type(uint128).max);
    int256[] memory assetDeltas = vault.batchSwap(IBalancerVault.SwapKind.GIVEN_IN, steps, assets, funds, limits, MAX_INT);

    return assetDeltas[1];
  }

  function _convert_weth_to_badger(uint256 amount) internal returns (int256) {
    IAsset[] memory assets = new IAsset[](3);
    assets[0] = IAsset(WETH);
    assets[1] = IAsset(WBTC);
    assets[2] = IAsset(BADGER);

    IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement(
    {
    sender: address(this),
    fromInternalBalance: false,
    recipient: payable(address(this)),
    toInternalBalance: false
    });

    IBalancerVault.BatchSwapStep memory step1 = IBalancerVault.BatchSwapStep(
    {
    poolId: WBTC_WETH_POOL_ID,
    assetInIndex: uint256(0),
    assetOutIndex: uint256(1),
    amount: amount,
    userData: ""
    }
    );

    IBalancerVault.BatchSwapStep memory step2 = IBalancerVault.BatchSwapStep(
    {
    poolId: BADGER_WBTC_POOL_ID,
    assetInIndex: uint256(1),
    assetOutIndex: uint256(2),
    amount: uint256(0),
    userData: ""
    }
    );

    IBalancerVault.BatchSwapStep[] memory steps = new IBalancerVault.BatchSwapStep[](2);
    steps[0] = step1;
    steps[1] = step2;

    IBalancerVault vault = IBalancerVault(payable(BALANCER_VAULT));
    int256[] memory limits = new int256[](3);
    limits[0] = int256(1e20);
    limits[1] = int256(1e20);
    limits[2] = int256(1e20);
    uint256 MAX_INT = 2**256-1;

    IERC20(WETH).safeApprove(BALANCER_VAULT, 0);
    IERC20(WETH).safeApprove(BALANCER_VAULT, type(uint128).max);
    int256[] memory assetDeltas = vault.batchSwap(IBalancerVault.SwapKind.GIVEN_IN, steps, assets, funds, limits, MAX_INT);

    return assetDeltas[2];
  }

  function _convert_aura(uint256 amount) internal returns (int256) {
    if (aura_convert_enabled == true) {
      return _convert_reward_asset(AURA, amount, AURA_WETH_POOL_ID);
    } else {
      return int256(0);
    }
  }

  function _convert_auraBAL(uint256 amount) internal returns (int256) {
    if (auraBal_convert_enabled == true) {
      return _convert_reward_asset(AURA_BAL, amount, AURABAL_WETH_POOL_ID);
    } else {
      return int256(0);
    }
  }

  function _convert_bb_a_USD(uint256 amount) internal returns (int256) {
    if (bBal_convert_enabled == true) {
      return _convert_reward_asset(BB_A_USD, amount, BBAUSD_WETH_POOL_ID);
    } else {
      return int256(0);
    }
  }

  /// GETTERS
  /// @dev Get autocompounder holdings after autocompounding
  function get_autocompounder_holdings() external view returns (uint256) {
    return badger_the_vault.balanceOf(address(this));
  }

  function get_badger_holdings() external view returns (uint256) {
    return badger_the_vault.balanceOf(address(this));
  }

  /// GOVERNANCE
  /// @dev Set new contract address
  /// @param _badger_sett BadgerDAO Sett vault
  function set_badger_sett(address _badger_sett) external {
    require(msg.sender == governance, "must be governance");
    badger_the_vault = ITheVault(_badger_sett);
  }

  /// @dev Set the Badger Tree
  /// @param _badger_tree Address of Badger Tree used to determine rewards
  function set_badger_tree(address _badger_tree) external {
    require(msg.sender == governance, "must be governance");
    badger_tree = IBadgerTreeV2(_badger_tree);
  }

  /// @dev Toggle autocompounding
  function set_autocompound_enabled(bool _enabled) external {
    require(msg.sender == governance, "must be governance");
    autocompound_enabled = _enabled;
  }

  /// @dev Withdraw funds from Badger Sett in case of emergency
  function emergency_withdraw() external {
    require(msg.sender == governance, "must be governance");
    badger_the_vault.withdrawAll();
  }

  /// GOVERNANCE
  /// @dev Propose governance transfer
  /// @param to Governance account address to propose
  function propose_governance(address to) external {
    require(msg.sender == governance, "must be governance");
    require(to != address(0), "can't set to 0");
    new_governance = to;
  }

  /// @dev Accept governance transfer
  function accept_governance() external {
    require(msg.sender == new_governance, "must be new governance");
    governance = msg.sender;
    new_governance = address(0);
  }

  /// @dev Sweep funds in case of emergency
  /// @param _token Token to sweep from this contract
  /// @param _to Sweep funds to this recipient's account address
  function sweep_erc(address _token, address _to) external {
    require(msg.sender == governance, "must be governance");
    IERC20 token = IERC20(_token);
    uint256 token_balance = token.balanceOf(address(this));
    emit ErcSwept(msg.sender, _to, _token, token_balance);
    token.transfer(_to, token_balance);
  }

  /// @dev Configuration to enable conversion of AURA reward
  /// @param enable_setting True to enable conversion, false to prevent conversion
  function set_aura_convert(bool enable_setting) external {
    require(msg.sender == governance, "must be governance");
    aura_convert_enabled = enable_setting;
  }

  /// @dev Configuration to enable conversion AuraBal reward
  /// @param enable_setting True to enable conversion, false to prevent conversion
  function set_auraBal_convert(bool enable_setting) external {
    require(msg.sender == governance, "must be governance");
    auraBal_convert_enabled = enable_setting;
  }

  /// @dev Configuration to enable conversion Balancer Aave Boosted StablePool reward
  /// @param enable_setting True to enable conversion, false to prevent conversion
  function set_bbalUsd_convert(bool enable_setting) external {
    require(msg.sender == governance, "must be governance");
    bBal_convert_enabled = enable_setting;
  }
}

/// @title Saffron Badger Adapter integrates the Aura - BADGER/WBTC vault with Saffron Pool V2
contract Saffron_Badger_Adapter is ISaffron_Badger_AdapterV2, ReentrancyGuard {
  using SafeERC20 for IERC20;

  // Governance and pool 
  address public governance;                          // Governance address
  address public new_governance;                      // Newly proposed governance address
  address public saffron_pool;                        // SaffronPool that owns this adapter

  // Platform-specific vars
  IERC20 public SETT_LP;                                  // Sett address (Badger Sett LP token)
  IERC20 public deposit_token;                           // The deposit token (WBTC)
  SaffronBadgerAutocompounder public autocompounder;     // Auto-Compounder

  // Saffron identifiers
  string public constant platform = "Badger";     // Platform name
  string public name;                                 // Adapter name

  /// @param _lp_address LP token address (e.g. Badger Sett 20WBTC-80BADGER)
  /// @param _deposit_token Token to deposit into Badger Sett (e.g. 20WBTC-80BADGER)
  /// @param _name Name of adapter (e.g. "Saffron Badger Adapter")
  constructor(address _lp_address, address _deposit_token, string memory _name) {
    require(_lp_address != address(0x0), "can't construct with 0 address");
    governance = msg.sender;
    name       = _name;
    SETT_LP     = IERC20(_lp_address);
    deposit_token = IERC20(_deposit_token);
  }

  // System Events
  event CapitalDeployed(uint256 lp_amount);
  event CapitalReturned(uint256 lp_amount, address to);
  event Holdings(uint256 holdings);
  event ErcSwept(address who, address to, address token, uint256 amount);

  /// @dev Adds funds (WBTC) to underlying protocol. Called from pool's deposit function
  function deploy_capital(uint256 lp_amount) external override nonReentrant returns (uint256){
    require(msg.sender == saffron_pool, "must be pool");

    // Send lp to autocompounder and deposit into BadgerDAO
    emit CapitalDeployed(lp_amount);
    deposit_token.safeTransfer(address(autocompounder), lp_amount);
    autocompounder.blend(lp_amount);
    return lp_amount;
  }

  /// @dev Returns funds to user. Called from pool's withdraw function
  function return_capital(uint256 lp_amount, address to) external override nonReentrant {
    require(msg.sender == saffron_pool, "must be pool");
    emit CapitalReturned(lp_amount, to);
    autocompounder.spill(lp_amount, to);
  }

  /// @dev Return autocompounder holdings and log (for use in pool / adapter core functions)
  function get_holdings() external override nonReentrant returns(uint256 holdings) {
    holdings = autocompounder.get_autocompounder_holdings();
    emit Holdings(holdings);
  }

  /// @dev Backwards compatible holdings getter (can be removed in next upgrade for gas efficiency)
  function get_holdings_view() external override view returns(uint256 holdings) {
    return autocompounder.get_autocompounder_holdings();
  }

  /// GOVERNANCE
  /// @dev Set a new Saffron autocompounder address
  /// @param _autocompounder Address of Autocompounder contract
  function set_autocompounder(address _autocompounder) external {
    require(msg.sender == governance, "must be governance");
    autocompounder = SaffronBadgerAutocompounder(_autocompounder);
  }

  /// @dev Set a new pool address
  /// @param pool Address of Saffron Pool V2
  function set_pool(address pool) external override {
    require(msg.sender == governance, "must be governance");
    require(pool != address(0x0), "can't set pool to 0 address");
    saffron_pool = pool;
  }

  /// @dev Set a new LP token
  /// @param addr Address of adapter's LP token
  function set_lp(address addr) external override {
    require(msg.sender == governance, "must be governance");
    SETT_LP=IERC20(addr);
  }

  /// @dev Set a new deposit token
  /// @param addr Address of token to deposit into Badger Sett vault
  function set_deposit_token(address addr) external override {
    require(msg.sender == governance, "must be governance");
    deposit_token=IERC20(addr);
  }

  /// @dev Governance transfer
  /// @param to Proposed governance account address
  function propose_governance(address to) external override {
    require(msg.sender == governance, "must be governance");
    require(to != address(0), "can't set to 0");
    new_governance = to;
  }

  /// @dev Governance transfer
  function accept_governance() external override {
    require(msg.sender == new_governance, "must be new governance");
    governance = msg.sender;
    new_governance = address(0);
  }

  /// @dev Sweep funds in case of emergency
  /// @param _token Token address to sweep
  /// @param _to Recipient's address
  function sweep_erc(address _token, address _to) external {
    require(msg.sender == governance, "must be governance");
    IERC20 token = IERC20(_token);
    uint256 token_balance = token.balanceOf(address(this));
    emit ErcSwept(msg.sender, _to, _token, token_balance);
    token.transfer(_to, token_balance);
  }

}