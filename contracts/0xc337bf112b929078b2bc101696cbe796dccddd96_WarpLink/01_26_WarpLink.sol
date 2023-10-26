// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {LibWarp} from '../libraries/LibWarp.sol';
import {LibStarVault} from '../libraries/LibStarVault.sol';
import {Stream} from '../libraries/Stream.sol';
import {LibUniV2Like} from '../libraries/LibUniV2Like.sol';
import {IUniswapV2Pair} from '../interfaces/external/IUniswapV2Pair.sol';
import {IWarpLink} from '../interfaces/IWarpLink.sol';
import {LibUniV3Like} from '../libraries/LibUniV3Like.sol';
import {IUniV3Callback} from '../interfaces/IUniV3Callback.sol';
import {IUniswapV3Pool} from '../interfaces/external/IUniswapV3Pool.sol';
import {LibCurve} from '../libraries/LibCurve.sol';
import {IPermit2} from '../interfaces/external/IPermit2.sol';
import {IAllowanceTransfer} from '../interfaces/external/IAllowanceTransfer.sol';
import {PermitParams} from '../libraries/PermitParams.sol';
import {IStargateRouter} from '../interfaces/external/IStargateRouter.sol';
import {IStargateReceiver} from '../interfaces/external/IStargateReceiver.sol';
import {IStargateComposer} from '../interfaces/external/IStargateComposer.sol';

abstract contract WarpLinkCommandTypes {
  uint256 internal constant COMMAND_TYPE_WRAP = 1;
  uint256 internal constant COMMAND_TYPE_UNWRAP = 2;
  uint256 internal constant COMMAND_TYPE_WARP_UNI_V2_LIKE_EXACT_INPUT_SINGLE = 3;
  uint256 internal constant COMMAND_TYPE_SPLIT = 4;
  uint256 internal constant COMMAND_TYPE_WARP_UNI_V2_LIKE_EXACT_INPUT = 5;
  uint256 internal constant COMMAND_TYPE_WARP_UNI_V3_LIKE_EXACT_INPUT_SINGLE = 6;
  uint256 internal constant COMMAND_TYPE_WARP_UNI_V3_LIKE_EXACT_INPUT = 7;
  uint256 internal constant COMMAND_TYPE_WARP_CURVE_EXACT_INPUT_SINGLE = 8;
  uint256 internal constant COMMAND_TYPE_JUMP_STARGATE = 9;
}

contract WarpLink is IWarpLink, IStargateReceiver, WarpLinkCommandTypes {
  using SafeERC20 for IERC20;
  using Stream for uint256;

  struct WarpUniV2LikeWarpSingleParams {
    address tokenOut;
    address pool;
    bool zeroForOne; // tokenIn < tokenOut
    uint16 poolFeeBps;
  }

  struct WarpUniV2LikeExactInputParams {
    // NOTE: Excluding the first token
    address[] tokens;
    address[] pools;
    uint16[] poolFeesBps;
  }

  struct WarpUniV3LikeExactInputSingleParams {
    address tokenOut;
    address pool;
    bool zeroForOne; // tokenIn < tokenOut
    uint16 poolFeeBps;
  }

  struct WarpCurveExactInputSingleParams {
    address tokenOut;
    address pool;
    uint8 tokenIndexIn;
    uint8 tokenIndexOut;
    uint8 kind;
    bool underlying;
  }

  struct JumpStargateParams {
    uint16 dstChainId;
    uint256 srcPoolId;
    uint256 dstPoolId;
    uint256 dstGasForCall;
    bytes payload;
  }

  struct TransientState {
    address paramPartner;
    uint16 paramFeeBps;
    address paramRecipient;
    uint256 paramAmountOut;
    uint16 paramSlippageBps;
    uint48 paramDeadline;
    uint256 amount;
    address payer;
    address token;
    /**
     * 0 or 1
     */
    uint256 jumped;
    /**
     * The amount of native value not spent. The native value starts off as
     * `msg.value - params.amount` and is decreased by spending money on jumps.
     *
     * Any leftover native value is returned to `msg.sender`
     */
    uint256 nativeValueRemaining;
  }

  function processSplit(
    uint256 stream,
    TransientState memory t
  ) internal returns (TransientState memory) {
    uint256 parts = stream.readUint8();
    uint256 amountRemaining = t.amount;
    uint256 amountOutSum;

    if (parts < 2) {
      revert NotEnoughParts();
    }

    // Store the token out for the previous part to ensure every part has the same output token
    address firstPartTokenOut;
    address firstPartPayerOut;

    for (uint256 partIndex; partIndex < parts; ) {
      // TODO: Unchecked?
      // For the last part, use the remaining amount. Else read the % from the stream
      uint256 partAmount = partIndex < parts - 1
        ? (t.amount * stream.readUint16()) / 10_000
        : amountRemaining;

      if (partAmount > amountRemaining) {
        revert InsufficientAmountRemaining();
      }

      amountRemaining -= partAmount;

      TransientState memory tPart;

      tPart.amount = partAmount;
      tPart.payer = t.payer;
      tPart.token = t.token;

      tPart = engageInternal(stream, tPart);

      if (tPart.jumped == 1) {
        revert IllegalJumpInSplit();
      }

      if (partIndex == 0) {
        firstPartPayerOut = tPart.payer;
        firstPartTokenOut = tPart.token;
      } else {
        if (tPart.token != firstPartTokenOut) {
          revert InconsistentPartTokenOut();
        }

        if (tPart.payer != firstPartPayerOut) {
          revert InconsistentPartPayerOut();
        }
      }

      // NOTE: Checked
      amountOutSum += tPart.amount;

      unchecked {
        partIndex++;
      }
    }

    t.payer = firstPartPayerOut;
    t.token = firstPartTokenOut;
    t.amount = amountOutSum;

    return t;
  }

  /**
   * Wrap ETH into WETH using the WETH contract
   *
   * The ETH must already be in this contract
   *
   * The next token will be WETH, with the amount and payer unchanged
   */
  function processWrap(TransientState memory t) internal returns (TransientState memory) {
    LibWarp.State storage s = LibWarp.state();

    if (t.token != address(0)) {
      revert UnexpectedTokenForWrap();
    }

    if (t.payer != address(this)) {
      // It's not possible to move a user's ETH
      revert UnexpectedPayerForWrap();
    }

    t.token = address(s.weth);

    s.weth.deposit{value: t.amount}();

    return t;
  }

  /**
   * Unwrap WETH into ETH using the WETH contract
   *
   * The payer can be the sender or this contract. After this operation, the
   * token will be ETH (0) and the amount will be unchanged. The next payer
   * will be this contract.
   */
  function processUnwrap(TransientState memory t) internal returns (TransientState memory) {
    LibWarp.State storage s = LibWarp.state();

    if (t.token != address(s.weth)) {
      revert UnexpectedTokenForUnwrap();
    }

    address prevPayer = t.payer;
    bool shouldMoveTokensFirst = prevPayer != address(this);

    if (shouldMoveTokensFirst) {
      t.payer = address(this);
    }

    t.token = address(0);

    if (shouldMoveTokensFirst) {
      s.permit2.transferFrom(prevPayer, address(this), (uint160)(t.amount), address(s.weth));
    }

    s.weth.withdraw(t.amount);

    return t;
  }

  /**
   * Warp a single token in a Uniswap V2-like pool
   *
   * Since the pool is not trusted, the amount out is checked before
   * and after the swap to ensure the correct amount was delivered.
   *
   * The payer can be the sender or this contract. The token must not be ETH (0).
   *
   * After this operation, the token will be `params.tokenOut` and the amount will
   * be the output of the swap. The next payer will be this contract.
   *
   * Params are read from the stream as:
   *   - tokenOut (address)
   *   - pool (address)
   *   - zeroForOne (0 or 1, uint8)
   *   - poolFeeBps (uint16)
   */
  function processWarpUniV2LikeExactInputSingle(
    uint256 stream,
    TransientState memory t
  ) internal returns (TransientState memory) {
    if (t.token == address(0)) {
      revert NativeTokenNotSupported();
    }

    WarpUniV2LikeWarpSingleParams memory params;

    params.tokenOut = stream.readAddress();
    params.pool = stream.readAddress();
    params.zeroForOne = stream.readUint8() == 1;
    params.poolFeeBps = stream.readUint16();

    if (t.payer == address(this)) {
      // Transfer tokens to the pool
      IERC20(t.token).safeTransfer(params.pool, t.amount);
    } else {
      // Transfer tokens from the sender to the pool
      LibWarp.state().permit2.transferFrom(t.payer, params.pool, (uint160)(t.amount), t.token);

      // Update the payer to this contract
      t.payer = address(this);
    }

    (uint256 reserveIn, uint256 reserveOut, ) = IUniswapV2Pair(params.pool).getReserves();

    if (!params.zeroForOne) {
      // Token in > token out
      (reserveIn, reserveOut) = (reserveOut, reserveIn);
    }

    unchecked {
      // For 30 bps, multiply by 997
      uint256 feeFactor = 10_000 - params.poolFeeBps;

      t.amount =
        ((t.amount * feeFactor) * reserveOut) /
        ((reserveIn * 10_000) + (t.amount * feeFactor));
    }

    // NOTE: This check can be avoided if the factory is trusted
    uint256 balancePrev = IERC20(params.tokenOut).balanceOf(address(this));

    IUniswapV2Pair(params.pool).swap(
      params.zeroForOne ? 0 : t.amount,
      params.zeroForOne ? t.amount : 0,
      address(this),
      ''
    );

    uint256 balanceNext = IERC20(params.tokenOut).balanceOf(address(this));

    if (balanceNext < balancePrev || balanceNext < balancePrev + t.amount) {
      revert InsufficientTokensDelivered();
    }

    t.token = params.tokenOut;

    return t;
  }

  /**
   * Warp multiple tokens in a series of Uniswap V2-like pools
   *
   * Since the pools are not trusted, the balance of `params.tokenOut` is checked
   * before the first swap and after the last swap to ensure the correct amount
   * was delivered.
   *
   * The payer can be the sender or this contract. The token must not be ETH (0).
   *
   * After this operation, the token will be `params.tokenOut` and the amount will
   * be the output of the last swap. The next payer will be this contract.
   *
   * Params are read from the stream as:
   *  - pool length (uint8)
   *  - tokens (address 0, address 1, address pool length - 1) excluding the first
   *  - pools (address 0, address 1, address pool length - 1)
   *  - pool fees (uint16 0, uint16 1, uint16 pool length - 1)
   */
  function processWarpUniV2LikeExactInput(
    uint256 stream,
    TransientState memory t
  ) internal returns (TransientState memory) {
    WarpUniV2LikeExactInputParams memory params;

    uint256 poolLength = stream.readUint8();

    params.tokens = new address[](poolLength + 1);

    // The params will contain all tokens including the first to remain compatible
    // with the LibUniV2Like library's getAmountsOut function
    params.tokens[0] = t.token;

    for (uint256 index; index < poolLength; ) {
      params.tokens[index + 1] = stream.readAddress();

      unchecked {
        index++;
      }
    }

    params.pools = stream.readAddresses(poolLength);
    params.poolFeesBps = stream.readUint16s(poolLength);

    uint256 tokenOutBalancePrev = IERC20(params.tokens[poolLength]).balanceOf(address(this));

    uint256[] memory amounts = LibUniV2Like.getAmountsOut(
      params.poolFeesBps,
      t.amount,
      params.tokens,
      params.pools
    );

    if (t.payer == address(this)) {
      // Transfer tokens from this contract to the first pool
      IERC20(t.token).safeTransfer(params.pools[0], t.amount);
    } else {
      // Transfer tokens from the sender to the first pool
      LibWarp.state().permit2.transferFrom(t.payer, params.pools[0], (uint160)(t.amount), t.token);

      // Update the payer to this contract
      t.payer = address(this);
    }

    // Same as UniV2Like
    for (uint index; index < poolLength; ) {
      uint256 indexPlusOne = index + 1;
      bool zeroForOne = params.tokens[index] < params.tokens[indexPlusOne] ? true : false;
      address to = index < params.tokens.length - 2 ? params.pools[indexPlusOne] : address(this);

      IUniswapV2Pair(params.pools[index]).swap(
        zeroForOne ? 0 : amounts[indexPlusOne],
        zeroForOne ? amounts[indexPlusOne] : 0,
        to,
        ''
      );

      unchecked {
        index++;
      }
    }

    uint256 nextTokenOutBalance = IERC20(params.tokens[poolLength]).balanceOf(address(this));

    t.amount = amounts[amounts.length - 1];

    if (
      // TOOD: Is this overflow check necessary?
      nextTokenOutBalance < tokenOutBalancePrev ||
      nextTokenOutBalance < tokenOutBalancePrev + t.amount
    ) {
      revert InsufficientTokensDelivered();
    }

    t.token = params.tokens[poolLength];

    return t;
  }

  /**
   * Warp a single token in a Uniswap V3-like pool
   *
   * Since the pool is not trusted, the amount out is checked before
   * and after the swap to ensure the correct amount was delivered.
   *
   * The payer can be the sender or this contract. The token must not be ETH (0).
   *
   * After this operation, the token will be `params.tokenOut` and the amount will
   * be the output of the swap. The next payer will be this contract.
   *
   * Params are read from the stream as:
   *  - tokenOut (address)
   *  - pool (address)
   */
  function processWarpUniV3LikeExactInputSingle(
    uint256 stream,
    TransientState memory t
  ) internal returns (TransientState memory) {
    WarpUniV3LikeExactInputSingleParams memory params;

    params.tokenOut = stream.readAddress();
    params.pool = stream.readAddress();

    if (t.token == address(0)) {
      revert NativeTokenNotSupported();
    }

    // NOTE: The pool is untrusted
    uint256 balancePrev = IERC20(params.tokenOut).balanceOf(address(this));

    bool zeroForOne = t.token < params.tokenOut;

    LibUniV3Like.beforeCallback(
      LibUniV3Like.CallbackState({payer: t.payer, token: t.token, amount: t.amount})
    );

    if (zeroForOne) {
      (, int256 amountOutSigned) = IUniswapV3Pool(params.pool).swap(
        address(this),
        zeroForOne,
        int256(t.amount),
        LibUniV3Like.MIN_SQRT_RATIO,
        ''
      );

      t.amount = uint256(-amountOutSigned);
    } else {
      (int256 amountOutSigned, ) = IUniswapV3Pool(params.pool).swap(
        address(this),
        zeroForOne,
        int256(t.amount),
        LibUniV3Like.MAX_SQRT_RATIO,
        ''
      );

      t.amount = uint256(-amountOutSigned);
    }

    LibUniV3Like.afterCallback();

    uint256 balanceNext = IERC20(params.tokenOut).balanceOf(address(this));

    if (balanceNext < balancePrev || balanceNext < balancePrev + t.amount) {
      revert InsufficientTokensDelivered();
    }

    t.token = params.tokenOut;

    // TODO: Compare check-and-set vs set
    t.payer = address(this);

    return t;
  }

  /**
   * Warp multiple tokens in a series of Uniswap V3-like pools
   *
   * Since the pools are not trusted, the balance of `params.tokenOut` is checked
   * before the first swap and after the last swap to ensure the correct amount
   * was delivered.
   *
   * The payer can be the sender or this contract. The token must not be ETH (0).
   *
   * After this operation, the token will be `params.tokenOut` and the amount will
   * be the output of the last swap. The next payer will be this contract.
   *
   * Params are read from the stream as:
   *  - pool length (uint8)
   *  - tokens (address 0, address 1, address pool length - 1) excluding the first
   *  - pools (address 0, address 1, address pool length - 1)
   */
  function processWarpUniV3LikeExactInput(
    uint256 stream,
    TransientState memory t
  ) internal returns (TransientState memory) {
    WarpUniV2LikeExactInputParams memory params;

    uint256 poolLength = stream.readUint8();

    // The first token is not included
    params.tokens = stream.readAddresses(poolLength);
    params.pools = stream.readAddresses(poolLength);

    address lastToken = params.tokens[poolLength - 1];

    uint256 tokenOutBalancePrev = IERC20(lastToken).balanceOf(address(this));

    for (uint index; index < poolLength; ) {
      address tokenIn = index == 0 ? t.token : params.tokens[index - 1]; // TOOD: unchecked
      t.token = params.tokens[index];
      bool zeroForOne = tokenIn < t.token;

      LibUniV3Like.beforeCallback(
        LibUniV3Like.CallbackState({payer: t.payer, token: tokenIn, amount: t.amount})
      );

      if (index == 0) {
        // Update the payer to this contract
        // TODO: Compare check-and-set vs set
        t.payer = address(this);
      }

      address pool = params.pools[index];

      if (zeroForOne) {
        (, int256 amountOutSigned) = IUniswapV3Pool(pool).swap(
          address(this),
          zeroForOne,
          int256(t.amount),
          LibUniV3Like.MIN_SQRT_RATIO,
          ''
        );

        t.amount = uint256(-amountOutSigned);
      } else {
        (int256 amountOutSigned, ) = IUniswapV3Pool(pool).swap(
          address(this),
          zeroForOne,
          int256(t.amount),
          LibUniV3Like.MAX_SQRT_RATIO,
          ''
        );

        t.amount = uint256(-amountOutSigned);
      }

      LibUniV3Like.afterCallback();

      unchecked {
        index++;
      }
    }

    uint256 nextTokenOutBalance = IERC20(t.token).balanceOf(address(this));

    if (
      // TOOD: Is this overflow check necessary?
      nextTokenOutBalance < tokenOutBalancePrev ||
      nextTokenOutBalance < tokenOutBalancePrev + t.amount
    ) {
      revert InsufficientTokensDelivered();
    }

    return t;
  }

  /**
   * Warp a single token in a Curve-like pool
   *
   * Since the pool is not trusted, the amount out is checked before
   * and after the swap to ensure the correct amount was delivered.
   *
   * The payer can be the sender or this contract. The token may be ETH (0)
   *
   * After this operation, the token will be `params.tokenOut` and the amount will
   * be the output of the swap. The next payer will be this contract.
   *
   * Params are read from the stream as:
   *  - tokenOut (address)
   *  - pool (address)
   */
  function processWarpCurveExactInputSingle(
    uint256 stream,
    TransientState memory t
  ) internal returns (TransientState memory) {
    WarpCurveExactInputSingleParams memory params;

    params.tokenOut = stream.readAddress();
    params.pool = stream.readAddress();
    params.tokenIndexIn = stream.readUint8();
    params.tokenIndexOut = stream.readUint8();
    params.kind = stream.readUint8();
    params.underlying = stream.readUint8() == 1;

    // NOTE: The pool is untrusted
    bool isFromEth = t.token == address(0);
    bool isToEth = params.tokenOut == address(0);

    if (t.payer != address(this)) {
      // Transfer tokens from the sender to this contract
      LibWarp.state().permit2.transferFrom(t.payer, address(this), (uint160)(t.amount), t.token);

      // Update the payer to this contract
      t.payer = address(this);
    }

    uint256 balancePrev = isToEth
      ? address(this).balance
      : IERC20(params.tokenOut).balanceOf(address(this));

    if (!isFromEth) {
      // TODO: Is this necessary to support USDT?
      IERC20(t.token).forceApprove(params.pool, t.amount);
    }

    LibCurve.exchange({
      kind: params.kind,
      underlying: params.underlying,
      pool: params.pool,
      eth: isFromEth ? t.amount : 0,
      i: params.tokenIndexIn,
      j: params.tokenIndexOut,
      dx: t.amount,
      // NOTE: There is no need to set a min out since the balance will be verified
      min_dy: 0
    });

    uint256 balanceNext = isToEth
      ? address(this).balance
      : IERC20(params.tokenOut).balanceOf(address(this));

    t.token = params.tokenOut;
    t.amount = balanceNext - balancePrev;

    return t;
  }

  /**
   * Cross-chain callback from Stargate
   *
   * The tokens have already been received by this contract, `t.payer` is set to this contract
   * before `sgReceive` is called by the router.
   *
   * The `_nonce` field is not checked since it's assumed that LayerZero will not deliver the
   * same message more than once.
   *
   * The Stargate composer is trusted, meaning `_token` and `amountLD` is not verified. Should the
   * Stargate composer be compromised, an attacker can drain this contract.
   *
   * If the payload can not be decoded, tokens are left in this contract.
   * If execution runs out of gas, tokens are left in this contract.
   *
   * If an error occurs during engage, such as insufficient output amount, tokens are refunded
   * to the recipient.
   *
   * See https://stargateprotocol.gitbook.io/stargate/interfaces/evm-solidity-interfaces/istargatereceiver.sol
   */
  function sgReceive(
    uint16, // _srcChainId
    bytes memory _srcAddress,
    uint256, // _nonce
    address _token,
    uint256 amountLD,
    bytes memory payload
  ) external {
    if (msg.sender != address(LibWarp.state().stargateComposer)) {
      revert InvalidSgReceiverSender();
    }

    // NOTE: Addresses cannot be decode from bytes using `abi.decode`
    // From https://ethereum.stackexchange.com/a/50528
    address srcAddress;

    assembly {
      srcAddress := mload(add(_srcAddress, 20))
    }

    if (srcAddress != address(this)) {
      // NOTE: This assumes that this contract is deployed at the same address on every chain
      revert InvalidSgReceiveSrcAddress();
    }

    Params memory params = abi.decode(payload, (Params));

    try
      IWarpLink(this).warpLinkEngage(
        Params({
          partner: params.partner,
          feeBps: params.feeBps,
          slippageBps: params.slippageBps,
          recipient: params.recipient,
          tokenIn: _token,
          tokenOut: params.tokenOut,
          amountIn: amountLD,
          amountOut: params.amountOut,
          deadline: params.deadline,
          commands: params.commands
        }),
        PermitParams({nonce: 0, signature: ''})
      )
    {} catch {
      // Refund tokens to the recipient
      IERC20(_token).safeTransfer(params.recipient, amountLD);
    }
  }

  /**
   * Jump to another chain using the Stargate bridge
   *
   * The token must not be ETH (0)
   *
   * After this operation, the token will be unchanged and `t.amount` will
   * be how much was sent. `t.jumped` will be set to `1` to indicate
   * that no more commands should be run
   *
   * The user may construct a command where `srcPoolId` is not for `t.token`. This is harmless
   * because only `t.token` can be moved by Stargate.
   *
   * This command must not run inside of a split.
   *
   * A bridge fee must be paid in the native token. This fee is determined with
   * `IStargateRouter.quoteLayerZeroFee`
   *
   * The value for `t.token` remains the same and is not chained.
   *
   * Params are read from the stream as:
   *   - dstChainId (uint16)
   *   - srcPoolId (uint8)
   *   - dstPoolId (uint8)
   *   - dstGasForCall (uint32)
   *   - tokenOut (address) when `dstGasForCall` > 0
   *   - amountOut (uint256) when `dstGasForCall` > 0
   *   - commands (uint256 length, ...bytes) when `dstGasForCall` > 0
   */
  function processJumpStargate(
    uint256 stream,
    TransientState memory t
  ) internal returns (TransientState memory) {
    if (t.token == address(0)) {
      // NOTE: There is a WETH pool
      revert NativeTokenNotSupported();
    }

    // TODO: Does this use the same gas than (a, b, c,) = (stream.read, ...)?
    JumpStargateParams memory params;
    params.dstChainId = stream.readUint16();
    params.srcPoolId = stream.readUint8();
    params.dstPoolId = stream.readUint8();
    params.dstGasForCall = stream.readUint32();

    if (params.dstGasForCall > 0) {
      // NOTE: `tokenIn`, `amountIn` are not required
      Params memory destParams;
      destParams.partner = t.paramPartner;
      destParams.feeBps = t.paramFeeBps;
      destParams.slippageBps = t.paramSlippageBps;
      destParams.recipient = t.paramRecipient;
      destParams.tokenOut = stream.readAddress();
      destParams.amountOut = stream.readUint256();
      destParams.deadline = t.paramDeadline;
      destParams.commands = stream.readBytes();
      params.payload = abi.encode(destParams);
    }

    // If the tokens are being delivered directly to the recipient without a second
    // WarpLink engage, the fee is charged on this chain
    if (params.payload.length == 0) {
      // NOTE: It is not possible to know how many tokens were delivered. Therfore positive slippage
      // is never charged
      t.amount = LibStarVault.calculateAndRegisterFee(
        t.paramPartner,
        t.token,
        t.paramFeeBps,
        t.amount,
        t.amount
      );
    }

    // Enforce minimum amount/max slippage
    if (t.amount < LibWarp.applySlippage(t.paramAmountOut, t.paramSlippageBps)) {
      revert InsufficientOutputAmount();
    }

    IStargateComposer stargateComposer = LibWarp.state().stargateComposer;

    if (t.token != address(0)) {
      if (t.payer != address(this)) {
        // Transfer tokens from the sender to this contract
        LibWarp.state().permit2.transferFrom(t.payer, address(this), (uint160)(t.amount), t.token);

        // Update the payer to this contract
        t.payer = address(this);
      }

      // Allow Stargate to transfer the tokens. When there is a payload, the composer is used, else the router
      IERC20(t.token).forceApprove(
        params.payload.length == 0 ? stargateComposer.stargateRouter() : address(stargateComposer),
        t.amount
      );
    }

    t.jumped = 1;

    // Swap on the composer if there is a payload, else the router
    IStargateRouter(
      params.payload.length == 0 ? stargateComposer.stargateRouter() : address(stargateComposer)
    ).swap{value: t.nativeValueRemaining}({
      _dstChainId: params.dstChainId,
      _srcPoolId: params.srcPoolId,
      _dstPoolId: params.dstPoolId,
      //  NOTE: There is no guarantee that `msg.sender` can handle receiving tokens/ETH
      // TODO: Use `msg.sender` if it's EOA, else use this contract
      _refundAddress: payable(address(this)),
      _amountLD: t.amount,
      // Max 5% slippage
      _minAmountLD: (t.amount * 95) / 100,
      _lzTxParams: IStargateRouter.lzTxObj({
        dstGasForCall: params.dstGasForCall,
        dstNativeAmount: 0,
        dstNativeAddr: ''
      }),
      // NOTE: This assumes the contract is deployed at the same address on every chain.
      // If this is not the case, a new param needs to be added with the next WarpLink address
      _to: abi.encodePacked(params.payload.length > 0 ? address(this) : t.paramRecipient),
      _payload: params.payload
    });

    t.nativeValueRemaining = 0;

    return t;
  }

  function engageInternal(
    uint256 stream,
    TransientState memory t
  ) internal returns (TransientState memory) {
    uint256 commandCount = stream.readUint8();

    // TODO: End of stream check?
    for (uint256 commandIndex; commandIndex < commandCount; commandIndex++) {
      // TODO: Unchecked?
      uint256 commandType = stream.readUint8();

      if (commandType == COMMAND_TYPE_WRAP) {
        t = processWrap(t);
      } else if (commandType == COMMAND_TYPE_UNWRAP) {
        t = processUnwrap(t);
      } else if (commandType == COMMAND_TYPE_WARP_UNI_V2_LIKE_EXACT_INPUT_SINGLE) {
        t = processWarpUniV2LikeExactInputSingle(stream, t);
      } else if (commandType == COMMAND_TYPE_SPLIT) {
        t = processSplit(stream, t);
      } else if (commandType == COMMAND_TYPE_WARP_UNI_V2_LIKE_EXACT_INPUT) {
        t = processWarpUniV2LikeExactInput(stream, t);
      } else if (commandType == COMMAND_TYPE_WARP_UNI_V3_LIKE_EXACT_INPUT_SINGLE) {
        t = processWarpUniV3LikeExactInputSingle(stream, t);
      } else if (commandType == COMMAND_TYPE_WARP_UNI_V3_LIKE_EXACT_INPUT) {
        t = processWarpUniV3LikeExactInput(stream, t);
      } else if (commandType == COMMAND_TYPE_WARP_CURVE_EXACT_INPUT_SINGLE) {
        t = processWarpCurveExactInputSingle(stream, t);
      } else if (commandType == COMMAND_TYPE_JUMP_STARGATE) {
        if (commandIndex != commandCount - 1) {
          revert JumpMustBeLastCommand();
        }

        t = processJumpStargate(stream, t);
      } else {
        revert UnhandledCommand();
      }
    }

    return t;
  }

  function warpLinkEngage(Params memory params, PermitParams calldata permit) external payable {
    if (block.timestamp > params.deadline) {
      revert DeadlineExpired();
    }

    TransientState memory t;
    t.paramPartner = params.partner;
    t.paramFeeBps = params.feeBps;
    t.paramSlippageBps = params.slippageBps;
    t.paramRecipient = params.recipient;
    t.paramAmountOut = params.amountOut;
    t.paramSlippageBps = params.slippageBps;
    t.paramDeadline = params.deadline;
    t.amount = params.amountIn;
    t.token = params.tokenIn;

    if (params.tokenIn == address(0)) {
      if (msg.value < params.amountIn) {
        revert InsufficientEthValue();
      }

      t.nativeValueRemaining = msg.value - params.amountIn;

      // The ETH has already been moved to this contract
      t.payer = address(this);
    } else {
      // Tokens will initially moved from the sender
      t.payer = msg.sender;

      t.nativeValueRemaining = msg.value;

      // Permit tokens / set allowance
      // The signature is omitted when `warpLinkEngage` is called from `sgReceive`
      if (permit.signature.length > 0) {
        LibWarp.state().permit2.permit(
          msg.sender,
          IAllowanceTransfer.PermitSingle({
            details: IAllowanceTransfer.PermitDetails({
              token: params.tokenIn,
              amount: (uint160)(params.amountIn),
              expiration: (uint48)(params.deadline),
              nonce: (uint48)(permit.nonce)
            }),
            spender: address(this),
            sigDeadline: (uint256)(params.deadline)
          }),
          permit.signature
        );
      }
    }

    uint256 stream = Stream.createStream(params.commands);

    t = engageInternal(stream, t);

    uint256 amountOut = t.amount;
    address tokenOut = t.token;

    if (tokenOut != params.tokenOut) {
      revert UnexpectedTokenOut();
    }

    // Enforce minimum amount/max slippage
    if (amountOut < LibWarp.applySlippage(params.amountOut, params.slippageBps)) {
      revert InsufficientOutputAmount();
    }

    if (t.jumped == 1) {
      // The coins have jumped away from this chain. Fees are colelcted before
      // the jump or on the other chain.
      //
      // `t.nativeValueRemaining` is not checked since it should be zero
      return;
    }

    // Collect fees
    amountOut = LibStarVault.calculateAndRegisterFee(
      params.partner,
      params.tokenOut,
      params.feeBps,
      params.amountOut,
      amountOut
    );

    if (amountOut == 0) {
      revert InsufficientOutputAmount();
    }

    // Deliver tokens
    if (tokenOut == address(0)) {
      payable(params.recipient).transfer(amountOut);
    } else {
      IERC20(tokenOut).safeTransfer(params.recipient, amountOut);
    }

    if (t.nativeValueRemaining > 0) {
      // TODO: Is this the correct recipient?
      payable(msg.sender).transfer(t.nativeValueRemaining);
    }
  }
}