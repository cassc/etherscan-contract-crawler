// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental "ABIEncoderV2";

import {IDexImplementation} from "./interfaces/IDexImplementation.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IDomaniDexGeneral} from "../interfaces/IDomaniDexGeneral.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {DomaniDexConstants} from "../lib/DomaniDexConstants.sol";

/**
 * @title UniswapV2Implementation
 * @author Domani Protocol
 *
 * UniswapV2Implementation is the implementation for UniswapV2 and forks used by DomaniDex
 *
 */
contract UniswapV2Implementation is IDexImplementation {
  using SafeERC20 for IERC20;

  function swapExactInput(bytes calldata _info, IDomaniDexGeneral.SwapParams memory _inputParams)
    external
    payable
    override
    returns (IDomaniDexGeneral.ReturnValues memory returnValues)
  {
    IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(decodeImplementationData(_info));

    address[] memory tokenSwapPath = decodeExtraData(_inputParams.extraData);

    uint256 lastTokenIndex = tokenSwapPath.length - 1;

    bool isNativeOutput = _inputParams.isNative;

    returnValues.inputToken = address(tokenSwapPath[0]);
    returnValues.inputAmount = _inputParams.exactAmount;

    returnValues.outputToken = isNativeOutput
      ? DomaniDexConstants.NATIVE_ADDR
      : address(tokenSwapPath[lastTokenIndex]);

    IERC20(tokenSwapPath[0]).safeIncreaseAllowance(
      address(uniswapV2Router),
      _inputParams.exactAmount
    );

    returnValues.outputAmount = isNativeOutput
      ? uniswapV2Router.swapExactTokensForETH(
        _inputParams.exactAmount,
        _inputParams.minOutOrMaxIn,
        tokenSwapPath,
        _inputParams.recipient,
        _inputParams.expiration
      )[lastTokenIndex]
      : uniswapV2Router.swapExactTokensForTokens(
        _inputParams.exactAmount,
        _inputParams.minOutOrMaxIn,
        tokenSwapPath,
        _inputParams.recipient,
        _inputParams.expiration
      )[lastTokenIndex];
  }

  function swapExactOutput(bytes calldata _info, IDomaniDexGeneral.SwapParams memory _inputParams)
    external
    payable
    override
    returns (IDomaniDexGeneral.ReturnValues memory returnValues)
  {
    IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(decodeImplementationData(_info));

    address[] memory tokenSwapPath = decodeExtraData(_inputParams.extraData);

    uint256 lastTokenIndex = tokenSwapPath.length - 1;

    bool isNativeInput = _inputParams.isNative;

    returnValues.inputToken = isNativeInput
      ? DomaniDexConstants.NATIVE_ADDR
      : address(tokenSwapPath[0]);
    returnValues.outputToken = address(tokenSwapPath[lastTokenIndex]);
    returnValues.outputAmount = _inputParams.exactAmount;

    if (isNativeInput) {
      returnValues.inputAmount = uniswapV2Router.swapETHForExactTokens{
        value: _inputParams.minOutOrMaxIn
      }(_inputParams.exactAmount, tokenSwapPath, _inputParams.recipient, _inputParams.expiration)[
        0
      ];
    } else {
      IERC20(tokenSwapPath[0]).safeIncreaseAllowance(
        address(uniswapV2Router),
        _inputParams.minOutOrMaxIn
      );

      returnValues.inputAmount = uniswapV2Router.swapTokensForExactTokens(
        _inputParams.exactAmount,
        _inputParams.minOutOrMaxIn,
        tokenSwapPath,
        _inputParams.recipient,
        _inputParams.expiration
      )[0];

      if (_inputParams.minOutOrMaxIn > returnValues.inputAmount) {
        IERC20(tokenSwapPath[0]).safeApprove(address(uniswapV2Router), 0);
      }
    }
  }

  function decodeImplementationData(bytes calldata _info) internal pure returns (address) {
    return abi.decode(_info, (address));
  }

  function decodeExtraData(bytes memory params) internal pure returns (address[] memory) {
    return abi.decode(params, (address[]));
  }
}