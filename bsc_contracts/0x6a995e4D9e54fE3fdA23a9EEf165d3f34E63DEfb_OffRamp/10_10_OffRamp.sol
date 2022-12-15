//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract OffRamp is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public fundCollectorAddress;
  mapping(address => bool) public operators;

  event WithdrawCurrency(address fundCollectorAddress, uint256 currencyAmount);
  event WithdrawToken(
    address fundCollectorAddress,
    uint256 tokenAmount,
    address tokenAddress
  );

  event OffRampSuccess(
    string payoutSubmissionID,
    uint256 cryptoAmount,
    address cryptoContract
  );

  constructor() {
    fundCollectorAddress = _msgSender();
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

  function offRampByToken(
    string memory _payoutSubmissionID,
    uint256 _cryptoAmount,
    address _cryptoContract
  ) external {
    require(_cryptoAmount >= 0, "DD_Offramp token amount invalid");

    require(
      IERC20(_cryptoContract).balanceOf(_msgSender()) >= _cryptoAmount,
      "DD_Offramp insufficient token balance"
    );

    IERC20(_cryptoContract).safeTransferFrom(
      _msgSender(),
      address(this),
      _cryptoAmount
    );

    emit OffRampSuccess(_payoutSubmissionID, _cryptoAmount, _cryptoContract);
  }

  function offRampByCurrency(string memory _payoutSubmissionID)
    external
    payable
  {
    require(msg.value > 0, "DD_Offramp currency amount invalid");

    require(
      _msgSender().balance >= 0,
      "DD_Offramp insufficient currency balance"
    );

    emit OffRampSuccess(_payoutSubmissionID, msg.value, address(0));
  }

  modifier onlyOperater() {
    require(operators[_msgSender()], "DD_You are not Operator");
    _;
  }

  modifier isValidAddress(address _address) {
    require(_address != address(0), "DD_Invalid address");
    _;
  }
}