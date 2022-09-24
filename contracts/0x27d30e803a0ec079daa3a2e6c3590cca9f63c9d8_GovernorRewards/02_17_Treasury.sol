// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title Treasury
 * @author Railgun Contributors
 * @notice Stores treasury funds for Railgun
 */
contract Treasury is Initializable, AccessControlUpgradeable {
  using SafeERC20 for IERC20;

  bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

  /**
   * @notice Sets initial admin
   * @param _admin - initial admin
   */
  function initializeTreasury(
    address _admin
  ) external initializer {
    // Call initializers
    AccessControlUpgradeable.__AccessControl_init();

    // Set owner
    AccessControlUpgradeable._grantRole(DEFAULT_ADMIN_ROLE, _admin);

    // Give owner the transfer role
    AccessControlUpgradeable._grantRole(TRANSFER_ROLE, _admin);
  }

  /**
   * @notice Transfers ETH to specified address
   * @param _to - Address to transfer ETH to
   * @param _amount - Amount of ETH to transfer
   */
  function transferETH(address payable _to, uint256 _amount) external onlyRole(TRANSFER_ROLE) {
    require(_to != address(0), "Treasury: Preventing accidental burn");
    //solhint-disable-next-line avoid-low-level-calls
    (bool sent,) = _to.call{value: _amount}("");
    require(sent, "Failed to send Ether");
  }

  /**
   * @notice Transfers ERC20 to specified address
   * @param _token - ERC20 token address to transfer
   * @param _to - Address to transfer tokens to
   * @param _amount - Amount of tokens to transfer
   */
  function transferERC20(IERC20 _token, address _to, uint256 _amount) external onlyRole(TRANSFER_ROLE) {
    require(_to != address(0), "Treasury: Preventing accidental burn");
    _token.safeTransfer(_to, _amount);
  }

  /**
   * @notice Recieve ETH
   */
  // solhint-disable-next-line no-empty-blocks
  fallback() external payable {}

  /**
   * @notice Receive ETH
   */
  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}
}