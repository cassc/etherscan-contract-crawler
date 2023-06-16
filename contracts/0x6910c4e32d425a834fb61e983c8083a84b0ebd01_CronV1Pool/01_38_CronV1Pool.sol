// SPDX-License-Identifier: BUSL-1.1

// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import { Math } from "./balancer-core-v2/lib/math/Math.sol";

import { IERC20 } from "./balancer-core-v2/lib/openzeppelin/IERC20.sol";
import { IERC20Decimals } from "./interfaces/IERC20Decimals.sol";
import { ReentrancyGuard } from "./balancer-core-v2/lib/openzeppelin/ReentrancyGuard.sol";

import { IMinimalSwapInfoPool } from "./balancer-core-v2/vault/interfaces/IMinimalSwapInfoPool.sol";
import { IBasePool } from "./balancer-core-v2/vault/interfaces/IBasePool.sol";
import { IVault } from "./balancer-core-v2/vault/interfaces/IVault.sol";
import { BalancerPoolToken } from "./balancer-core-v2/pools/BalancerPoolToken.sol";

import { IArbitrageurList } from "./interfaces/IArbitrageurList.sol";
import { ICronV1Pool } from "./interfaces/ICronV1Pool.sol";
import { ICronV1PoolFactory } from "./interfaces/ICronV1PoolFactory.sol";
import { ICronV1FactoryOwnerActions } from "./interfaces/pool/ICronV1FactoryOwnerActions.sol";
import { ICronV1PoolAdminActions } from "./interfaces/pool/ICronV1PoolAdminActions.sol";
import { ICronV1PoolArbitrageurActions } from "./interfaces/pool/ICronV1PoolArbitrageurActions.sol";
import { ICronV1PoolEnums } from "./interfaces/pool/ICronV1PoolEnums.sol";
import { ICronV1PoolEvents } from "./interfaces/pool/ICronV1PoolEvents.sol";
import { ICronV1PoolHelpers } from "./interfaces/pool/ICronV1PoolHelpers.sol";

import { C } from "./miscellany/Constants.sol";
import { requireErrCode, CronErrors } from "./miscellany/Errors.sol";
import { sqrt } from "./miscellany/Misc.sol";
import { BitPackingLib } from "./miscellany/BitPacking.sol";
import { VirtualOrders, OrderPools, Order, ExecVirtualOrdersMem, LoopMem, PriceOracle } from "./interfaces/Structs.sol";

/// @title  An implementation of a Time-Weighted Average Market Maker on Balancer V2 Vault Pools.
/// @author Zero Slippage (0slippage), Based upon the Paradigm paper TWAMM and the reference design
///         created by frankieislost with optimizations from FRAX incorporated for gas efficiency.
///
/// @notice For usage details, see the online Cron-Fi documentation at https://docs.cronfi.com/.
///
/// @dev Uses Balancer math library for overflow/underflow checks on standard U256 containers.
///      However, as many custom representations are used (i.e. non native word lengths) there
///      are a number of explicit checks against the maximum of other word lengths.
///      Furthermore there are unchecked operations (this code targets Solidity 0.7.x which
///      didn't yet feature implicit arithmetic checks or have the 'unchecked' block feature)
///      herein for reasons of efficiency or desired overflow. Wherever they appear they will
///      be documented and accompanied with one of the following tags:
///        - #unchecked
///        - #overUnderFlowIntended
///      Identified risks will be accompanied and described with the following tag:
///        - #RISK
///
/// @dev Conventions in the methods, variables and constants are as follows:
///
///      Prefixes:
///
///      - In constants, the prefix "Sn", where 1 <= n <= 4, denotes which slot the constant
///        pertains too. There are four storage slots that are bitpacked. For example,
///        "S2_OFFSET_ORACLE_TIMESTAMP" refers to the offset of the oracle timestamp in bit-
///        packed storage slot 2.
///
///      Suffixes:
///
///      - The suffix of a variable name denotes the type contained within the variable.
///        For instance "uint256 _incrementU96" is a 256-bit unsigned container representing
///        the 96-bit value "_increment".
///        In the case of "uint256 _balancerFeeDU1F18", the 256-bit unsigned container is
///        representing a 19 digit decimal value with 18 fractional digits. In this scenario,
///        the D=Decimal, U=Unsigned, F=Fractional.
///        Finally, "uint128 valueU128F64" is a 128-bit container representing a 128-bit value
///        with 64 fractional bits.
///
///      - The suffix of a function name denotes what slot it is proprietary too as a
///        matter of convention. While unchecked at run-time or by the compiler, the naming
///        convention easily aids in understanding what slot a packed value is stored within.
///        For instance the function "unpackFeeShiftS3" unpacks the fee shift from slot 3.
///        If the value of slot 2 were passed to this method, the unpacked value would be
///        incorrect.
///
/// @dev Fee Points (FP) is a system used herein to calculate applicable fees. THESE ABSOLUTELY
///      SHOULD NOT BE CONFUSED WITH BASIS POINTS--THEY ARE NOT BASIS POINTS! It consists of
///      fees, such as a swap fee, expressed in FP. The swap fee is multiplied by the amount
///      of token being swapped and divided by the total fee points (TOTAL_FP), which is 100,000,
///      to obtain the fee. For instance, a swap fee of 0.050% can be realized as follows:
///
///                    token_in x FEE_BP
///         swap_fee = -----------------
///                         TOTAL_FP
///
///                      token_in x 50
///                  = -----------------
///                          100000
///
contract CronV1Pool is ICronV1Pool, IMinimalSwapInfoPool, BalancerPoolToken, ReentrancyGuard {
  using Math for uint256;

  IVault private immutable VAULT;
  bytes32 public immutable override POOL_ID;
  IERC20 private immutable TOKEN0;
  IERC20 private immutable TOKEN1;
  PoolType public immutable override POOL_TYPE;
  uint16 private immutable ORDER_BLOCK_INTERVAL;
  uint24 private immutable MAX_ORDER_INTERVALS;
  uint256 private immutable ORDER_POOL0_PROCEEDS_SCALING;
  uint256 private immutable ORDER_POOL1_PROCEEDS_SCALING;
  address private immutable FACTORY;

  VirtualOrders private virtualOrders;

  /* Slot 1 Layout:
   *
   * The following variables are bit-mapped into uint256 slot1 in
   * container sizes related to their actual ranges as depicted below:
   *
   *   256-255  free (2-bits)
   *   -------
   *   254-245  shortTermFeeFP (10-bits)
   *   -------
   *   244-235  partnerFeeFP (10-bits)
   *   -------
   *   234-225  longTermFeeFP (10-bits)
   *   -------
   *   224-113  token0Orders (112-bits)
   *   -------
   *   112-  1  token1Orders (112-bits)
   *
   */
  uint256 internal slot1;

  /* Slot 2 Layout:
   *
   * The following variables are bit-mapped into uint256 slot2 in
   * container sizes related to their actual ranges as depicted below:
   *
   *   256-225  oracleTimeStamp (32-bits)
   *   -------
   *   224-113  token0Proceeds (112-bits)
   *   -------
   *   112-  1  token1Proceeds (112-bits)
   *
   */
  uint256 internal slot2;

  /* Slot 3 Layout:
   *
   * The following variables are bit-mapped into uint256 slot3 in
   * container sizes related to their actual ranges as depicted below:
   *
   *   256-226  free (31-bits)
   *   -------
   *   225-223  feeShiftU3 (3-bits)
   *   -------
   *   222-213  free (10-bits)
   *   -------
   *   212-193  free (20-bits)
   *   -------
   *   192- 97  token0CronFiFees (96-bits)
   *   -------
   *    96-  1  token1CronFiFees (96-bits)
   *
   */
  uint256 internal slot3;

  /* Slot 4 Layout
   *
   * The following variables are bit-mapped into uint256 slot4 in
   * container sizes related to their actual ranges as depicted below:
   *
   *       256  paused (1-bit)
   *   -------
   *       255  cronFeeEnabled (1-bit)
   *   -------
   *       254  collectBalancerFees (1-bit)
   *   -------
   *       253  zeroCronFiFees (1-bit)
   *   -------
   *   252-193  balancerFeeDU1F18 (60-bits)
   *   -------
   *   192- 97  token0BalancerFees (96-bits)
   *   -------
   *    96-  1  token1BalancerFees (96-bits)
   *
   */
  uint256 internal slot4;

  // @notice Uniswap V2 Style Oracle.
  // @dev Call function getOracleTimeStamp to get the timestamp associated
  //      with the oracle price values in this state variable.
  PriceOracle internal priceOracle;

  mapping(address => bool) internal adminAddrMap;
  mapping(address => address) internal partnerContractAddrMap;

  address internal feeAddr;

  mapping(address => uint256[]) private orderIdMap;

  /// @notice Ensure that the modified function is called by an address that is the factory owner.
  /// @dev    Cannot be used on Balancer Vault callbacks (onJoin, onExit,
  ///         onSwap) because msg.sender is the Vault address.
  ///
  modifier senderIsFactoryOwner() {
    _senderIsFactoryOwner(); // #contractsize optimization
    _;
  }

  /// @notice Ensures that the modified function is called by an address with administrator privileges.
  /// @dev    Cannot be used on Balancer Vault callbacks (onJoin, onExit,
  ///         onSwap) because msg.sender is the Vault address.
  ///
  modifier senderIsAdmin() {
    _senderIsAdmin(); // #contractsize optimization
    _;
  }

  /// @notice Ensures the modified function is called by an address with arbitrage partner privileges.
  /// @dev    Cannot be used on Balancer Vault callbacks (onJoin, onExit,
  ///         onSwap) because msg.sender is the Vault address.
  ///
  modifier senderIsArbitragePartner() {
    _senderIsArbitragePartner(); // #contractsize optimization
    _;
  }

  /// @notice Ensures that the modified function is not executed if the pool is currently paused.
  ///
  modifier poolNotPaused() {
    _poolNotPaused(); // #contractsize optimization
    _;
  }

  /// @notice Creates an instance of the Cron-Fi TWAMM pool. A Cron-Fi TWAMM pool features virtual order management and
  ///         virtualized reserves. Liquidity is managed through an instance of BalancerPoolToken.
  ///         The fees associated with the pool are configurable at run-time.
  ///
  ///         Importantly, the OBI cannot be changed after instantiation. If a pool's OBI is inappropriate to the
  ///         properties of the pair of tokens, it is recommended to create a new pool.
  ///
  ///         In the event of a failure, the pool can be paused which bypasses computation of virtual orders and allows
  ///         liquidity to be removed and long-term virtual orders to be withdrawn and refunded. Other operations are
  ///         blocked.
  ///
  ///         Management of the pool is performed by administrators who are able set gross swap fee amounts and
  ///         aribtrage partner status.
  ///
  ///         The pool factory owner is able to set the status of administrators, enable Cron-Fi fees, modify the
  ///         Cron-Fi fee address, adjust the fee-split between Cron-Fi and liquidity providers, and enable Balancer
  ///         fees.
  ///
  ///         Arbitrage partners are able to set and update a contract address that lists their arbitrageur's addresses,
  ///         which are able to swap at reduced fees as an incentive to provide better long-term order execution by
  ///         adjusting the bonding curve to compensate for the effect of virtual orders. These partners perform
  ///         accounting and capture a percentage of the trades or capture fees in another way which are periodically
  ///         remitted to the pool, rewarding the liquidity providers. This may be thought of as a constructive pay for
  ///         order flow or Maximal Extractable Value (MEV) recapture.
  ///
  /// @param _token0Inst The contract instance for token 0.
  /// @param _token1Inst The contract instance for token 1.
  /// @param _vaultInst The Balancer Vault instance this pool be a member of.
  /// @param _poolName The name for this pool.
  /// @param _poolSymbol The symbol for this pool.
  /// @param _poolType A value in the enumeration PoolType that controls the initial fee values and Order Block
  ///                  Interval (OBI) of the pool. See the documentation for the PoolType enumeration for details.
  ///
  constructor(
    IERC20 _token0Inst,
    IERC20 _token1Inst,
    IVault _vaultInst,
    string memory _poolName,
    string memory _poolSymbol,
    PoolType _poolType
  ) BalancerPoolToken(_poolName, _poolSymbol) {
    // Only factory can create pools, or else _senderIsFactoryOwner will revert:
    FACTORY = msg.sender;

    bytes32 poolIdValue = _vaultInst.registerPool(IVault.PoolSpecialization.TWO_TOKEN);

    IERC20[] memory tokens = new IERC20[](2);
    tokens[C.INDEX_TOKEN0] = _token0Inst;
    tokens[C.INDEX_TOKEN1] = _token1Inst;
    _vaultInst.registerTokens(
      poolIdValue,
      tokens,
      new address[](2) /* assetManagers */
    );

    VAULT = _vaultInst;
    POOL_ID = poolIdValue;
    TOKEN0 = _token0Inst;
    TOKEN1 = _token1Inst;

    POOL_TYPE = _poolType;

    // Compute the scaling factors for the order pool proceeds of each token. The addition of 1 is buffering the scaled
    // result to preserve additional precision.
    //
    uint256 token0Decimals = IERC20Decimals(address(_token0Inst)).decimals();
    requireErrCode(
      C.MIN_DECIMALS <= token0Decimals && token0Decimals <= C.MAX_DECIMALS,
      CronErrors.UNSUPPORTED_TOKEN_DECIMALS
    );
    ORDER_POOL0_PROCEEDS_SCALING = (10**(token0Decimals + 1));

    uint256 token1Decimals = IERC20Decimals(address(_token1Inst)).decimals();
    requireErrCode(
      C.MIN_DECIMALS <= token1Decimals && token1Decimals <= C.MAX_DECIMALS,
      CronErrors.UNSUPPORTED_TOKEN_DECIMALS
    );
    ORDER_POOL1_PROCEEDS_SCALING = (10**(token1Decimals + 1));

    // NOTE: Conditional assignment style / ternary operator hell required for immutables.
    //
    ORDER_BLOCK_INTERVAL = (_poolType == PoolType.Stable) ? C.STABLE_OBI : (_poolType == PoolType.Liquid)
      ? C.LIQUID_OBI
      : C.VOLATILE_OBI;
    MAX_ORDER_INTERVALS = (_poolType == PoolType.Stable) ? C.STABLE_MAX_INTERVALS : (_poolType == PoolType.Liquid)
      ? C.LIQUID_MAX_INTERVALS
      : C.VOLATILE_MAX_INTERVALS;

    if (_poolType == PoolType.Stable) {
      uint256 localSlot1 = BitPackingLib.packU10(0, C.STABLE_ST_FEE_FP, C.S1_OFFSET_SHORT_TERM_FEE_FP);
      localSlot1 = BitPackingLib.packU10(localSlot1, C.STABLE_ST_PARTNER_FEE_FP, C.S1_OFFSET_PARTNER_FEE_FP);
      slot1 = BitPackingLib.packU10(localSlot1, C.STABLE_LT_FEE_FP, C.S1_OFFSET_LONG_TERM_FEE_FP);
    } else if (_poolType == PoolType.Liquid) {
      uint256 localSlot1 = BitPackingLib.packU10(0, C.LIQUID_ST_FEE_FP, C.S1_OFFSET_SHORT_TERM_FEE_FP);
      localSlot1 = BitPackingLib.packU10(localSlot1, C.LIQUID_ST_PARTNER_FEE_FP, C.S1_OFFSET_PARTNER_FEE_FP);
      slot1 = BitPackingLib.packU10(localSlot1, C.LIQUID_LT_FEE_FP, C.S1_OFFSET_LONG_TERM_FEE_FP);
    } else {
      // PoolType.Volatile
      uint256 localSlot1 = BitPackingLib.packU10(0, C.VOLATILE_ST_FEE_FP, C.S1_OFFSET_SHORT_TERM_FEE_FP);
      localSlot1 = BitPackingLib.packU10(localSlot1, C.VOLATILE_ST_PARTNER_FEE_FP, C.S1_OFFSET_PARTNER_FEE_FP);
      slot1 = BitPackingLib.packU10(localSlot1, C.VOLATILE_LT_FEE_FP, C.S1_OFFSET_LONG_TERM_FEE_FP);
    }

    slot3 = BitPackingLib.packFeeShiftS3(slot3, C.DEFAULT_FEE_SHIFT);

    uint256 localSlot4 = BitPackingLib.packBit(0, 0, C.S4_OFFSET_PAUSE);
    localSlot4 = BitPackingLib.packBit(localSlot4, 0, C.S4_OFFSET_CRON_FEE_ENABLED);
    localSlot4 = BitPackingLib.packBit(localSlot4, 1, C.S4_OFFSET_COLLECT_BALANCER_FEES);
    slot4 = BitPackingLib.packBit(localSlot4, 1, C.S4_OFFSET_ZERO_CRONFI_FEES);

    adminAddrMap[C.CRON_DEPLOYER_ADMIN] = true;
    emit AdministratorStatusChange(msg.sender, C.CRON_DEPLOYER_ADMIN, true);

    emit FeeAddressChange(msg.sender, C.NULL_ADDR);
  }

  /// @notice Called by the vault when a user calls IVault.swap. Can be used to perform a Short-Term (ST)
  ///         swap, Long-Term (LT) swap, or Partner swap
  ///         ST swaps and Partner swaps behave like traditional Automated Market Maker atomic swaps
  ///         (think Uniswap V2 swaps).
  ///         LT swaps are virtual orders and behave differently, executing over successive blocks until
  ///         their expiry. Each LT swap is assigned an order id that is logged in a LongTermSwap event and
  ///         can also be fetched using getOrderIds for a given address. LT swaps can be withdrawn or
  ///         cancelled through the IVault.exit function (see onExitPool documentation).
  /// @param _swapRequest Is documented in Balancer's IPoolSwapStructs.sol. However, the userData field
  ///                     of this _swapRequest struct is a uint256 value, swapTypeU, followed by another
  ///                     uint256 value, argument, detailed below:
  ///                       * swapTypeU is decoded into the enum SwapType and determines if the transaction
  ///                         is a RegularSwap, LongTermSwap, or PartnerSwap.
  ///                         Min. = 0, Max. = 3
  ///                       * argument is a value, the use of which depends upon the SwapType value passed
  ///                                  into swapTypeU:
  ///                           - swapTypeU=0 (RegularSwap):  argument is ignored / not used.
  ///                           - swapTypeU=1 (LongTermSwap): argument is the number of order intervals for
  ///                                                         the LT trade before expiry.
  ///                           - swapTypeU=2 (PartnerSwap):  argument is the Partner address stored in a
  ///                                                         uint256. It is used to loop up the Partner's
  ///                                                         current arbitrage list contract address.
  ///                     Delegates:
  ///                     If the specified swapType is a LongTermSwap, the _swapRequest.to field can be
  ///                     used to specify a LT-Swap delegate. The delegate account is able to withdraw or
  ///                     cancel the LT-swap on behalf of the order owner (_swapRequest.from) at any time,
  ///                     so long as the recipient account specified for proceeds or refunds is the order
  ///                     owner. (The order owner does not have this restriction and direct proceeds or
  ///                     refunds to any desired account.)
  ///                     If the specified _swapRequest.to field is the null address or the order owner,
  ///                     then the delegate is disabled (and set to the null address).
  /// @param _currentBalanceTokenInU112 The Balancer Vault balance of the token being sold to the pool.
  ///                                   Min. = 0, Max. = (2**112) - 1
  /// @param _currentBalanceTokenOutU112 The Balancer Vault balance of the token being bought from the pool.
  ///                                    Min. = 0, Max. = (2**112) - 1
  /// @return amountOutU112 The amount of token being bought from the pool in this swap. For LT swaps this
  ///                       will always be zero. Proceeds from an LT swap can be withdrawn or the order
  ///                       refunded with an appropriate call to the IVault.exit function (see onExitPool
  ///                       documentation).
  ///
  function onSwap(
    SwapRequest memory _swapRequest,
    uint256 _currentBalanceTokenInU112,
    uint256 _currentBalanceTokenOutU112
  ) external override(IMinimalSwapInfoPool) poolNotPaused returns (uint256 amountOutU112) {
    requireErrCode(msg.sender == address(VAULT), CronErrors.NON_VAULT_CALLER);

    // NOTE: Not checking for balance overflow (amount + _currentBalanceTokenInU112) because this is
    //       handled by Balancer error BAL#526 BALANCE_TOTAL_OVERFLOW

    // #savegas #savesize
    IERC20 tokenIn = _swapRequest.tokenIn;
    address from = _swapRequest.from;
    uint256 amount = _swapRequest.amount;

    requireErrCode(_swapRequest.kind == IVault.SwapKind.GIVEN_IN, CronErrors.UNSUPPORTED_SWAP_KIND);

    // This style of decoding the data into the enum saves 16b of contract size.
    (uint256 swapTypeU, uint256 argument) = abi.decode(_swapRequest.userData, (uint256, uint256));
    SwapType swapType = SwapType(swapTypeU);

    bool token0To1 = (tokenIn == TOKEN0);
    (uint256 token0ReserveU112, uint256 token1ReserveU112) = _executeVirtualOrders(
      token0To1 ? _currentBalanceTokenInU112 : _currentBalanceTokenOutU112,
      token0To1 ? _currentBalanceTokenOutU112 : _currentBalanceTokenInU112,
      block.number
    );

    if (swapType == SwapType.LongTermSwap) {
      address delegate = _swapRequest.to;
      uint256 orderId = _longTermSwap(from, delegate, token0To1, amount, argument);
      emit LongTermSwap(from, delegate, address(tokenIn), amount, argument, orderId);
    } else {
      if (swapType == SwapType.PartnerSwap) {
        address contractAddress = partnerContractAddrMap[address(argument)];
        requireErrCode(IArbitrageurList(contractAddress).isArbitrageur(from), CronErrors.SENDER_NOT_PARTNER);
      }

      amountOutU112 = _shortTermSwap(
        token0To1,
        (swapType == SwapType.RegularSwap),
        amount,
        token0ReserveU112,
        token1ReserveU112
      );
      emit ShortTermSwap(from, address(tokenIn), amount, amountOutU112, swapTypeU);
    }
  }

  /// @notice Called by the Vault when a user calls IVault.joinPool. Can be use to add liquidity to
  ///         the pool in exchange for Liquidity Provider (LP) pool tokens or to reward the pool with
  ///         liquidity (MEV rewards from arbitrageurs).
  ///         WARNING: The initial liquidity provider, in a call to join the pool with joinTypeU=0
  ///                  (JoinType.Join), will sacrifice MINIMUM_LIQUIDITY, 1000, Liquidity Provider (LP)
  ///                  tokens. This may be an insignificant sacrifice for tokens with fewer decimal
  ///                  places and high worth (i.e. WBTC).
  ///         Importantly, the reward capability remains when the pool is paused to mitigate any
  ///         possible issue with underflowed pool reserves computed by differencing the pool accounting
  ///         from the pool token balances.
  /// @param _poolId The ID for this pool in the Balancer Vault
  /// @param _sender is the account performing the Join or Reward transaction (typically an LP or MEV reward
  ///                contract, respectively).
  /// @param _recipient is the account designated to receive pool shares in the form of LP tokens when
  ///                   Joining the pool. Can be set to _sender if sender wishes to receive the tokens
  ///                   and Join Events.
  /// @param _currentBalancesU112 an array containing the Balancer Vault balances of Token 0 and Token 1
  ///                             in this pool. The balances are in the same order that IVault.getPoolTokens
  ///                             returns.
  ///                             Min. = 0, Max. = (2**112) - 1
  /// @param _protocolFeeDU1F18 the Balancer protocol fee.
  ///                           Min. = 0, Max. = 10**18
  /// @param _userData is uint256 value, joinTypeU, followed by an array of 2 uint256 values, amounts,
  ///                  and another array of 2 uint256 values, minAmounts, detailed below:
  ///                    * joinTypeU is decoded into the enum JoinType and determines if the transaction is
  ///                                a Join or Reward.
  ///                                Min. = 0, Max. = 1
  ///                    * amountsInU112 are the amount of Token 0 and Token 1 to Join or Reward the pool
  ///                                    with, passed in the same array ordering that IVault.getPoolTokens
  ///                                    returns.
  ///                                    Min. = 0, Max. = (2**112) - 1
  ///                    * minAmountsU112 are the minimum amount of Token 0 and Token 1 prices at which
  ///                                     to Join the pool (protecting against sandwich attacks), passed
  ///                                     in the same array ordering that IVault.getPoolTokens returns.
  ///                                     The minAmountsU112 values are ignored unless joinTypeU is
  ///                                     0 (JoinType.Join). In the initial join, these values are
  ///                                     ignored.
  ///                                     Min. = 0, Max. = (2**112) - 1
  /// @return amountsInU112 is the amount of Token 0 and Token 1 provided to the pool as part of a Join or
  ///                       Reward transaction. Values are returned in the same array ordering that
  ///                       IVault.getPoolTokens returns.
  ///                       Min. = 0, Max. = (2**112) - 1
  /// @return dueProtocolFeeAmountsU96 the amount of Token 0 and Token 1 collected by the pool for
  ///                                  Balancer. Values are returned in the same array ordering that
  ///                                  IVault.getPoolTokens returns.
  ///                                  Min. = 0, Max. = (2**96) - 1
  ///
  function onJoinPool(
    bytes32 _poolId,
    address _sender,
    address _recipient,
    uint256[] memory _currentBalancesU112,
    uint256, /* lastChangeBlock - not used */
    uint256 _protocolFeeDU1F18,
    bytes calldata _userData
  ) external override(IBasePool) returns (uint256[] memory amountsInU112, uint256[] memory dueProtocolFeeAmountsU96) {
    _poolSafetyChecks(msg.sender, _poolId);

    JoinType joinType;
    uint256[] memory minAmountsU112;
    // Following block is a Stack Too Deep Workaround
    {
      // This style of decoding the data into the enum saves 16b of contract size.
      uint256 joinTypeU;
      (joinTypeU, amountsInU112, minAmountsU112) = abi.decode(_userData, (uint256, uint256[], uint256[]));
      joinType = JoinType(joinTypeU);
    }

    // NOTE: Not checking for balance overflows (amountsInU112 + _currentBalancesU112) because this is
    //       handled by Balancer error BAL#526 BALANCE_TOTAL_OVERFLOW

    ////////////////////////////////////////////////////////////////////////////////
    //                                                                            //
    // BEGIN WARNING: Moving the following 3 lines of code or separating them     //
    //                results in increased contract size (3b - ~53b or more       //
    //                depending on where the code is moved or how separated).     //
    //                                                                            //
    ////////////////////////////////////////////////////////////////////////////////
    // #savesize #savegas
    uint256 token0InU112 = amountsInU112[C.INDEX_TOKEN0];
    uint256 token1InU112 = amountsInU112[C.INDEX_TOKEN1];

    uint256 amountLP;
    ////////////////////////////////////////////////////////////////////////////////
    // END WARNING                                                                //
    ////////////////////////////////////////////////////////////////////////////////

    // NOTE:  If the pool is paused, JoinType.Join reverts.  JoinType.Reward does not revert, but proceeds
    //        without running execute virtual orders deliberately; this is because it is a fallback mitigation
    //        if _calculateReserves within the execute virtual orders process fails due to unforeseen finite
    //        precision effects (specifically if Balancer's accounting is less than the sum of this pool's
    //        orders, proceeds, and fees for either pool token--in this case a reward can be used to increase
    //        the balancer vault accounting preventing the failure and allowing withdraws, cancels, and pool
    //        exits that would otherwise be blocked by the failing _calculateReserves call).
    //
    //        If the pool is not paused, execute virtual orders is run for JoinType.Reward to ensure the added
    //        liquidity applies to the newest trades (i.e. those after the JoinType.Reward transaction).
    //
    if (!isPaused()) {
      uint256 token0ReserveU112;
      uint256 token1ReserveU112;

      if ((joinType == JoinType.Join && totalSupply() != 0) || (joinType == JoinType.Reward)) {
        (token0ReserveU112, token1ReserveU112) = _executeVirtualOrders(
          _currentBalancesU112[C.INDEX_TOKEN0],
          _currentBalancesU112[C.INDEX_TOKEN1],
          block.number
        );
      }

      if (joinType == JoinType.Join) {
        _joinMinimumCheck(
          token0InU112,
          token1InU112,
          minAmountsU112[C.INDEX_TOKEN0],
          minAmountsU112[C.INDEX_TOKEN1],
          token0ReserveU112,
          token1ReserveU112
        );
        amountLP = _join(_recipient, token0InU112, token1InU112, token0ReserveU112, token1ReserveU112);
      }
    } else {
      requireErrCode(joinType != JoinType.Join, CronErrors.POOL_PAUSED);
    }

    // When amountLP = 0, the PoolJoin event log doubles as a Reward event log.
    emit PoolJoin(_sender, _recipient, token0InU112, token1InU112, amountLP);

    dueProtocolFeeAmountsU96 = _handleBalancerFees(_protocolFeeDU1F18);
  }

  /// @notice Called by the Vault when a user calls IVault.exitPool. Can be used to remove liquidity from
  ///         the pool in exchange for Liquidity Provider (LP) pool tokens, to withdraw proceeds of a
  ///         Long-Term (LT) order, to cancel an LT order, or by the factory owner to withdraw protocol
  ///         fees if they are being collected.
  /// @param _poolId is the ID for this pool in the Balancer Vault
  /// @param _sender is the account performing the liquidity removal, LT order withdrawl, LT order
  ///                cancellation or the factory owner withdrawing fees.
  ///                For long term orders, a "delegate" may be specified, this address is able to
  ///                perform LT order withdraws and cancellations on behalf of the LT swap owner as
  ///                long as the recipient is the LT swap owner.
  /// @param _recipient For LT swaps the recipient must always be the original order owner (the address
  ///                   that issued the order) if a "delegate" address is performing the withdrawl or
  ///                   cancellation. If the order owner is performing the withdrawl or cancellation, the
  ///                   recipient can be set to whatever destination address desired.
  ///                   For other exit types (Exit & FeeWithdraw), the recipient can be set as desired
  ///                   so long as the sender is set to the authorized address.
  /// @param _currentBalancesU112 is an array containing the Balancer Vault balances of Token 0 and Token 1
  ///                             in this pool. The balances are in the same order that IVault.getPoolTokens
  ///                             returns.
  ///                             Min. = 0, Max. = (2**112) - 1
  /// @param _protocolFeeDU1F18 is the Balancer protocol fee.
  ///                           Min. = 0, Max. = 10**18
  /// @param _userData is uint256 value, exitTypeU, followed by a uint256, argument, detailed below:
  ///                    * exitTypeU is decoded into the enum ExitType and determines if the transaction is
  ///                                an Exit, Withdraw, Cancel, or FeeWithdraw.
  ///                                Min. = 0, Max. = 3
  ///                    * argument is used differently based on the ExitType value passed into exitTypeU:
  ///                                 - exitTypeU=0 (Exit):        argument is the number of LP tokens to
  ///                                                              redeem on Exit.
  ///                                 - exitTypeU=1 (Withdraw):    argument is the LT Swap order ID.
  ///                                 - exitTypeU=2 (Cancel):      argument is the LT Swap order ID.
  ///                                 - exitTypeU=3 (FeeWithdraw): argument is ignored / not used.
  /// @return amountsOutU112 is the amount of Token 0 and Token 1 provided by the pool as part of an Exit,
  ///                        LT Swap Withdrawl, LT Swap Cancel, or Fee Withdraw transaction. Values are
  ///                        returned in the same array ordering that IVault.getPoolTokens returns.
  ///                        Min. = 0, Max. = (2**112) - 1
  /// @return dueProtocolFeeAmountsU96 the amount of Token 0 and Token 1 collected by the pool for
  ///                                  Balancer. Values are returned in the same array ordering that
  ///                                  IVault.getPoolTokens returns.
  ///                                  Min. = 0, Max. = (2**96) - 1
  function onExitPool(
    bytes32 _poolId,
    address _sender,
    address _recipient,
    uint256[] memory _currentBalancesU112,
    uint256, /* lastChangeBlock - not used */
    uint256 _protocolFeeDU1F18,
    bytes calldata _userData
  ) external override(IBasePool) returns (uint256[] memory amountsOutU112, uint256[] memory dueProtocolFeeAmountsU96) {
    _poolSafetyChecks(msg.sender, _poolId);

    ExitType exitType;
    uint256 argument;
    // Following block is a Stack Too Deep Workaround
    {
      // This style of decoding the data into the enum saves 16b of contract size.
      uint256 exitTypeU;
      (exitTypeU, argument) = abi.decode(_userData, (uint256, uint256));
      exitType = ExitType(exitTypeU);
    }

    uint256 token0OutU112;
    uint256 token1OutU112;
    if (exitType == ExitType.FeeWithdraw) {
      (token0OutU112, token1OutU112) = _withdrawCronFees(_sender);
    } else {
      // Following block is a Stack Too Deep Workaround
      {
        // _executeVirtualOrders must be run for all exit types below, but it is in
        // this block b/c token0ReserveU112 and token1ReserveU112 variables are only for the
        // ExitType.Exit and cause Stack Too Deep otherwise.
        (uint256 token0ReserveU112, uint256 token1ReserveU112) = _executeVirtualOrders(
          _currentBalancesU112[C.INDEX_TOKEN0],
          _currentBalancesU112[C.INDEX_TOKEN1],
          block.number
        );

        if (exitType == ExitType.Exit) {
          (token0OutU112, token1OutU112) = _exit(_sender, argument, token0ReserveU112, token1ReserveU112);
        }
      }

      if (exitType == ExitType.Withdraw || exitType == ExitType.Cancel) {
        // NOTE: For all calls in this else block:
        //   - argument is the Order ID
        //   - _sender must be the original virtual order _sender
        (token0OutU112, token1OutU112) = _withdrawLongTermSwapWrapper(
          argument,
          _sender,
          _recipient,
          exitType == ExitType.Cancel
        );
      }
    }

    amountsOutU112 = new uint256[](2);
    amountsOutU112[C.INDEX_TOKEN0] = token0OutU112;
    amountsOutU112[C.INDEX_TOKEN1] = token1OutU112;

    dueProtocolFeeAmountsU96 = _handleBalancerFees(_protocolFeeDU1F18);
  }

  /// @notice Set the administrator status of the provided address, _admin. Status "true" gives
  ///         administrative privileges, "false" removes privileges.
  /// @param _admin  The address to add or remove administrative privileges from.
  /// @param _status Whether to grant (true) or deny (false) administrative privileges.
  /// @dev CAREFUL! You can remove all administrative privileges, rendering the contract unmanageable.
  /// @dev NOTE: Must be called by the factory owner.
  ///
  function setAdminStatus(address _admin, bool _status)
    external
    override(ICronV1FactoryOwnerActions)
    senderIsFactoryOwner
    nonReentrant
  {
    adminAddrMap[_admin] = _status;
    emit AdministratorStatusChange(msg.sender, _admin, _status);
  }

  /// @notice Enables Cron-Fi fee collection for Long-Term swaps when the provided address,
  ///         _feeDestination is not the null address.
  /// @param _feeDestination The address that can collect Cron-Fi Swap fees. If set to the null address,
  ///                        no Cron-Fi Long-Term swap fees are collected.
  /// @dev CAREFUL! Only the _feeDestination address can collect Cron-Fi fees from the pool.
  /// @dev NOTE: Must be called by the factory owner.
  ///
  function setFeeAddress(address _feeDestination)
    external
    override(ICronV1FactoryOwnerActions)
    senderIsFactoryOwner
    nonReentrant
  {
    feeAddr = _feeDestination;

    uint256 cronFeeEnabled = (_feeDestination != C.NULL_ADDR) ? 1 : 0;
    slot4 = BitPackingLib.packBit(slot4, cronFeeEnabled, C.S4_OFFSET_CRON_FEE_ENABLED);

    emit FeeAddressChange(msg.sender, _feeDestination);
  }

  /// @notice Sets whether the pool is paused or not. When the pool is paused:
  ///             * New swaps of any kind cannot be issued.
  ///             * Liquidity cannot be provided.
  ///             * Virtual orders are not executed for the remainder of allowable
  ///               operations, which include: removing liquidity, cancelling or
  ///               withdrawing a Long-Term swap order,
  ///         This is a safety measure that is not a part of expected pool operations.
  /// @param _pauseValue Pause the pool (true) or not (false).
  /// @dev NOTE: Must be called by an administrator.
  ///
  function setPause(bool _pauseValue) external override(ICronV1PoolAdminActions) senderIsAdmin nonReentrant {
    slot4 = BitPackingLib.packBit(slot4, _pauseValue ? 1 : 0, C.S4_OFFSET_PAUSE);

    emit BoolParameterChange(msg.sender, BoolParamType.Paused, _pauseValue);
  }

  /// @notice Set fee parameters.
  /// @param _paramTypeU A numerical value corresponding to the enum ParamType (see documentation
  ///                    for that above or values and corresponding ranges below).
  /// @param _value A value to set the specified parameter given in _paramTypeU. The values and
  ///               their ranges are as follows:
  ///
  ///     Short-Term Swap Fee Points:
  ///         * _paramTypeU = 0  (ParamType.SwapFeeFP)
  ///         * 0 <= _value <= C.MAX_FEE_FP (1000, ~1.000%)
  ///
  ///     Partner Swap Fee Points:
  ///         * _paramTypeU = 1  (ParamType.PartnerFeeFP)
  ///         * 0 <= _value <= C.MAX_FEE_FP (1000, ~1.000%)
  ///
  ///     Long-Term Swap Fee Points:
  ///         * _paramTypeU = 2  (ParamType.LongSwapFeeFP)
  ///         * 0 <= _value <= C.MAX_FEE_FP (1000, ~1.000%)
  ///
  /// @dev NOTE: Total FP = 100,000. Thus a fee portion is the number of FP out of 100,000.
  /// @dev NOTE: Must be called by an administrator.
  ///
  function setParameter(uint256 _paramTypeU, uint256 _value)
    external
    override(ICronV1PoolAdminActions)
    senderIsAdmin
    nonReentrant
  {
    ParamType paramType = ParamType(_paramTypeU);

    // 1. Determine the bit-offset for any values that require an offset to be set:
    //
    uint256 offset;
    if (paramType == ParamType.SwapFeeFP) {
      offset = C.S1_OFFSET_SHORT_TERM_FEE_FP;
    } else if (paramType == ParamType.PartnerFeeFP) {
      offset = C.S1_OFFSET_PARTNER_FEE_FP;
    } else if (paramType == ParamType.LongSwapFeeFP) {
      offset = C.S1_OFFSET_LONG_TERM_FEE_FP;
    } // else offset can be zero.

    // 2. Map _paramType numerically to the corresponding slot and then do numerical limits test
    //    and set the value if conformant. Otherwise revert with a numerical limit error from a
    //    call to BitPackingLib or a parameter error.
    //
    uint256 value = _value;
    if (paramType <= ParamType.LongSwapFeeFP && offset != 0 && _value <= C.MAX_FEE_FP) {
      slot1 = BitPackingLib.packU10(slot1, value, offset);
    } else {
      requireErrCode(
        false, /* error intentionally, 9b smaller than dedicated revert refactor of this */
        CronErrors.PARAM_ERROR
      );
    }

    emit ParameterChange(msg.sender, paramType, value);
  }

  /// @notice Enable or disable the collection of Balancer Fees. When enabled Balancer takes a
  ///         a portion of every fee collected in the pool. The pool remits fees to Balancer
  ///         automatically when onJoinPool and onExitPool are called. Disabling balancer fees
  ///         through this function supersedes any setting of balancer fee values in onJoinPool
  ///         and onExitPool.
  /// @param _collectBalancerFee When true, Balancer fees are collected, when false they are
  ///                            not collected.
  /// @dev NOTE: Must be called by the factory owner.
  ///
  function setCollectBalancerFees(bool _collectBalancerFee)
    external
    override(ICronV1FactoryOwnerActions)
    senderIsFactoryOwner
    nonReentrant
  {
    slot4 = BitPackingLib.packBit(slot4, _collectBalancerFee ? 1 : 0, C.S4_OFFSET_COLLECT_BALANCER_FEES);

    emit BoolParameterChange(msg.sender, BoolParamType.CollectBalancerFees, _collectBalancerFee);
  }

  /// @notice Sets the fee shift that splits Long-Term (LT) swap fees remaining after Balancer's cut
  ///         between the Liquidity Providers (LP) and Cron-Fi, if Cron-Fi fee collection is enabled.
  /// @param _feeShift A value between 1 and 4. Specifiying invalid values results in no-operation
  ///                  (percentages are approximate). The implication of these values are outlined
  ///                  below and are only applicable if Cron-Fi fees are being collected:
  ///
  ///                      _feeShift = 1:
  ///                          LP gets 2 fee shares (~66%), Cron-Fi gets 1 fee share (~33%)
  ///
  ///                      _feeShift = 2:
  ///                          LP gets 4 fee shares (~80%), Cron-Fi gets 1 fee share (~20%)
  ///
  ///                      _feeShift = 3:
  ///                          LP gets 8 fee shares (~88%), Cron-Fi gets 1 fee share (~12%)
  ///
  ///                      _feeShift = 4:
  ///                          LP gets 16 fee shares (~94%), Cron-Fi gets 1 fee share (~6%)
  ///
  /// @dev NOTE: Must be called by the factory owner.
  ///
  function setFeeShift(uint256 _feeShift)
    external
    override(ICronV1FactoryOwnerActions)
    senderIsFactoryOwner
    nonReentrant
  {
    requireErrCode(_feeShift >= 1 && _feeShift <= 4, CronErrors.PARAM_ERROR);

    slot3 = BitPackingLib.packFeeShiftS3(slot3, _feeShift);

    emit FeeShiftChange(msg.sender, _feeShift);
  }

  /// @notice Sets the arbitrageur list contract address, _arbitrageList, for an arbitrage
  ///         partner, _arbPartner. To clear an arbitrage partner, set _arbitrageList to the
  ///         null address.
  /// @param _arbPartner The address of the arbitrage partner. This should be the aribtrage
  ///                    partner's public address and shareable with members of the the
  ///                    arbitrage list contract.
  /// @param _arbitrageList The address of a deployed arbitrageur list contract for the
  ///                       specified arbitrage partner. The deployed contract should
  ///                       conform to the interface IArbitrageurList.
  ///
  /// @dev NOTE: Must be called by an administrator.
  ///
  function setArbitragePartner(address _arbPartner, address _arbitrageList)
    external
    override(ICronV1PoolAdminActions)
    senderIsAdmin
    nonReentrant
  {
    partnerContractAddrMap[_arbPartner] = _arbitrageList;
    emit UpdatedArbitragePartner(msg.sender, _arbPartner, _arbitrageList);
  }

  /// @notice Advances the specified arbitrage partner (msg.sender) arbitrageur list
  ///         contract to the newest contract, if available. See IArbitrageurList for
  ///         details on the calls made by this contract to that interface's nextList
  ///         function.
  /// @return the new arbitrageur list contract address.
  /// @dev NOTE: Must be called by an arbitrage partner.
  ///
  function updateArbitrageList()
    external
    override(ICronV1PoolArbitrageurActions)
    senderIsArbitragePartner
    nonReentrant
    returns (address)
  {
    address currentList;
    address oldList = partnerContractAddrMap[msg.sender];
    address nextList = oldList;

    do {
      currentList = nextList;
      nextList = IArbitrageurList(currentList).nextList();
    } while (nextList != C.NULL_ADDR);

    partnerContractAddrMap[msg.sender] = currentList;

    emit UpdatedArbitrageList(msg.sender, oldList, currentList);
    return currentList;
  }

  /// @notice Executes active virtual orders, Long-Term swaps, since the last virtual order block
  ///         executed,  updating reserve and other state variables to the current block.
  /// @param _maxBlock A block to update the virtual orders to. In most situations this would be
  ///                  the current block, however if the pool has been inactive for a considerable
  ///                  duration, specifying an earlier block allows gas use to be reduced in the event
  ///                  that the gas needed to update to the current block for a transaction to be
  ///                  performed exceeds the nominal or extended amounts available to an Ethereum
  ///                  transaction (15M & 30M respectively at the time of this writing).
  ///                  If the specified max block preceeds the last virtual order block then the
  ///                  current block number is automatically used.
  ///
  function executeVirtualOrdersToBlock(uint256 _maxBlock)
    external
    override(ICronV1PoolArbitrageurActions)
    nonReentrant
  {
    _triggerVaultReentrancyCheck();
    (, uint256[] memory balances, ) = VAULT.getPoolTokens(POOL_ID);

    _executeVirtualOrders(balances[C.INDEX_TOKEN0], balances[C.INDEX_TOKEN1], _maxBlock);

    emit ExecuteVirtualOrdersEvent(msg.sender, _maxBlock);
  }

  /// @notice Get the virtual price oracle data for the pool at the specified block, _maxBlock.
  ///
  ///         IMPORTANT - This function calls _getVirtualReserves, which triggers a re-entrancy check. Due
  ///                     to contract size challanges, there is no explicit call to that re-entrancy check
  ///                     in this function, where it's presence would be more obvious.
  ///
  ///         IMPORTANT - This function does not meaningfully modify state despite the lack of a "view"
  ///                     designator for state mutability. (The call to _triggerVaultReentrancyCheck
  ///                     Unfortunately prevents the "view" designator as meaningless value is written
  ///                     to state to trigger a reentracy check).
  ///
  ///         Runs virtual orders from the last virtual order block up to the current block to provide
  ///         visibility into the current accounting for the pool.
  ///         If the pool is paused, this function reflects the accounting values of the pool at
  ///         the last virtual order block (i.e. it does not execute virtual orders to deliver the result).
  /// @param _maxBlock is the block to determine the virtual oracle values at. Its value must be
  ///                  greater than the last virtual order block and less than or equal to the
  ///                  current block. Otherwise, current block is used in the computation and
  ///                  reflected in the return value, blockNumber.
  /// @return timestamp is the virtual timestamp in seconds corresponding to the price oracle
  ///                   values.
  /// @return token0U256F112 The virtual cumulative price of Token0 measured in amount of
  ///                        Token1 * seconds at timestamp.
  /// @return token1U256F112 The virtual cumulative price of Token1 measured in amount of
  ///                        Token0 * seconds at timestamp.
  /// @return blockNumber The block that the virtual oracle values were computed at. Should
  ///                     match parameter _maxBlock, unless _maxBlock was not greater than the
  ///                     last virtual order block or less than or equal to the current block.
  /// @dev Check that blockNumber matches _maxBlock to ensure that _maxBlock was correctly
  ///      specified.
  ///
  function getVirtualPriceOracle(uint256 _maxBlock)
    external
    override(ICronV1PoolHelpers)
    returns (
      uint256 timestamp,
      uint256 token0U256F112,
      uint256 token1U256F112,
      uint256 blockNumber
    )
  {
    ExecVirtualOrdersMem memory evoMem;
    (evoMem, blockNumber) = _getVirtualReserves(
      _maxBlock,
      false /* not paused */
    );

    if (virtualOrders.lastVirtualOrderBlock > 0) {
      uint32 timeElapsed;
      (timeElapsed, timestamp) = _getOracleTimeData(blockNumber);

      token0U256F112 = priceOracle.token0U256F112;
      token1U256F112 = priceOracle.token1U256F112;
      if (timeElapsed > 0) {
        // #overUnderFlowIntended
        //                        The UQ256x112 incremented result relies upon and expects overflow
        //                        and is unchecked. The reason is that it is the difference between
        //                        price oracle samples over time that matters, not the absolute value.
        //                        As noted above, see the Uniswap V2 whitepaper.
        token0U256F112 += evoMem.token0OracleU256F112;
        token1U256F112 += evoMem.token1OracleU256F112;
      }
    }
  }

  /// @notice Returns the TWAMM pool's reserves after the non-stateful execution of all virtual orders
  ///         up to the specified maximum block (unless an invalid block is specified, which results
  ///         in execution to the current block).
  ///
  ///         IMPORTANT - This function calls _getVirtualReserves, which triggers a re-entrancy check. Due
  ///                     to contract size challanges, there is no explicit call to that re-entrancy check
  ///                     in this function, where it's presence would be more obvious.
  ///
  ///         IMPORTANT - This function does not meaningfully modify state despite the lack of a "view"
  ///                     designator for state mutability. (The call to _triggerVaultReentrancyCheck
  ///                     Unfortunately prevents the "view" designator as meaningless value is written
  ///                     to state to trigger a reentracy check).
  ///
  /// @param _maxBlock a block to update virtual orders to. If less than or equal to the last virtual order
  ///                  block or greater than the current block, the value is set to the current
  ///                  block number.
  /// @param _paused is true to indicate the result should be returned as though the pool is in a paused
  ///                state where virtual orders are not executed and only withdraw, cancel and liquidations
  ///                are possible (check function isPaused to see if the pool is in that state). If false
  ///                then the virtual reserves are computed from virtual order execution to the specified
  ///                block.
  /// @return blockNumber The block that the virtual reserve values were computed at. Should
  ///                     match parameter _maxBlock, unless _maxBlock was not greater than the
  ///                     last virtual order block or less than or equal to the current block.
  /// @return token0ReserveU112 virtual reserves of Token0 in the TWAMM pool at blockNumber.
  /// @return token1ReserveU112 virtual reserves of Token1 in the TWAMM pool at blockNumber.
  /// @return token0OrdersU112 virtual amount of Token0 remaining to be sold to the pool in LT swap orders
  ///                          at blockNumber.
  /// @return token1OrdersU112 virtual amount of Token1 remaining to be sold to the pool in LT swap orders
  ///                          at blockNumber.
  /// @return token0ProceedsU112 virtual amount of Token0 purchased from the pool by LT swap orders
  ///                            at blockNumber.
  /// @return token1ProceedsU112 virtual amount of Token1 purchased from the pool by LT swap orders
  ///                            at blockNumber.
  /// @return token0BalancerFeesU96 virtual Balancer fees collected for all types of Token0-->Token1 swaps
  ///                               at blockNumber.
  /// @return token1BalancerFeesU96 virtual Balancer fees collected for all types of Token1-->Token0 swaps
  ///                               at blockNumber.
  /// @return token0CronFiFeesU96 virtual Cron-Fi fees collected for Token0-->Token1 Long-Term swaps at
  ///                             blockNumber.
  /// @return token1CronFiFeesU96 virtual Cron-Fi fees collected for Token1-->Token0 Long-Term swaps at
  ///                             blockNumber.
  ///
  function getVirtualReserves(uint256 _maxBlock, bool _paused)
    external
    override(ICronV1PoolHelpers)
    returns (
      uint256 blockNumber,
      uint256 token0ReserveU112,
      uint256 token1ReserveU112,
      uint256 token0OrdersU112,
      uint256 token1OrdersU112,
      uint256 token0ProceedsU112,
      uint256 token1ProceedsU112,
      uint256 token0BalancerFeesU96,
      uint256 token1BalancerFeesU96,
      uint256 token0CronFiFeesU96,
      uint256 token1CronFiFeesU96
    )
  {
    ExecVirtualOrdersMem memory evoMem;
    (evoMem, blockNumber) = _getVirtualReserves(_maxBlock, _paused);

    token0ReserveU112 = evoMem.token0ReserveU112;
    token1ReserveU112 = evoMem.token1ReserveU112;

    // Note that the order difference is a subtraction (virtual orders change orders
    // by selling them into the pool reserves):
    (uint256 t0Orders, uint256 t1Orders) = BitPackingLib.unpackPairU112(slot1);
    token0OrdersU112 = t0Orders - evoMem.token0OrdersU112;
    token1OrdersU112 = t1Orders - evoMem.token1OrdersU112;

    (uint256 t0Proceeds, uint256 t1Proceeds) = BitPackingLib.unpackPairU112(slot2);
    token0ProceedsU112 = t0Proceeds + evoMem.token0ProceedsU112;
    token1ProceedsU112 = t1Proceeds + evoMem.token1ProceedsU112;

    (uint256 t0BalFees, uint256 t1BalFees) = BitPackingLib.unpackPairU96(slot4);
    token0BalancerFeesU96 = t0BalFees + evoMem.token0BalancerFeesU96;
    token1BalancerFeesU96 = t1BalFees + evoMem.token1BalancerFeesU96;

    (uint256 t0CronFiFees, uint256 t1CronFiFees) = BitPackingLib.unpackPairU96(slot3);
    token0CronFiFeesU96 = t0CronFiFees + evoMem.token0CronFiFeesU96;
    token1CronFiFeesU96 = t1CronFiFees + evoMem.token1CronFiFeesU96;
  }

  /// @notice Get the price oracle data for the pool as of the last virtual order block.
  /// @return timestamp is the timestamp in seconds when the price oracle was last updated.
  /// @return token0U256F112 The cumulative price of Token0 measured in amount of
  ///                        Token1 * seconds.
  /// @return token1U256F112 The cumulative price of Token1 measured in amount of
  ///                        Token0 * seconds.
  ///
  function getPriceOracle()
    external
    view
    override(ICronV1PoolHelpers)
    returns (
      uint256 timestamp,
      uint256 token0U256F112,
      uint256 token1U256F112
    )
  {
    timestamp = BitPackingLib.unpackOracleTimeStampS2(slot2);
    token0U256F112 = priceOracle.token0U256F112;
    token1U256F112 = priceOracle.token1U256F112;
  }

  /// @notice Return an array of the order IDs for the specified user _owner. Allows all orders to be fetched
  ///         at once or pagination through the _offset and _maxResults parameters. For instance to get the
  ///         first 100 orderIds of a user, specify _offset=0 and _maxResults=100. To get the second 100
  ///         orderIds for the same user, specify _offset=100 and _maxResults=100. To get all results at once,
  ///         either specify all known results or 0 for _maxResults.
  /// @param  _owner is the address of the owner to fetch order ids for.
  /// @param  _offset is the number of elements from the end of the list to start fetching results from (
  ///                 consult the operating description above).
  /// @param  _maxResults is the maximum number of results to return when calling this function (i.e. if
  ///                     this is set to 1,000 and there are 10,000 results available, only 1,000 from the
  ///                     specified offset will be returned). If 0 is specified, then all results available are
  ///                     returned.
  /// @return orderIds A uint256 array of order IDs associated with user's address.
  /// @return numResults The number of order IDs returned (if a user has less than the specified maximum
  ///                    number of results, indices in the returned order ids array after numResults-1 will
  ///                    be zero).
  /// @return totalResults The total number of order IDs associated with this user's address.
  ///                      (Useful for pagination of results--i.e. increase _offset by 100 until
  ///                       totalResults - 100 is reached).
  ///
  function getOrderIds(
    address _owner,
    uint256 _offset,
    uint256 _maxResults
  )
    external
    view
    override(ICronV1PoolHelpers)
    returns (
      uint256[] memory orderIds,
      uint256 numResults,
      uint256 totalResults
    )
  {
    uint256[] storage orderIdArr = orderIdMap[_owner];
    totalResults = orderIdArr.length;

    uint256 maxResults = (_maxResults == 0) ? totalResults : _maxResults;
    orderIds = new uint256[](maxResults);

    for (uint256 index = _offset; numResults < maxResults && index < totalResults; index++) {
      orderIds[numResults++] = orderIdArr[index];
    }
  }

  /// @notice Return the order information of a given order id.
  /// @param _orderId is the id of the order to return.
  /// @return order is the order data corresponding to the given order id. See Order struct documentation
  ///               for additional information.
  ///
  function getOrder(uint256 _orderId) external view override(ICronV1PoolHelpers) returns (Order memory order) {
    return virtualOrders.orderMap[_orderId];
  }

  /// @notice Returns the number of virtual orders, Long-Term (LT) swaps, that have been transacted in
  ///         this pool.
  /// @return nextOrderId The number of virtual orders issued (also the next order ID that is
  ///                     assigned to a LT swap.)
  ///
  function getOrderIdCount() external view override(ICronV1PoolHelpers) returns (uint256 nextOrderId) {
    nextOrderId = virtualOrders.nextOrderId;
  }

  /// @notice Returns the sales rate of each of the two order pools at the last virtual order block.
  ///         This is the value persisted to state.
  /// @return salesRate0U112 order pool 0 sales rate. The amount of Token 0 sold to the pool, per block,
  ///                        in exchange for Token 1, on behalf of all active Long-Term (LT) swap orders,
  ///                        swapping Token0 for Token1, as of the last virtual order block.
  ///                        Min. = 0, Max. = (2**112) - 1
  /// @return salesRate1U112 order pool 1 sales rate. The amount of Token 1 sold to the pool, per block,
  ///                        in exchange for Token 0, on behalf of all active Long-Term (LT) swap orders,
  ///                        swapping Token1 for Token0, as of the last virtual order block.
  ///                        Min. = 0, Max. = (2**112) - 1
  ///
  function getSalesRates()
    external
    view
    override(ICronV1PoolHelpers)
    returns (uint256 salesRate0U112, uint256 salesRate1U112)
  {
    uint256 salesRates = virtualOrders.orderPools.currentSalesRates;
    salesRate0U112 = (salesRates >> 112) & C.MAX_U112;
    salesRate1U112 = salesRates & C.MAX_U112;
  }

  /// @notice Get the Last Virtual Order Block (LVOB) for the pool. This is the block number indicating the last block
  ///         where virtual orders have been executed by the pool. If the LVOB is significantly less than the current
  ///         block number, it indicates that the pool has been inactive and that a call to any function that requires
  ///         the execution of virtual orders may incur siginificant gas use.
  /// @return lastVirtualOrderBlock is the last block number that virtual orders have been executed to.
  ///
  function getLastVirtualOrderBlock()
    external
    view
    override(ICronV1PoolHelpers)
    returns (uint256 lastVirtualOrderBlock)
  {
    return virtualOrders.lastVirtualOrderBlock;
  }

  /// @notice Get the sales rate ending (per block) at the specified block number.
  /// @param salesRateEndingPerBlock0U112 the amount of Token 0 per block that will stop being sold
  ///                                     to the pool after the specified block.
  ///                                     Min. = 0, Max. = (2**112) - 1
  /// @param salesRateEndingPerBlock1U112 the amount of Token 0 per block that will stop being sold
  ///                                     to the pool after the specified block.
  ///                                     Min. = 0, Max. = (2**112) - 1
  /// @dev NOTE: these values are inserted into state at block numbers divisible by the Order Block
  ///            Interval (OBI)--specifiying block numbers other than those evenly divisible by the
  ///            OBI will result in the returned values being zero.
  ///
  function getSalesRatesEndingPerBlock(uint256 _blockNumber)
    external
    view
    override(ICronV1PoolHelpers)
    returns (uint256 salesRateEndingPerBlock0U112, uint256 salesRateEndingPerBlock1U112)
  {
    (salesRateEndingPerBlock0U112, salesRateEndingPerBlock1U112) = BitPackingLib.unpackPairU112(
      virtualOrders.orderPools.salesRatesEndingPerBlock[_blockNumber]
    );
  }

  // Slot 1 Access Functions:
  //
  ////////////////////////////////////////////////////////////////////////////////

  /// @notice Gets the current Short-Term (ST) swap fee for the pool in Fee Points.
  /// @return The ST swap Fee Points (FP).
  ///         Min. = 0, Max. = 1000 (C.MAX_FEE_FP)
  /// @dev NOTE: Total FP = 100,000. Thus a fee portion is the number of FP out
  ///            of 100,000.
  ///
  function getShortTermFeePoints() external view override(ICronV1PoolHelpers) returns (uint256) {
    return BitPackingLib.unpackU10(slot1, C.S1_OFFSET_SHORT_TERM_FEE_FP);
  }

  /// @notice Gets the current Partner swap fee for the pool in Fee Points.
  /// @return The Partner swap Fee Points (FP).
  ///         Min. = 0, Max. = 1000 (C.MAX_FEE_FP)
  /// @dev NOTE: Total FP = 100,000. Thus a fee portion is the number of FP out
  ///            of 100,000.
  ///
  function getPartnerFeePoints() external view override(ICronV1PoolHelpers) returns (uint256) {
    return BitPackingLib.unpackU10(slot1, C.S1_OFFSET_PARTNER_FEE_FP);
  }

  /// @notice Gets the current Long-Term (LT) swap fee for the pool in Fee Points.
  /// @return The LT swap Fee Points (FP).
  ///         Min. = 0, Max. = 1000 (C.MAX_FEE_FP)
  /// @dev NOTE: Total FP = 100,000. Thus a fee portion is the number of FP out
  ///            of 100,000.
  ///
  function getLongTermFeePoints() external view override(ICronV1PoolHelpers) returns (uint256) {
    return BitPackingLib.unpackU10(slot1, C.S1_OFFSET_LONG_TERM_FEE_FP);
  }

  /// @notice Gets the amounts of Token0 and Token1 in active virtual orders waiting to
  ///         be sold to the pool as of the last virtual order block.
  /// @return orders0U112 is the aggregated amount of Token0 for active swaps from Token0 to Token1,
  ///         waiting to be sold to the pool since the last virtual order block.
  ///         Min. = 0, Max. = (2**112)-1
  /// @return orders1U112 is the aggregated amount of Token1 for active swaps from Token1 to Token0,
  ///         waiting to be sold to the pool since the last virtual order block.
  ///         Min. = 0, Max. = (2**112)-1
  ///
  function getOrderAmounts()
    external
    view
    override(ICronV1PoolHelpers)
    returns (uint256 orders0U112, uint256 orders1U112)
  {
    (orders0U112, orders1U112) = BitPackingLib.unpackPairU112(slot1);
  }

  // Slot 2 Access Functions:
  //
  ////////////////////////////////////////////////////////////////////////////////

  /// @notice Get the proceeds of Token0 and Token1 resulting from
  ///         virtual orders, Long-Term swaps, up to the last virtual order block.
  /// @return proceeds0U112 is the aggregated amount of Token0 from swaps selling Token1 for Token0
  ///                       to the pool, waiting to be withdrawn, as of the last virtual order block.
  ///                       Min. = 0, Max. = (2**112)-1
  /// @return proceeds1U112 is the aggregated amount of Token1 from swaps selling Token1 for Token0
  ///                       to the pool, waiting to be withdrawn, as of the last virtual order block.
  ///                       Min. = 0, Max. = (2**112)-1
  ///
  function getProceedAmounts()
    external
    view
    override(ICronV1PoolHelpers)
    returns (uint256 proceeds0U112, uint256 proceeds1U112)
  {
    (proceeds0U112, proceeds1U112) = BitPackingLib.unpackPairU112(slot2);
  }

  // Slot 3 Access Functions:
  //
  ////////////////////////////////////////////////////////////////////////////////

  /// @notice Gets the current value of the fee shift, which indicates how Long-Term (LT) swap fees are
  ///         split between Cron-Fi and Liquidity Providers (LPs) when Cron-Fi fee collection is enabled.
  /// @return A value between 1 and 4 that is the fee shift used to determine fee spliting between Cron-Fi
  ///         and LPs:
  ///
  ///               Fee Shift = 1:
  ///                   LP gets 2 fee shares (~66%), Cron-Fi gets 1 fee share (~33%)
  ///
  ///               Fee Shift = 2:
  ///                   LP gets 4 fee shares (~80%), Cron-Fi gets 1 fee share (~20%)
  ///
  ///               Fee Shift = 3:
  ///                   LP gets 8 fee shares (~88%), Cron-Fi gets 1 fee share (~12%)
  ///
  ///               Fee Shift = 4:
  ///                   LP gets 16 fee shares (~94%), Cron-Fi gets 1 fee share (~6%)
  ///
  function getFeeShift() external view override(ICronV1PoolHelpers) returns (uint256) {
    return BitPackingLib.unpackFeeShiftS3(slot3);
  }

  /// @notice Gets the amounts of Token0 and Token1 collected as Cron-Fi fees on Long-Term (LT) swaps
  ///         as of the last virtual order block.
  /// @return cronFee0U96 the amount of Token0 Cron-Fi fees collected as of the last virtual order block.
  ///                      Min. = 0, Max. = (2**96) - 1
  /// @return cronFee1U96 the amount of Token1 Cron-Fi fees collected as of the last virtual order block.
  ///                      Min. = 0, Max. = (2**96) - 1
  ///
  function getCronFeeAmounts()
    external
    view
    override(ICronV1PoolHelpers)
    returns (uint256 cronFee0U96, uint256 cronFee1U96)
  {
    (cronFee0U96, cronFee1U96) = BitPackingLib.unpackPairU96(slot3);
  }

  // Slot 4 Access Functions:
  //
  ////////////////////////////////////////////////////////////////////////////////

  /// @notice Use to determine if the pool is collecting Cron-Fi fees currently (Cron-Fi fees are only
  ///         collected on Long-Term swaps if enabled).
  /// @return True if the pool is collecting Cron-Fi fees, false otherwise.
  ///
  function isCollectingCronFees() external view override(ICronV1PoolHelpers) returns (bool) {
    return BitPackingLib.unpackBit(slot4, C.S4_OFFSET_CRON_FEE_ENABLED) != C.FALSE;
  }

  /// @notice Use to determine if the pool is collecting Balancer fees currently (Balancer fees apply to
  ///         any fee collected by the pool--Short and Long Term swaps).
  /// @return True if the pool is collecting Balancer fees, false otherwise.
  ///
  function isCollectingBalancerFees() external view override(ICronV1PoolHelpers) returns (bool) {
    return BitPackingLib.unpackBit(slot4, C.S4_OFFSET_COLLECT_BALANCER_FEES) != C.FALSE;
  }

  /// @notice Get the Balancer Fee charged by the pool.
  /// @return The current Balancer Fee, a number that is divided by 1e18 (C.ONE_DU1_18) to arrive at a
  ///         fee multiplier between 0 and 1 with 18 fractional decimal digits.
  ///         Min. = 0.000000000000000000, Max. = 1.000000000000000000
  ///
  function getBalancerFee() external view override(ICronV1PoolHelpers) returns (uint256) {
    return BitPackingLib.unpackBalancerFeeS4(slot4);
  }

  /// @notice Gets the amounts of Token0 and Token1 collected as Balancer fees on all swaps as of the last
  ///         virtual order block.
  /// @return balFee0U96 the amount of Token0 Balancer fees collected as of the last virtual order block.
  ///                      Min. = 0, Max. = (2**96) - 1
  /// @return balFee1U96 the amount of Token1 Balancer fees collected as of the last virtual order block.
  ///                      Min. = 0, Max. = (2**96) - 1
  ///
  function getBalancerFeeAmounts()
    external
    view
    override(ICronV1PoolHelpers)
    returns (uint256 balFee0U96, uint256 balFee1U96)
  {
    (balFee0U96, balFee1U96) = BitPackingLib.unpackPairU96(slot4);
  }

  /// @notice Use to determine if the pool's virtual orders are currently paused. If virtual orders are
  ///         paused, the pool will allow Long-Term (LT) swaps to be cancelled and withdrawn from as well
  ///         as liquidity positions to be withdrawn.
  /// @return True if the pool is paused, false otherwise.
  ///
  function isPaused() public view override(ICronV1PoolHelpers) returns (bool) {
    return BitPackingLib.unpackBit(slot4, C.S4_OFFSET_PAUSE) != C.FALSE;
  }

  /// @notice Reverts with error if msg.sender is not the factory owner.
  /// @dev This internal function is a modifier contract size optimization.
  ///
  function _senderIsFactoryOwner() internal view {
    requireErrCode(msg.sender == ICronV1PoolFactory(FACTORY).owner(), CronErrors.SENDER_NOT_FACTORY_OWNER);
  }

  /// @notice Reverts with error if msg.sender is not a pool administrator.
  /// @dev This internal function is a modifier contract size optimization.
  ///
  function _senderIsAdmin() internal view {
    requireErrCode(adminAddrMap[msg.sender], CronErrors.SENDER_NOT_ADMIN);
  }

  /// @notice Reverts with error if msg.sender is not an arbitrage partner.
  /// @dev This internal function is a modifier contract size optimization.
  ///
  function _senderIsArbitragePartner() internal view {
    requireErrCode(partnerContractAddrMap[msg.sender] != C.NULL_ADDR, CronErrors.SENDER_NOT_ARBITRAGE_PARTNER);
  }

  /// @notice Reverts with error if the pool is paused.
  /// @dev This internal function is a modifier contract size optimization.
  ///
  function _poolNotPaused() internal view {
    requireErrCode(!isPaused(), CronErrors.POOL_PAUSED);
  }

  /// @notice Computes the proceeds of a virtual order, Long-Term (LT) swap, for withdrawl or
  ///         cancellation purposes. Proceeds are determined using the staking algorithm, where
  ///         the user's order sales rate, _stakedAmountU128, represents their stake and the
  ///         difference between the normalized proceeds at this juncture or their order end and
  ///         order start are used to calculate their share. The normalized proceeds are
  ///         stored in 128-bits with 64 fractional-bits, hence the scaling down by 64-bits below.
  /// @param _scaledProceedsU128 The current or order end normalized scaled proceeds value.
  /// @param _startScaledProceedsU128 The normalized scaled proceeds value at the start of the
  ///                                 order (or when it was last withdrawn from).
  /// @param _salesRateU112 The order's sales rate in token per block.
  /// @param _token0To1 the direction of this swap, true if selling Token 0 for Token1, false otherwise.
  /// @dev Note explanations for required underflow in this calculation below.
  ///
  function _calculateProceeds(
    uint256 _scaledProceedsU128,
    uint256 _startScaledProceedsU128,
    uint256 _salesRateU112,
    bool _token0To1
  ) internal view returns (uint256 proceedsU112) {
    // NOTE: uint128 casts used here instead of as arguments to this function for gas/size efficiency.

    // #overUnderFlowIntended
    //                        Underflow is required here because it's not the scaled proceeds value but the distance
    //                        between them that is important. Underflow maintains the distance relationship. Consult
    //                        the Cron-Fi TWAMM Numerical Analysis for a discussion and analysis on this matter.
    uint256 orderProceedsU128 = uint128(uint128(_scaledProceedsU128) - uint128(_startScaledProceedsU128));

    // #unchecked
    //            The multiplication below is not checked for overflow because the product of a U128 and U112
    //            cannot exceed a U256. (The order proceeds is correct by construction because it is recovered
    //            from a 128-bit storage that checks for 128-bit overflow when stored, the sales rate is known
    //            to be 112-bits or less because Balancer checks the amount in with BAL#526
    //            BALANCE_TOTAL_OVERFLOW, which is then divided by the number of sales blocks).
    //
    //            Proceeds is not examined to see if it exceeds MAX_U112 because it is checked downstream from
    //            its use here in the bit packing library's decrementPairU112 function call for underflow on
    //            subtraction from a U112.
    proceedsU112 =
      (orderProceedsU128 * _salesRateU112) /
      (_token0To1 ? ORDER_POOL0_PROCEEDS_SCALING : ORDER_POOL1_PROCEEDS_SCALING);
  }

  /// @notice executes existing Virtual Orders (Long-Term-swaps) since last virtual order block,
  ///         updating TWAMM reserve values and other TWAMM state variables up to the specified
  ///         maximum block.
  /// @param _balance0U112 The Balancer Vault balance of Token 0 for this pool.
  ///                      Min. = 0, Max. = (2**112) - 1
  /// @param _balance1U112 The Balancer Vault balance of Token 1 for this pool.
  ///                      Min. = 0, Max. = (2**112) - 1
  /// @param _maxBlock a block to update virtual orders to (useful to specify in emergency situation
  ///                  where inactive pool requires too much gas for a single successful call to
  ///                  executeVirtualOrders.) If less than or equal to the last virtual order block
  ///                  or greater than the current block, the value is set to the current block number.
  /// @param token0ReserveU112 is the Token 0 reserves of the pool as of _maxBlock.
  ///                          Min. = 0, Max. = (2**112) - 1
  /// @param token1ReserveU112 is the Token 1 reserves of the pool as of _maxBlock.
  ///                          Min. = 0, Max. = (2**112) - 1
  ///
  function _executeVirtualOrders(
    uint256 _balance0U112,
    uint256 _balance1U112,
    uint256 _maxBlock
  ) private returns (uint256 token0ReserveU112, uint256 token1ReserveU112) {
    if (!(virtualOrders.lastVirtualOrderBlock < _maxBlock && _maxBlock <= block.number)) {
      _maxBlock = block.number;
    }

    uint256 localSlot4 = slot4; // #savegas
    ExecVirtualOrdersMem memory evoMem = _getExecVirtualOrdersMem(_balance0U112, _balance1U112);

    if (!isPaused()) {
      _executeVirtualOrdersToBlock(evoMem, _maxBlock);

      // Optimization:
      //               (evoMem.feeShiftU3 != 0) --> cronFeeEnabled == true
      //
      //               Rather than read from storage again, use the value of feeShiftU3 that was set in
      //               _getExecVirtualOrdersMem based on the cron fee enabled flag (S4_OFFSET_CRON_FEE_ENABLED).
      //               (feeShiftU3 can only take on values 1 through 4 once Cron-Fi fees are enabled, and is 1
      //               on construction).
      if (evoMem.feeShiftU3 != 0) {
        // CAREFUL!  Note the change to localSlot4 here!!! It gets set below when balancer fees
        //           are updated.
        localSlot4 = BitPackingLib.packBit(localSlot4, 0, C.S4_OFFSET_ZERO_CRONFI_FEES);

        slot3 = BitPackingLib.incrementPairWithClampU96(slot3, evoMem.token0CronFiFeesU96, evoMem.token1CronFiFeesU96);
      }

      slot4 = BitPackingLib.incrementPairWithClampU96(
        localSlot4,
        evoMem.token0BalancerFeesU96,
        evoMem.token1BalancerFeesU96
      );

      // Update order accounting:
      //
      slot1 = BitPackingLib.decrementPairU112(slot1, evoMem.token0OrdersU112, evoMem.token1OrdersU112);

      // Update proceeds accounting:
      //
      slot2 = BitPackingLib.incrementPairU112(slot2, evoMem.token0ProceedsU112, evoMem.token1ProceedsU112);

      // As in UNI V2, the oracle price is based on the reserves before the current operation (i.e. swap).
      // For TWAMM, we augment that to incorporate the reserves after executing virtual operations.
      //
      // NOTE: We only update the oracle when not paused.  If paused, pricing info becomes distorted and
      //       shouldn't be incorporated into the oracle.
      //
      _updateOracle(evoMem, _maxBlock);
    }

    token0ReserveU112 = evoMem.token0ReserveU112;
    token1ReserveU112 = evoMem.token1ReserveU112;
  }

  /// @notice Executes all active virtual orders from the last virtual order block stored
  ///         in state to the specified order block, _blockNumber. The specified order block
  ///         should be greater than the last virtual order block. Writes updates and changes
  ///         to state.
  /// @param _evoMem aggregated information for gas efficient virtual order exection. See
  ///                documentation in Structs.sol.
  /// @param _blockNumber is the block number to execute active virtual orders up to from
  ///                     the last virtual order block.
  /// @dev NOTE: Total FP = 100,000. Thus a fee portion is the number of FP out of 100,000.
  ///
  function _executeVirtualOrdersToBlock(ExecVirtualOrdersMem memory _evoMem, uint256 _blockNumber) private {
    uint256 poolFeeLTFP = BitPackingLib.unpackU10(slot1, C.S1_OFFSET_LONG_TERM_FEE_FP);
    (LoopMem memory loopMem, uint256 expiryBlock) = _getLoopMem();

    // Loop through active virtual orders preceeding the final block interval, performing
    // aggregate Long-Term (LT) swaps and updating sales rates in memory and scaled proceeds
    // in state.
    //
    uint256 prevLVOB = loopMem.lastVirtualOrderBlock;
    while (expiryBlock < _blockNumber) {
      _executeVirtualTradesAndOrderExpiries(_evoMem, expiryBlock, loopMem, poolFeeLTFP);

      _calculateOracleIncrement(_evoMem, prevLVOB, expiryBlock);
      prevLVOB = loopMem.lastVirtualOrderBlock;

      // Handle orders expiring at end of interval
      _decrementSalesRates(expiryBlock, loopMem);
      _storeScaledProceeds(loopMem, expiryBlock);

      expiryBlock += ORDER_BLOCK_INTERVAL;
    }

    // Process the active virtual orders of the final block interval, performing
    // aggregate Long-Term (LT) swaps and updating sales rates in memory and scaled proceeds
    // in state.
    //
    if (loopMem.lastVirtualOrderBlock != _blockNumber) {
      expiryBlock = _blockNumber;
      _executeVirtualTradesAndOrderExpiries(_evoMem, expiryBlock, loopMem, poolFeeLTFP);

      _calculateOracleIncrement(_evoMem, prevLVOB, _blockNumber);

      // Handle orders expiring at end of interval
      _decrementSalesRates(expiryBlock, loopMem);
      _storeScaledProceeds(loopMem, expiryBlock);
    }

    // Update virtual order and order pool state from values in memory:
    //
    virtualOrders.lastVirtualOrderBlock = loopMem.lastVirtualOrderBlock;
    virtualOrders.orderPools.currentSalesRates = BitPackingLib.packPairU112(
      0,
      loopMem.currentSalesRate0U112,
      loopMem.currentSalesRate1U112
    );
    virtualOrders.orderPools.scaledProceeds = BitPackingLib.packPairU128(
      loopMem.scaledProceeds0U128,
      loopMem.scaledProceeds1U128
    );
  }

  /// @notice Stores the scaled proceeds contained in _loopMem in state at the given block number,
  ///         _expiryBlock.
  /// @param _loopMem aggregated information for gas efficient virtual order loop execution. See
  ///                 documentation in Structs.sol.
  /// @param _expiryBlock is the next block upon which virtual orders expire. It is aligned on
  ///                     multiples of the order block interval.
  ///
  function _storeScaledProceeds(LoopMem memory _loopMem, uint256 _expiryBlock) private {
    virtualOrders.scaledProceedsAtBlock[_expiryBlock] = BitPackingLib.packPairU128(
      _loopMem.scaledProceeds0U128,
      _loopMem.scaledProceeds1U128
    );
  }

  /// @notice Update the price oracle on the first transaction within a block (Uniswap V2 style Price
  ///         Oracle adapted for TWAMM).
  /// @param _evoMem aggregated information for gas efficient virtual order exection. See
  ///                documentation in Structs.sol.
  /// @param _updateBlock is the block number specified in the calling function. This may be less
  ///                     than the current block number (for example if executeVirtualOrdersToBlock
  ///                     is called with a number less than the current block number to free up
  ///                     excess gas load from inactivity).
  ///
  function _updateOracle(ExecVirtualOrdersMem memory _evoMem, uint256 _updateBlock) private {
    (uint32 timeElapsed, uint32 blockTimeStamp) = _getOracleTimeData(_updateBlock);

    if (timeElapsed > 0) {
      // #overUnderFlowIntended
      //                        The UQ256x112 incremented result relies upon and expects overflow
      //                        and is unchecked. The reason is that it is the difference between
      //                        price oracle samples over time that matters, not the absolute value.
      //                        As noted above, see the Uniswap V2 whitepaper.
      priceOracle.token0U256F112 += _evoMem.token0OracleU256F112;
      priceOracle.token1U256F112 += _evoMem.token1OracleU256F112;
    }

    slot2 = BitPackingLib.packOracleTimeStampS2(slot2, blockTimeStamp);
  }

  /// @notice Trigger Balancer Vault re-entrancy check for read-only re-entrancy vulnerability
  ///         described here:
  ///
  ///             https://forum.balancer.fi/t/reentrancy-vulnerability-scope-expanded/4345
  /// @dev Balancer describes this workaround as follows:
  ///
  ///          '... this is the cheapest way to trigger a reentrancy check on the Vault. In
  ///           short, it does nothing. The code "withdraws" an amount of 0 of token address(0)
  ///           from the Vault's internal balance for the calling contract (the pool) and sends
  ///           it to address(0).'
  ///
  function _triggerVaultReentrancyCheck() private {
    IVault.UserBalanceOp[] memory ops = new IVault.UserBalanceOp[](1);
    ops[0].kind = IVault.UserBalanceOpKind.WITHDRAW_INTERNAL;
    ops[0].sender = address(this);
    VAULT.manageUserBalance(ops);
  }

  /// @notice Execute a Short-Term (ST) swap atomically in a single block on one token for the other as
  ///         described in the parameters below.
  /// @param _token0To1 the direction of this swap, true if selling Token 0 for Token1, false otherwise.
  /// @param _regularSwapType is true if the swap is SwapType.RegularSwap, false if it is
  ///                         SwapType.PartnerSwap.
  /// @param _amountInU112 is the amount of token being sold to the pool in this swap.
  ///                      Min. = 0, Max. = (2**112) - 1
  /// @param _token0ReserveU112 is the current Token 0 reserves of the pool.
  ///                           Min. = 0, Max. = (2**112) - 1
  /// @param _token1ReserveU112 is the current Token 1 reserves of the pool.
  ///                           Min. = 0, Max. = (2**112) - 1
  /// @return amountOutU112 is the amount of token being bought from the pool in this swap.
  ///                       Min. = 0, Max. = (2**112) - 1
  function _shortTermSwap(
    bool _token0To1,
    bool _regularSwapType,
    uint256 _amountInU112,
    uint256 _token0ReserveU112,
    uint256 _token1ReserveU112
  ) private returns (uint256 amountOutU112) {
    uint256 swapFeeU10 = BitPackingLib.unpackU10(
      slot1,
      _regularSwapType ? C.S1_OFFSET_SHORT_TERM_FEE_FP : C.S1_OFFSET_PARTNER_FEE_FP
    );
    // #unchecked
    //            Balancer confirms the amount in does not overflow the pool (BAL#526
    //            BALANCE_TOTAL_OVERFLOW), thus the multiply of _amountInU112 and a U10
    //            cannot overflow a U256.
    uint256 grossFee = (_amountInU112 * swapFeeU10).divDown(C.TOTAL_FP);

    uint256 localSlot4 = slot4; // #savegas
    uint256 collectBalancerFees = BitPackingLib.unpackBit(localSlot4, C.S4_OFFSET_COLLECT_BALANCER_FEES);
    if (collectBalancerFees != C.FALSE) {
      uint256 balancerFeeDU1F18 = BitPackingLib.unpackBalancerFeeS4(localSlot4);
      // #unchecked
      //            Multiplication of the grossFee (which at most could be U122 as described
      //            above--and is much less because of division by C.TOTAL_FP, i.e. U106) by
      //            balancerFeeDU1F18, a U60 at most, results in U166 to U182 at worst which
      //            will not overflow a U256. Further mitigated with the division by 1e18 (U59).
      uint256 balancerFeeU112 = (grossFee * balancerFeeDU1F18).divDown(C.DENOMINATOR_DU1_18);

      // #contractsize add balancer fees from swap
      slot4 = BitPackingLib.incrementPairWithClampU96(
        localSlot4,
        (_token0To1 ? balancerFeeU112 : 0),
        (_token0To1 ? 0 : balancerFeeU112)
      );
    }

    // NOTE: LP Fees are automatically collected in the vault balances and need not be calculated here.
    // #unchecked
    //            Subtraction unchecked below because grossFee is a fraction of _amountInU112 and
    //            cannot underflow.
    //            IMPORTANT: divDown in computing the grossFee above essential to prevent underflow
    //                       zero amount in attack.
    uint256 amountInLessFeesU112 = _amountInU112 - grossFee;

    // #unchecked
    //            Balancer confirms the amount in does not overflow the pool (BAL#526
    //            BALANCE_TOTAL_OVERFLOW), thus the multiply of _amountInU112 and a value,
    //            _tokenNReserve, less than the value confirmed to not overflow will
    //            not exceed the U256 container (worst case U113).
    uint256 nextTokenInReserveU112 = (
      /* token-in reserve: */
      _token0To1 ? _token0ReserveU112 : _token1ReserveU112
    ) + amountInLessFeesU112;

    // #unchecked
    //            Because of Balancer Vault overflow checks and the way the token reserves
    //            are computed from known U112 maximum values, the multiplication below is
    //            unchecked as the product of two U112 values is not going to overflow the
    //            U256 container.
    amountOutU112 = ((
      /* token-out reserve: */
      _token0To1 ? _token1ReserveU112 : _token0ReserveU112
    ) * amountInLessFeesU112).divDown(nextTokenInReserveU112);
  }

  /// @notice Execute a Long-Term swap (LT) Virtual Order, which sells an amount of one of the pool
  ///         tokens to the pool over a number of blocks, as described in the parameters below.
  ///         An LT swap can be withdrawn one or more times until the order has expired and all proceeds
  ///         have been withdrawn.
  ///         An LT swap can be cancelled anytime before expiry for a refund of unsold tokens and any
  ///         proceeds obtained before cancellation.
  ///         To withdraw or cancel, call the IVault.exit function (see documentaion for onExitPool).
  ///         WARNING: Any amount specified that does not divide evenly into the amount of blocks for
  ///         the virtual order will end up in pool reserves, yielding the user nothing for their capital.
  ///         For instance a trade of 224 Token-0 over two intervals (OBI=75) starting at block 75 would
  ///         result in a sales rate of 2 Token-0 per block for 150 blocks, 2 Order Block Intervals (OBI),
  ///         and the remaining 74 Token-0 would end up in the pool reserves yielding no benefit to the user.
  /// @param _sender is the account issuing the LT swap transaction. Only this account can withdraw the
  ///                order.
  /// @param _delegate is an account that is able to withdraw or cancel the LT swap on behalf of the
  ///                  sender account, as long as the recipient specified is the sender account.
  ///                  If the delegate is set to the sender account, then the delegate is set
  ///                  to the null address.
  /// @param _token0To1 is the direction of this swap, true if selling Token 0 for Token1, false otherwise.
  /// @param _amountInU112 is the amount of token being sold to the pool in this swap.
  ///                      Min. = 0, Max. = (2**112) - 1
  /// @param _orderIntervals is the number of intervals to execute the LT swap before expiring. An interval
  ///                        can be 75 blocks (Stable Pool), 300 blocks (Liquid Pool) or 1200 blocks (Volatile
  ///                        Pool).
  ///                        Min. = 0, Max. = STABLE_MAX_INTERVALS,
  ///                                         LIQUID_MAX_INTERVALS,
  ///                                         VOLATILE_MAX_INTERVALS (depending on POOL_TYPE).
  /// @return orderId is the order identifier for the LT swap virtual order created. Users can see what
  ///                 order identifiers they've created by callin getOrderIds.
  /// @dev The order id for an issued order is in the event log emitted by this function. No safety is provided
  ///      for checking existing order ids being reissued because the order id space is very large: (2**256) - 1.
  ///
  /// #RISK: An order-wrap attack (where a user trys to issue so many orders that the order ID counter
  ///        overflows, giving them access to order proceeds) is unlikely since the minimum measured gas
  ///        cost of a call to onSwap resulting in a call to _longTermSwap is ~220k gas (not including
  ///        approvals and transfers).
  ///
  function _longTermSwap(
    address _sender,
    address _delegate,
    bool _token0To1,
    uint256 _amountInU112,
    uint256 _orderIntervals
  ) private returns (uint256 orderId) {
    // #RISK: The accumulation of scaled proceeds works based on the difference between the proceeds
    //        at collection and the proceeds at submission. Underflow is supported when subtracting these
    //        values, however, there is a risk that an order goes so long that the proceeds overflow twice.
    //        It's an unlikely risk that occurs in pools with extremely asymmetric reserves, but this
    //        maximum order length serves to reduce that risk.
    requireErrCode(_orderIntervals <= MAX_ORDER_INTERVALS, CronErrors.MAX_ORDER_LENGTH_EXCEEDED);

    // Determine selling rate based on number of blocks to expiry and total amount:
    //
    // #unchecked:
    //             Subtraction in assignment of lastExpiryBlock won't underflow because the
    //             block number will always be greater than the ORDER_BLOCK_INTERVAL on mainnet until
    //             it overflows in a very long time (suspect the universe may have collapsed by then).
    //
    //             Overflow not possible in the multiplication and addition of the assignment of
    //             orderExpiry in a reasonable time (i.e. universe may collapse first). Reason is
    //             that max(_orderIntervals) = STABLE_MAX_INTERVALS (18-bits), max(ORDER_BLOCK_INTERVAL) =
    //             VOLATILE_OBI (16-bits), which the product of maxes at 34-bits. Thus lastExpiryBlock
    //             is the dominant term when the block.number approaches (2**256 - 1) - (2**34 - 1).
    //
    //             Underflow not possible in assignment to tradeBlocks since orderExpiry always >
    //             block.number.
    uint256 lastExpiryBlock = block.number - (block.number % ORDER_BLOCK_INTERVAL);
    uint256 orderExpiry = ORDER_BLOCK_INTERVAL * (_orderIntervals + 1) + lastExpiryBlock; // +1 protects from div 0
    uint256 tradeBlocks = orderExpiry - block.number;
    uint256 sellingRateU112 = _amountInU112 / tradeBlocks; // Intended: Solidity rounds towards zero.
    requireErrCode(sellingRateU112 > 0, CronErrors.ZERO_SALES_RATE);

    // Update the current and ending sales rates state:
    //
    // NOTE: re-using pair increment methods with single value for #contractsize reduction.
    OrderPools storage ops = virtualOrders.orderPools;
    ops.currentSalesRates = BitPackingLib.incrementPairU112(
      ops.currentSalesRates,
      _token0To1 ? sellingRateU112 : 0,
      _token0To1 ? 0 : sellingRateU112
    );
    ops.salesRatesEndingPerBlock[orderExpiry] = BitPackingLib.incrementPairU112(
      ops.salesRatesEndingPerBlock[orderExpiry],
      _token0To1 ? sellingRateU112 : 0,
      _token0To1 ? 0 : sellingRateU112
    );

    // NOTE: Cast to uint112 below for sellingRateU112 is safe because _amountInU112 must be less than 112-bits
    //       as checked by Balancer and reverted with Balancer error BAL#526 BALANCE_TOTAL_OVERFLOW.
    // NOTE: Cast to uint128 below for unpackPairU128 is safe because the result of that function
    //       cannot execeed 128-bits (correct by construction, i.e. function pulls a 128-bit value from
    //       packed storage in 256-bit slot).
    // NOTE: scaledProceeds0 is measured in amount of Token 1 received for selling Token 0 from Order Pool 0
    //       to the AMM (and vice-versa scaledProceeds1).
    //
    // #overUnderFlowIntended
    //                        In the very distant future, the nextOrderId will overflow. Given the 5 year
    //                        order length limit, it's improbable that 2**256 -1 orders will occur and
    //                        result in the overwriting of an existing order:
    //
    //                            * Assume 12s blocks.
    //                            * Five years in seconds 157788000 (365.25d / year).
    //                            * Blocks in 5 years = 13149000.
    //                            * Conservatively overestimate 1000 orders per block,
    //                              then 13149000000 orders in 5 years.
    //                            * 34-bits used for 5 years, assuming an excessive number of orders per block.
    //                            * Caveat Emptor on those who do not withdraw their proceeds in
    //                              an insufficient amount of time from order start.
    orderId = virtualOrders.nextOrderId++;
    virtualOrders.orderMap[orderId] = Order(
      _token0To1,
      uint112(sellingRateU112),
      uint128(BitPackingLib.unpackU128(ops.scaledProceeds, _token0To1)),
      _sender,
      ((_sender != _delegate) ? _delegate : C.NULL_ADDR),
      orderExpiry
    );
    orderIdMap[_sender].push(orderId);

    // Update order accounting (add the user's order amount to the global orders accounting):
    //
    // NOTE: The amount in (_amountInU112) is not the amount that will be swapped due to
    //       truncation. The amount that will be swapped is the number of blocks in the order
    //       multiplied by the order sales rate. The remainder is implicitly added to the pool
    //       reserves, augmenting LP rewards (Caveat Emptor Design Philosophy for Swap User).
    //
    // #unchecked
    //            Multiplication below is unchecked because sellingRate is maximum U112 and
    //            tradeBlocks is maximum U24 (STABLE_OBI * STABLE_MAX_INTERVALS = 13149000 blocks),
    //            the product of which will not overflow a U256. Also note the U112 limit is checked
    //            in the increment call.
    uint256 orderAmount = sellingRateU112 * tradeBlocks;
    slot1 = BitPackingLib.incrementPairU112(slot1, (_token0To1 ? orderAmount : 0), (_token0To1 ? 0 : orderAmount));
  }

  /// @notice Withdraws any collected Cron-Fi fees from the pool and resets the pool accounting of
  ///         Cron-Fi fees to zero for both Token0 and Token1.
  /// @param _sender must be the current fee address.
  /// @return token0OutU96 Amount of Token0 collected as Cron-Fi fees in Long-Term (LT) swaps.
  ///                      Min. = 0, Max = (2**96) - 1
  /// @return token1OutU96 Amount of Token1 collected as Cron-Fi fees in LT swaps.
  ///                      Min. = 0, Max = (2**96) - 1
  ///
  function _withdrawCronFees(address _sender) private returns (uint256 token0OutU96, uint256 token1OutU96) {
    // IMPORTANT: safety check to ensure user calling this is fee address:
    requireErrCode(feeAddr == _sender, CronErrors.SENDER_NOT_FEE_ADDRESS);

    // Optimization:
    //               The U96 Cron-Fi fees below are assigned to the output tokens in onExitPool and
    //               the pool's Cron-Fi fee counters in slot3 are cleared.
    //               A flag indicating they have been cleared in slot4 is also set. This reduces the
    //               gas used in calculating pool reserves for subsequent transactions (why read slot3
    //               if the values within are zero?). See function _calculateReserves for the use of
    //               this flag in slot4.
    //               The optimization is re-used here too (why read the Cron-Fi fees from slot3
    //               if they are zero).
    uint256 localSlot4 = slot4; // #savegas
    requireErrCode(
      BitPackingLib.unpackBit(localSlot4, C.S4_OFFSET_ZERO_CRONFI_FEES) == C.FALSE,
      CronErrors.NO_FEES_AVAILABLE
    );

    // Send the Cron-Fi fees out of the pool and zero our accounting of them:
    (slot3, token0OutU96, token1OutU96) = BitPackingLib.unpackAndClearPairU96(slot3);

    // Set the Zero Cron-Fi fees flag since we've cleared the Cron-Fi fees counters:
    slot4 = BitPackingLib.packBit(localSlot4, 1, C.S4_OFFSET_ZERO_CRONFI_FEES);

    emit FeeWithdraw(_sender, token0OutU96, token1OutU96);
  }

  /// @notice A wrapper around _withdrawLongTermSwap to mitigate stack depth limitations in that method.
  ///         See documentation of _withdrawLongTermSwap for more information.
  /// @param _orderId the order id to withdraw or cancel.
  /// @param _sender is the account performing the LT swap order withdrawl or cancellation.
  ///                For long term orders, a "delegate" may be specified, this address is able to
  ///                perform LT order withdraws and cancellations on behalf of the LT swap owner as
  ///                long as the recipient is the LT swap owner.
  /// @param _recipient the recipient must always be the original order owner (the address
  ///                   that issued the order) if a "delegate" address is performing the withdrawl or
  ///                   cancellation. If the order owner is performing the withdrawl or cancellation, the
  ///                   recipient can be set to whatever destination address desired.
  /// @param _cancel if true, cancel the order, otherwise if false, withdraw the order.
  /// @return token0OutU112 the amount of Token 0 remitted from the order as either proceeds or a refund.
  ///                       Min. = 0, Max. = (2**112)-1
  /// @return token1OutU112 the amount of Token 1 remitted from the order as either proceeds or a refund.
  ///                       Min. = 0, Max. = (2**112)-1
  ///
  function _withdrawLongTermSwapWrapper(
    uint256 _orderId,
    address _sender,
    address _recipient,
    bool _cancel
  ) private returns (uint256 token0OutU112, uint256 token1OutU112) {
    Order storage order = virtualOrders.orderMap[_orderId];

    requireErrCode(order.owner != C.NULL_ADDR, CronErrors.CLEARED_ORDER);
    if (_sender != order.owner) {
      requireErrCode(_recipient == order.owner, CronErrors.RECIPIENT_NOT_OWNER);
    }
    requireErrCode(
      (_sender == order.owner || _sender == order.delegate) && _sender != C.NULL_ADDR,
      CronErrors.SENDER_NOT_ORDER_OWNER_OR_DELEGATE
    );

    (bool token0To1, uint256 refundU112, uint256 proceedsU112) = _withdrawLongTermSwap(order, _cancel);

    emit WithdrawLongTermSwap(
      order.owner,
      (_cancel)
        ? ((token0To1) ? address(TOKEN0) : address(TOKEN1)) // sell token
        : C.NULL_ADDR,
      refundU112,
      (token0To1) ? address(TOKEN1) : address(TOKEN0), // buy token
      proceedsU112,
      _orderId,
      _sender
    );

    // NOTE: The execute virtual orders run prior to this function in function onExitPool updates the
    //       orders and proceeds amounts.
    token0OutU112 = (token0To1) ? refundU112 : proceedsU112;
    token1OutU112 = (token0To1) ? proceedsU112 : refundU112;
  }

  /// @notice This function performs a withdraw or a cancel of a Long-Term (LT) swap virtual order, which
  ///         remits proceeds and if cancelling, also refunds remaining order amounts.
  ///         Funds may be withdrawn from an order multiple times up until order expiry and the last of
  ///         the proceeds are withdrawn.
  ///         Orders may be cancelled up to order expiry. Both proceeds and remaining order funds will be
  ///         remitted upon cancellation.
  /// @param _order information of a specific LT swap order. See Order struct documentation in Structs.sol.
  /// @param _cancel indicates whether the virtual order is to be cancelled if true. If false, the order
  ///                proceeds are to be withdrawn.
  /// @return token0To1 is the direction of this LT swap. It is true if selling Token 0 for Token1, false
  ///                   otherwise.
  /// @return refundU112 is the amount of token to be refunded.
  ///                    Min. = 0, Max. = (2**112) - 1
  /// @return proceedsU112 is the amount of token already purchased in the LT swap to be remitted.
  ///                      Min. = 0, Max. = (2**112) - 1
  ///
  function _withdrawLongTermSwap(Order storage _order, bool _cancel)
    private
    returns (
      bool token0To1,
      uint256 refundU112,
      uint256 proceedsU112
    )
  {
    token0To1 = _order.token0To1;
    uint256 expiryBlock = _order.orderExpiry;
    uint256 salesRateU112 = _order.salesRate;

    // NOTE: There is no need to check if order is completed using orderExpiry
    //       or salesRate, because entire Order struct is zeroed/falsed on cancel
    //       or final withdraw. A 2nd cancel or withdraw attempt will revert with
    //       CronErrors.SENDER_NOT_ORDER_OWNER_OR_DELEGATE

    // #RISK: Although the NULL_ADDR technically owns zeroed cancelled orders,
    //        anyone owning that address would be able to withdraw nothing
    //        because the salesRateU112 (order.salesRate) is zerod after
    //        cancel.
    if (_cancel) {
      // Calculate unsold amount to refund:
      //
      // NOTE: Must use last virtual order block, not block.number to yield correct result
      //       when pool is paused.
      //
      // #unchecked
      //            The subtraction is unchecked because the error check confirms that expiryBlock
      //            is larger than lastVirtualOrderBlock, preventing underflow.
      //
      //            The multiplication is unchecked for overflow because the sales rate is
      //            computed from the amount in, which is checked by Balancer (BAL#526
      //            BALANCE_TOTAL_OVERFLOW) and known to be less than U112. The maximum
      //            difference between the expiry block and last virtual order block is
      //            constrained to be U18 (the MAX_ORDER_INTERVALS largest value,
      //            STABLE_MAX_INTERVALS), the product of which cannot exceed U130.
      requireErrCode(expiryBlock > virtualOrders.lastVirtualOrderBlock, CronErrors.CANT_CANCEL_COMPLETED_ORDER);
      refundU112 = (expiryBlock - virtualOrders.lastVirtualOrderBlock) * salesRateU112;
    }

    uint256 scaledProceedsU128 = BitPackingLib.unpackU128(
      (!_cancel && (block.number > expiryBlock))
        ? virtualOrders.scaledProceedsAtBlock[expiryBlock] // Expired or cancelled order - calculate scaled proceeds at expiryBlock.
        : virtualOrders.orderPools.scaledProceeds, // Unexpired order. Remit current proceeds.
      token0To1
    );
    proceedsU112 = _calculateProceeds(
      scaledProceedsU128,
      _order.scaledProceedsAtSubmissionU128,
      salesRateU112,
      token0To1
    );

    // CAREFUL: This must come after the calculation of proceedsU112
    if (!_cancel && (block.number <= expiryBlock)) {
      // Reset stake (sales rate) if not cancellation and not expired order

      // NOTE: Cast to uint128 below for scaledProceedsAtSubmissionU128 is safe because result of function unpackPairU128
      //       cannot execeed 128-bits (correct by construction, i.e. function pulls a 128-bit value from
      //       packed storage in 256-bit slot, value is checked for overflow when it was stored).
      _order.scaledProceedsAtSubmissionU128 = uint128(scaledProceedsU128);
    }

    requireErrCode(refundU112 > 0 || proceedsU112 > 0, CronErrors.NO_FUNDS_AVAILABLE);

    if (_cancel) {
      OrderPools storage ops = virtualOrders.orderPools;

      // Decrement the current and ending sales rates:
      ops.currentSalesRates = BitPackingLib.decrementPairU112(
        ops.currentSalesRates,
        token0To1 ? salesRateU112 : 0,
        token0To1 ? 0 : salesRateU112
      );
      ops.salesRatesEndingPerBlock[expiryBlock] = BitPackingLib.decrementPairU112(
        ops.salesRatesEndingPerBlock[expiryBlock],
        token0To1 ? salesRateU112 : 0,
        token0To1 ? 0 : salesRateU112
      );

      // Update the order accounting:
      slot1 = BitPackingLib.decrementPairU112(slot1, (token0To1 ? refundU112 : 0), (token0To1 ? 0 : refundU112));
    }

    // Update the proceed accounting:
    slot2 = BitPackingLib.decrementPairU112(slot2, (token0To1 ? 0 : proceedsU112), (token0To1 ? proceedsU112 : 0));

    if (_cancel || block.number > expiryBlock) {
      // Remove stake (sales rate) and clear order state for rebate and to indicate order complete:
      _order.token0To1 = false;
      _order.salesRate = 0;
      _order.scaledProceedsAtSubmissionU128 = 0;
      _order.owner = C.NULL_ADDR;
      _order.delegate = C.NULL_ADDR;
      _order.orderExpiry = 0;
    }
  }

  /// @notice This function performs a join given the amounts of Token 0 and Token 1 to add to the pool
  ///         along with the current virtual reserves.
  /// @param _recipient is the account designated to receive pool shares in the form of LP tokens when
  ///                   Joining the pool. Can be set to _sender if sender wishes to receive the tokens
  ///                   and Join Events.
  /// @param _token0InU112 is the amount of Token 0 to Join the pool with.
  ///                      Min. = 0, Max. = (2**112) - 1
  /// @param _token1InU112 is the amount of Token 1 to Join the pool with.
  ///                      Min. = 0, Max. = (2**112) - 1
  /// @param _token0ReserveU112 is the current Token 0 reserves of the pool.
  ///                           Min. = 0, Max. = (2**112) - 1
  /// @param _token1ReserveU112 is the current Token 1 reserves of the pool.
  ///                           Min. = 0, Max. = (2**112) - 1
  /// @return amountLP is the amount of Liquidity Provider (LP) tokens returned in exchange for the
  ///                  amounts of Token 0 and Token 1 provided to the pool.
  function _join(
    address _recipient,
    uint256 _token0InU112,
    uint256 _token1InU112,
    uint256 _token0ReserveU112,
    uint256 _token1ReserveU112
  ) private returns (uint256 amountLP) {
    requireErrCode(_recipient != C.NULL_ADDR, CronErrors.NULL_RECIPIENT_ON_JOIN);

    uint256 supplyLP = totalSupply();
    if (supplyLP == 0) {
      requireErrCode(
        (_token0InU112 > C.MINIMUM_LIQUIDITY) && (_token1InU112 > C.MINIMUM_LIQUIDITY),
        CronErrors.INSUFFICIENT_LIQUIDITY
      );

      // #unchecked
      //            The check of _token0InU112 and _token1InU112 ensure that both are less
      //            than 112-bit maximums. Multiplying two 112-bit numbers will not exceed
      //            224-bits, hence no checked mul operator here.
      //            The check that both _token0InU112 and _token1InU112 exceed
      //            C.MINIMUM_LIQUIDITY, means that the square root of their product cannot
      //            be less than C.MINIMUM_LIQUIDITY, hence no checked sub operator here.
      amountLP = sqrt(_token0InU112 * _token1InU112) - C.MINIMUM_LIQUIDITY;

      // Initial Join / Mint does not execute virtual orders, is only run once b/c of MINIMUM_LIQUIDITY,
      // thus a call to update the oracle resolves to simply setting the oracle timestamp:
      slot2 = BitPackingLib.packOracleTimeStampS2(slot2, block.timestamp);

      _mintPoolTokens(address(0), C.MINIMUM_LIQUIDITY); // Permanently locked for div / 0 safety.

      // Set the last virtual order block to the block number. This reduces the gas used
      // in virtual order execution iterations for the first call to execute virtual orders
      // now that the pool has liquidity.
      virtualOrders.lastVirtualOrderBlock = block.number;
    } else {
      amountLP = Math.min(
        _token0InU112.mul(supplyLP).divDown(_token0ReserveU112),
        _token1InU112.mul(supplyLP).divDown(_token1ReserveU112)
      );
    }

    requireErrCode(amountLP > 0, CronErrors.INSUFFICIENT_LIQUIDITY);
    _mintPoolTokens(_recipient, amountLP);
  }

  /// @notice This function performs an exit given the amount of Liquidity Provider (LP) tokens
  ///         to return to the pool along with the current virtual reserves.
  /// @param _sender the account performing the liquidity removal.
  /// @param _tokensLP the number of LP tokens to redeem in exchange for the pool's asset tokens.
  /// @param _token0ReserveU112 is the current Token 0 reserves of the pool.
  ///                           Min. = 0, Max. = (2**112) - 1
  /// @param _token1ReserveU112 is the current Token 1 reserves of the pool.
  ///                           Min. = 0, Max. = (2**112) - 1
  /// @return token0OutU112 is the amount of Token 0 returned by the pool in exchange for LP tokens.
  ///                       Min. = 0, Max. = (2**112) - 1
  /// @return token1OutU112 is the amount of Token 1 returned by the pool in exchange for LP tokens.
  ///                       Min. = 0, Max. = (2**112) - 1
  ///
  function _exit(
    address _sender,
    uint256 _tokensLP,
    uint256 _token0ReserveU112,
    uint256 _token1ReserveU112
  ) private returns (uint256 token0OutU112, uint256 token1OutU112) {
    // CAREFUL: Next line must preceed burning of pool liquidity provider tokens.
    uint256 lTotalSupply = totalSupply();
    _burnPoolTokens(_sender, _tokensLP);
    token0OutU112 = (_token0ReserveU112.mul(_tokensLP)).divDown(lTotalSupply);
    token1OutU112 = (_token1ReserveU112.mul(_tokensLP)).divDown(lTotalSupply);

    emit PoolExit(_sender, _tokensLP, token0OutU112, token1OutU112);
  }

  /// @notice Handles the updating of the stored Balancer fee multiplier and remittance of any collected
  ///         Balancer fees in onJoinPool and onExitPool function calls.
  /// @param _protocolFeeDU1F18 the newest Balancer Fee passed into the pool by the onJoinPool and
  ///                           onExitPool functions. This number is divided by 1e18 (C.ONE_DU1_18) to
  ///                           arrive at a fee multiplier between 0 and 1, inclusive, with 18
  ///                           fractional decimal digits.
  ///                           Min. = 0, Max. = 10**18
  /// @return dueProtocolFeeAmountsU96 the amount of Token 0 and Token 1 collected by the pool for
  ///                                  Balancer. Values are returned in the same array ordering that
  ///                                  IVault.getPoolTokens returns.
  ///                                  Min. = 0, Max. = (2**96) - 1
  ///
  function _handleBalancerFees(uint256 _protocolFeeDU1F18) private returns (uint256[] memory dueProtocolFeeAmountsU96) {
    uint256 localSlot4 = slot4;

    if (_protocolFeeDU1F18 <= C.ONE_DU1_18) {
      uint256 currentBalancerFee = BitPackingLib.unpackBalancerFeeS4(localSlot4);
      // #savegas: check before write
      if (currentBalancerFee != _protocolFeeDU1F18) {
        localSlot4 = BitPackingLib.packBalancerFeeS4(localSlot4, _protocolFeeDU1F18);
      }
    } else {
      // Ignore change and keep operating with old fee if new fee is too large but notify through logs.
      emit ProtocolFeeTooLarge(_protocolFeeDU1F18);
    }

    // Send the Balancer fees out of the pool and zero our accounting of them:
    dueProtocolFeeAmountsU96 = new uint256[](2);
    (slot4, dueProtocolFeeAmountsU96[C.INDEX_TOKEN0], dueProtocolFeeAmountsU96[C.INDEX_TOKEN1]) = BitPackingLib
      .unpackAndClearPairU96(localSlot4);
  }

  /// @notice Returns the TWAMM pool's reserves after the non-stateful execution of all virtual orders
  ///         up to the current block.
  ///         IMPORTANT - This function does not meaningfully modify state despite the lack of a "view"
  ///                     designator for state mutability. (The call to _triggerVaultReentrancyCheck
  ///                     Unfortunately prevents the "view" designator as meaningless value is written
  ///                     to state to trigger a reentracy check).
  ///         Runs virtual orders from the last virtual order block up to the current block to provide
  ///         visibility into the current accounting for the pool.
  ///         If the pool is paused, this function reflects the accounting values of the pool at
  ///         the last virtual order block (i.e. it does not execute virtual orders to deliver the result).
  /// @param _maxBlock a block to update virtual orders to. If less than or equal to the last virtual order
  ///                  block or greater than the current block, the value is set to the current
  ///                  block number.
  /// @param _paused is true to indicate the result should be returned as though the pool is in a paused
  ///                state where virtual orders are not executed and only withdraw, cancel and liquidations
  ///                are possible (check function isPaused to see if the pool is in that state). If false
  ///                then the virtual reserves are computed from virtual order execution to the specified
  ///                block.
  /// @return evoMem a struct containing the pool's virtual reserves for Token 0 and Token 1 along with
  ///                the changes to the Orders, Proceeds, and Fee accounting to the current state values
  ///                for Token 0 and Token 1. See the documentation of struct ExecVirtualOrdersMem for
  ///                details.
  ///                IMPORTANT Note above that struct values for token0ReserveU112 and token1ReserveU112
  ///                          are the virtual values of the reserves at the current block, whereas other
  ///                          values in the ExecVirtualOrdersMem struct are the DIFFERENCES from the
  ///                          state of their respective values and their virtual values.
  /// @return blockNumber The block that the virtual reserve values were computed at. Should
  ///                     match parameter _maxBlock, unless _maxBlock was not greater than the
  ///                     last virtual order block or less than or equal to the current block.
  ///
  function _getVirtualReserves(uint256 _maxBlock, bool _paused)
    private
    returns (ExecVirtualOrdersMem memory evoMem, uint256 blockNumber)
  {
    blockNumber = (virtualOrders.lastVirtualOrderBlock < _maxBlock && _maxBlock <= block.number)
      ? _maxBlock
      : block.number;

    _triggerVaultReentrancyCheck();
    (, uint256[] memory balancesU112, ) = VAULT.getPoolTokens(POOL_ID);

    evoMem = _getExecVirtualOrdersMem(balancesU112[C.INDEX_TOKEN0], balancesU112[C.INDEX_TOKEN1]);

    if (!_paused) {
      _executeVirtualOrdersView(evoMem, blockNumber);
    }
  }

  /// @notice Executes all virtual orders between current lastVirtualOrderBlock and blockNumber
  ///         also handles orders that expire at end of final block. This assumes that no orders
  ///         expire inside the given interval.
  ///
  /// @param _evoMem aggregated information for gas efficient virtual order execution. See
  ///                documentation in Structs.sol.
  /// @param _expiryBlock is the next block upon which virtual orders expire. It is aligned on
  ///                     multiples of the order block interval.
  /// @param _loopMem aggregated information for gas efficient virtual order loop execution. See
  ///                 documentation in Structs.sol.
  /// @param _poolFeeLTFP is the pool fee charged for long term swaps in Fee Points (FP).
  /// @dev NOTE: Total FP = 100,000. Thus a fee portion is the number of FP out of 100,000.
  ///
  function _executeVirtualTradesAndOrderExpiries(
    ExecVirtualOrdersMem memory _evoMem,
    uint256 _expiryBlock,
    LoopMem memory _loopMem,
    uint256 _poolFeeLTFP
  ) private view {
    // Determine how many blocks are in the current interval and compute
    // the amount of Token0 and Token1 being sold to the pool and any
    // fees. (Fees are collected as a percentage of tokens being sold to
    // the pool as opposed to tokens bought from the pool).
    //
    // #unchecked
    //            Subtraction below is unchecked because _expiryBlock is
    //            always greater than the lastVirtualOrderBlock by at least
    //            1, and up to a block interval (see function _getLoopMem
    //            where it's initialized).
    uint256 intervalBlocks = _expiryBlock - _loopMem.lastVirtualOrderBlock;

    uint256 currentSalesRate0U112 = _loopMem.currentSalesRate0U112; // #savegas
    uint256 currentSalesRate1U112 = _loopMem.currentSalesRate1U112; // #savegas

    // #unchecked
    //            The computation of token0In and token1In are not checked
    //            for overflow. The current sales rates will not exceed MAX_U112
    //            and the number of interval blocks is bounded to a maximum of
    //            1200 (VOLATILE_OBI), well within the safe range of MAX_U256.
    //
    //            Likewise calculation of grossFeeT0 and grossFeeT1 are not
    //            checked for overflow because token0In has a maximum of MAX_U123
    //            and it's multiplied by _poolFeeLTFP which has a maximum
    //            of 1000 (MAX_FEE_FP), well within the safe range of MAX_U256.
    //
    //            grossFeeT0 and grossFeeT1 thus have a practical maximum value of
    //              MAX_U112 * 1200 * 1000 / 100000 ---> 116-bits
    //
    // NOTE: division with rounding up is performed to favor the pool.
    uint256 token0In = currentSalesRate0U112 * intervalBlocks;
    uint256 grossFeeT0 = (token0In * _poolFeeLTFP).divUp(C.TOTAL_FP);
    //
    uint256 token1In = currentSalesRate1U112 * intervalBlocks;
    uint256 grossFeeT1 = (token1In * _poolFeeLTFP).divUp(C.TOTAL_FP);

    (uint256 lpFeeT0, uint256 lpFeeT1) = _updateFees(_evoMem, grossFeeT0, grossFeeT1);

    // Compute the amount of each token bought from the pool for the current
    // interval. Then update counts for the orders sold to the pool, the
    // proceeds bought from the pool, and add the LP fees into the reserves
    // after the swap is performed (LP fees are added in after the swap because
    // otherwise, they wouldn't be implicitly collected and the reserves wouldn't
    // grow and compensate the LPs).
    //
    // #unchecked
    //            The subtraction of grossFeeT0 and grossFeeT1 from token0In and
    //            token1In, respectively, are unchecked because gross fees are
    //            computed as a fraction less than one (multiplying by a numerator
    //            that is less than the denominator) of the token in values. The resulting
    //            gross fee values will always be less than their respective token in
    //            values.
    (uint256 token0Out, uint256 token1Out) = _computeVirtualReserves(
      _evoMem,
      token0In - grossFeeT0,
      token1In - grossFeeT1
    );

    // NOTE: For gas efficiency the order and proceed amounts are summed and then
    //       used to modify the global order and proceed accounting after all
    //       iterations are performed.
    //
    // #unchecked
    //            The incrementing of tokenNOrdersU112 below is unchecked because the
    //            order amounts in are checked by Balancer (BAL#526 BALANCE_TOTAL_OVERFLOW)
    //            when orders are taken in by the pool. Repeatedly adding them to a
    //            zero initialized value (tokenNOrdersU112) would take longer to overflow
    //            than this loop could run before it runs out of gas. At the end of the
    //            loop calling this method, these values are then subtracted from the order
    //            accounting and zeroed again for the next execution (the subtraction checks
    //            for underflow on a verified <= U112 value, see BitPackingLib.decrementPairU112).
    _evoMem.token0OrdersU112 += token0In;
    _evoMem.token1OrdersU112 += token1In;

    // The check below for values exceeding U112 cover the unchecked increment of tokenNProceedsU112
    // as safe for the duration of this loop. They also cover the call to _incrementScaledProceeds
    // which depends upon the tokenNOut values being <= U112.  (The two one sided active trade use
    // cases will never produce an output > U112, need to confirm the TWAMM approximation with
    // two active trades is similar, hence the check below.)
    requireErrCode(token0Out <= C.MAX_U112, CronErrors.OVERFLOW);
    requireErrCode(token1Out <= C.MAX_U112, CronErrors.OVERFLOW);
    _evoMem.token0ProceedsU112 += token0Out;
    _evoMem.token1ProceedsU112 += token1Out;

    // Compensate the LPs:
    //
    // #unchecked
    //            The incrementing below is unchecked because the lpFeeTN values are a fraction
    //            of the grossFeeTN values which themselves are a fraction of the tokenNIn values
    //            that are known to be limited to 112-bits by the Balancer check when the order is
    //            taken (BAL#526 BALANCE_TOTAL_OVERFLOW). (As discussed above the grossFeeTN values
    //            have a maximum practical value of 116-bits which won't result in a 256-bit overflow
    //            in the increment below before the loop ends).
    _evoMem.token0ReserveU112 += lpFeeT0;
    _evoMem.token1ReserveU112 += lpFeeT1;

    // Distribute proceeds to pools:
    _incrementScaledProceeds(_loopMem, token0Out, token1Out, currentSalesRate0U112, currentSalesRate1U112);

    _loopMem.lastVirtualOrderBlock = _expiryBlock;
  }

  /// @notice Read only execution of active virtual orders from the last virtual order block
  ///         in state to the current block number. Does not write updates or changes to state.
  /// @param _evoMem aggregated information for gas efficient virtual order exection. See
  ///                documentation in Structs.sol.
  /// @param _blockNumber is the block number to execute active virtual orders up to from
  ///                     the last virtual order block.
  /// @dev NOTE: Total FP = 100,000. Thus a fee portion is the number of FP out of 100,000.
  /// @dev This method's utility comes from the values stored in _evoMem at the end of
  ///      calling it; fees, orders, proceeds and reserves will all reflect the most up-to-date
  ///      values for virtual orders at the current block.
  ///
  function _executeVirtualOrdersView(ExecVirtualOrdersMem memory _evoMem, uint256 _blockNumber) private view {
    uint256 poolFeeLTFP = BitPackingLib.unpackU10(slot1, C.S1_OFFSET_LONG_TERM_FEE_FP);
    (LoopMem memory loopMem, uint256 expiryBlock) = _getLoopMem();

    // Loop through active virtual orders preceeding the final block interval, performing
    // aggregate Long-Term (LT) swaps and updating sales rates in memory
    //
    uint256 prevLVOB = loopMem.lastVirtualOrderBlock;
    while (expiryBlock < _blockNumber) {
      _executeVirtualTradesAndOrderExpiries(_evoMem, expiryBlock, loopMem, poolFeeLTFP);

      _calculateOracleIncrement(_evoMem, prevLVOB, expiryBlock);
      prevLVOB = loopMem.lastVirtualOrderBlock;

      // Handle orders expiring at end of interval
      _decrementSalesRates(expiryBlock, loopMem);

      expiryBlock += ORDER_BLOCK_INTERVAL;
    }

    // Process the active virtual orders of the final block interval, performing
    // aggregate Long-Term (LT) swaps
    //
    if (loopMem.lastVirtualOrderBlock != _blockNumber) {
      expiryBlock = _blockNumber;
      _executeVirtualTradesAndOrderExpiries(_evoMem, expiryBlock, loopMem, poolFeeLTFP);

      _calculateOracleIncrement(_evoMem, prevLVOB, _blockNumber);
    }
  }

  /// @notice Increments the current scaled proceeds of an order pool with the normalized
  ///         proceeds of recent swaps when given the current scaled proceeds, token out amount
  ///         and sales rate of the order pools.
  /// @param _loopMem aggregated information for gas efficient virtual order loop execution. See
  ///                 documentation in Structs.sol.
  /// @param _token0OutU112 The amount of Token 0 purchased in aggregate in an interval. This amount
  ///                       is normalized by the sales rate and then increments the scaled proceeds.
  /// @param _token1OutU112 The amount of Token 1 purchased in aggregate in an interval. This amount
  ///                       is normalized by the sales rate and then increments the scaled proceeds.
  /// @param _currentSalesRate0U112 The current amount of Token 0 sold per block to the order pool.
  /// @param _currentSalesRate1U112 The current amount of Token 1 sold per block to the order pool.
  ///
  function _incrementScaledProceeds(
    LoopMem memory _loopMem,
    uint256 _token0OutU112,
    uint256 _token1OutU112,
    uint256 _currentSalesRate0U112,
    uint256 _currentSalesRate1U112
  ) private view {
    // #overUnderFlowIntended The addition of scaledProceeds below is required to overflow a uint128
    //                        to work properly. This is because when a user withdraws or
    //                        cancels their order, the distance between the scaled proceeds
    //                        at the time of withdraw/cancel from when their order started is
    //                        used to determine their portion.  In other words it's not the
    //                        value of their scaled proceeds that determines their portion but
    //                        the distance between scaled proceeds at withdraw/cancel and order
    //                        start.  As long as the scaled proceeds doesn't overflow twice
    //                        during an order, they have not lost proceeds--overflowing twice
    //                        is highly unlikely because of the scaling by the number of decimal
    //                        places of the source token in the stored result. Consult Cron-Fi TWAMM
    //                        Numerical Analysis for a discussion on this matter.
    //
    if (_currentSalesRate0U112 != 0) {
      _loopMem.scaledProceeds0U128 = uint128(
        uint128(_loopMem.scaledProceeds0U128) +
          uint128((_token1OutU112 * ORDER_POOL0_PROCEEDS_SCALING) / _currentSalesRate0U112)
      );
    }

    if (_currentSalesRate1U112 != 0) {
      _loopMem.scaledProceeds1U128 = uint128(
        uint128(_loopMem.scaledProceeds1U128) +
          uint128((_token0OutU112 * ORDER_POOL1_PROCEEDS_SCALING) / _currentSalesRate1U112)
      );
    }
  }

  /// @notice Decrements the sales rates expiring in the specified block, _expiryBlock, from the
  ///         current sales rates.
  /// @param _expiryBlock is the next block upon which virtual orders expire. It is aligned on
  ///                     multiples of the order block interval.
  /// @param _loopMem aggregated information for gas efficient virtual order loop execution. See
  ///                 documentation in Structs.sol.
  ///
  function _decrementSalesRates(uint256 _expiryBlock, LoopMem memory _loopMem) private view {
    // NOTE: Stored sales rates are correct by construction (the packPairU112 method checks for exceeding
    //       MAX_U112), thus these fetched values here are within the range of MAX_U112.
    (uint256 salesRateEndingPerBlock0U112, uint256 salesRateEndingPerBlock1U112) = BitPackingLib.unpackPairU112(
      virtualOrders.orderPools.salesRatesEndingPerBlock[_expiryBlock]
    );

    if (salesRateEndingPerBlock0U112 > 0) {
      requireErrCode(_loopMem.currentSalesRate0U112 >= salesRateEndingPerBlock0U112, CronErrors.UNDERFLOW);
      _loopMem.currentSalesRate0U112 -= salesRateEndingPerBlock0U112;
    }
    if (salesRateEndingPerBlock1U112 > 0) {
      requireErrCode(_loopMem.currentSalesRate1U112 >= salesRateEndingPerBlock1U112, CronErrors.UNDERFLOW);
      _loopMem.currentSalesRate1U112 -= salesRateEndingPerBlock1U112;
    }
  }

  /// @notice Converts the provided block number, _updateBlock, to a timestamp and returns the computed
  ///         time elapsed between the timestamp and the previous oracle timestamp.
  ///         If _updateBlock is the current block number, the block.timestamp is used for the timestamp.
  ///         Otherwise the timestamp is computed by subtracting the block time, 12s, multiplied by the
  ///         number of blocks between the current block, block.number, and the provided _updateBlock.
  /// @param _updateBlock A block number to compute a timestamp for and the elapsed time since the
  ///                     previous oracle timestamp.
  ///                     NOTE: Expects that all calling functions ensure that updateBlock <= block.number.
  /// @return timeElapsed The difference between the computed timestamp and the previous oracle timestamp.
  /// @return blockTimestamp The computed timestamp.
  ///
  function _getOracleTimeData(uint256 _updateBlock) private view returns (uint32 timeElapsed, uint32 blockTimestamp) {
    uint32 oracleTimeStamp = uint32(BitPackingLib.unpackOracleTimeStampS2(slot2));

    if (_updateBlock == block.number) {
      // _updateBlock is the current block number, use the current block timestamp:
      blockTimestamp = uint32(block.timestamp % 2**32);
    } else {
      // _update block is less than the current block, use the current block minus an approximate
      // amount of time based on the difference multiplied by the block time in seconds guaranteed
      // by the beacon chain, to generate a timestamp approximation between the current block and
      // previous last virtual order block:
      //
      // #unchecked:
      //             The subtraction of _updateBlock below is unchecked here b/c the calls to
      //             _updateOracle are guaranteed to either pass in a value less than or equal
      //             to the current block number.
      //
      //             The subtraction of the unelapsed blocks multiplied by the block time from
      //             the timestamp should be able to underflow with the modulus result being
      //             correct for the purposes herein (i.e. the nature of this entire system being
      //             based in differences makes that acceptable).
      blockTimestamp = uint32((block.timestamp - C.SECONDS_PER_BLOCK * (block.number - _updateBlock)) % 2**32);
    }

    // #overUnderFlowIntended
    //                        As documented in the Uniswap V2 whitepaper, the 32-bits allocated to
    //                        store the timestamp will overflow approximately every 136 years. As
    //                        long as users take 1 sample every 136 years, then the resulting underflow
    //                        that would occur in the following 32-bit subtraction will be appropriate
    //                        as it will yield the correct distance in seconds between the two samples.
    timeElapsed = blockTimestamp - oracleTimeStamp;
  }

  /// @notice Balancer custom pool specific safety checks.
  /// @param _sender The message sender. Must be the vault address.
  /// @param _poolId The pool ID in the calling function. Must be this pool.
  ///
  function _poolSafetyChecks(address _sender, bytes32 _poolId) private view {
    requireErrCode(_sender == address(VAULT), CronErrors.NON_VAULT_CALLER);
    requireErrCode(_poolId == POOL_ID, CronErrors.INCORRECT_POOL_ID);
  }

  /// @notice Gets an initialized instance of struct ExecVirtualOrdersMem. The
  ///         orders, proceeds and fees struct members are all initialized to zero.
  ///         The reserves are initialized to the difference between the
  ///         Balancer Vault's notion of the pool's token balances and the sum
  ///         of the orders, proceeds, and fee counters in state.
  ///         State is also used to configure the fee percentages, which are
  ///         explained in more detail below, see NOTE.
  /// @param _balance0U112 The Balancer Vault balance of Token 0 for this pool.
  ///                      Min. = 0, Max. = (2**112) - 1
  /// @param _balance1U112 The Balancer Vault balance of Token 1 for this pool.
  ///                      Min. = 0, Max. = (2**112) - 1
  /// @return evoMem A Struct for executing virtual orders across functions
  ///                efficiently (saves on gas use from continual accesses to
  ///                storage/state). See documentation for ExecVirtualOrdersMem
  ///                struct.
  /// @dev NOTE: This getter also sets struct members lpFeeU60, feeShareU60 and
  ///            feeShiftU3 based on current state. Explanations for these are
  ///            detailed in the documentation for the ExecVirtualOrdersMem struct.
  ///            For convenience though, note that when Cron-Fi fees are not being
  ///            collected (cronFeeEnabled == C.FALSE), feeShiftU3 and feeShareU60
  ///            are set to zero as they are not needed since Cron-Fi fees need not
  ///            be calculated. When Cron-Fi fees are collected, then the following
  ///            equations are applicable:
  ///
  ///                lpFeeU60 = ONE_DU1_18 - balancerFeeDU1F18                (1)
  ///
  ///                                  lpFeeU60
  ///                feeShareU60 = -----------------                          (2)
  ///                              1 + 2**feeShiftU3
  ///
  ///            The results of equations 1 & 2 above are used in the function
  ///            _updateFees to divide the gross fees between
  ///            Cron-Fi and the Liquidity Providers (LPs), efficiently. The
  ///            sum of those collected fees are then subtracted from the gross fees
  ///            and the remainder goes to Balancer.
  ///            A similar strategy is used when Cron-Fi fees are not collected,
  ///            however there is no need to split fees between Cron-Fi and the LPs
  ///            in that scenario, so feeShiftU3 and feeShareU60 are not needed.
  ///
  function _getExecVirtualOrdersMem(uint256 _balance0U112, uint256 _balance1U112)
    private
    view
    returns (ExecVirtualOrdersMem memory evoMem)
  {
    (uint256 token0ReserveU112, uint256 token1ReserveU112) = _calculateReserves(_balance0U112, _balance1U112);

    uint256 localSlot = slot4; // #savegas
    uint256 cronFeeEnabled = BitPackingLib.unpackBit(localSlot, C.S4_OFFSET_CRON_FEE_ENABLED);
    uint256 collectBalancerFees = BitPackingLib.unpackBit(localSlot, C.S4_OFFSET_COLLECT_BALANCER_FEES);
    uint256 balancerFeeDU1F18 = BitPackingLib.unpackBalancerFeeS4(localSlot);

    // #unchecked
    //            The subtraction below is unchecked because the Balancer Fee, balancerFeeDU1F18, is
    //            retrieved from storage that does not permit values > C.ONE_DU1_18 to be stored.
    //            See predicate in function _handleBalancerFees that ensures potential stored values
    //            are <= C.ONE_DU1_18.
    uint256 lpFeeU60 = (collectBalancerFees != C.FALSE) ? C.ONE_DU1_18 - balancerFeeDU1F18 : C.ONE_DU1_18;

    uint256 feeShiftU3;
    uint256 feeShareU60;
    if (cronFeeEnabled != C.FALSE) {
      feeShiftU3 = BitPackingLib.unpackFeeShiftS3(slot3);
      feeShareU60 = lpFeeU60 / (1 + 2**feeShiftU3);
    }

    evoMem = ExecVirtualOrdersMem(
      token0ReserveU112,
      token1ReserveU112,
      lpFeeU60,
      feeShareU60,
      feeShiftU3,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0
    );
  }

  /// @notice Constructs an execute virtual order loop memory struct from virtual orders
  ///         state and the order block interval.
  ///
  function _getLoopMem() private view returns (LoopMem memory loopMem, uint256 expiryBlock) {
    // #unchecked
    //            The subtraction of lvob from the mod of it by the ORDER_BLOCK_INTERVAL
    //            is unchecked because lvob will always be greater than it's modulus by
    //            ORDER_BLOCK_INTERVAL and can't underflow. This is because it is initialized
    //            in the constructor to block.number, which is much greater than the maximum
    //            value of ORDER_BLOCK_INTERVAL (1200, VOLATILE_OBI).
    //
    //            The addition of ORDER_BLOCK_INTERVAL is unchecked because it is
    //            at most adding 1200 (VOLATILE_OBI) to the previous result,
    //            which is unlikely to overflow unless that result is already near overflow
    //            because block.number is approaching 2**256 - 1.
    //
    uint256 lvob = virtualOrders.lastVirtualOrderBlock; // #savegas
    expiryBlock = lvob - (lvob % ORDER_BLOCK_INTERVAL) + ORDER_BLOCK_INTERVAL;
    loopMem.lastVirtualOrderBlock = lvob;

    (loopMem.currentSalesRate0U112, loopMem.currentSalesRate1U112) = BitPackingLib.unpackPairU112(
      virtualOrders.orderPools.currentSalesRates
    );

    (loopMem.scaledProceeds0U128, loopMem.scaledProceeds1U128) = BitPackingLib.unpackPairU128(
      virtualOrders.orderPools.scaledProceeds
    );
  }

  /// @notice Calculates the pool's reserves at the current state or Last Virtual Order Block (LVOB) (i.e.
  ///         not considering unexecuted virtual orders). The calculation is the difference between the
  ///         Balancer Vault notion of the pool's token balances and the sum of the pool's internal
  ///         accounting of orders, proceeds, and fees for both tokens.
  /// @param _balance0U112 The Balancer Vault balance of Token 0 for this pool.
  ///                      Min. = 0, Max. = (2**112) - 1
  /// @param _balance1U112 The Balancer Vault balance of Token 1 for this pool.
  ///                      Min. = 0, Max. = (2**112) - 1
  /// @return token0ReserveU112 The reserves of Token 0 in this pool as of the LVOB.
  ///                           Min. = 0, Max. = (2**112) - 1
  /// @return token1ReserveU112 The reserves of Token 0 in this pool as of the LVOB.
  ///                           Min. = 0, Max. = (2**112) - 1
  /// @dev NOTE: _balance0U112 and _balance1U112 can not exceed (2**112) - 1 according to Balancer
  ///            documentation and code comments. This was further confirmed in conversations with
  ///            Balancer's engineering team.
  ///            [https://dev.balancer.fi/deep-dive/guided-tour-of-balancer-vault/episode-2-joins#vault-poolbalances.sol-5]
  ///            That means that if this function does not revert, we are assured that token0ReserveU112
  ///            and token1ReserveU112 are < MAX_U112.
  /// @dev #RISK: If the _balance0U112 and/or _balance1U112 values exceed the sum of the respective
  ///             token accounting (orders, proceeds, fees), this function will revert, rendering the
  ///             pool unusable. Even if paused!
  ///             We have mitigated this risk using the onJoinPool function when JoinType.Reward is
  ///             specified. In this scenario, a pool problem will have been identified and the pool
  ///             will have been paused. Anyone could then reward the pool with sufficient liquidity
  ///             to ensure the difference no longer underflows, enabling withdraw, cancel, and exit
  ///             operations.
  ///
  function _calculateReserves(uint256 _balance0U112, uint256 _balance1U112)
    private
    view
    returns (uint256 token0ReserveU112, uint256 token1ReserveU112)
  {
    (uint256 token0OrdersU112, uint256 token1OrdersU112) = BitPackingLib.unpackPairU112(slot1);
    (uint256 token0ProceedsU112, uint256 token1ProceedsU112) = BitPackingLib.unpackPairU112(slot2);

    uint256 localSlot4 = slot4;
    (uint256 token0BalancerFeesU96, uint256 token1BalancerFeesU96) = BitPackingLib.unpackPairU96(localSlot4);

    // NOTE: Optimization - prevent un-necessary read of slot3 by checking whether the Cron-Fi Fees stored
    //       in slot3 are zero (in flag zeroCronFiFees stored in slot4):
    //
    uint256 token0CronFiFeesU96;
    uint256 token1CronFiFeesU96;
    uint256 zeroCronFiFees = BitPackingLib.unpackBit(localSlot4, C.S4_OFFSET_ZERO_CRONFI_FEES);
    if (zeroCronFiFees == C.FALSE) {
      (token0CronFiFeesU96, token1CronFiFeesU96) = BitPackingLib.unpackPairU96(slot3);
    }

    /// #unchecked
    ///            The orders, proceeds and fees summed below are correct by construction (that is to say,
    ///            their values cannot exceed 112-bits or 96-bits, because they are stored as only 112-bits
    ///            or 96-bits and checked at storage time to ensure these limits aren't exceeded).
    ///            The sum of four 112-bit numbers cannot exceed 116-bits, and thus the unchecked addition
    ///            because a 256-bit overflow is impossible.
    ///            Safe math is used for the subtraction though in case an unforeseen error results in
    ///            the sum of orders, proceeds and fees exceeding Balancer's notion of the the pool's total
    ///            balance of either token.
    token0ReserveU112 = _balance0U112.sub(
      token0OrdersU112 + token0ProceedsU112 + token0BalancerFeesU96 + token0CronFiFeesU96
    );
    token1ReserveU112 = _balance1U112.sub(
      token1OrdersU112 + token1ProceedsU112 + token1BalancerFeesU96 + token1CronFiFeesU96
    );
  }

  /// @notice Computes the virtual reserves and output amounts of the pool for active
  ///         virtual orders. Handles the no-active orders, swap of Token0 to Token1 only
  ///         active orders, Token1 to Token0 only active orders and concurrent swap between
  ///         Token0 and Token1 active orders.
  ///         Updated virtual reserves are returned in the _evoMem struct and output amounts
  ///         through the token0OutU112 and token1OutU112 variables.
  /// @param _evoMem aggregated information for gas efficient virtual order exection. See
  ///                documentation in Structs.sol.
  /// @param _token0InU112 amount of Token0 to sell to the pool in exchange for Token1 for active
  ///                  virtual orders swapping in this direction.
  /// @param _token1InU112 amount of Token1 to sell to the pool in exchange for Token0 for active
  ///                  virtual orders swapping in this direction.
  /// @return token0OutU112 amount of Token0 received from swapping _token1InU112 Token1 with the pool.
  /// @return token1OutU112 amount of Token1 received from swapping _token0InU112 Token0 with the pool.
  ///
  function _computeVirtualReserves(
    ExecVirtualOrdersMem memory _evoMem,
    uint256 _token0InU112,
    uint256 _token1InU112
  ) private pure returns (uint256 token0OutU112, uint256 token1OutU112) {
    if (_token0InU112 != 0 || _token1InU112 != 0) {
      uint256 token0ReserveU112 = _evoMem.token0ReserveU112; // #savegas #savesize
      uint256 token1ReserveU112 = _evoMem.token1ReserveU112;

      if (_token0InU112 == 0) {
        // For single pool selling, use CPAMM formula:
        //
        // #unchecked
        //            The increment of token1ReserveU112 is unchecked below because the
        //            _token1InU112 value is derived from the orders which are checked along
        //            with the reserves by Balancer not to exceed U112 (BAL#526
        //            BALANCE_TOTAL_OVERFLOW). Also, at the start of execute virtual orders
        //            cycles, the token1ReserveU112 is computed from a known U112 value (the
        //            Balancer Vault balance) by subtracting orders, proceeds and fees accounting.
        //
        //            The multiplication of token0ReserveU112 and _token1InU112 is similarly
        //            constrained to U112 because of the BAL#526 checks performed. The maximum
        //            product of these two values is therefore a U224, which will not overflow
        //            the U256 container (especially given the division by token1ReserveU112).
        //
        //            The subtraction of token0OutU112 from token0ReserveU112 is unchecked
        //            because token0OutU112 is derived from multiplying token0ReserveU112 by
        //            values that amount to being less than 1, thus reducing it in comparison
        //            to token0ReserveU112.
        token1ReserveU112 += _token1InU112;
        token0OutU112 = (token0ReserveU112 * _token1InU112) / token1ReserveU112;
        token0ReserveU112 = token0ReserveU112 - token0OutU112;
      } else if (_token1InU112 == 0) {
        // For single pool selling, use CPAMM formula:
        //
        // #unchecked
        //            The following 3 lines are unchecked using the same rationale presented
        //            above for trades in the opposite direction.
        token0ReserveU112 += _token0InU112;
        token1OutU112 = (token1ReserveU112 * _token0InU112) / token0ReserveU112;
        token1ReserveU112 = token1ReserveU112 - token1OutU112;
      } else {
        // When both pools sell, apply the TWAMM formula in the form of the FRAX Approximation
        //
        // #unchecked
        //            The addition of tokenNReserveU112 to _tokenNInU112 below is unchecked
        //            because both values are known to be <= U112 by Balancer overflow checks
        //            (BAL#526 BALANCE_TOTAL_OVERFLOW). Also as noted in the single-sided rationale
        //            above, the reserves are computed by subtracting order, proceeds and fees
        //            accounting from known U112 values at the start of any execute virtual orders
        //            cycle (the Balancer Vault balance).
        uint256 sum0 = token0ReserveU112 + _token0InU112;
        uint256 sum1 = token1ReserveU112 + _token1InU112;

        // NOTE: purposely using standard rounding (divDown = /) here to reduce operating error.
        //
        // #unchecked
        //            Multiplication of token0ReserveU112 and sum1 is unchecked because these
        //            values are known to max out at U112 and U113, the product of which is U225,
        //            much less than the U256 container they're stored in.
        //
        //            Multiplication by token0ReserveU112 and token1ReserveU112, values known to
        //            be within U112 by Balancer overflow checks and their construction at the start
        //            of the execute virtual orders cycle, cannot exceed a U224 value, thus safe
        //            from overflow.
        uint256 ammEndToken0 = (token1ReserveU112 * sum0) / sum1;
        uint256 ammEndToken1 = (token0ReserveU112 * sum1) / sum0;
        token0ReserveU112 = ammEndToken0;
        token1ReserveU112 = ammEndToken1;

        // #unchecked
        //            Both subtractions below are unchecked for underflow because they take the form:
        //
        //                     x * z
        //                z - -------
        //                       y
        //
        //                where x <= y
        //
        //
        //            Full explanation for token0OutU112 & token1OutU112:
        //
        //                token0OutU112 = sum0 - ammEndToken0
        //
        //                                        sum0 * token1ReserveU112
        //                              = sum0 - --------------------------
        //                                                 sum1
        //
        //                                            sum0 * token1ReserveU112
        //                              = sum0 - -----------------------------------
        //                                        token1ReserveU112 + _token1InU112
        //
        //                    where: token1ReserveU112 <= token1ReserveU112 + token1InU112
        //
        //
        //                token1OutU112 = sum1 - ammEndToken1
        //
        //                                        sum1 * token0ReserveU112
        //                token1OutU112 = sum1 - --------------------------
        //                                                  sum0
        //
        //                                              sum1 * token0ReserveU112
        //                              = sum1 - ------------------------------------
        //                                        (token0ReserveU112 + token0InU112)
        //
        //                    where: token0ReserveU112 <= token0ReserveU112 + token0InU112
        //
        token0OutU112 = sum0 - ammEndToken0;
        token1OutU112 = sum1 - ammEndToken1;
      }

      _evoMem.token0ReserveU112 = token0ReserveU112;
      _evoMem.token1ReserveU112 = token1ReserveU112;
    }
  }

  /// @notice Updates the fees collected for Balancer, Liquidity Providers (LPs) and Cron-Fi (if
  ///         enabled) in the provided struct, _evoMem, for later addition to the pool.
  /// @param _grossFeeT0 is the gross fee amount collected by the pool for performing LT swaps.
  ///                    Min. = 0, Max. = (2**116) - 1
  /// @param _grossFeeT1 is the gross fee amount collected by the pool for performing LT swaps.
  ///                    Min. = 0, Max. = (2**116) - 1
  ///
  /// @dev see _executeVirtualTradesAndOrderExpiries for analysis explaining
  ///      why _grossFeeT0 and _grossFeeT1 are limited to MAX_U116.
  ///
  function _updateFees(
    ExecVirtualOrdersMem memory _evoMem,
    uint256 _grossFeeT0,
    uint256 _grossFeeT1
  ) private pure returns (uint256 lpFeeT0, uint256 lpFeeT1) {
    uint256 feeShiftU3 = _evoMem.feeShiftU3; // #savegas #savesize
    uint256 lpFeeU60 = _evoMem.lpFeeU60; // #savegas #savesize

    if (feeShiftU3 == 0) {
      // Cron-Fi Fees Not Collected:

      // #unchecked
      //            Multiplication of the gross fees, _grossFeeT0 and _grossFeeT1,
      //            with lp fee, lpFeeU60, is unchecked because the gross fees
      //            max out at 116-bits and the lp fee, lpFeeU60, at 60-bits, the
      //            product of which has a theoretical maximum of 186-bits, far less
      //            than the 256-bit result container.
      //
      // NOTE: division with rounding down is performed to protect against underflow
      //       in subtraction below.
      lpFeeT0 = (_grossFeeT0 * lpFeeU60).divDown(C.DENOMINATOR_DU1_18);
      lpFeeT1 = (_grossFeeT1 * lpFeeU60).divDown(C.DENOMINATOR_DU1_18);

      // Accumulate fees for balancer
      // #unchecked
      //            The accumulation of gross fees for balancer involves unchecked
      //            subtraction because _grossFeeT0 and _grossFeeT1 will always
      //            be greater than lpFeeT0 and lpFeeT1, respectively. This is
      //            because lpFee0 and lpFee1 are derived from the gross fees
      //            by multipling them with a fraction less than one (multiplying
      //            by a numerator that is less than the denominator, C.DENOMINATOR_FP18).
      //
      //            Overflow is also not checked here in the addition because the
      //            values are clamped to 96-bits when stored in state and the
      //            theoretical maximum _grossFee of 116-bits when added to
      //            96-bits would not exceed the 256-bit intermediate container resolution.
      //
      // Predicate prevents unintended rounding error based balancer fee collection when
      // balancer fees are zero. (see CronV1Pool.sol::_getExecVirtualOrdersMem documentation).
      if (lpFeeU60 < C.ONE_DU1_18) {
        _evoMem.token0BalancerFeesU96 += _grossFeeT0 - lpFeeT0;
        _evoMem.token1BalancerFeesU96 += _grossFeeT1 - lpFeeT1;
      }
    } else {
      // Cron-Fi Fees Collected:
      //
      // NOTE: When the fee address is set, Cron-Fi splits the fees with the LPs
      //       and balancer.  The feeShareU60 value is 1/(1+2**feeShift) multiplied by the
      //       fee remaining from collecting the Balancer Protocol fee. This value is then
      //       aportioned with 1 share going to Cron-Fi and (2**feeShift) shares to the LPs.
      //       For example if the Balancer Protocol fee is half of all fees collected
      //       and feeShift=1, then 1/6 of the total collected fee goes to Cron-Fi and
      //       1/3 of the fees collected go to the LPs (the other 1/2 of collected fees
      //       going to Balancer).
      uint256 feeShareU60 = _evoMem.feeShareU60; // #savegas #savesize

      // #unchecked
      //            Multiplication of the gross fees, _grossFeeT0 and _grossFeeT1,
      //            with fee share, feeShareU60, is unchecked because the gross fees
      //            max out at 116-bits and the lp fee, feeShareU60, at 60-bits, the
      //            product of which has a theoretical maximum of 186-bits, far less
      //            than the 256-bit result container.
      //
      // NOTE: division with rounding down is performed to protect against underflow
      //       in subtraction below.
      uint256 feeShareT0 = (_grossFeeT0 * feeShareU60).divDown(C.DENOMINATOR_DU1_18);
      uint256 feeShareT1 = (_grossFeeT1 * feeShareU60).divDown(C.DENOMINATOR_DU1_18);

      // LPs get 2**_evoMem.feeShiftU3 of the fee shares, Cron Fi gets one share.
      //
      // #unchecked
      //            The left shifts of feeShareT0 and feeShareT1 below are unchecked
      //            because the maximum shift, feeShiftU3, is limited to 4 (see
      //            check in CronV1Pool.sol::setFeeShift. The worst case value of
      //            feeShareT0 and feeShareT1 is 186-bits before division by
      //            C.DENOMINATOR_DU1_18, well within the 256-bit container limit.
      lpFeeT0 = feeShareT0 << feeShiftU3;
      lpFeeT1 = feeShareT1 << feeShiftU3;

      // Accumulate fees for balancer
      // #unchecked
      //            The accumulation of fees for balancer involves unchecked
      //            subtraction because _grossFeeT0 and _grossFeeT1 will always
      //            be greater than lpFeeT0, lpFeeT1 feeShareT0, and feeShareT1 combined,
      //            respectively. This is because lpFee0, lpFee1, feeShareT0 and feeShareT1
      //            are derived from the gross fees by multipling them with a fraction less
      //            than or equal to one (multiplying by a numerator that is less than or equal
      //            to the denominator, C.DENOMINATOR_FP18, which rounds down). (The value of
      //            feeShareU60 is such that multiplying it by 2**feeShift and then adding it
      //            to itself will sum to the gross fee minus fees collected for balancer).
      //
      //            Overflow is also not checked here in the addition because the
      //            values are clamped to 96-bits when stored in state and the
      //            theortical maximum _grossFee of 116-bits when added to
      //            96-bits would not exceed the 256-bit intermediate container range.
      //
      // Predicate prevents unintended rounding error based balancer fee collection when
      // balancer fees are zero. (see CronV1Pool.sol::_getExecVirtualOrdersMem documentation).
      if (lpFeeU60 < C.ONE_DU1_18) {
        _evoMem.token0BalancerFeesU96 += (_grossFeeT0 - lpFeeT0) - feeShareT0;
        _evoMem.token1BalancerFeesU96 += (_grossFeeT1 - lpFeeT1) - feeShareT1;
      }

      // Accumulate fees for CronFi
      // #unchecked
      //            Similar to above, overflow is not checked in the addition because
      //            Cron-Fi fees are clamped to 96-bits when stored in state and the
      //            theoretical maximum _grossFee of 116-bits (which greatly exceeds
      //            the feeShareT0 and feeShareT1 values) when added to 96-bits would not
      //            exceed the 256-bit intermediate container range.
      _evoMem.token0CronFiFeesU96 += feeShareT0;
      _evoMem.token1CronFiFeesU96 += feeShareT1;
    }
  }

  /// @notice Calculate the oracle increment by incrementing the oracle change struct members
  ///         (token0OracleU256F112 and token1OracleU256F112) of struct _evoMem based on the
  ///         current reserve values and the time elapsed since the last reserve values.
  /// @param _evoMem aggregated information for gas efficient virtual order exection. See
  ///                documentation in Structs.sol.
  /// @param _lastVirtualOrderBlock is the ethereum block number before the last virtual
  ///                               orders were executed.
  /// @param _expiryBlock is the next block upon which virtual orders expire. It is aligned
  ///                     on multiples of the order block interval.
  function _calculateOracleIncrement(
    ExecVirtualOrdersMem memory _evoMem,
    uint256 _lastVirtualOrderBlock,
    uint256 _expiryBlock
  ) private pure {
    // #unchecked
    //            Overflow is not possible in the shift below: U256 > (U112 << 112).
    //            Token reserve values known to be U112 because computed from Balancer Vault values
    //            by subtracting accounting and funds going in/out of them all known to sum to
    //            less than U112 mathematically.
    //
    //            The subtraction of lastVirtualOrderBlock from _expiryBlock is unchecked below
    //            because the following functions that call this function ensure that _expiryBlock
    //            is greater than _lastVirtualOrderBlock in their call to _getLoopMem, which sets
    //            expiryBlock to the next block number divisible by order block interval after the
    //            last virtual order block:
    //                - executeVirtualOrdersToBlock
    //                - executeVirtualOrdersView
    //
    // #overUnderFlowIntended
    //                        The UQ256x112 incremented result relies upon and expects overflow
    //                        and is unchecked. The reason is that it is the difference between
    //                        price oracle samples over time that matters, not the absolute value.
    //                        As noted above, see the Uniswap V2 whitepaper.
    //                        That said, this is a partial increment that will be added to the
    //                        stored accumulation of values and is unlikely to overflow during
    //                        virtual order execution because both tokenXOracleU256F112 values
    //                        are initialized to zero at the start of execution (the time elapsed
    //                        would need to be on the order of 2 ** 32 to overflow the worst case
    //                        ratio of token reserves ((2 ** 112-1) / 1)--that means
    //                        (2**32-1/12s) = 357913941 blocks must elapse since the last oracle
    //                        update and the worst case reserves to overflow this incremental value
    //                        and cause an oracle price error.
    //
    uint256 timeElapsed = C.SECONDS_PER_BLOCK * (_expiryBlock - _lastVirtualOrderBlock);
    if (_evoMem.token0ReserveU112 > 0) {
      _evoMem.token0OracleU256F112 += ((_evoMem.token1ReserveU112 << 112) / _evoMem.token0ReserveU112) * timeElapsed;
    }
    if (_evoMem.token1ReserveU112 > 0) {
      _evoMem.token1OracleU256F112 += ((_evoMem.token0ReserveU112 << 112) / _evoMem.token1ReserveU112) * timeElapsed;
    }
  }

  /// @notice
  /// @param _token0InU112 is the amount of Token 0 to Join the pool with.
  ///                      Min. = 0, Max. = (2**112) - 1
  /// @param _token1InU112 is the amount of Token 1 to Join the pool with.
  ///                      Min. = 0, Max. = (2**112) - 1
  /// @param _token0MinU112 is the minimum price of Token 0 permitted.
  ///                       Min. = 0, Max. = (2**112) - 1
  /// @param _token1MinU112 is the minimum price of Token 1 permitted.
  ///                       Min. = 0, Max. = (2**112) - 1
  /// @param _token0ReserveU112 is the current Token 0 reserves of the pool.
  ///                           Min. = 0, Max. = (2**112) - 1
  /// @param _token1ReserveU112 is the current Token 1 reserves of the pool.
  ///                           Min. = 0, Max. = (2**112) - 1
  ///
  function _joinMinimumCheck(
    uint256 _token0InU112,
    uint256 _token1InU112,
    uint256 _token0MinU112,
    uint256 _token1MinU112,
    uint256 _token0ReserveU112,
    uint256 _token1ReserveU112
  ) private pure {
    if (_token0ReserveU112 > 0 && _token1ReserveU112 > 0) {
      // #unchecked
      //            The multiplication below is unchecked for overflow because the product
      //            of two 112-bit values is less than 256-bits. (Reserves are correct by
      //            construction and Balancer ensures that the tokens in do not cause the
      //            pool to exceed 112-bits).
      uint256 nominalToken0 = (_token1InU112 * _token0ReserveU112) / _token1ReserveU112;
      uint256 nominalToken1 = (_token0InU112 * _token1ReserveU112) / _token0ReserveU112;
      requireErrCode(
        nominalToken0 >= _token0MinU112 && nominalToken1 >= _token1MinU112,
        CronErrors.MINIMUM_NOT_SATISFIED
      );
    }
  }
}