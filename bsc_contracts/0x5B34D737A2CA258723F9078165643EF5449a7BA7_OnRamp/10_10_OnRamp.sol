//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract OnRamp is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public fundCollectorAddress;
  mapping(address => bool) public operators;
  mapping(address => uint256) public maxTokenAmountToSend;
  uint256 maxCurrencyAmountToSend;

  event WithdrawCurrency(address fundCollectorAddress, uint256 currencyAmount);
  event WithdrawToken(
    address fundCollectorAddress,
    uint256 tokenAmount,
    address tokenAddress
  );

  event SendCurrency(address receiver, uint256 currencyAmount);
  event SendToken(address receiver, uint256 tokenAmount, address tokenAddress);

  constructor() {
    fundCollectorAddress = _msgSender();
    maxCurrencyAmountToSend = 0;
  }

  function setupOperator(address operatorAddress)
    external
    onlyOwner
    isValidAddress(operatorAddress)
  {
    require(!operators[operatorAddress], "DD_Operator has already existed");
    operators[operatorAddress] = true;
  }

  function removeOperator(address operatorAddress)
    external
    onlyOwner
    isValidAddress(operatorAddress)
  {
    require(operators[operatorAddress], "DD_Operator has not existed yet");
    operators[operatorAddress] = false;
  }

  function setfundCollectorAddress(address _fundCollectorAddress)
    external
    onlyOwner
    isValidAddress(_fundCollectorAddress)
  {
    fundCollectorAddress = _fundCollectorAddress;
  }

  function setMaxTokenAmountPerSend(
    address tokenAddress,
    uint256 maxTokenAmountPerSend
  ) external onlyOwner isValidAddress(tokenAddress) {
    maxTokenAmountToSend[tokenAddress] = maxTokenAmountPerSend;
  }

  function setMaxCurrencyAmountPerSend(uint256 maxCurrencyAmountPerSend)
    external
    onlyOwner
  {
    maxCurrencyAmountToSend = maxCurrencyAmountPerSend;
  }

  function withdrawCurrency(uint256 currencyAmount) external onlyOperater {
    require(currencyAmount > 0, "DD_Withdraw amount invalid");

    require(
      currencyAmount <= address(this).balance,
      "DD_Not enough amount to withdraw"
    );

    require(
      fundCollectorAddress != address(0),
      "DD_Invalid fund collector address"
    );

    payable(fundCollectorAddress).transfer(currencyAmount);

    emit WithdrawCurrency(fundCollectorAddress, currencyAmount);
  }

  function withdrawToken(uint256 tokenAmount, address tokenAddress)
    external
    onlyOperater
  {
    require(tokenAmount > 0, "DD_Withdraw amount invalid");

    require(
      tokenAmount <= IERC20(tokenAddress).balanceOf(address(this)),
      "DD_Not enough amount to withdraw"
    );

    require(
      fundCollectorAddress != address(0),
      "DD_Invalid fund collector address"
    );

    IERC20(tokenAddress).safeTransfer(fundCollectorAddress, tokenAmount);

    emit WithdrawToken(fundCollectorAddress, tokenAmount, tokenAddress);
  }

  function sendToken(
    uint256 tokenAmount,
    address tokenAddress,
    address receiver
  ) external onlyOperater isValidAddress(receiver) {
    require(maxTokenAmountToSend[tokenAddress] > 0, "DD_Token is not sendable");

    require(tokenAmount > 0, "DD_Send amount invalid");

    require(
      tokenAmount <= maxTokenAmountToSend[tokenAddress],
      "DD_Send token amount exceeds limit"
    );

    require(
      tokenAmount <= IERC20(tokenAddress).balanceOf(address(this)),
      "DD_Not enough amount to send"
    );

    IERC20(tokenAddress).safeTransfer(receiver, tokenAmount);

    emit SendToken(receiver, tokenAmount, tokenAddress);
  }

  function sendCurrency(uint256 currencyAmount, address receiver)
    external
    onlyOperater
    isValidAddress(receiver)
  {
    require(maxCurrencyAmountToSend > 0, "DD_Currency is not sendable");

    require(currencyAmount > 0, "DD_Send amount invalid");

    require(
      currencyAmount <= maxCurrencyAmountToSend,
      "DD_Send currency amount exceeds limit"
    );

    require(
      currencyAmount <= address(this).balance,
      "DD_Not enough amount to send"
    );

    payable(receiver).transfer(currencyAmount);

    emit SendCurrency(receiver, currencyAmount);
  }

  function depositCurrency() external payable {}

  modifier onlyOperater() {
    require(operators[_msgSender()], "DD_You are not Operator");
    _;
  }

  modifier isValidAddress(address _address) {
    require(_address != address(0), "DD_Invalid address");
    _;
  }
}