// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import { ZeroController } from "../controllers/ZeroController.sol";
import { ZeroLib } from "../libraries/ZeroLib.sol";

contract ControllerFundsRelease {
  address public governance;
  address public strategist;

  address public onesplit;
  address public rewards;
  mapping(address => address) public vaults;
  mapping(address => address) public strategies;
  mapping(address => mapping(address => bool)) public approvedStrategies;

  uint256 public split = 500;
  uint256 public constant max = 10000;
  uint256 internal maxGasPrice = 100e9;
  uint256 internal maxGasRepay = 250000;
  uint256 internal maxGasLoan = 500000;
  string internal constant UNDERWRITER_LOCK_IMPLEMENTATION_ID = "zero.underwriter.lock-implementation";
  address internal underwriterLockImpl;
  mapping(bytes32 => ZeroLib.LoanStatus) public loanStatus;
  bytes32 internal constant ZERO_DOMAIN_SALT = 0xb225c57bf2111d6955b97ef0f55525b5a400dc909a5506e34b102e193dd53406;
  bytes32 internal constant ZERO_DOMAIN_NAME_HASH = keccak256("ZeroController.RenVMBorrowMessage");
  bytes32 internal constant ZERO_DOMAIN_VERSION_HASH = keccak256("v2");
  bytes32 internal constant ZERO_RENVM_BORROW_MESSAGE_TYPE_HASH =
    keccak256("RenVMBorrowMessage(address module,uint256 amount,address underwriter,uint256 pNonce,bytes pData)");
  bytes32 internal constant TYPE_HASH = keccak256("TransferRequest(address asset,uint256 amount)");
  bytes32 internal ZERO_DOMAIN_SEPARATOR;

  function converters(address, address) public view returns (address) {
    return address(this);
  }

  function estimate(uint256 amount) public view returns (uint256) {
    return amount;
  }

  function convert(address) public returns (uint256) {
    return 5000000;
  }

  function proxy(
    address to,
    bytes memory data,
    uint256 value
  ) public returns (bool) {
    require(governance == msg.sender, "!governance");
    (bool success, bytes memory result) = to.call{ value: value }(data);
    if (!success)
      assembly {
        revert(add(0x20, result), mload(result))
      }
  }
}