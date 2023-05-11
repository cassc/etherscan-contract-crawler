// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import {StrikeConversion} from "@timeswap-labs/v2-library/contracts/StrikeConversion.sol";
import {ITimeswapV2OptionFactory} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2OptionFactory.sol";
import {ITimeswapV2Option} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2Option.sol";
import {TimeswapV2OptionBurnParam, TimeswapV2OptionSwapParam} from "@timeswap-labs/v2-option/contracts/structs/Param.sol";
import {TimeswapV2OptionSwapCallbackParam} from "@timeswap-labs/v2-option/contracts/structs/CallbackParam.sol";

import {TimeswapV2OptionBurn, TimeswapV2OptionSwap} from "@timeswap-labs/v2-option/contracts/enums/Transaction.sol";
import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

import {ITimeswapV2PoolFactory} from "@timeswap-labs/v2-pool/contracts/interfaces/ITimeswapV2PoolFactory.sol";
import {ITimeswapV2Pool} from "@timeswap-labs/v2-pool/contracts/interfaces/ITimeswapV2Pool.sol";
import {PoolFactoryLibrary} from "@timeswap-labs/v2-pool/contracts/libraries/PoolFactory.sol";

import {TimeswapV2PoolDeleverageParam} from "@timeswap-labs/v2-pool/contracts/structs/Param.sol";
import {TimeswapV2PoolDeleverageChoiceCallbackParam, TimeswapV2PoolDeleverageCallbackParam} from "@timeswap-labs/v2-pool/contracts/structs/CallbackParam.sol";

import {TimeswapV2PoolDeleverage} from "@timeswap-labs/v2-pool/contracts/enums/Transaction.sol";

import {TimeswapV2TokenBurnParam} from "@timeswap-labs/v2-token/contracts/structs/Param.sol";

import {ITimeswapV2Token} from "@timeswap-labs/v2-token/contracts/interfaces/ITimeswapV2Token.sol";

import {ITimeswapV2PeripheryCloseBorrowGivenPosition} from "./interfaces/ITimeswapV2PeripheryCloseBorrowGivenPosition.sol";

import {TimeswapV2PeripheryCloseBorrowGivenPositionParam} from "./structs/Param.sol";
import {TimeswapV2PeripheryCloseBorrowGivenPositionChoiceInternalParam, TimeswapV2PeripheryCloseBorrowGivenPositionInternalParam} from "./structs/InternalParam.sol";

import {Verify} from "./libraries/Verify.sol";

/// @title Abstract contract which specifies functions that are required for  close borrow given position which are to be inherited for a specific DEX/Aggregator implementation
abstract contract TimeswapV2PeripheryCloseBorrowGivenPosition is
  ITimeswapV2PeripheryCloseBorrowGivenPosition,
  ERC1155Receiver
{
  /* ===== MODEL ===== */
  /// @inheritdoc ITimeswapV2PeripheryCloseBorrowGivenPosition
  address public immutable override optionFactory;
  /// @inheritdoc ITimeswapV2PeripheryCloseBorrowGivenPosition
  address public immutable override poolFactory;
  /// @inheritdoc ITimeswapV2PeripheryCloseBorrowGivenPosition
  address public immutable override tokens;

  /* ===== INIT ===== */

  constructor(address chosenOptionFactory, address chosenPoolFactory, address chosenTokens) {
    optionFactory = chosenOptionFactory;
    poolFactory = chosenPoolFactory;
    tokens = chosenTokens;
  }

  /// @notice the abstract implementation for closeBorrowGivenPosition function
  /// @param param params for  closeBorrowGivenPosition as mentioned in the TimeswapV2PeripheryCloseBorrowGivenPositionParam struct
  /// @return token0Amount the amount of token0
  /// @return token1Amount the amount of token1
  /// @return data data passed as bytes in the param
  function closeBorrowGivenPosition(
    TimeswapV2PeripheryCloseBorrowGivenPositionParam memory param
  ) internal returns (uint256 token0Amount, uint256 token1Amount, bytes memory data) {
    (, address poolPair) = PoolFactoryLibrary.getWithCheck(optionFactory, poolFactory, param.token0, param.token1);

    ITimeswapV2Token(tokens).burn(
      TimeswapV2TokenBurnParam({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        long0To: address(this),
        long1To: address(this),
        shortTo: address(this),
        long0Amount: param.isLong0 ? param.positionAmount : 0,
        long1Amount: param.isLong0 ? 0 : param.positionAmount,
        shortAmount: 0,
        data: bytes("")
      })
    );

    data = abi.encode(param.token0, param.token1, param.to, param.isLong0, param.positionAmount, param.data);

    (token0Amount, token1Amount, , data) = ITimeswapV2Pool(poolPair).deleverage(
      TimeswapV2PoolDeleverageParam({
        strike: param.strike,
        maturity: param.maturity,
        to: address(this),
        transaction: TimeswapV2PoolDeleverage.GivenSum,
        delta: StrikeConversion.combine(
          param.isLong0 ? param.positionAmount : 0,
          param.isLong0 ? 0 : param.positionAmount,
          param.strike,
          false
        ),
        data: data
      })
    );
  }

  /// @notice the abstract implementation for deleverageChoiceCallback function
  /// @param param params for  timeswapV2PoolDeleverageChoiceCallback as mentioned in the TimeswapV2PoolDeleverageChoiceCallbackParam struct
  /// @return long0Amount the amount of long0 chosen
  /// @return long1Amount the amount of long1 chosen
  /// @return data data passed as bytes in the param
  function timeswapV2PoolDeleverageChoiceCallback(
    TimeswapV2PoolDeleverageChoiceCallbackParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data) {
    address token0;
    address token1;
    address to;
    bool isLong0;
    uint256 positionAmount;
    (token0, token1, to, isLong0, positionAmount, data) = abi.decode(
      param.data,
      (address, address, address, bool, uint256, bytes)
    );

    Verify.timeswapV2Pool(optionFactory, poolFactory, token0, token1);

    uint256 tokenAmount = positionAmount - StrikeConversion.turn(param.shortAmount, param.strike, !isLong0, false);

    (long0Amount, long1Amount, data) = timeswapV2PeripheryCloseBorrowGivenPositionChoiceInternal(
      TimeswapV2PeripheryCloseBorrowGivenPositionChoiceInternalParam({
        token0: token0,
        token1: token1,
        strike: param.strike,
        maturity: param.maturity,
        isLong0: isLong0,
        tokenAmount: StrikeConversion.combine(
          isLong0 ? tokenAmount : 0,
          isLong0 ? 0 : tokenAmount,
          param.strike,
          false
        ),
        data: data
      })
    );

    data = abi.encode(token0, token1, to, isLong0, positionAmount, data);
  }

  /// @notice the abstract implementation for deleverageCallback function
  /// @param param params for  timeswapV2PoolDeleverageCallback as mentioned in the TimeswapV2PoolDeleverageCallbackParam struct
  /// @return data data passed as bytes in the param
  function timeswapV2PoolDeleverageCallback(
    TimeswapV2PoolDeleverageCallbackParam calldata param
  ) external override returns (bytes memory data) {
    address token0;
    address token1;
    address to;
    bool isLong0;
    uint256 positionAmount;
    (token0, token1, to, isLong0, positionAmount, data) = abi.decode(
      param.data,
      (address, address, address, bool, uint256, bytes)
    );

    address optionPair = Verify.timeswapV2Pool(optionFactory, poolFactory, token0, token1);

    (uint256 token0Amount, uint256 token1Amount, , ) = ITimeswapV2Option(optionPair).burn(
      TimeswapV2OptionBurnParam({
        strike: param.strike,
        maturity: param.maturity,
        token0To: isLong0 ? to : address(this),
        token1To: isLong0 ? address(this) : to,
        transaction: TimeswapV2OptionBurn.GivenShorts,
        amount0: isLong0 ? param.shortAmount : 0,
        amount1: isLong0 ? 0 : param.shortAmount,
        data: bytes("")
      })
    );

    if ((isLong0 ? param.long0Amount : param.long1Amount) != 0)
      ITimeswapV2Option(optionPair).transferPosition(
        param.strike,
        param.maturity,
        msg.sender,
        isLong0 ? TimeswapV2OptionPosition.Long0 : TimeswapV2OptionPosition.Long1,
        isLong0 ? param.long0Amount : param.long1Amount
      );

    if ((isLong0 ? param.long1Amount : param.long0Amount) != 0) {
      data = abi.encode(token0, token1, isLong0, isLong0 ? token0Amount : token1Amount, positionAmount, data);

      (, , data) = ITimeswapV2Option(optionPair).swap(
        TimeswapV2OptionSwapParam({
          strike: param.strike,
          maturity: param.maturity,
          tokenTo: to,
          longTo: msg.sender,
          isLong0ToLong1: isLong0,
          transaction: isLong0 ? TimeswapV2OptionSwap.GivenToken0AndLong0 : TimeswapV2OptionSwap.GivenToken1AndLong1,
          amount: positionAmount - (isLong0 ? token0Amount + param.long0Amount : token1Amount + param.long1Amount),
          data: data
        })
      );
    } else {
      data = timeswapV2PeripheryCloseBorrowGivenPositionInternal(
        TimeswapV2PeripheryCloseBorrowGivenPositionInternalParam({
          optionPair: msg.sender,
          token0: token0,
          token1: token1,
          strike: param.strike,
          maturity: param.maturity,
          isLong0: isLong0,
          token0Amount: token0Amount,
          token1Amount: token1Amount,
          positionAmount: positionAmount,
          data: data
        })
      );
    }
  }

  /// @notice the abstract implementation for TimeswapV2OptionSwapCallback
  /// @param param params for swapCallBack from TimeswapV2Option
  /// @return data data passed in bytes in the param passed back
  function timeswapV2OptionSwapCallback(
    TimeswapV2OptionSwapCallbackParam calldata param
  ) external returns (bytes memory data) {
    address token0;
    address token1;
    bool isLong0;
    uint256 withdrawAmount;
    uint256 positionAmount;
    (token0, token1, isLong0, withdrawAmount, positionAmount, data) = abi.decode(
      param.data,
      (address, address, bool, uint256, uint256, bytes)
    );

    Verify.timeswapV2Option(optionFactory, token0, token1);

    data = timeswapV2PeripheryCloseBorrowGivenPositionInternal(
      TimeswapV2PeripheryCloseBorrowGivenPositionInternalParam({
        optionPair: msg.sender,
        token0: token0,
        token1: token1,
        strike: param.strike,
        maturity: param.maturity,
        isLong0: isLong0,
        token0Amount: param.token0AndLong0Amount + (isLong0 ? withdrawAmount : 0),
        token1Amount: param.token1AndLong1Amount + (isLong0 ? 0 : withdrawAmount),
        positionAmount: positionAmount,
        data: data
      })
    );
  }

  /// @notice the implementation which is to be overriden for DEX/Aggregator specific logic for TimeswapV2CloseBorrowGivenPositionChoice
  /// @param param params for calling the implementation specfic closeBorrowGivenPositionChoice to be overriden
  /// @return token0Amount the amount of token0
  /// @return token1Amount the amount of token1
  /// @return data data passed in bytes in the param passed back
  function timeswapV2PeripheryCloseBorrowGivenPositionChoiceInternal(
    TimeswapV2PeripheryCloseBorrowGivenPositionChoiceInternalParam memory param
  ) internal virtual returns (uint256 token0Amount, uint256 token1Amount, bytes memory data);

  /// @notice the implementation which is to be overriden for DEX/Aggregator specific logic for TimeswapV2CloseBorrowGivenPosition
  /// @param param params for calling the implementation specfic closeBorrowGivenPosition to be overriden
  /// @return data data passed in bytes in the param passed back
  function timeswapV2PeripheryCloseBorrowGivenPositionInternal(
    TimeswapV2PeripheryCloseBorrowGivenPositionInternalParam memory param
  ) internal virtual returns (bytes memory data);
}