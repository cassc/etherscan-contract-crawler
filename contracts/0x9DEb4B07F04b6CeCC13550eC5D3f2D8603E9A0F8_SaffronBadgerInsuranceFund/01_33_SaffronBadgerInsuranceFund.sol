// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./SaffronPoolV2.sol";
import "./SaffronPositionNFT.sol";
import "./balancer/WeightedPoolUserData.sol";
import "./balancer/IAsset.sol";
import { IVault as IBalancerVault } from "./balancer/IVault.sol";
import { IBalancerQueries, IVault as IQryVault } from "./balancer/IBalancerQueries.sol";
import "./interfaces/ITheVault.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error UnsupportedConversion(address token);
error UnsupportedSettWithdraw(address token);


contract SaffronBadgerInsuranceFund is ReentrancyGuard {
  using SafeERC20 for IERC20;

  // Reward tokens
  address internal constant WBTC_BADGER = 0xb460DAa847c45f1C4a41cb05BFB3b51c92e41B36;        // Balancer 20WBTC-80BADGER
  address internal constant B_AURA_BAL  = 0x37d9D2C6035b744849C15F1BFEE8F268a20fCBd8;        // Badger Sett Aura BAL
  address internal constant B_BAL_AAVE_STABLE = 0x06D756861De0724FAd5B5636124e0f252d3C1404;  // Badger Sett Balancer Aave Boosted StablePool (USD)
  address internal constant B_GRAV_AURA  = 0xBA485b556399123261a5F9c95d413B4f93107407;       // Gravitationally Bound AURA

  address internal constant AURA = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
  address internal constant AURA_BAL = 0x616e8BfA43F920657B3497DBf40D6b1A02D4608d;
  address internal constant BB_A_USD = 0x7B50775383d3D6f0215A8F290f2C9e2eEBBEceb2;

  ITheVault internal constant bAuraBal = ITheVault(B_AURA_BAL);
  ITheVault internal constant bbbAUsd = ITheVault(B_BAL_AAVE_STABLE);
  ITheVault internal constant bGravAura = ITheVault(B_GRAV_AURA);

  // Constants needed for conversion
  address[] internal reward_tokens = [ WBTC_BADGER ];

  address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
  address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address internal constant BADGER = 0x3472A5A71965499acd81997a54BBA8D852C6E53d;
  address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  bytes32 internal constant BADGER_WBTC_POOL_ID = 0xb460daa847c45f1c4a41cb05bfb3b51c92e41b36000200000000000000000194;
  bytes32 internal constant WBTC_WETH_POOL_ID = 0xa6f548df93de924d73be7d25dc02554c6bd66db500020000000000000000000e;
  bytes32 internal constant WETH_USDC_POOL_ID = 0x96646936b91d6b9d7d0c47c496afbf3d6ec7b6f8000200000000000000000019;
  address internal constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
  address internal constant BALANCER_QUERIES = 0xE39B5e3B6D74016b2F6A9673D7d7493B6DF549d5;
  uint256 internal constant CONVERSION_MIN = uint256(1000);
  uint256 internal constant EARNINGS_MIN = uint256(1000);

  // Governance
  address public treasury;          // Saffron treasury to collect fees
  address public governance;        // Governance address for operations
  address public new_governance;    // Proposed new governance address

  // System
  address public insurance_asset;   // Asset to insure the pool's senior tranche with
  address public pool_base_asset;   // Base asset to accumulate from pool, the Badger Vault (Sett) token
  SaffronPoolV2 public pool;        // SaffronPoolV2 this contract insures
  SaffronPositionNFT public NFT;    // Saffron Position NFT
  uint256 public immutable TRANCHE; // Tranche indicated in NFT storage value

  // User balance vars
  uint256 public total_supply_lp;   // Total balance of all user LP tokens

  // Additional Reentrancy Guard
  // Needed for update(), which can be called twice in some cases
  uint256 private _update_status = 1;
  modifier non_reentrant_update() {
    require(_update_status != 2, "ReentrancyGuard: reentrant call");
    _update_status = 2;
    _;
    _update_status = 1;
  }

  // System Events
  event FundsDeposited(uint256 tranche, uint256 lp, uint256 principal, uint256 token_id, address indexed owner);
  event FundsWithdrawn(uint256 tranche, uint256 principal, uint256 earnings, uint256 token_id, address indexed owner, address caller);
  event FundsConverted(address token_from, address token_to, uint256 amount_from, uint256 amount_to);
  event ErcSwept(address who, address to, address token, uint256 amount);

  constructor(address _insurance_asset, address _pool_base_asset) {
    require(_insurance_asset != address(0) && _pool_base_asset != address(0), "can't construct with 0 address");
    governance = msg.sender;
    treasury = msg.sender;
    pool_base_asset = _pool_base_asset;
    insurance_asset = _insurance_asset;
    TRANCHE = 2;
  }
  
  // Deposit insurance_assets into the insurance fund
  function deposit(uint256 principal) external nonReentrant {
    // Checks
    require(!pool.shut_down(), "pool shut down");
    require(!pool.deposits_disabled(), "deposits disabled");
    require(principal > 0, "can't deposit 0");

    // Effects
    update();
    uint256 total_holdings = IERC20(insurance_asset).balanceOf(address(this));

    // If holdings or total supply are zero then lp tokens are equivalent to the underlying
    uint256 lp = total_holdings == 0 || total_supply_lp == 0 ? principal : principal * total_supply_lp / total_holdings;
    total_supply_lp += lp;

    // Interactions
    IERC20(insurance_asset).safeTransferFrom(msg.sender, address(this), principal);
    uint256 token_id = NFT.mint(msg.sender, lp, principal, TRANCHE);
    emit FundsDeposited(TRANCHE, lp, principal, token_id, msg.sender);
  }

  // Withdraw principal + earnings from the insurance fund
  function withdraw(uint256 token_id) external nonReentrant {
    // Checks
    require(!pool.shut_down(), "pool shut down");
    require(NFT.tranche(token_id) == 2, "must be insurance NFT");
    
    // Effects
    update();
    uint256 total_holdings = IERC20(insurance_asset).balanceOf(address(this));
    uint256 lp = NFT.balance(token_id);
    uint256 principal = NFT.principal(token_id);
    address owner = NFT.ownerOf(token_id);
    uint256 principal_new = lp * total_holdings / total_supply_lp;
    
    total_supply_lp -= lp;

    // Interactions
    IERC20(insurance_asset).safeTransfer(owner, principal_new );
    NFT.burn(token_id);
    emit FundsWithdrawn(TRANCHE, principal, (principal_new > principal ? principal_new-principal : 0), token_id, owner, msg.sender);
  }

  // Emergency withdraw with as few interactions / state changes as possible / BUT still have to wait for expiration
  function emergency_withdraw(uint256 token_id) external {
    // Extra checks
    require(!pool.shut_down(), "removal paused");
    require(NFT.tranche(token_id) == 2, "must be insurance NFT");
    require(NFT.ownerOf(token_id) == msg.sender, "must be owner");
    uint256 principal = NFT.principal(token_id);

    // Minimum effects
    total_supply_lp -= NFT.balance(token_id);

    // Minimum interactions
    emit FundsWithdrawn(TRANCHE, principal, 0, token_id, msg.sender, msg.sender);
    IERC20(insurance_asset).safeTransfer(msg.sender, principal); 
    NFT.burn(token_id);
  }
  
  // Update state and accumulated assets_per_share
  function update() public non_reentrant_update {
    uint256 total_holdings = IERC20(insurance_asset).balanceOf(address(this));

    // Withdraw fees and measure earnings in pool_base_assets
    ITheVault base_asset_sett = ITheVault(pool_base_asset);
    IERC20 base_asset_token = IERC20(base_asset_sett.token());
    uint256 p_before = base_asset_token.balanceOf(address(this));
    pool.withdraw_fees(address(this));
    uint256 p_earnings = base_asset_token.balanceOf(address(this)) - p_before;

    // Nothing to do if we don't have enough pool_base_assets to split up
    if (p_earnings > EARNINGS_MIN) {
      if (total_holdings == 0) {
        // If no one has deposited to the insurance fund then all pool_base_asset earnings go to the treasury and assets_per_share can be safely reset to 0
        base_asset_token.transfer(treasury, p_earnings);
      } else {
        // Transfer half of p_earnings to treasury, convert the rest to insurance_asset, update state
        base_asset_token.transfer(treasury, p_earnings / 2);

        convert();
        // ---------------------------------------------------------
      }
    }
  }

  function convert() internal {
    for (uint256 token_idx = 0; token_idx < reward_tokens.length; token_idx++) {
      _convert_reward(reward_tokens[token_idx]);
    }
  }

  // Get total amount of insurance asset held by pool
  function total_principal() external view returns(uint256) {
      return IERC20(insurance_asset).balanceOf(address(this));
  }
  
  // Set the pool and NFT
  function set_pool(address _pool) external {
    require(msg.sender == governance, "must be governance");
    pool = SaffronPoolV2(_pool);
    NFT = pool.NFT();
  }

  // Set the treasury address
  function set_treasury(address _treasury) external {
    require(msg.sender == governance, "must be governance");
    require(_treasury != address(0), "can't set to 0");
    treasury = _treasury;
  }

  // Get pending earnings
  function pending_earnings(uint256 token_id) external view returns(uint256) {
    return total_supply_lp == 0 ? 0 : NFT.balance(token_id) * IERC20(insurance_asset).balanceOf(address(this)) / total_supply_lp;
  }

  /// GOVERNANCE
  // Propose governance transfer
  function propose_governance(address to) external {
    require(msg.sender == governance, "must be governance");
    require(to != address(0), "can't set to 0");
    new_governance = to;
  }

  // Accept governance transfer
  function accept_governance() external {
    require(msg.sender == new_governance, "must be new governance");
    governance = msg.sender;
    new_governance = address(0);
  }

  // Sweep funds in case of emergency
  function sweep_erc(address _token, address _to) external {
    require(msg.sender == governance, "must be governance");
    IERC20 token = IERC20(_token);
    uint256 token_balance = token.balanceOf(address(this));
    emit ErcSwept(msg.sender, _to, _token, token_balance);
    token.transfer(_to, token_balance);
  }

  function convert_rewards(address[] memory tokens) external  {
    for (uint256 token_idx = 0; token_idx < tokens.length; token_idx++) {
      _convert_reward(tokens[token_idx]);
    }
  }

  function _convert_reward(address token) internal returns (uint256) {
    // Only support 20WBTC-BADGER conversion
    if (token != WBTC_BADGER) {
      return uint256(0);
    }

    // Expect rewards as 20WBTC-80BADGER, return USDC amount
    //
    // Exit Balancer pool
    //   https://dev.balancer.fi/resources/joins-and-exits/pool-exits
    //   Receive WBTC and BADGER
    //
    // Paths for conversions:
    //   WBTC --> WETH --> USDC
    //   BADGER --> WBTC --> WETH --> USDC
    //
    uint256 tokenAmount = IERC20(token).balanceOf(address(this));
        if (tokenAmount < CONVERSION_MIN) {
      return uint256(0);
    }

    IAsset[] memory assets = new IAsset[](2);
    assets[0] = IAsset(WBTC);
    assets[1] = IAsset(BADGER);

    uint256[] memory minAmountsOut = new uint256[](2);
    minAmountsOut[0] = uint256(1);
    minAmountsOut[1] = uint256(1);

    bytes memory userData = abi.encode(WeightedPoolUserData.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, tokenAmount);

    address[] memory qAssets = new address[](2);
    qAssets[0] = WBTC;
    qAssets[1] = BADGER;

    IQryVault.ExitPoolRequest memory qRequest = IQryVault.ExitPoolRequest({
      assets: qAssets,
      minAmountsOut: minAmountsOut,
      userData: userData,
      toInternalBalance: false
    });

    IBalancerVault vault = IBalancerVault(BALANCER_VAULT);
    IBalancerQueries queries = IBalancerQueries(BALANCER_QUERIES);

    (uint256 qryBptIn, uint256[] memory qryAmountsOut) = queries.queryExit(BADGER_WBTC_POOL_ID, address(this), address(this), qRequest);

    minAmountsOut[0] = qryAmountsOut[0];
    minAmountsOut[1] = qryAmountsOut[1];
    IBalancerVault.ExitPoolRequest memory request = IBalancerVault.ExitPoolRequest({
      assets: assets,
      minAmountsOut: minAmountsOut,
      userData: userData,
      toInternalBalance: false
    });

    IERC20(WBTC_BADGER).safeApprove(BALANCER_VAULT, 0);
    IERC20(WBTC_BADGER).safeApprove(BALANCER_VAULT, type(uint128).max);
    vault.exitPool(BADGER_WBTC_POOL_ID, address(this), payable(address(this)), request);

    int256 wbtcReceived = _convert_badger(qryAmountsOut[1]);     // Convert BADGER from above to WBTC
    if (wbtcReceived < 0) {
      wbtcReceived = -1 * wbtcReceived;
    }

    uint256 totalWbtc = uint256(wbtcReceived) + qryAmountsOut[0];
    int256 usdcReceived = _convert_wbtc(totalWbtc);
    if (usdcReceived < 0) {
      usdcReceived = -1 * usdcReceived;
    }
    return uint256(usdcReceived);
  }

  function _convert_wbtc(uint256 amount) internal returns (int256) {
        IAsset[] memory assets = new IAsset[](3);
    assets[0] = IAsset(WBTC);
    assets[1] = IAsset(WETH);
    assets[2] = IAsset(USDC);

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
      poolId: WETH_USDC_POOL_ID,
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

    IERC20(WBTC).safeApprove(BALANCER_VAULT, 0);
    IERC20(WBTC).safeApprove(BALANCER_VAULT, type(uint128).max);
    int256[] memory assetDeltas = vault.batchSwap(IBalancerVault.SwapKind.GIVEN_IN, steps, assets, funds, limits, MAX_INT);

    return assetDeltas[2];
  }

  function _convert_badger(uint256 amount) internal returns (int256) {
        return _convert_asset_to(BADGER, WBTC, amount, BADGER_WBTC_POOL_ID);
  }

  function _convert_asset_to(address assetIn, address assetOut, uint256 amount, bytes32 pool) internal returns (int256) {
        if (amount < CONVERSION_MIN) {
            return int256(0);
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
}