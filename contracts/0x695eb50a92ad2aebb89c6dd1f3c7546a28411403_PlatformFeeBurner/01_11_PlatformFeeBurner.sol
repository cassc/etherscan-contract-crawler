// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import { ITokenConverter } from "../converter/ITokenConverter.sol";

import { BurnerBase } from "./BurnerBase.sol";

contract PlatformFeeBurner is BurnerBase {
  using SafeERC20 for IERC20;

  /**********
   * Events *
   **********/

  /// @notice Emitted when the address of converter contract is updated.
  /// @param converter The address of new converter contract.
  event UpdateConverter(address converter);

  /*************
   * Variables *
   *************/

  /// @notice The address of converter contract.
  address public converter;

  /***************
   * Constructor *
   ***************/

  constructor(address _converter, address _receiver) BurnerBase(_receiver) {
    converter = _converter;
  }

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Convert all tokenIn with given routes.
  /// @dev The token should already in this contract.
  /// @param _tokenIn The address of token to convert.
  /// @param _routes The routes used to convert.
  /// @param _minOut The minimum amount of token should received.
  /// @return uint256 The amount of token converted.
  function burn(
    address _tokenIn,
    uint256[] memory _routes,
    uint256 _minOut
  ) external payable onlyKeeper returns (uint256) {
    uint256 _amountIn;
    if (_tokenIn == address(0)) {
      _amountIn = address(this).balance;
    } else {
      _amountIn = IERC20(_tokenIn).balanceOf(address(this));
    }

    if (_routes.length == 0) {
      IERC20(_tokenIn).safeTransfer(receiver, _amountIn);
    } else {
      address _converter = converter;
      if (_tokenIn == address(0)) {
        (bool success, ) = _converter.call{ value: _amountIn }("");
        require(success, "transfer ETH failed");
      } else {
        IERC20(_tokenIn).safeTransfer(_converter, _amountIn);
      }

      for (uint256 i = 0; i < _routes.length; i++) {
        if (i + 1 < _routes.length) {
          _amountIn = ITokenConverter(_converter).convert(_routes[i], _amountIn, _converter);
        } else {
          _amountIn = ITokenConverter(_converter).convert(_routes[i], _amountIn, receiver);
        }
      }
    }
    require(_amountIn >= _minOut, "insufficient output");

    return _amountIn;
  }

  /************************
   * Restricted Functions *
   ************************/

  /// @notice Update the address of converter contract.
  /// @param _converter The new address of converter contract.
  function updateConverter(address _converter) external onlyOwner {
    converter = _converter;

    emit UpdateConverter(_converter);
  }
}