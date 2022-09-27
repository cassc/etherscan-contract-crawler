// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '../interfaces/IDCAHubCompanion.sol';

/// @dev All public functions are payable, so that they can be multicalled together with other payable functions when msg.value > 0
abstract contract DCAHubCompanionHubProxyHandler is IDCAHubCompanionHubProxyHandler {
  /// @inheritdoc IDCAHubCompanionHubProxyHandler
  function permissionPermit(
    IDCAPermissionManager _permissionManager,
    IDCAPermissionManager.PermissionSet[] calldata _permissions,
    uint256 _tokenId,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external payable {
    _permissionManager.permissionPermit(_permissions, _tokenId, _deadline, _v, _r, _s);
  }

  /// @inheritdoc IDCAHubCompanionHubProxyHandler
  function deposit(
    IDCAHub _hub,
    address _from,
    address _to,
    uint256 _amount,
    uint32 _amountOfSwaps,
    uint32 _swapInterval,
    address _owner,
    IDCAPermissionManager.PermissionSet[] calldata _permissions,
    bytes calldata _miscellaneous
  ) public payable virtual returns (uint256 _positionId) {
    _approveHub(address(_from), _hub, _amount);
    _positionId = _miscellaneous.length > 0
      ? _hub.deposit(_from, _to, _amount, _amountOfSwaps, _swapInterval, _owner, _permissions, _miscellaneous)
      : _hub.deposit(_from, _to, _amount, _amountOfSwaps, _swapInterval, _owner, _permissions);
  }

  /// @inheritdoc IDCAHubCompanionHubProxyHandler
  function depositWithBalanceOnContract(
    IDCAHub _hub,
    address _from,
    address _to,
    uint32 _amountOfSwaps,
    uint32 _swapInterval,
    address _owner,
    IDCAPermissionManager.PermissionSet[] calldata _permissions,
    bytes calldata _miscellaneous
  ) external payable returns (uint256 _positionId) {
    uint256 _amount = IERC20(_from).balanceOf(address(this));
    return deposit(_hub, _from, _to, _amount, _amountOfSwaps, _swapInterval, _owner, _permissions, _miscellaneous);
  }

  /// @inheritdoc IDCAHubCompanionHubProxyHandler
  function withdrawSwapped(
    IDCAHub _hub,
    uint256 _positionId,
    address _recipient
  ) external payable verifyPermission(_hub, _positionId, IDCAPermissionManager.Permission.WITHDRAW) returns (uint256 _swapped) {
    _swapped = _hub.withdrawSwapped(_positionId, _recipient);
  }

  /// @inheritdoc IDCAHubCompanionHubProxyHandler
  function withdrawSwappedMany(
    IDCAHub _hub,
    IDCAHub.PositionSet[] calldata _positions,
    address _recipient
  ) external payable returns (uint256[] memory _withdrawn) {
    for (uint256 i = 0; i < _positions.length; ) {
      uint256[] memory _positionIds = _positions[i].positionIds;
      for (uint256 j = 0; j < _positionIds.length; ) {
        _checkPermissionOrFail(_hub, _positionIds[j], IDCAPermissionManager.Permission.WITHDRAW);
        unchecked {
          j++;
        }
      }
      unchecked {
        i++;
      }
    }
    _withdrawn = _hub.withdrawSwappedMany(_positions, _recipient);
  }

  /// @inheritdoc IDCAHubCompanionHubProxyHandler
  function increasePosition(
    IDCAHub _hub,
    uint256 _positionId,
    uint256 _amount,
    uint32 _newSwaps
  ) external payable verifyPermission(_hub, _positionId, IDCAPermissionManager.Permission.INCREASE) {
    IERC20Metadata _from = _hub.userPosition(_positionId).from;
    _approveHub(address(_from), _hub, _amount);
    _hub.increasePosition(_positionId, _amount, _newSwaps);
  }

  /// @inheritdoc IDCAHubCompanionHubProxyHandler
  function increasePositionWithBalanceOnContract(
    IDCAHub _hub,
    uint256 _positionId,
    uint32 _newSwaps
  ) external payable verifyPermission(_hub, _positionId, IDCAPermissionManager.Permission.INCREASE) {
    IERC20Metadata _from = _hub.userPosition(_positionId).from;
    uint256 _amount = _from.balanceOf(address(this));
    _approveHub(address(_from), _hub, _amount);
    _hub.increasePosition(_positionId, _amount, _newSwaps);
  }

  /// @inheritdoc IDCAHubCompanionHubProxyHandler
  function reducePosition(
    IDCAHub _hub,
    uint256 _positionId,
    uint256 _amount,
    uint32 _newSwaps,
    address _recipient
  ) external payable verifyPermission(_hub, _positionId, IDCAPermissionManager.Permission.REDUCE) {
    _hub.reducePosition(_positionId, _amount, _newSwaps, _recipient);
  }

  /// @inheritdoc IDCAHubCompanionHubProxyHandler
  function terminate(
    IDCAHub _hub,
    uint256 _positionId,
    address _recipientUnswapped,
    address _recipientSwapped
  )
    external
    payable
    verifyPermission(_hub, _positionId, IDCAPermissionManager.Permission.TERMINATE)
    returns (uint256 _unswapped, uint256 _swapped)
  {
    (_unswapped, _swapped) = _hub.terminate(_positionId, _recipientUnswapped, _recipientSwapped);
  }

  function _approveHub(
    address _token,
    IDCAHub _hub,
    uint256 _amount
  ) internal {
    uint256 _allowance = IERC20(_token).allowance(address(this), address(_hub));
    if (_allowance < _amount) {
      if (_allowance > 0) {
        IERC20(_token).approve(address(_hub), 0); // We do this because some tokens (like USDT) fail if we don't
      }
      IERC20(_token).approve(address(_hub), type(uint256).max);
    }
  }

  function _checkPermissionOrFail(
    IDCAHub _hub,
    uint256 _positionId,
    IDCAPermissionManager.Permission _permission
  ) internal view {
    if (!_hub.permissionManager().hasPermission(_positionId, msg.sender, _permission)) revert UnauthorizedCaller();
  }

  modifier verifyPermission(
    IDCAHub _hub,
    uint256 _positionId,
    IDCAPermissionManager.Permission _permission
  ) {
    _checkPermissionOrFail(_hub, _positionId, _permission);
    _;
  }
}