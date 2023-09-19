// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import { ILidoStETH } from "../../interfaces/ILidoStETH.sol";
import { IMarket } from "../interfaces/IMarket.sol";

// solhint-disable contract-name-camelcase

contract stETHGateway {
  using SafeERC20 for IERC20;

  /*************
   * Constants *
   *************/

  /// @dev The address of Lido's stETH token.
  address public constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

  /// @notice The address of Fractional ETH.
  address public immutable fToken;

  /// @notice The address of Leveraged ETH.
  address public immutable xToken;

  /// @notice The address of Market.
  address public immutable market;

  /************
   * Modifier *
   ************/

  constructor(
    address _market,
    address _fToken,
    address _xToken
  ) {
    market = _market;
    fToken = _fToken;
    xToken = _xToken;

    IERC20(stETH).safeApprove(_market, uint256(-1));
    IERC20(_fToken).safeApprove(_market, uint256(-1));
    IERC20(_xToken).safeApprove(_market, uint256(-1));
  }

  receive() external payable {}

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Mint some fToken with some ETH.
  /// @param _minFTokenMinted The minimum amount of fToken should be received.
  /// @return _fTokenMinted The amount of fToken should be received.
  function mintFToken(uint256 _minFTokenMinted) external payable returns (uint256 _fTokenMinted) {
    ILidoStETH(stETH).submit{ value: msg.value }(address(0));

    _fTokenMinted = IMarket(market).mintFToken(msg.value, msg.sender, _minFTokenMinted);

    _refund(stETH, msg.sender);
  }

  /// @notice Mint some xToken with some ETH.
  /// @param _minXTokenMinted The minimum amount of xToken should be received.
  /// @return _xTokenMinted The amount of xToken should be received.
  function mintXToken(uint256 _minXTokenMinted) external payable returns (uint256 _xTokenMinted) {
    ILidoStETH(stETH).submit{ value: msg.value }(address(0));

    _xTokenMinted = IMarket(market).mintXToken(msg.value, msg.sender, _minXTokenMinted);

    _refund(stETH, msg.sender);
  }

  /// @notice Mint some xToken by add some ETH as collateral.
  /// @param _minXTokenMinted The minimum amount of xToken should be received.
  /// @return _xTokenMinted The amount of xToken should be received.
  function addBaseToken(uint256 _minXTokenMinted) external payable returns (uint256 _xTokenMinted) {
    ILidoStETH(stETH).submit{ value: msg.value }(address(0));

    _xTokenMinted = IMarket(market).addBaseToken(msg.value, msg.sender, _minXTokenMinted);

    _refund(stETH, msg.sender);
  }

  /**********************
   * Internal Functions *
   **********************/

  /// @dev Internal function to transfer token to this contract.
  /// @param _token The address of token to transfer.
  /// @param _amount The amount of token to transfer.
  /// @return uint256 The amount of token transfered.
  function _transferTokenIn(address _token, uint256 _amount) internal returns (uint256) {
    if (_amount == uint256(-1)) {
      _amount = IERC20(_token).balanceOf(msg.sender);
    }

    if (_amount > 0) {
      IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    return _amount;
  }

  /// @dev Internal function to refund extra token.
  /// @param _token The address of token to refund.
  /// @param _recipient The address of the token receiver.
  function _refund(address _token, address _recipient) internal {
    uint256 _balance = IERC20(_token).balanceOf(address(this));

    IERC20(_token).safeTransfer(_recipient, _balance);
  }
}