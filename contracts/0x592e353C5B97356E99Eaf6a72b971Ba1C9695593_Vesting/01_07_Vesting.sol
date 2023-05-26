// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

// solhint-disable not-rely-on-time

contract Vesting is Ownable {
  using SafeERC20 for IERC20;

  /// @notice Emitted when a token vest is added.
  /// @param _recipient The address of recipient who will receive the vest.
  /// @param _index The index of the vesting list.
  /// @param _amount The amount of token to vest.
  /// @param _startTime The timestamp in second when the vest starts.
  /// @param _endTime The timestamp in second when the vest ends.
  event Vest(address indexed _recipient, uint256 indexed _index, uint256 _amount, uint256 _startTime, uint256 _endTime);

  /// @notice Emitted when a vest is cancled.
  /// @param _recipient The address of recipient who will receive the vest.
  /// @param _index The index of the vesting list.
  /// @param _unvested The amount of unvested token.
  /// @param _cancleTime The timestamp in second when the vest is cancled.
  event Cancle(address indexed _recipient, uint256 indexed _index, uint256 _unvested, uint256 _cancleTime);

  /// @notice Emitted when a user claim his vest.
  /// @param _recipient The address of recipient who will receive the token.
  /// @param _amount The amount of token claimed.
  event Claim(address indexed _recipient, uint256 _amount);

  /// @notice The address of token to vest.
  address public immutable token;

  struct VestState {
    uint128 vestingAmount;
    uint128 claimedAmount;
    uint64 startTime;
    uint64 endTime;
    uint64 cancleTime;
  }

  /// @notice Mapping from user address to vesting list.
  mapping(address => VestState[]) public vesting;

  /// @notice The list of whilelist address.
  mapping(address => bool) public isWhitelist;

  constructor(address _token) {
    require(_token != address(0), "Vesting: zero address token");

    token = _token;
  }

  /// @notice Return the vesting list for some user.
  /// @param _recipient The address of user to query.
  function getUserVest(address _recipient) external view returns (VestState[] memory) {
    return vesting[_recipient];
  }

  /// @notice Return the total amount of vested tokens.
  /// @param _recipient The address of user to query.
  function vested(address _recipient) external view returns (uint256 _vested) {
    uint256 _length = vesting[_recipient].length;
    for (uint256 i = 0; i < _length; i++) {
      _vested += _getVested(vesting[_recipient][i], block.timestamp);
    }
    return _vested;
  }

  /// @notice Return the total amount of unvested tokens.
  /// @param _recipient The address of user to query.
  function locked(address _recipient) external view returns (uint256 _unvested) {
    uint256 _length = vesting[_recipient].length;
    for (uint256 i = 0; i < _length; i++) {
      VestState memory _state = vesting[_recipient][i];
      _unvested += _state.vestingAmount - _getVested(_state, block.timestamp);
    }
  }

  /// @notice Claim pending tokens
  /// @return _claimable The amount of token will receive in this claim.
  function claim() external returns (uint256 _claimable) {
    uint256 _length = vesting[msg.sender].length;
    for (uint256 i = 0; i < _length; i++) {
      VestState memory _state = vesting[msg.sender][i];

      uint256 _vested = _getVested(_state, block.timestamp);
      vesting[msg.sender][i].claimedAmount = uint128(_vested);

      _claimable += _vested - _state.claimedAmount;
    }

    IERC20(token).safeTransfer(msg.sender, _claimable);

    emit Claim(msg.sender, _claimable);
  }

  /// @notice Add a new token vesting
  /// @param _recipient The address of user who will receive the vesting.
  /// @param _amount The amount of token to vest.
  /// @param _startTime The timestamp in second when the vest starts.
  /// @param _endTime The timestamp in second when the vest ends.
  function newVesting(
    address _recipient,
    uint128 _amount,
    uint64 _startTime,
    uint64 _endTime
  ) external {
    require(_startTime < _endTime, "Vesting: invalid timestamp");
    require(isWhitelist[msg.sender], "Vesting: caller not whitelisted");

    IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);

    uint256 _index = vesting[_recipient].length;
    vesting[_recipient].push(
      VestState({ vestingAmount: _amount, claimedAmount: 0, startTime: _startTime, endTime: _endTime, cancleTime: 0 })
    );

    emit Vest(_recipient, _index, _amount, _startTime, _endTime);
  }

  /// @notice Cancle a vest for some user. The unvested tokens will be transfered to owner.
  /// @param _user The address of the user to cancle.
  /// @param _index The index of the vest to cancle.
  function cancle(address _user, uint256 _index) external onlyOwner {
    VestState memory _state = vesting[_user][_index];
    require(_state.cancleTime == 0, "already cancled");

    uint256 _vestedAmount = _getVested(_state, block.timestamp);
    uint256 _unvested = _state.vestingAmount - _vestedAmount;
    IERC20(token).safeTransfer(msg.sender, _unvested);

    vesting[_user][_index].cancleTime = uint64(block.timestamp);

    emit Cancle(_user, _index, _unvested, block.timestamp);
  }

  /// @notice Update the whitelist status of given accounts.
  /// @param _accounts The list of accounts to update.
  /// @param _status The status to update.
  function updateWhitelist(address[] memory _accounts, bool _status) external onlyOwner {
    for (uint256 i = 0; i < _accounts.length; i++) {
      isWhitelist[_accounts[i]] = _status;
    }
  }

  /// @dev Internal function to calculate vested token amount for a single vest.
  /// @param _state The vest state.
  /// @param _claimTime The timestamp in second when someone claim vested token.
  function _getVested(VestState memory _state, uint256 _claimTime) internal pure returns (uint256) {
    // This vest is cancled before, so we take minimum between claimTime and cancleTime.
    if (_state.cancleTime != 0 && _state.cancleTime < _claimTime) {
      _claimTime = _state.cancleTime;
    }

    if (_claimTime < _state.startTime) {
      return 0;
    } else if (_claimTime >= _state.endTime) {
      return _state.vestingAmount;
    } else {
      // safe math is not needed, since all amounts are valid.
      return (uint256(_state.vestingAmount) * (_claimTime - _state.startTime)) / (_state.endTime - _state.startTime);
    }
  }
}