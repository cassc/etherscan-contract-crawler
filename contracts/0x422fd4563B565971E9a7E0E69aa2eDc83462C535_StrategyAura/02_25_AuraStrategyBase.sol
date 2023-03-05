// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@tetu_io/tetu-contracts/contracts/base/strategies/ProxyStrategyBase.sol";
import "../../third_party/balancer/IBVault.sol";
import "../../third_party/aura/IBooster.sol";
import "../../third_party/aura/IBaseRewardPool.sol";
import "../../third_party/aura/IVirtualBalanceRewardPool.sol";
import "../../third_party/aura/IAura.sol";
import "../../interface/ITetuLiquidator.sol";

/// @title Base contract for BPT farming with Aura
/// @author a17
abstract contract AuraStrategyBase is ProxyStrategyBase {
  using SafeERC20 for IERC20;

  // *******************************************************
  //                      CONSTANTS
  // *******************************************************

  /// @notice Strategy type for statistical purposes
  string public constant override STRATEGY_NAME = "AuraStrategyBase";
  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant VERSION = "1.0.0";

  uint private constant PRICE_IMPACT_TOLERANCE = 10_000;
  IBVault public constant BALANCER_VAULT = IBVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
  IBooster public constant AURA_BOOSTER = IBooster(0xA57b8d98dAE62B26Ec3bcC4a365338157060B234);
  ITetuLiquidator public constant TETU_LIQUIDATOR = ITetuLiquidator(0x90351d15F036289BE9b1fd4Cb0e2EeC63a9fF9b0);
  address public constant BAL_TOKEN = 0xba100000625a3754423978a60c9317c58a424e3D;
  address public constant AURA_TOKEN = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;

  // *******************************************************
  //                      VARIABLES
  // *******************************************************

  address public depositToken;
  IAsset[] public poolTokens;
  bytes32 public poolId;
  IBaseRewardPool public auraRewardPool;
  uint public auraPoolId;
  address public govRewardsConsumer;
  uint public lastHw;

  /// @notice Initialize contract after setup it as proxy implementation
  function initializeStrategy(
    address controller_,
    address vault_,
    address depositToken_,
    bytes32 poolId_,
    address auraRewardPool_,
    uint buybackRatio_
  ) public initializer {

    (IERC20[] memory tokens,,) = BALANCER_VAULT.getPoolTokens(poolId_);
    IAsset[] memory tokenAssets = new IAsset[](tokens.length);
    for (uint i = 0; i < tokens.length; i++) {
      tokenAssets[i] = IAsset(address(tokens[i]));
    }
    poolTokens = tokenAssets;

    depositToken = depositToken_;
    poolId = poolId_;

    auraRewardPool = IBaseRewardPool(auraRewardPool_);
    IERC20(_getPoolAddress(poolId_)).safeApprove(address(AURA_BOOSTER), type(uint).max);
    auraPoolId = auraRewardPool.pid();

    govRewardsConsumer = IController(controller_).governance();

    uint extraLength = auraRewardPool.extraRewardsLength();
    address[] memory rewardTokens_ = new address[](2 + extraLength);

    rewardTokens_[0] = BAL_TOKEN;
    rewardTokens_[1] = AURA_TOKEN;
    for (uint i = 2; i < 2 + extraLength; ++i) {
      rewardTokens_[i] = IVirtualBalanceRewardPool(auraRewardPool.extraRewards(i - 2)).rewardToken();
    }

    ProxyStrategyBase.initializeStrategyBase(
      controller_,
      _getPoolAddress(poolId_),
      vault_,
      rewardTokens_,
      buybackRatio_
    );
  }

  // *******************************************************
  //                      GOV ACTIONS
  // *******************************************************

  /// @dev Set new reward tokens
  function setRewardTokens(address[] memory rts) external restricted {
    delete _rewardTokens;
    for (uint i = 0; i < rts.length; i++) {
      _rewardTokens.push(rts[i]);
      _unsalvageableTokens[rts[i]] = true;
    }
  }

  function setGovRewardsConsumer(address value) external restricted {
    govRewardsConsumer = value;
  }

  // *******************************************************
  //                      STRATEGY LOGIC
  // *******************************************************

  /// @dev Balance of staked BPTs to Aura by strategy
  function _rewardPoolBalance() internal override view returns (uint) {
    return auraRewardPool.balanceOf(address(this));
  }

  /// @dev Rewards amount ready to claim
  function readyToClaim() external view override returns (uint[] memory toClaim) {
    toClaim = new uint[](_rewardTokens.length);
    toClaim[0] = auraRewardPool.earned(address(this));

    IAura aura = IAura(AURA_TOKEN);
    uint emissionsMinted = aura.totalSupply() - aura.EMISSIONS_MAX_SUPPLY();
    uint cliff = emissionsMinted / aura.reductionPerCliff();
    if (cliff < aura.totalCliffs()) {
      uint reduction = (aura.totalCliffs() - cliff) * 5 / 2 + 700;
      toClaim[1] = toClaim[0] * reduction / aura.totalCliffs();
      uint amtTillMax = aura.EMISSIONS_MAX_SUPPLY() - emissionsMinted;
      if (toClaim[1] > amtTillMax) {
        toClaim[1] = amtTillMax;
      }
    }

    for (uint i = 2; i < _rewardTokens.length; i++) {
      toClaim[i] = IVirtualBalanceRewardPool(auraRewardPool.extraRewards(i - 2)).earned(address(this));
    }
  }

  /// @dev Return TVL of the farmable pool
  function poolTotalAmount() external view override returns (uint) {
    return auraRewardPool.totalAssets();
  }

  /// @dev Platform name for statistical purposes
  /// @return Platform enum index
  function platform() external override pure returns (Platform) {
    return Platform.AURA;
  }
  /// @dev assets should reflect underlying tokens need to investing
  function assets() external override view returns (address[] memory) {
    address[] memory token = new address[](poolTokens.length);
    for (uint i = 0; i < poolTokens.length; i++) {
      token[i] = address(poolTokens[i]);
    }
    return token;
  }

  /// @dev Deposit LP tokens to booster
  function depositToPool(uint amount) internal override {
    _doHardWork(true, false);
    if (amount != 0) {
      AURA_BOOSTER.deposit(auraPoolId, amount, true);
    }
  }

  /// @dev Withdraw LP tokens
  function withdrawAndClaimFromPool(uint amount) internal override {
    if (amount != 0) {
      auraRewardPool.withdrawAndUnwrap(amount, false);
    }
    _doHardWork(true, false);
  }

  /// @dev Emergency withdraw all from a gauge
  function emergencyWithdrawFromPool() internal override {
    auraRewardPool.withdrawAndUnwrap(auraRewardPool.balanceOf(address(this)), false);
  }

  /// @dev Make something useful with rewards
  function doHardWork() external onlyNotPausedInvesting override hardWorkers {
    _doHardWork(false, true);
  }

  function _doHardWork(bool silently, bool push) internal {
    uint _lastHw = lastHw;
    if (push || _lastHw == 0 || block.timestamp - _lastHw > 12 hours) {
      auraRewardPool.getReward();
      for (uint i = 2; i < _rewardTokens.length; i++) {
        IVirtualBalanceRewardPool(auraRewardPool.extraRewards(i - 2)).getReward();
      }
      liquidateReward(silently);
      // hit for properly statistic metrics
      IBookkeeper(IController(_controller()).bookkeeper()).registerStrategyEarned(0);
      lastHw = block.timestamp;
    }
  }

  function liquidateReward() internal override {
    // noop
  }

  function liquidateReward(bool silently) internal {
    address _govRewardsConsumer = govRewardsConsumer;
    address _depositToken = depositToken;
    uint bbRatio = _buyBackRatio();
    address[] memory rts = _rewardTokens;
    for (uint i = 0; i < rts.length; i++) {
      address rt = rts[i];
      uint amount = IERC20(rt).balanceOf(address(this));
      if (amount != 0) {
        uint toCompound = amount * (_BUY_BACK_DENOMINATOR - bbRatio) / _BUY_BACK_DENOMINATOR;
        uint toGov = amount - toCompound;
        if (toCompound != 0) {
          _liquidate(rt, _depositToken, toCompound, silently);
        }
        if (toGov != 0) {
          IERC20(rt).safeTransfer(_govRewardsConsumer, toGov);
        }
      }
    }

    uint toPool = IERC20(_depositToken).balanceOf(address(this));
    if (toPool != 0) {
      _balancerJoin(poolTokens, poolId, _depositToken, toPool);
    }
  }

  /// @dev Join to the given pool (exchange tokenIn to underlying BPT)
  function _balancerJoin(IAsset[] memory _poolTokens, bytes32 _poolId, address _tokenIn, uint _amountIn) internal {
    if (_amountIn != 0) {
      if (_isJoinBySwapAvailable(_poolTokens, _poolId)) {
        // just swap for enter
        _balancerSwap(_poolId, _tokenIn, _getPoolAddress(_poolId), _amountIn);
      } else {
        uint[] memory amounts = new uint[](_poolTokens.length);
        for (uint i = 0; i < amounts.length; i++) {
          amounts[i] = address(_poolTokens[i]) == _tokenIn ? _amountIn : 0;
        }
        bytes memory userData = abi.encode(1, amounts, 1);
        IBVault.JoinPoolRequest memory request = IBVault.JoinPoolRequest({
        assets : _poolTokens,
        maxAmountsIn : amounts,
        userData : userData,
        fromInternalBalance : false
        });
        _approveIfNeeds(_tokenIn, _amountIn, address(BALANCER_VAULT));
        BALANCER_VAULT.joinPool(_poolId, address(this), address(this), request);
      }
    }
  }

  function _isJoinBySwapAvailable(IAsset[] memory _poolTokens, bytes32 _poolId) internal pure returns (bool){
    address poolAdr = _getPoolAddress(_poolId);
    for (uint i; i < _poolTokens.length; ++i) {
      if (address(_poolTokens[i]) == poolAdr) {
        return true;
      }
    }
    return false;
  }

  /// @dev Swap _tokenIn to _tokenOut using pool identified by _poolId
  function _balancerSwap(bytes32 _poolId, address _tokenIn, address _tokenOut, uint _amountIn) internal {
    if (_amountIn != 0) {
      IBVault.SingleSwap memory singleSwapData = IBVault.SingleSwap({
      poolId : _poolId,
      kind : IBVault.SwapKind.GIVEN_IN,
      assetIn : IAsset(_tokenIn),
      assetOut : IAsset(_tokenOut),
      amount : _amountIn,
      userData : ""
      });

      IBVault.FundManagement memory fundManagementStruct = IBVault.FundManagement({
      sender : address(this),
      fromInternalBalance : false,
      recipient : payable(address(this)),
      toInternalBalance : false
      });

      _approveIfNeeds(_tokenIn, _amountIn, address(BALANCER_VAULT));
      BALANCER_VAULT.swap(singleSwapData, fundManagementStruct, 1, block.timestamp);
    }
  }

  function _liquidate(address tokenIn, address tokenOut, uint amount, bool silently) internal {
    address tokenOutRewrite = _rewriteLinearUSDC(tokenOut);

    if (tokenIn != tokenOutRewrite && amount != 0) {
      _approveIfNeeds(tokenIn, amount, address(TETU_LIQUIDATOR));
      // don't revert on errors
      if (silently) {
        try TETU_LIQUIDATOR.liquidate(tokenIn, tokenOutRewrite, amount, PRICE_IMPACT_TOLERANCE) {} catch {}
      } else {
        TETU_LIQUIDATOR.liquidate(tokenIn, tokenOutRewrite, amount, PRICE_IMPACT_TOLERANCE);
      }
    }

    // assume need to swap rewritten token manually
    if (tokenOut != tokenOutRewrite && amount != 0) {
      _swapLinearUSDC(tokenOutRewrite, tokenOut);
    }
  }

  /// @dev It is a temporally logic until liquidator implement swapper for LinearPool
  function _rewriteLinearUSDC(address token) internal pure returns (address){
    if (token == 0x82698aeCc9E28e9Bb27608Bd52cF57f704BD1B83 /*bbamUSDC*/) {
      // USDC
      return 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    }
    return token;
  }

  /// @dev It is a temporally logic until liquidator implement swapper for LinearPool
  function _swapLinearUSDC(address tokenIn, address tokenOut) internal {
    _balancerSwap(
      0x82698aecc9e28e9bb27608bd52cf57f704bd1b83000000000000000000000336,
      tokenIn,
      tokenOut,
      IERC20(tokenIn).balanceOf(address(this))
    );
  }

  function _approveIfNeeds(address token, uint amount, address spender) internal {
    if (IERC20(token).allowance(address(this), spender) < amount) {
      IERC20(token).safeApprove(spender, 0);
      IERC20(token).safeApprove(spender, type(uint).max);
    }
  }


  /// @dev Returns the address of a Pool's contract.
  ///      Due to how Pool IDs are created, this is done with no storage accesses and costs little gas.
  function _getPoolAddress(bytes32 id) internal pure returns (address) {
    // 12 byte logical shift left to remove the nonce and specialization setting. We don't need to mask,
    // since the logical shift already sets the upper bits to zero.
    return address(uint160(uint(id) >> (12 * 8)));
  }


  //slither-disable-next-line unused-state
  uint[43] private ______gap;
}