// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

/// @title interface to interact with TokenDelgator
interface ITokenDelegator {
  function _setImplementation(address implementation_) external;

  function _setOwner(address owner_) external;

  fallback() external payable;

  receive() external payable;
}

/// @title interface to interact with TokenDelgate
interface ITokenDelegate {
  function initialize(address account_, uint256 initialSupply_) external;

  function changeName(string calldata name_) external;

  function changeSymbol(string calldata symbol_) external;

  function allowance(address account, address spender) external view returns (uint256);

  function approve(address spender, uint256 rawAmount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address dst, uint256 rawAmount) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 rawAmount
  ) external returns (bool);

  //function mint(address dst, uint256 rawAmount) external;

  function permit(
    address owner,
    address spender,
    uint256 rawAmount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function delegate(address delegatee) external;

  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function getCurrentVotes(address account) external view returns (uint96);

  function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);
}

/// @title interface which contains all events emitted by delegator & delegate
interface TokenEvents {
  /// @notice An event thats emitted when an account changes its delegate
  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

  /// @notice An event thats emitted when a delegate account's vote balance changes
  event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

  /// @notice An event thats emitted when the minter changes
  event MinterChanged(address indexed oldMinter, address indexed newMinter);

  /// @notice The standard EIP-20 transfer event
  event Transfer(address indexed from, address indexed to, uint256 amount);

  /// @notice The standard EIP-20 approval event
  event Approval(address indexed owner, address indexed spender, uint256 amount);

  /// @notice Emitted when implementation is changed
  event NewImplementation(address oldImplementation, address newImplementation);

  /// @notice An event thats emitted when the token symbol is changed
  event ChangedSymbol(string oldSybmol, string newSybmol);

  /// @notice An event thats emitted when the token name is changed
  event ChangedName(string oldName, string newName);
}