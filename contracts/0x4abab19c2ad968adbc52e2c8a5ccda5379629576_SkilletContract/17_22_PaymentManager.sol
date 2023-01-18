//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import './FeeManager.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IWETH {
  function withdraw(uint256) external;
}

contract PaymentManager is ProxyApprovable, ReentrancyGuard, Ownable {
  address private WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address private ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  IFeeManager public feeManager;

  uint256 private MAX_UINT256 = 2**256 - 1;
  bool public alwaysWithdrawWeth = true;

  /* Payment options for paying seller with payment token */
  struct PaymentOptionParams {
    address paymentTokenAddress;
    uint256 amountOutMin;
  }

  function setFeeManager(address feeManagerAddress) public onlyOwner {
    feeManager = IFeeManager(feeManagerAddress);
  }

  function setAlwaysWithdrawWeth(bool _alwaysWithdrawWeth) public onlyOwner {
    alwaysWithdrawWeth = _alwaysWithdrawWeth;
  }

  function paySellerAllPayments(
    uint256[] memory initialProtocolOutputTokenBalances,
    PaymentOptionParams[] memory paymentOptions
  ) internal 
  {
    for (uint256 i=0; i<paymentOptions.length; i++) {
      paySellerPayment(
        initialProtocolOutputTokenBalances[i],
        paymentOptions[i]
      );
    }
  }

  /**
   * Pay seller owed amount for given payment option
   * initialPaymentTokenBalance -> initial balance of token paid by protocol
   * paymentOption -> specific instructions for required amounts
   */
  function paySellerPayment(
    uint256 initialPaymentTokenBalance,
    PaymentOptionParams memory paymentOption
  ) private 
    nonReentrant 
  {
    /* Make sure balance of paymentToken is higher than amountOutMin */
    uint256 currentPaymentTokenBalance = getCurrentTokenBalance(paymentOption.paymentTokenAddress);
    uint256 paymentTokenOwed = currentPaymentTokenBalance - initialPaymentTokenBalance;
    require(
      paymentTokenOwed >= paymentOption.amountOutMin, 
      "PAYMENT TOKEN AMOUNT OWED LESS THAN MIN AMOUNT OUT"
    );
    
    transferPaymentToSeller(paymentOption.paymentTokenAddress, paymentTokenOwed);
    return;
  }

  function getAllPaymentTokenBalances(
    PaymentOptionParams[] memory paymentOptions
  ) internal 
    view 
    returns (uint256[] memory) 
  {
    uint256[] memory protocolOutputTokenBalances = new uint256[](paymentOptions.length);
    for (uint256 i=0; i<paymentOptions.length; i++) {
      PaymentOptionParams memory paymentOption = paymentOptions[i];
      protocolOutputTokenBalances[i] = getCurrentTokenBalance(paymentOption.paymentTokenAddress);
    }
    return protocolOutputTokenBalances;
  }

  function getCurrentTokenBalance(
    address paymentTokenAddress
  ) private 
    view 
    returns (uint256) 
  {
    uint256 balance;
    if (paymentTokenAddress == ETH_ADDRESS) {
      balance = address(this).balance;
      return balance;
    }

    IERC20 paymentToken = IERC20(paymentTokenAddress);
    balance = paymentToken.balanceOf(address(this));
    return balance;
  }

  function calculateAndTakeFee(
    address paymentTokenAddress, 
    uint256 amountOwed
  ) private 
    returns (uint256)
  {
    uint256 feeAmount = feeManager.calculateFee(msg.sender, amountOwed);
    address payable protocolFeeRecipient = feeManager.protocolFeeRecipient();

    if (paymentTokenAddress == ETH_ADDRESS) {
      protocolFeeRecipient.transfer(feeAmount);
      return feeAmount;
    }

    IERC20 paymentToken = IERC20(paymentTokenAddress);
    paymentToken.transfer(protocolFeeRecipient, feeAmount);
    return feeAmount;
  }

  function withdrawWethAndTransferEth(uint256 amountOwed) private {
    uint256 initEthBalance = address(this).balance;
    
    IWETH(WETH_ADDRESS).withdraw(amountOwed);
    require(
      address(this).balance - initEthBalance == amountOwed, 
      "WITHDRAW WETH AMOUNT LESS THAN AMOUNT OWED"
    );
    payable(msg.sender).transfer(amountOwed);
  }

  function transferPaymentToSeller(
    address paymentTokenAddress, 
    uint256 amountOwed
  ) private 
  {
    uint256 feeAmount = calculateAndTakeFee(paymentTokenAddress, amountOwed);
    uint256 netAmount = amountOwed - feeAmount;

    if (paymentTokenAddress == ETH_ADDRESS) {
      payable(msg.sender).transfer(netAmount);
      return;
    
    } else if (paymentTokenAddress == WETH_ADDRESS && alwaysWithdrawWeth) {
      withdrawWethAndTransferEth(netAmount);
      return;
    }

    IERC20 paymentToken = IERC20(paymentTokenAddress);
    paymentToken.transfer(msg.sender, netAmount);
    return;
  }
}