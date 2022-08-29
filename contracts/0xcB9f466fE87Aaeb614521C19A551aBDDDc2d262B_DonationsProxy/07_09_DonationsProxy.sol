// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IDonationsProxy.sol";

interface IWETH is IERC20 {
  function deposit() external payable;
}

contract DonationsProxy is IDonationsProxy {
  using SafeERC20 for ERC20;
  using SafeERC20 for IWETH;

  // The Targeted ERC20 for Swaps
  ERC20 public baseToken;

  // The WETH contract.
  IWETH public immutable WETH;

  constructor(IWETH _weth, ERC20 _baseToken) {
    if (address(_weth) == address(0) || address(_baseToken) == address(0))
      revert CannotBeZeroAddress();
    WETH = _weth;
    baseToken = _baseToken;
  }

  receive() external payable {}

  function _swap(
    ERC20 sellToken,
    ERC20 buyToken,
    uint256 amount,
    address location,
    address spender,
    address payable swapTarget,
    bytes calldata swapCallData,
    uint256 protocolFee
  ) internal {
    uint256 boughtAmount = buyToken.balanceOf(address(this));
    if (sellToken.allowance(address(this), spender) == 0) {
      sellToken.safeApprove(spender, type(uint256).max);
    } else if (sellToken.allowance(address(this), spender) < amount) {
      sellToken.safeApprove(spender, 0);
      sellToken.safeApprove(spender, type(uint256).max);
    }
    (bool success, ) = swapTarget.call{ value: protocolFee }(swapCallData);
    if (!success) revert ZeroXSwapFailed();
    payable(msg.sender).transfer(address(this).balance);
    boughtAmount = buyToken.balanceOf(address(this)) - boughtAmount;
    buyToken.safeTransfer(location, boughtAmount);
  }

  function depositETH(
    ERC20 buyToken,
    uint256 amount,
    address location,
    address spender,
    address payable swapTarget,
    bytes calldata swapCallData
  ) external payable {
    if (buyToken != baseToken) revert IncorrectBuyToken();
    WETH.deposit{ value: amount }();
    emit SwapETH(msg.sender, amount, location);
    _swap(
      ERC20(address(WETH)),
      buyToken,
      amount,
      location,
      spender,
      swapTarget,
      swapCallData,
      msg.value - amount
    );
  }

  function depositERC20(
    ERC20 sellToken,
    ERC20 buyToken,
    uint256 amount,
    address location,
    address spender,
    address payable swapTarget,
    bytes calldata swapCallData
  ) external payable override {
    if (buyToken != baseToken) revert IncorrectBuyToken();
    sellToken.safeTransferFrom(msg.sender, address(this), amount);
    _swap(
      sellToken,
      buyToken,
      amount,
      location,
      spender,
      swapTarget,
      swapCallData,
      msg.value
    );
    emit SwapDeposit(msg.sender, amount, sellToken, location);
  }
}