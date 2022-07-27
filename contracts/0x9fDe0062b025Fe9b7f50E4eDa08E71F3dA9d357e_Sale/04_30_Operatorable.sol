// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Error.sol";

contract Operatorable is AccessControl, Ownable {
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  event LogOperatorAdded(address indexed account);

  event LogOperatorRemoved(address indexed account);

  /**
    * @dev Restricted to members of the `operator` role.
    */
  modifier onlyOperator() {
    if (!hasRole(OPERATOR_ROLE, msg.sender)) revert NoOperatorRole();

    _;
  }

  /**
   * @dev Contract owner is operator
   */
  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(OPERATOR_ROLE, msg.sender);
  }

  /**
   * @dev Add a new operator
   *
   * Requirements:
   * - Only contract owner can call
   * @param _account new operator address; must not be zero address
   */
  function addOperator(address _account) external onlyOwner {
    if (_account == address(0)) revert InvalidAddress();

    super._grantRole(OPERATOR_ROLE, _account);
    emit LogOperatorAdded(_account);
  }

  /**
    * @dev Remove operator
    *
    * Requirements:
    * - Only contract owner can call
    * @param _account removing operator address
    */
  function removeOperator(address _account) external onlyOwner {
    super._revokeRole(OPERATOR_ROLE, _account);
    emit LogOperatorRemoved(_account);
  }

  /**
    * @dev Check operator role ownership
    * @param _account checking account
    */
  function isOperator(address _account) external view returns (bool) {
    return super.hasRole(OPERATOR_ROLE, _account);
  }

  /**
   * @dev Override {Ownable-transferOwnership}
   * Super method has `onlyOwner` modifier
   * Revoke default admin role and operator role from old owner and grant to new owner
   * @param _newOwner new owner address; must not be zero address
   */
  function transferOwnership(address _newOwner) public virtual override {
    address oldOwner = owner();
    super._revokeRole(DEFAULT_ADMIN_ROLE, oldOwner);
    super._revokeRole(OPERATOR_ROLE, oldOwner);
    super._grantRole(DEFAULT_ADMIN_ROLE, _newOwner);
    super._grantRole(OPERATOR_ROLE, _newOwner);
    super.transferOwnership(_newOwner);
  }
}