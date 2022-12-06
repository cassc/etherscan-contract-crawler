// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISaplings {
  error InvalidSignature();
  error WrongAmount();
  error SoldOut();
  error Timeout();
  error PaymentFailed();
  error SendToCharityFirst();
  error SwapFailed();

  event SwapSuccess(address indexed currency, uint256 indexed wethAmount, uint256 indexed currencyAmount);
  event SwapFailure(string reason);
  event ReceivedEth(address sender, uint256 amount);
  event UpdatedCharity(address indexed charity1, address indexed charity2, address indexed charity3);
}