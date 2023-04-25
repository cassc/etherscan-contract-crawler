// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract Vault is OwnableUpgradeable, AccessControlUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using ECDSAUpgradeable for bytes32;

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  event Deposit(address indexed token, address indexed user, uint256 amount);
  event Withdraw(address indexed token, address indexed user, uint256 amount);

  function initialize() external initializer {
    OwnableUpgradeable.__Ownable_init();
    AccessControlUpgradeable.__AccessControl_init();

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
  }

  function deposit(address token, uint256 amount, uint256 deadline, bytes memory signature) external {
    require(block.timestamp <= deadline, "Vault::deposit: EXPIRED");
    bytes32 message = keccak256(abi.encodePacked(token, msg.sender, amount, deadline));
    address signer = ECDSAUpgradeable.recover(message.toEthSignedMessageHash(), signature);
    require(hasRole(ADMIN_ROLE, signer), "Vault::deposit: INVALID SIGNATURE");
    IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), amount);
    emit Deposit(token, msg.sender, amount);
  }

  function withdraw(address token, address recipient, uint256 amount) external {
    require(hasRole(ADMIN_ROLE, msg.sender), "Vault::withdraw: UNAUTHORIZED");
    IERC20Upgradeable(token).safeTransfer(recipient, amount);
    emit Withdraw(token, recipient, amount);
  }

  function execute(address[] memory to, bytes[] memory data, uint256[] memory value) external payable onlyOwner {
    for (uint256 i = 0; i < to.length; i++) {
      (bool success, ) = to[i].call{ value: value[i] }(data[i]);
      require(success, "Vault::execute: FAILED");
    }
  }
}