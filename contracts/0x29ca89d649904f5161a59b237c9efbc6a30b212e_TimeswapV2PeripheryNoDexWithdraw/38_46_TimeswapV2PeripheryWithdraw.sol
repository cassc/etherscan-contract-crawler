// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import {StrikeConversion} from "@timeswap-labs/v2-library/contracts/StrikeConversion.sol";

import {ITimeswapV2OptionFactory} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2OptionFactory.sol";
import {ITimeswapV2Option} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2Option.sol";

import {OptionFactoryLibrary} from "@timeswap-labs/v2-option/contracts/libraries/OptionFactory.sol";

import {TimeswapV2OptionMintParam, TimeswapV2OptionCollectParam} from "@timeswap-labs/v2-option/contracts/structs/Param.sol";
import {TimeswapV2OptionMintCallbackParam} from "@timeswap-labs/v2-option/contracts/structs/CallbackParam.sol";

import {TimeswapV2OptionMint, TimeswapV2OptionCollect} from "@timeswap-labs/v2-option/contracts/enums/Transaction.sol";
import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

import {ITimeswapV2PoolFactory} from "@timeswap-labs/v2-pool/contracts/interfaces/ITimeswapV2PoolFactory.sol";
import {ITimeswapV2Pool} from "@timeswap-labs/v2-pool/contracts/interfaces/ITimeswapV2Pool.sol";

import {ITimeswapV2Token} from "@timeswap-labs/v2-token/contracts/interfaces/ITimeswapV2Token.sol";

import {TimeswapV2TokenBurnParam} from "@timeswap-labs/v2-token/contracts/structs/Param.sol";

import {TimeswapV2PeripheryWithdrawParam} from "./structs/Param.sol";

import {ITimeswapV2PeripheryWithdraw} from "./interfaces/ITimeswapV2PeripheryWithdraw.sol";
import {Verify} from "./libraries/Verify.sol";

/// @title Abstract contract which specifies functions that are required for  withdraw which are to be inherited for a specific DEX/Aggregator implementation

abstract contract TimeswapV2PeripheryWithdraw is ITimeswapV2PeripheryWithdraw, ERC1155Receiver {
  /* ===== MODEL ===== */
  /// @inheritdoc ITimeswapV2PeripheryWithdraw
  address public immutable override optionFactory;
  /// @inheritdoc ITimeswapV2PeripheryWithdraw
  address public immutable override tokens;

  /* ===== INIT ===== */

  constructor(address chosenOptionFactory, address chosenTokens) {
    optionFactory = chosenOptionFactory;
    tokens = chosenTokens;
  }

  /// @notice the abstract implementation for withdraw function
  /// @param param params for  withdraw as mentioned in the TimeswapV2PeripheryWithdrawParam struct
  /// @return token0Amount is the token0Amount recieved
  /// @return token1Amount is the token0Amount recieved
  function withdraw(
    TimeswapV2PeripheryWithdrawParam memory param
  ) internal returns (uint256 token0Amount, uint256 token1Amount) {
    address optionPair = OptionFactoryLibrary.getWithCheck(optionFactory, param.token0, param.token1);

    ITimeswapV2Token(tokens).burn(
      TimeswapV2TokenBurnParam({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        long0To: address(this),
        long1To: address(this),
        shortTo: address(this),
        long0Amount: 0,
        long1Amount: 0,
        shortAmount: param.positionAmount,
        data: bytes("")
      })
    );

    (token0Amount, token1Amount, , ) = ITimeswapV2Option(optionPair).collect(
      TimeswapV2OptionCollectParam({
        strike: param.strike,
        maturity: param.maturity,
        token0To: param.token0To,
        token1To: param.token1To,
        transaction: TimeswapV2OptionCollect.GivenShort,
        amount: param.positionAmount,
        data: bytes("")
      })
    );
  }
}