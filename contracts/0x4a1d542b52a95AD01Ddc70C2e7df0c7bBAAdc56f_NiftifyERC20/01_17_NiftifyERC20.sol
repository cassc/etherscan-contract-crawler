// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/// @title Niftify ERC20 Token
/// @author Niftify
contract NiftifyERC20 is ERC20Pausable, ERC20Permit, AccessControl {
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  /**
   * @dev Contract constructor.
   * @param name token name
   * @param symbol token symbol
   * @param initialBalance starting token fund balance
   * @param owner address of the Smart Contract owner
   */
  constructor(
    string memory name,
    string memory symbol,
    uint256 initialBalance,
    address owner
  ) ERC20(name, symbol) ERC20Permit(name) {
    _mint(owner, initialBalance);
    _setupRole(DEFAULT_ADMIN_ROLE, owner);
    _setupRole(OPERATOR_ROLE, owner);
  }

  /**
   * @dev Function for pausing the Smart Contract (any transactions made during the pause period get reverted).
   */
  function pause() external onlyOperator {
    _pause();
  }

  /**
   * @dev Function for unpausing the Smart Contract.
   */
  function unpause() external onlyOperator {
    _unpause();
  }

  /**
   * @dev Function for approving incoming token transfer and initiating the transfer.
   * @param recipient address of the recipient of the transferred funds
   * @param owner address of the owner that is transferring the funds
   * @param value the amount of tokens that are being transferred
   * @param deadline time until the permit expires
   * @param signature the signature of the transaction, which contains the transfer permit
   */
  function transferWithPermit(
    address recipient,
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    bytes memory signature
  ) external {
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    ERC20Permit.permit(owner, spender, value, deadline, v, r, s);

    transferFrom(owner, recipient, value);
  }

  /**
   * @dev Function for overriding the ERC20Pausable function
   * @param from the address from which tokens get transferred
   * @param to the address that the tokens will be transferred to
   * @param amount the amount of tokens that are being transferred
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20Pausable, ERC20) {
    ERC20Pausable._beforeTokenTransfer(from, to, amount);
  }

  /**
   * @dev Modifier to make a function callable only by OPERATOR_ROLE.
   */
  modifier onlyOperator() {
    require(hasRole(OPERATOR_ROLE, msg.sender), "Caller is not operator");
    _;
  }
}