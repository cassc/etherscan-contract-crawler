// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IStakeDAOVault {
  /// @notice Emitted when user deposit staking token to the contract.
  /// @param _owner The address of the owner of the staking token.
  /// @param _recipient The address of the recipient of the staking token.
  /// @param _amount The amount of staking token deposited.
  event Deposit(address indexed _owner, address indexed _recipient, uint256 _amount);

  /// @notice Emitted when user withdraw staking token from the contract.
  /// @param _owner The address of the owner of the staking token.
  /// @param _recipient The address of the recipient of the staking token.
  /// @param _amount The amount of staking token withdrawn.
  /// @param _fee The amount of withdraw fee.
  event Withdraw(address indexed _owner, address indexed _recipient, uint256 _amount, uint256 _fee);

  /// @notice Emitted when user claim pending rewards from the contract.
  /// @param _owner The address of the owner of the staking token.
  /// @param _recipient The address of the recipient of the pending rewards.
  /// @param _amounts The list of pending reward amounts.
  event Claim(address indexed _owner, address indexed _recipient, uint256[] _amounts);

  /// @notice Emitted when someone harvest pending rewards.
  /// @param _caller The address of the caller.
  /// @param _rewards The list of harvested rewards.
  /// @param _bounties The list of harvest bounty given to caller.
  /// @param _platformFees The list of platform fee taken.
  /// @param _boostFee The amount SDT for veSDT boost delegation fee.
  event Harvest(
    address indexed _caller,
    uint256[] _rewards,
    uint256[] _bounties,
    uint256[] _platformFees,
    uint256 _boostFee
  );

  /// @notice Return the amount of staking token staked in the contract.
  function totalSupply() external view returns (uint256);

  /// @notice Return the amount of staking token staked in the contract for some user.
  /// @param _user The address of user to query.
  function balanceOf(address _user) external view returns (uint256);

  /// @notice Deposit some staking token to the contract.
  /// @dev use `_amount=-1` to deposit all tokens.
  /// @param _amount The amount of staking token to deposit.
  /// @param _recipient The address of recipient who will receive the deposited staking token.
  function deposit(uint256 _amount, address _recipient) external;

  /// @notice Withdraw some staking token from the contract.
  /// @dev use `_amount=-1` to withdraw all tokens.
  /// @param _amount The amount of staking token to withdraw.
  /// @param _recipient The address of recipient who will receive the withdrawn staking token.
  function withdraw(uint256 _amount, address _recipient) external;

  /// @notice Claim all pending rewards from some user.
  /// @param _user The address of user to claim.
  /// @param _recipient The address of recipient who will receive the rewards.
  /// @return _amounts The list of amount of rewards claimed.
  function claim(address _user, address _recipient) external returns (uint256[] memory _amounts);

  /// @notice Harvest pending reward from the contract.
  /// @param _recipient The address of recipient who will receive the harvest bounty.
  function harvest(address _recipient) external;

  /// @notice Update the user information.
  /// @param _user The address of user to update.
  function checkpoint(address _user) external;
}