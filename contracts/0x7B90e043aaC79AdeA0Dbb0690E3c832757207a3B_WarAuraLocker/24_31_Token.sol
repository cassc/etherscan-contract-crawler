//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝

pragma solidity 0.8.16;
//SPDX-License-Identifier: BUSL-1.1

import {ERC20} from "solmate/tokens/ERC20.sol";
import {AccessControl} from "openzeppelin/access/AccessControl.sol";
import {Errors} from "utils/Errors.sol";

/**
 * @title Warlord Token contract
 * @author Paladin
 * @notice ERC20 token minted by deposit in Warlord
 */
contract WarToken is ERC20, AccessControl {
  /**
   * @notice Event emitted when a new pending owner is set
   */
  event NewPendingOwner(address indexed previousPendingOwner, address indexed newPendingOwner);

  /**
   * @notice Address of the current pending owner
   */
  address public pendingOwner;
  /**
   * @notice Address of the current owner
   */
  address public owner;
  /**
   * @notice Minter role
   */
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  /**
   * @notice Burner role
   */
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  // Constructor

  constructor() ERC20("Warlord token", "WAR", 18) {
    owner = msg.sender;
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, keccak256("NO_ROLE"));
  }

  /**
   * @notice Set the given address as the new pending owner
   * @param newOwner Address to set as pending owner
   */
  function transferOwnership(address newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (newOwner == address(0)) revert Errors.ZeroAddress();
    if (newOwner == owner) revert Errors.CannotBeOwner();

    address oldPendingOwner = pendingOwner;

    pendingOwner = newOwner;

    emit NewPendingOwner(oldPendingOwner, newOwner);
  }

  /**
   * @notice Accept the ownership transfer (only callable by the current pending owner)
   */
  function acceptOwnership() external {
    if (msg.sender != pendingOwner) revert Errors.CallerNotPendingOwner();
    address newOwner = pendingOwner;

    // Revoke the previous owner ADMIN role and set it for the new owner
    _revokeRole(DEFAULT_ADMIN_ROLE, owner);
    _grantRole(DEFAULT_ADMIN_ROLE, newOwner);

    owner = newOwner;
    // Reset the pending owner
    pendingOwner = address(0);

    emit NewPendingOwner(newOwner, address(0));
  }

  /**
   * @notice Mints the given amount of tokens to the given address
   * @param to Address to mint token to
   * @param amount Amount of token to mint
   */
  function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
    _mint(to, amount);
  }

  /**
   * @notice Burns the given amount of tokens from the given address
   * @param from Address to burn token from
   * @param amount Amount of token to burn
   */
  function burn(address from, uint256 amount) external onlyRole(BURNER_ROLE) {
    _burn(from, amount);
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   * @param spender The address of the spender
   * @param addedValue Amount of token to increase the allowance
   */
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
    uint256 newAllowance = allowance[msg.sender][spender] + addedValue;

    allowance[msg.sender][spender] = newAllowance;

    emit Approval(msg.sender, spender, newAllowance);

    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   * @param spender The address of the spender
   * @param subtractedValue Amount of token to increase the allowance
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
    uint256 currentAllowance = allowance[msg.sender][spender];
    if (subtractedValue > currentAllowance) revert Errors.AllowanceUnderflow();

    uint256 newAllowance = currentAllowance - subtractedValue;

    allowance[msg.sender][spender] = newAllowance;

    emit Approval(msg.sender, spender, newAllowance);

    return true;
  }
}