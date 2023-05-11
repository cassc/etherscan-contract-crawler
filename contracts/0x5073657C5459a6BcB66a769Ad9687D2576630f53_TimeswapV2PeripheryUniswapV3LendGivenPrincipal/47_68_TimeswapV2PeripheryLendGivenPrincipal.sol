// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {StrikeConversion} from "@timeswap-labs/v2-library/contracts/StrikeConversion.sol";

import {ITimeswapV2OptionFactory} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2OptionFactory.sol";
import {ITimeswapV2Option} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2Option.sol";

import {OptionFactoryLibrary} from "@timeswap-labs/v2-option/contracts/libraries/OptionFactory.sol";
import {TimeswapV2OptionMintParam} from "@timeswap-labs/v2-option/contracts/structs/Param.sol";
import {TimeswapV2OptionMintCallbackParam} from "@timeswap-labs/v2-option/contracts/structs/CallbackParam.sol";

import {TimeswapV2OptionMint} from "@timeswap-labs/v2-option/contracts/enums/Transaction.sol";
import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

import {ITimeswapV2PoolFactory} from "@timeswap-labs/v2-pool/contracts/interfaces/ITimeswapV2PoolFactory.sol";
import {ITimeswapV2Pool} from "@timeswap-labs/v2-pool/contracts/interfaces/ITimeswapV2Pool.sol";

import {TimeswapV2PoolDeleverageParam} from "@timeswap-labs/v2-pool/contracts/structs/Param.sol";
import {TimeswapV2PoolDeleverageChoiceCallbackParam, TimeswapV2PoolDeleverageCallbackParam} from "@timeswap-labs/v2-pool/contracts/structs/CallbackParam.sol";

import {TimeswapV2PoolDeleverage} from "@timeswap-labs/v2-pool/contracts/enums/Transaction.sol";

import {PoolFactoryLibrary} from "@timeswap-labs/v2-pool/contracts/libraries/PoolFactory.sol";

import {ITimeswapV2Token} from "@timeswap-labs/v2-token/contracts/interfaces/ITimeswapV2Token.sol";

import {TimeswapV2TokenMintParam} from "@timeswap-labs/v2-token/contracts/structs/Param.sol";
import {TimeswapV2TokenMintCallbackParam} from "@timeswap-labs/v2-token/contracts/structs/CallbackParam.sol";

import {ITimeswapV2PeripheryLendGivenPrincipal} from "./interfaces/ITimeswapV2PeripheryLendGivenPrincipal.sol";

import {TimeswapV2PeripheryLendGivenPrincipalParam} from "./structs/Param.sol";
import {TimeswapV2PeripheryLendGivenPrincipalInternalParam} from "./structs/InternalParam.sol";

import {Verify} from "./libraries/Verify.sol";

/// @title Abstract contract which specifies functions that are required for lending which are to be inherited for a specific DEX/Aggregator implementation
abstract contract TimeswapV2PeripheryLendGivenPrincipal is ITimeswapV2PeripheryLendGivenPrincipal {
  /* ===== MODEL ===== */
  /// @inheritdoc ITimeswapV2PeripheryLendGivenPrincipal
  address public immutable override optionFactory;
  /// @inheritdoc ITimeswapV2PeripheryLendGivenPrincipal
  address public immutable override poolFactory;
  /// @inheritdoc ITimeswapV2PeripheryLendGivenPrincipal
  address public immutable override tokens;

  /* ===== INIT ===== */

  constructor(address chosenOptionFactory, address chosenPoolFactory, address chosenTokens) {
    optionFactory = chosenOptionFactory;
    poolFactory = chosenPoolFactory;
    tokens = chosenTokens;
  }

  /// @notice the abstract implementation for lendGivenPrincipal function
  /// @param param params for  lendGivenPrincipal as mentioned in the TimeswapV2PeripheryLendGivenPrincipalParam struct
  /// @return positionAmount the amount of lend position a user has
  /// @return data data passed as bytes in the param
  function lendGivenPrincipal(
    TimeswapV2PeripheryLendGivenPrincipalParam memory param
  ) internal returns (uint256 positionAmount, bytes memory data) {
    (, address poolPair) = PoolFactoryLibrary.getWithCheck(optionFactory, poolFactory, param.token0, param.token1);

    data = abi.encode(param.token0, param.token1, param.to, param.token0Amount, param.token1Amount, param.data);

    (, , , data) = ITimeswapV2Pool(poolPair).deleverage(
      TimeswapV2PoolDeleverageParam({
        strike: param.strike,
        maturity: param.maturity,
        to: address(this),
        transaction: TimeswapV2PoolDeleverage.GivenLong,
        delta: StrikeConversion.combine(param.token0Amount, param.token1Amount, param.strike, false),
        data: data
      })
    );

    (positionAmount, data) = abi.decode(data, (uint256, bytes));
  }

  /// @notice the abstract implementation for deleverageChoiceCallback function
  /// @param param params for  timeswapV2PoolDeleverageChoiceCallback as mentioned in the TimeswapV2PoolDeleverageChoiceCallbackParam struct
  /// @return long0Amount the amount of long0 chosen
  /// @return long1Amount the amount of long1 chosen
  /// @return data data passed as bytes in the param
  function timeswapV2PoolDeleverageChoiceCallback(
    TimeswapV2PoolDeleverageChoiceCallbackParam calldata param
  ) external view override returns (uint256 long0Amount, uint256 long1Amount, bytes memory data) {
    address token0;
    address token1;
    address to;
    (token0, token1, to, long0Amount, long1Amount, data) = abi.decode(
      param.data,
      (address, address, address, uint256, uint256, bytes)
    );

    Verify.timeswapV2Pool(optionFactory, poolFactory, token0, token1);

    data = abi.encode(token0, token1, to, data);
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
    (token0, token1, to, data) = abi.decode(param.data, (address, address, address, bytes));

    address optionPair = Verify.timeswapV2Pool(optionFactory, poolFactory, token0, token1);

    data = abi.encode(token0, token1, to, param.shortAmount, data);

    (, , , data) = ITimeswapV2Option(optionPair).mint(
      TimeswapV2OptionMintParam({
        strike: param.strike,
        maturity: param.maturity,
        long0To: msg.sender,
        long1To: msg.sender,
        shortTo: address(this),
        transaction: TimeswapV2OptionMint.GivenTokensAndLongs,
        amount0: param.long0Amount,
        amount1: param.long1Amount,
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
    address token0;
    address token1;
    address to;
    uint256 shortAmount;
    (token0, token1, to, shortAmount, data) = abi.decode(param.data, (address, address, address, uint256, bytes));

    Verify.timeswapV2Option(optionFactory, token0, token1);

    shortAmount += param.shortAmount;

    ITimeswapV2Token(tokens).mint(
      TimeswapV2TokenMintParam({
        token0: token0,
        token1: token1,
        strike: param.strike,
        maturity: param.maturity,
        long0To: address(this),
        long1To: address(this),
        shortTo: to,
        long0Amount: 0,
        long1Amount: 0,
        shortAmount: shortAmount,
        data: bytes("")
      })
    );

    data = timeswapV2PeripheryLendGivenPrincipalInternal(
      TimeswapV2PeripheryLendGivenPrincipalInternalParam({
        optionPair: msg.sender,
        token0: token0,
        token1: token1,
        strike: param.strike,
        maturity: param.maturity,
        token0Amount: param.token0AndLong0Amount,
        token1Amount: param.token1AndLong1Amount,
        positionAmount: shortAmount,
        data: data
      })
    );

    data = abi.encode(shortAmount, data);
  }

  /// @notice the abstract implementation for TimeswapV2TokenMintCallback
  /// @param param params for mintCallBack from TimeswapV2Token
  /// @return data data passed in bytes in the param passed back
  function timeswapV2TokenMintCallback(
    TimeswapV2TokenMintCallbackParam calldata param
  ) external returns (bytes memory data) {
    Verify.timeswapV2Token(tokens);

    address optionPair = OptionFactoryLibrary.get(optionFactory, param.token0, param.token1);

    ITimeswapV2Option(optionPair).transferPosition(
      param.strike,
      param.maturity,
      msg.sender,
      TimeswapV2OptionPosition.Short,
      param.shortAmount
    );

    data = bytes("");
  }

  /// @notice the implementation which is to be overriden for DEX/Aggregator specific logic for TimeswapV2ALendGivenPrincipal
  /// @param param params for calling the implementation specfic lendGivenPrincipal to be overriden
  /// @return data data passed in bytes in the param passed back
  function timeswapV2PeripheryLendGivenPrincipalInternal(
    TimeswapV2PeripheryLendGivenPrincipalInternalParam memory param
  ) internal virtual returns (bytes memory data);
}