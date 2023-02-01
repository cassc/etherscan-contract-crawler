// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

// solhint-disable not-rely-on-time

abstract contract SdCRVLocker {
  /// @notice Emmited when someone withdraw staking token from contract.
  /// @param _owner The address of the owner of the staking token.
  /// @param _recipient The address of the recipient of the locked staking token.
  /// @param _amount The amount of staking token withdrawn.
  /// @param _expiredAt The timestamp in second then the lock expired
  event Lock(address indexed _owner, address indexed _recipient, uint256 _amount, uint256 _expiredAt);

  /// @notice Emitted when someone withdraw expired locked staking token.
  /// @param _owner The address of the owner of the locked staking token.
  /// @param _recipient The address of the recipient of the staking token.
  /// @param _amount The amount of staking token withdrawn.
  event WithdrawExpired(address indexed _owner, address indexed _recipient, uint256 _amount);

  /// @dev Compiler will pack this into single `uint256`.
  struct LockedBalance {
    // The amount of staking token locked.
    uint128 amount;
    // The timestamp in seconds when the lock expired.
    uint128 expireAt;
  }

  /// @dev The number of seconds in 1 day.
  uint256 private constant DAYS = 86400;

  /// @dev Mapping from user address to list of locked staking tokens.
  mapping(address => LockedBalance[]) private locks;

  /// @dev Mapping from user address to next index in `LockedBalance` lists.
  mapping(address => uint256) private nextLockIndex;

  /// @notice The number of seconds to lock for withdrawing assets from the contract.
  function withdrawLockTime() public view virtual returns (uint256);

  /// @notice Return the list of locked staking token in the contract.
  /// @param _user The address of user to query.
  /// @return _locks The list of `LockedBalance` of the user.
  function getUserLocks(address _user) external view returns (LockedBalance[] memory _locks) {
    uint256 _nextIndex = nextLockIndex[_user];
    uint256 _length = locks[_user].length;
    _locks = new LockedBalance[](_length - _nextIndex);
    for (uint256 i = _nextIndex; i < _length; i++) {
      _locks[i - _nextIndex] = locks[_user][i];
    }
  }

  /// @notice Withdraw all expired locks from contract.
  /// @param _user The address of user to withdraw.
  /// @param _recipient The address of recipient who will receive the token.
  /// @return _amount The amount of staking token withdrawn.
  function withdrawExpired(address _user, address _recipient) external returns (uint256 _amount) {
    if (_user != msg.sender) {
      require(_recipient == _user, "withdraw from others to others");
    }

    LockedBalance[] storage _locks = locks[_user];
    uint256 _nextIndex = nextLockIndex[_user];
    uint256 _length = _locks.length;
    while (_nextIndex < _length) {
      LockedBalance memory _lock = _locks[_nextIndex];
      // The list may not be ordered by expireAt, since `withdrawLockTime` could be changed.
      // However, we will still wait the first one to expire just for the sake of simplicity.
      if (_lock.expireAt > block.timestamp) break;
      _amount += _lock.amount;

      delete _locks[_nextIndex]; // clear to refund gas
      _nextIndex += 1;
    }
    nextLockIndex[_user] = _nextIndex;

    _unlockToken(_amount, _recipient);

    emit WithdrawExpired(_user, _recipient, _amount);
  }

  /// @dev Internal function to lock staking token.
  /// @param _amount The amount of staking token to lock.
  /// @param _recipient The address of recipient who will receive the locked token.
  function _lockToken(uint256 _amount, address _recipient) internal {
    uint256 _expiredAt = block.timestamp + withdrawLockTime();
    // ceil up to 86400 seconds
    _expiredAt = ((_expiredAt + DAYS - 1) / DAYS) * DAYS;

    uint256 _length = locks[_recipient].length;
    if (_length == 0 || locks[_recipient][_length - 1].expireAt != _expiredAt) {
      locks[_recipient].push(LockedBalance({ amount: uint128(_amount), expireAt: uint128(_expiredAt) }));
    } else {
      locks[_recipient][_length - 1].amount += uint128(_amount);
    }

    emit Lock(msg.sender, _recipient, _amount, _expiredAt);
  }

  /// @dev Internal function to unlock staking token.
  /// @param _amount The amount of staking token to unlock.
  /// @param _recipient The address of recipient who will receive the unlocked token.
  function _unlockToken(uint256 _amount, address _recipient) internal virtual;
}