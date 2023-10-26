// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ISwap {
  /** ERRORS */

  /// @notice reverts when a zero address is passed in as a potential admin or smart contract location
  error CannotBeZeroAddress();
  /// @notice reverts when the 0x token swap fails
  error ZeroXSwapFailed();
  /// @notice reverts when the user provides an incorrect buy token
  error IncorrectBuyToken();

  /**
    @notice emits when a user swaps a token to deposit into a thin wallet
    @param user the user who swapped the token
    @param amount the amount the user swapped of their token
    @param token the token that the user swapped
    @param target the thin wallet that the user was depositing into
  */
  event SwapDeposit(address user, uint256 amount, ERC20 token, address target);

  /**
    @notice emits when a user swaps a token to deposit into a thin wallet
    @param user the user who swapped the token
    @param amount the amount the user swapped of their token
    @param target the thin wallet that the user was depositing into
  */
  event SwapETH(address user, uint256 amount, address target);

  /**
    @notice this function is used to swap donated ETH to a desired token before it is deposited into another external contract
    @param buyToken the token that the user wishes to swap for, should be the base token
    @param amount the amount the user is selling of their sellToken
    @param location where the bought tokens will be sent after they are swapped
    @param spender an address provided by the 0x Quote API
    @param swapTarget an address provided by the 0x Quote API
    @param swapCallData the calldata provided by the 0x Quote API
  */
  function depositETH(
    ERC20 buyToken,
    uint256 amount,
    address location,
    address spender,
    address payable swapTarget,
    bytes calldata swapCallData
  ) external payable;

  /**
    @notice this function is used to swap donated ERC20 tokens to a desired token before it is deposited into another external contract
    @param sellToken the token that the user is selling to acquire the base token
    @param buyToken the token that the user wishes to swap for, should be the base token
    @param amount the amount the user is selling of their sellToken
    @param location where the bought tokens will be sent after they are swapped
    @param spender an address provided by the 0x Quote API
    @param swapTarget an address provided by the 0x Quote API
    @param swapCallData the calldata provided by the 0x Quote API
  */
  function depositERC20(
    ERC20 sellToken,
    ERC20 buyToken,
    uint256 amount,
    address location,
    address spender,
    address payable swapTarget,
    bytes calldata swapCallData
  ) external payable;

  function baseToken() external view returns (ERC20);
}