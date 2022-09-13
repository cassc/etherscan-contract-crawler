// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../interfaces/IWeth.sol';

/// @notice Library to help safely transfer tokens and handle ETH wrapping and unwrapping of WETH
library TransferHelper {
  using SafeERC20 for IERC20;

  /// @notice Internal function used for standard ERC20 transferFrom method
  /// @notice it contains a pre and post balance check
  /// @notice as well as a check on the msg.senders balance
  /// @param token is the address of the ERC20 being transferred
  /// @param from is the remitting address
  /// @param to is the location where they are being delivered
  function transferTokens(
    address token,
    address from,
    address to,
    uint256 amount
  ) internal {
    uint256 priorBalance = IERC20(token).balanceOf(address(to));
    require(IERC20(token).balanceOf(from) >= amount, 'THL01');
    SafeERC20.safeTransferFrom(IERC20(token), from, to, amount);
    uint256 postBalance = IERC20(token).balanceOf(address(to));
    require(postBalance - priorBalance == amount, 'THL02');
  }

  /// @notice Internal function is used with standard ERC20 transfer method
  /// @notice this function ensures that the amount received is the amount sent with pre and post balance checking
  /// @param token is the ERC20 contract address that is being transferred
  /// @param to is the address of the recipient
  /// @param amount is the amount of tokens that are being transferred
  function withdrawTokens(
    address token,
    address to,
    uint256 amount
  ) internal {
    uint256 priorBalance = IERC20(token).balanceOf(address(to));
    SafeERC20.safeTransfer(IERC20(token), to, amount);
    uint256 postBalance = IERC20(token).balanceOf(address(to));
    require(postBalance - priorBalance == amount, 'THL02');
  }

  /// @dev Internal function that handles transfering payments from buyers to sellers with special WETH handling
  /// @dev this function assumes that if the recipient address is a contract, it cannot handle ETH - so we always deliver WETH
  /// @dev special care needs to be taken when using contract addresses to sell deals - to ensure it can handle WETH properly when received
  function transferPayment(
    address weth,
    address token,
    address from,
    address payable to,
    uint256 amount
  ) internal {
    if (token == weth) {
      require(msg.value == amount, 'THL03');
      if (!Address.isContract(to)) {
        (bool success, ) = to.call{value: amount}('');
        require(success, 'THL04');
      } else {
        /// @dev we want to deliver WETH from ETH here for better handling at contract
        IWeth(weth).deposit{value: amount}();
        assert(IWeth(weth).transfer(to, amount));
      }
    } else {
      transferTokens(token, from, to, amount);
    }
  }

  /// @dev Internal funciton that handles withdrawing tokens and WETH that are up for sale to buyers
  /// @dev this function is only called if the tokens are not timelocked
  /// @dev this function handles weth specially and delivers ETH to the recipient
  function withdrawPayment(
    address weth,
    address token,
    address payable to,
    uint256 amount
  ) internal {
    if (token == weth) {
      IWeth(weth).withdraw(amount);
      (bool success, ) = to.call{value: amount}('');
      require(success, 'THL04');
    } else {
      withdrawTokens(token, to, amount);
    }
  }
}