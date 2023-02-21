// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IThinWallet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ThinWallet is IThinWallet, Initializable, AccessControl {
  using SafeERC20 for IERC20;

  // Access Control Role Definitions
  bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER");
  bytes32 public constant TRANSFER_ADMIN_ROLE = keccak256("TRANSFER_ADMIN");

  // Store admin address
  address public admin;

  /// ### Functions
  function initialize(address _admin, address[] calldata _owners)
    external
    initializer
  {
    require(_admin != address(0), "admin address cannot be 0x0");
    admin = _admin;
    _setupRole(TRANSFER_ADMIN_ROLE, _admin);
    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    for (uint64 i = 0; i < _owners.length; i++) {
      require(_owners[i] != address(0), "owner cannot be 0x0");
      _setupRole(TRANSFER_ROLE, _owners[i]);
      _setupRole(TRANSFER_ADMIN_ROLE, _owners[i]);
    }
  }

  function transferERC20(TokenMovement[] calldata _transfers) external {
    if (!(hasRole(TRANSFER_ROLE, msg.sender) || msg.sender == admin)) {
      revert InvalidPermissions(msg.sender);
    }

    emit TransferERC20(_transfers);

    for (uint64 i = 0; i < _transfers.length; i++) {
      IERC20 token = IERC20(_transfers[i].token);
      token.safeTransfer(_transfers[i].recipient, _transfers[i].amount);
    }
  }

  function transferEther(EtherPaymentTransfer[] calldata _transfers) external {
    if (!(hasRole(TRANSFER_ROLE, msg.sender) || msg.sender == admin)) {
      revert InvalidPermissions(msg.sender);
    }
    emit TransferEther(_transfers);
    for (uint64 i = 0; i < _transfers.length; i++) {
      (bool success, ) = address(_transfers[i].recipient).call{
        value: _transfers[i].amount
      }("");
      require(success, "failed to send ether");
    }
  }

  function emergencyEjectERC20(address _token, address _destination)
    external
    override
  {
    if (!(hasRole(TRANSFER_ROLE, msg.sender) || msg.sender == admin)) {
      revert InvalidPermissions(msg.sender);
    }
    if (_token == address(0)) {
      revert InvalidAddress();
    }
    if (_destination == address(0)) {
      revert InvalidAddress();
    }
    IERC20 token = IERC20(_token);
    token.safeTransfer(_destination, token.balanceOf(address(this)));
  }

  function emergencyEjectEth(address _destination) external override {
    if (!(hasRole(TRANSFER_ROLE, msg.sender) || msg.sender == admin)) {
      revert InvalidPermissions(msg.sender);
    }
    if (_destination == address(0)) {
      revert InvalidAddress();
    }
    (bool success, ) = _destination.call{value: address(this).balance}("");
    require(success, "failed to send ether");
  }

  receive() external payable {}
}