// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Multicall.sol';
import '../interfaces/IDCAFeeManager.sol';

contract DCAFeeManager is RunSwap, AccessControl, Multicall, IDCAFeeManager {
  bytes32 public constant SUPER_ADMIN_ROLE = keccak256('SUPER_ADMIN_ROLE');
  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

  using SafeERC20 for IERC20;
  using Address for address payable;

  /// @inheritdoc IDCAFeeManager
  uint16 public constant MAX_TOKEN_TOTAL_SHARE = 10000;
  /// @inheritdoc IDCAFeeManager
  uint32 public constant SWAP_INTERVAL = 1 days;
  /// @inheritdoc IDCAFeeManager
  mapping(bytes32 => uint256) public positions; // key(from, to) => position id

  mapping(address => uint256[]) internal _positionsWithToken; // token address => all positions with address as to

  constructor(
    address _swapperRegistry,
    address _superAdmin,
    address[] memory _initialAdmins
  ) SwapAdapter(_swapperRegistry) {
    if (_superAdmin == address(0)) revert ZeroAddress();
    // We are setting the super admin role as its own admin so we can transfer it
    _setRoleAdmin(SUPER_ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setRoleAdmin(ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setupRole(SUPER_ADMIN_ROLE, _superAdmin);
    for (uint256 i; i < _initialAdmins.length; i++) {
      _setupRole(ADMIN_ROLE, _initialAdmins[i]);
    }
  }

  /// @inheritdoc IDCAFeeManager
  function runSwap(RunSwapParams calldata _parameters) public payable override(IDCAFeeManager, RunSwap) onlyRole(ADMIN_ROLE) {
    super.runSwap(_parameters);
  }

  /// @inheritdoc IDCAFeeManager
  function withdrawFromPlatformBalance(
    IDCAHub _hub,
    IDCAHub.AmountOfToken[] calldata _amountToWithdraw,
    address _recipient
  ) external onlyRole(ADMIN_ROLE) {
    _hub.withdrawFromPlatformBalance(_amountToWithdraw, _recipient);
  }

  /// @inheritdoc IDCAFeeManager
  function withdrawFromBalance(IDCAHub.AmountOfToken[] calldata _amountToWithdraw, address _recipient) external onlyRole(ADMIN_ROLE) {
    for (uint256 i = 0; i < _amountToWithdraw.length; ) {
      IDCAHub.AmountOfToken memory _amountOfToken = _amountToWithdraw[i];
      _sendToRecipient(_amountOfToken.token, _amountOfToken.amount, _recipient);
      unchecked {
        i++;
      }
    }
  }

  /// @inheritdoc IDCAFeeManager
  function withdrawFromPositions(
    IDCAHub _hub,
    IDCAHub.PositionSet[] calldata _positionSets,
    address _recipient
  ) external onlyRole(ADMIN_ROLE) {
    _hub.withdrawSwappedMany(_positionSets, _recipient);
  }

  /// @inheritdoc IDCAFeeManager
  function fillPositions(
    IDCAHub _hub,
    AmountToFill[] calldata _amounts,
    TargetTokenShare[] calldata _distribution
  ) external onlyRole(ADMIN_ROLE) {
    for (uint256 i = 0; i < _amounts.length; ) {
      AmountToFill memory _amount = _amounts[i];

      _maxApproveSpenderIfNeeded(
        IERC20(_amount.token),
        address(_hub),
        true, // No need to check if the hub is a valid allowance target
        _amount.amount
      );

      // Distribute to different tokens
      uint256 _amountSpent;
      for (uint256 j = 0; j < _distribution.length; ) {
        uint256 _amountToDeposit = j < _distribution.length - 1
          ? (_amount.amount * _distribution[j].shares) / MAX_TOKEN_TOTAL_SHARE
          : _amount.amount - _amountSpent; // If this is the last token, then assign everything that hasn't been spent. We do this to prevent unspent tokens due to rounding errors

        bool _failed = _depositToHub(_hub, _amount.token, _distribution[j].token, _amountToDeposit, _amount.amountOfSwaps);
        if (!_failed) {
          _amountSpent += _amountToDeposit;
        }
        unchecked {
          j++;
        }
      }
      unchecked {
        i++;
      }
    }
  }

  /// @inheritdoc IDCAFeeManager
  function terminatePositions(
    IDCAHub _hub,
    uint256[] calldata _positionIds,
    address _recipient
  ) external onlyRole(ADMIN_ROLE) {
    for (uint256 i = 0; i < _positionIds.length; ) {
      uint256 _positionId = _positionIds[i];
      IDCAHubPositionHandler.UserPosition memory _position = _hub.userPosition(_positionId);
      _hub.terminate(_positionId, _recipient, _recipient);
      delete positions[getPositionKey(address(_position.from), address(_position.to))];
      unchecked {
        i++;
      }
    }
  }

  /// @inheritdoc IDCAFeeManager
  function revokeAllowances(RevokeAction[] calldata _revokeActions) external onlyRole(ADMIN_ROLE) {
    _revokeAllowances(_revokeActions);
  }

  /// @inheritdoc IDCAFeeManager
  function availableBalances(IDCAHub _hub, address[] calldata _tokens) external view returns (AvailableBalance[] memory _balances) {
    _balances = new AvailableBalance[](_tokens.length);
    for (uint256 i = 0; i < _tokens.length; i++) {
      address _token = _tokens[i];
      uint256[] memory _positionIds = _positionsWithToken[_token];
      PositionBalance[] memory _positions = new PositionBalance[](_positionIds.length);
      for (uint256 j = 0; j < _positionIds.length; j++) {
        IDCAHubPositionHandler.UserPosition memory _userPosition = _hub.userPosition(_positionIds[j]);
        _positions[j] = PositionBalance({
          positionId: _positionIds[j],
          from: _userPosition.from,
          to: _userPosition.to,
          swapped: _userPosition.swapped,
          remaining: _userPosition.remaining
        });
      }
      _balances[i] = AvailableBalance({
        token: _token,
        platformBalance: _hub.platformBalance(_token),
        feeManagerBalance: IERC20(_token).balanceOf(address(this)),
        positions: _positions
      });
    }
  }

  function getPositionKey(address _from, address _to) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_from, _to));
  }

  function _depositToHub(
    IDCAHub _hub,
    address _from,
    address _to,
    uint256 _amount,
    uint32 _amountOfSwaps
  ) internal returns (bool _failed) {
    // We will try to create or increase an existing position, but both could fail. Maybe one of the tokens is no longer
    // allowed, or a pair not supported, so we need to check if it fails or not and act accordingly

    // Find the position for this token
    bytes32 _key = getPositionKey(_from, _to);
    uint256 _positionId = positions[_key];

    if (_positionId == 0) {
      // If position doesn't exist, then try to create it
      try _hub.deposit(_from, _to, _amount, _amountOfSwaps, SWAP_INTERVAL, address(this), new IDCAPermissionManager.PermissionSet[](0)) returns (
        uint256 _newPositionId
      ) {
        positions[_key] = _newPositionId;
        _positionsWithToken[_to].push(_newPositionId);
      } catch {
        _failed = true;
      }
    } else {
      // If position exists, then try to increase it
      try _hub.increasePosition(_positionId, _amount, _amountOfSwaps) {} catch {
        _failed = true;
      }
    }
  }
}