// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {StrikeConversion} from "@timeswap-labs/v2-library/contracts/StrikeConversion.sol";

import {ITimeswapV2OptionFactory} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2OptionFactory.sol";
import {ITimeswapV2Option} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2Option.sol";
import {TimeswapV2OptionMintParam, TimeswapV2OptionSwapParam} from "@timeswap-labs/v2-option/contracts/structs/Param.sol";
import {TimeswapV2OptionMintCallbackParam, TimeswapV2OptionSwapCallbackParam} from "@timeswap-labs/v2-option/contracts/structs/CallbackParam.sol";
import {TimeswapV2OptionSwap} from "@timeswap-labs/v2-option/contracts/enums/Transaction.sol";
import {TimeswapV2OptionMint} from "@timeswap-labs/v2-option/contracts/enums/Transaction.sol";
import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

import {OptionFactoryLibrary} from "@timeswap-labs/v2-option/contracts/libraries/OptionFactory.sol";

import {ITimeswapV2PoolFactory} from "@timeswap-labs/v2-pool/contracts/interfaces/ITimeswapV2PoolFactory.sol";
import {ITimeswapV2Pool} from "@timeswap-labs/v2-pool/contracts/interfaces/ITimeswapV2Pool.sol";

import {TimeswapV2PoolLeverageParam} from "@timeswap-labs/v2-pool/contracts/structs/Param.sol";
import {TimeswapV2PoolLeverageChoiceCallbackParam, TimeswapV2PoolLeverageCallbackParam} from "@timeswap-labs/v2-pool/contracts/structs/CallbackParam.sol";
import {PoolFactoryLibrary} from "@timeswap-labs/v2-pool/contracts/libraries/PoolFactory.sol";

import {TimeswapV2PoolLeverage} from "@timeswap-labs/v2-pool/contracts/enums/Transaction.sol";

import {ITimeswapV2Token} from "@timeswap-labs/v2-token/contracts/interfaces/ITimeswapV2Token.sol";

import {TimeswapV2TokenMintParam} from "@timeswap-labs/v2-token/contracts/structs/Param.sol";
import {TimeswapV2TokenMintCallbackParam} from "@timeswap-labs/v2-token/contracts/structs/CallbackParam.sol";

import {ITimeswapV2PeripheryBorrowGivenPrincipal} from "./interfaces/ITimeswapV2PeripheryBorrowGivenPrincipal.sol";

import {TimeswapV2PeripheryBorrowGivenPrincipalParam} from "./structs/Param.sol";
import {TimeswapV2PeripheryBorrowGivenPrincipalInternalParam} from "./structs/InternalParam.sol";

import {Verify} from "./libraries/Verify.sol";

/// @title Abstract contract which specifies functions that are required for  borrow given principal which are to be inherited for a specific DEX/Aggregator implementation
abstract contract TimeswapV2PeripheryBorrowGivenPrincipal is ITimeswapV2PeripheryBorrowGivenPrincipal {
  /* ===== MODEL ===== */
  /// @inheritdoc ITimeswapV2PeripheryBorrowGivenPrincipal
  address public immutable override optionFactory;
  /// @inheritdoc ITimeswapV2PeripheryBorrowGivenPrincipal
  address public immutable override poolFactory;
  /// @inheritdoc ITimeswapV2PeripheryBorrowGivenPrincipal
  address public immutable override tokens;
  ///@dev data recieved from optionMintCallback
  struct CacheForTimeswapV2OptionMintCallback {
    address token0;
    address token1;
    address tokenTo;
    address longTo;
    bool isLong0;
    uint256 swapAmount;
    uint256 positionAmount;
  }

  /* ===== INIT ===== */

  constructor(address chosenOptionFactory, address chosenPoolFactory, address chosenTokens) {
    optionFactory = chosenOptionFactory;
    poolFactory = chosenPoolFactory;
    tokens = chosenTokens;
  }

  /// @notice the abstract implementation for borrowGivenPrincipal function
  /// @param param params for  borrowGivenPrincipal as mentioned in the TimeswapV2PeripheryBorrowGivenPrincipalParam struct
  /// @return positionAmount resulting borrowPosition amount
  /// @return data data passed as bytes in the param
  function borrowGivenPrincipal(
    TimeswapV2PeripheryBorrowGivenPrincipalParam memory param
  ) internal returns (uint256 positionAmount, bytes memory data) {
    (, address poolPair) = PoolFactoryLibrary.getWithCheck(optionFactory, poolFactory, param.token0, param.token1);

    data = abi.encode(
      param.token0,
      param.token1,
      param.tokenTo,
      param.longTo,
      param.isLong0,
      param.token0Amount,
      param.token1Amount,
      param.data
    );

    (, , , data) = ITimeswapV2Pool(poolPair).leverage(
      TimeswapV2PoolLeverageParam({
        strike: param.strike,
        maturity: param.maturity,
        long0To: address(this),
        long1To: address(this),
        transaction: TimeswapV2PoolLeverage.GivenLong,
        delta: StrikeConversion.combine(param.token0Amount, param.token1Amount, param.strike, true),
        data: data
      })
    );

    (positionAmount, data) = abi.decode(data, (uint256, bytes));
  }

  /// @notice the abstract implementation for leverageCallback function
  /// @param param params for  leverageChoiceCallback as mentioned in the TimeswapV2PoolLeverageChoiceCallbackParam struct
  /// @return long0Amount the amount of long0 chosen
  /// @return long1Amount the amount of long1 chosen
  /// @return data data passed as bytes in the param
  function timeswapV2PoolLeverageChoiceCallback(
    TimeswapV2PoolLeverageChoiceCallbackParam calldata param
  ) external view override returns (uint256 long0Amount, uint256 long1Amount, bytes memory data) {
    address token0;
    address token1;
    address tokenTo;
    address longTo;
    bool isLong0;
    (token0, token1, tokenTo, longTo, isLong0, long0Amount, long1Amount, data) = abi.decode(
      param.data,
      (address, address, address, address, bool, uint256, uint256, bytes)
    );

    Verify.timeswapV2Pool(optionFactory, poolFactory, token0, token1);

    data = abi.encode(token0, token1, tokenTo, longTo, isLong0, data);
  }

  /// @notice the abstract implementation for leverageCallback function
  /// @param param params for  leverageCallback as mentioned in the TimeswapV2PoolLeverageCallbackParam struct
  /// @return data data passed as bytes in the param
  function timeswapV2PoolLeverageCallback(
    TimeswapV2PoolLeverageCallbackParam calldata param
  ) external override returns (bytes memory data) {
    address token0;
    address token1;
    address tokenTo;
    address longTo;
    bool isLong0;
    (token0, token1, tokenTo, longTo, isLong0, data) = abi.decode(
      param.data,
      (address, address, address, address, bool, bytes)
    );

    address optionPair = Verify.timeswapV2Pool(optionFactory, poolFactory, token0, token1);

    data = abi.encode(
      CacheForTimeswapV2OptionMintCallback(
        token0,
        token1,
        tokenTo,
        longTo,
        isLong0,
        isLong0 ? param.long1Amount : param.long0Amount,
        isLong0 ? param.long0Amount : param.long1Amount
      ),
      data
    );

    (, , , data) = ITimeswapV2Option(optionPair).mint(
      TimeswapV2OptionMintParam({
        strike: param.strike,
        maturity: param.maturity,
        long0To: address(this),
        long1To: address(this),
        shortTo: msg.sender,
        transaction: TimeswapV2OptionMint.GivenShorts,
        amount0: isLong0 ? param.shortAmount : 0,
        amount1: isLong0 ? 0 : param.shortAmount,
        data: data
      })
    );
  }

  /// @notice the abstract implementation for TimeswapV2OptionMintCallback
  /// @param param params for mintCallBack from TimeswapV2Option
  /// @return data data passed in bytes in the param passed back
  function timeswapV2OptionMintCallback(
    TimeswapV2OptionMintCallbackParam memory param
  ) external override returns (bytes memory data) {
    CacheForTimeswapV2OptionMintCallback memory cache;
    (cache, data) = abi.decode(param.data, (CacheForTimeswapV2OptionMintCallback, bytes));

    Verify.timeswapV2Option(optionFactory, cache.token0, cache.token1);

    cache.positionAmount += cache.isLong0 ? param.token0AndLong0Amount : param.token1AndLong1Amount;

    if (cache.swapAmount != 0) {
      data = abi.encode(
        cache.token0,
        cache.token1,
        cache.longTo,
        cache.isLong0 ? param.token0AndLong0Amount : param.token1AndLong1Amount,
        cache.positionAmount,
        data
      );

      (, , data) = ITimeswapV2Option(msg.sender).swap(
        TimeswapV2OptionSwapParam({
          strike: param.strike,
          maturity: param.maturity,
          tokenTo: cache.tokenTo,
          longTo: address(this),
          isLong0ToLong1: !cache.isLong0,
          transaction: cache.isLong0
            ? TimeswapV2OptionSwap.GivenToken1AndLong1
            : TimeswapV2OptionSwap.GivenToken0AndLong0,
          amount: cache.swapAmount,
          data: data
        })
      );
    } else {
      ITimeswapV2Token(tokens).mint(
        TimeswapV2TokenMintParam({
          token0: cache.token0,
          token1: cache.token1,
          strike: param.strike,
          maturity: param.maturity,
          long0To: cache.isLong0 ? cache.longTo : address(this),
          long1To: cache.isLong0 ? address(this) : cache.longTo,
          shortTo: address(this),
          long0Amount: cache.isLong0 ? cache.positionAmount : 0,
          long1Amount: cache.isLong0 ? 0 : cache.positionAmount,
          shortAmount: 0,
          data: bytes("")
        })
      );

      data = timeswapV2PeripheryBorrowGivenPrincipalInternal(
        TimeswapV2PeripheryBorrowGivenPrincipalInternalParam({
          optionPair: msg.sender,
          token0: cache.token0,
          token1: cache.token1,
          strike: param.strike,
          maturity: param.maturity,
          isLong0: cache.isLong0,
          token0Amount: cache.isLong0 ? param.token0AndLong0Amount : 0,
          token1Amount: cache.isLong0 ? 0 : param.token1AndLong1Amount,
          positionAmount: cache.positionAmount,
          data: data
        })
      );

      data = abi.encode(cache.positionAmount, data);
    }
  }

  /// @notice the abstract implementation for TimeswapV2OptionSwapCallback
  /// @param param params for swapCallBack from TimeswapV2Option
  /// @return data data passed in bytes in the param passed back
  function timeswapV2OptionSwapCallback(
    TimeswapV2OptionSwapCallbackParam calldata param
  ) external override returns (bytes memory data) {
    address token0;
    address token1;
    address longTo;
    uint256 depositAmount;
    uint256 positionAmount;
    (token0, token1, longTo, depositAmount, positionAmount, data) = abi.decode(
      param.data,
      (address, address, address, uint256, uint256, bytes)
    );

    Verify.timeswapV2Option(optionFactory, token0, token1);

    positionAmount += param.isLong0ToLong1 ? param.token1AndLong1Amount : param.token0AndLong0Amount;

    ITimeswapV2Token(tokens).mint(
      TimeswapV2TokenMintParam({
        token0: token0,
        token1: token1,
        strike: param.strike,
        maturity: param.maturity,
        long0To: param.isLong0ToLong1 ? address(this) : longTo,
        long1To: param.isLong0ToLong1 ? longTo : address(this),
        shortTo: address(this),
        long0Amount: param.isLong0ToLong1 ? 0 : positionAmount,
        long1Amount: param.isLong0ToLong1 ? positionAmount : 0,
        shortAmount: 0,
        data: bytes("")
      })
    );

    data = timeswapV2PeripheryBorrowGivenPrincipalInternal(
      TimeswapV2PeripheryBorrowGivenPrincipalInternalParam({
        optionPair: msg.sender,
        token0: token0,
        token1: token1,
        strike: param.strike,
        maturity: param.maturity,
        isLong0: !param.isLong0ToLong1,
        token0Amount: param.token0AndLong0Amount + (param.isLong0ToLong1 ? 0 : depositAmount),
        token1Amount: param.token1AndLong1Amount + (param.isLong0ToLong1 ? depositAmount : 0),
        positionAmount: positionAmount,
        data: data
      })
    );

    data = abi.encode(positionAmount, data);
  }

  /// @notice the abstract implementation for TimeswapV2TokenMintCallback
  /// @param param params for mintCallBack from TimeswapV2Token
  /// @return data data passed in bytes in the param passed back
  function timeswapV2TokenMintCallback(
    TimeswapV2TokenMintCallbackParam calldata param
  ) external override returns (bytes memory data) {
    Verify.timeswapV2Token(tokens);

    address optionPair = OptionFactoryLibrary.get(optionFactory, param.token0, param.token1);

    ITimeswapV2Option(optionPair).transferPosition(
      param.strike,
      param.maturity,
      msg.sender,
      param.long0Amount != 0 ? TimeswapV2OptionPosition.Long0 : TimeswapV2OptionPosition.Long1,
      param.long0Amount != 0 ? param.long0Amount : param.long1Amount
    );

    data = bytes("");
  }

  /// @notice the implementation which is to be overriden for DEX/Aggregator specific logic for TimeswapV2BorrowGivenPrincipal
  /// @param param params for calling the implementation specfic borrowGivenPrincipal to be overriden
  /// @return data data passed in bytes in the param passed back
  function timeswapV2PeripheryBorrowGivenPrincipalInternal(
    TimeswapV2PeripheryBorrowGivenPrincipalInternalParam memory param
  ) internal virtual returns (bytes memory data);
}