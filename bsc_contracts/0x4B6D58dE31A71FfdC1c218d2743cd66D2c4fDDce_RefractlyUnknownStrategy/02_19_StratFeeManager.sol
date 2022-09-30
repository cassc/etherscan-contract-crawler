// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract StratFeeManager is Ownable, Pausable {
  struct CommonAddresses {
    address vault;
    address router;
    address feeRecipient;
  }

  // common addresses for the strategy
  address public vault;
  address public router;
  address public feeRecipient;

  uint256 public constant MAX_FEE = 1000;

  uint256 public constant TOTAL_FEE_CAP = 40; // 4% max
  uint256 public totalFee = 30; // 3%

  uint256 public constant CALL_FEE_CAP = 111;
  uint256 public callFee = 50; // 5% of total fee

  uint256 public performanceFee = MAX_FEE - callFee;

  event SetTotalFee(uint256 totalFee);
  event SetCallFee(uint256 callFee);
  event SetVault(address vault);
  event SetRouter(address router);
  event SetFeeRecipient(address feeRecipient);

  constructor(CommonAddresses memory _commonAddresses) {
    vault = _commonAddresses.vault;
    router = _commonAddresses.router;
    feeRecipient = _commonAddresses.feeRecipient;
  }

  // adjust total fee
  function setTotalFee(uint256 _fee) public onlyOwner {
    require(_fee <= TOTAL_FEE_CAP, "!cap");
    totalFee = _fee;
    emit SetTotalFee(_fee);
  }

  // adjust call fee
  function setCallFee(uint256 _fee) public onlyOwner {
    require(_fee <= CALL_FEE_CAP, "!cap");
    callFee = _fee;
    performanceFee = MAX_FEE - callFee;
    emit SetCallFee(_fee);
  }

  // set new vault (only for strategy upgrades)
  function setVault(address _vault) external onlyOwner {
    vault = _vault;
    emit SetVault(_vault);
  }

  // set new router
  function setRouter(address _router) external onlyOwner {
    router = _router;
    emit SetRouter(_router);
  }

  // set new fee address to receive fees
  function setFeeRecipient(address _feeRecipient) external onlyOwner {
    feeRecipient = _feeRecipient;
    emit SetFeeRecipient(_feeRecipient);
  }

  function beforeDeposit() external virtual {}
}