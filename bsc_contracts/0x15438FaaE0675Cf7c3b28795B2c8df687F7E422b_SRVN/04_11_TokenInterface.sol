// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

import "./TokenStorage.sol";
import "./GovernanceStorage.sol";

contract TokenInterface is TokenStorage, GovernanceStorage {
  /// @notice An event thats emitted when an account changes its delegate
  event DelegateChanged(
    address indexed delegator,
    address indexed fromDelegate,
    address indexed toDelegate
  );

  /// @notice An event thats emitted when a delegate account's vote balance changes
  event DelegateVotesChanged(
    address indexed delegate,
    uint256 previousBalance,
    uint256 newBalance
  );

  /*** Gov Events ***/

  /**
   * @notice Event emitted when pendingGov is changed
   */
  event NewPendingGov(address oldPendingGov, address newPendingGov);

  /**
   * @notice Event emitted when gov is changed
   */
  event NewGov(address oldGov, address newGov);

  /**
   * @notice Event emitted when Emssion is changed
   */
  event NewEmission(address oldEmission, address newEmission);

  /**
   * @notice Event emitted when Guardian is changed
   */
  event NewGuardian(address oldGuardian, address newGuardian);

  /**
   * @notice Event emitted when the pause is triggered.
   */
  event Paused(address account);

  /**
   * @dev Event emitted when the pause is lifted.
   */
  event Unpaused(address account);

  /* - ERC20 Events - */

  /**
   * @notice EIP20 Transfer event
   */
  event Transfer(address indexed from, address indexed to, uint256 amount);

  /**
   * @notice EIP20 Approval event
   */
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 amount
  );

  /* - Extra Events - */
  /**
   * @notice Tokens minted event
   */
  event Mint(address to, uint256 amount);
  event Burn(address from, uint256 amount);

  // Public functions
  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner_, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function increaseAllowance(address spender, uint256 addedValue)
    external
    returns (bool);

  function decreaseAllowance(address spender, uint256 subtractedValue)
    external
    returns (bool);

  /* - Governance Functions - */
  function getPriorVotes(address account, uint256 blockNumber)
    external
    view
    returns (uint256);

  //    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;
  function delegate(address delegatee) external;

  function delegates(address delegator) external view returns (address);

  function getCurrentVotes(address account) external view returns (uint256);

  /* - Permissioned/Governance functions - */
  function _setPendingGov(address pendingGov_) external;

  function _acceptGov() external;
}