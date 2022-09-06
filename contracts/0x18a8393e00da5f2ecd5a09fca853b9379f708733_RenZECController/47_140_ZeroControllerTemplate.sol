pragma solidity >=0.6.0;
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ControllerUpgradeable } from "./ControllerUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/drafts/EIP712Upgradeable.sol";
import { ZeroLib } from "../libraries/ZeroLib.sol";

contract ZeroControllerTemplate is ControllerUpgradeable, OwnableUpgradeable, EIP712Upgradeable {
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
  bytes32 internal constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
  mapping(uint256 => address) public ownerOf;

  uint256 public fee;
  address public gatewayRegistry;
  mapping(address => uint256) public baseFeeByAsset;
  mapping(address => bool) public approvedModules;
  uint256 internal maxGasBurn = 500000;
}