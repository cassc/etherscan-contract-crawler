// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '../interfaces/ISwapperRegistry.sol';

contract SwapperRegistry is AccessControl, ISwapperRegistry {
  enum Role {
    NONE,
    SWAPPER,
    SUPPLEMENTARY_ALLOWANCE_TARGET
  }

  bytes32 public constant SUPER_ADMIN_ROLE = keccak256('SUPER_ADMIN_ROLE');
  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

  mapping(address => Role) internal _accountRole;

  constructor(
    address[] memory _initialSwappersAllowlisted,
    address[] memory _initialSupplementaryAllowanceTargets,
    address _superAdmin,
    address[] memory _initialAdmins
  ) {
    if (_superAdmin == address(0)) revert ZeroAddress();
    // We are setting the super admin role as its own admin so we can transfer it
    _setRoleAdmin(SUPER_ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setRoleAdmin(ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setupRole(SUPER_ADMIN_ROLE, _superAdmin);
    for (uint256 i = 0; i < _initialAdmins.length; ) {
      _setupRole(ADMIN_ROLE, _initialAdmins[i]);
      unchecked {
        i++;
      }
    }

    if (_initialSupplementaryAllowanceTargets.length > 0) {
      for (uint256 i = 0; i < _initialSupplementaryAllowanceTargets.length; ) {
        _accountRole[_initialSupplementaryAllowanceTargets[i]] = Role.SUPPLEMENTARY_ALLOWANCE_TARGET;
        unchecked {
          i++;
        }
      }
      emit AllowedSupplementaryAllowanceTargets(_initialSupplementaryAllowanceTargets);
    }

    if (_initialSwappersAllowlisted.length > 0) {
      for (uint256 i = 0; i < _initialSwappersAllowlisted.length; ) {
        _accountRole[_initialSwappersAllowlisted[i]] = Role.SWAPPER;
        unchecked {
          i++;
        }
      }
      emit AllowedSwappers(_initialSwappersAllowlisted);
    }
  }

  /// @inheritdoc ISwapperRegistry
  function isSwapperAllowlisted(address _account) public view returns (bool) {
    return _accountRole[_account] == Role.SWAPPER;
  }

  /// @inheritdoc ISwapperRegistry
  function isValidAllowanceTarget(address _account) public view returns (bool) {
    return _accountRole[_account] != Role.NONE;
  }

  /// @inheritdoc ISwapperRegistry
  function allowSwappers(address[] calldata _swappers) external onlyRole(ADMIN_ROLE) {
    for (uint256 i = 0; i < _swappers.length; ) {
      address _swapper = _swappers[i];
      _assertAccountHasNoRole(_swapper);
      _accountRole[_swapper] = Role.SWAPPER;
      unchecked {
        i++;
      }
    }
    emit AllowedSwappers(_swappers);
  }

  /// @inheritdoc ISwapperRegistry
  function removeSwappersFromAllowlist(address[] calldata _swappers) external onlyRole(ADMIN_ROLE) {
    for (uint256 i = 0; i < _swappers.length; ) {
      address _swapper = _swappers[i];
      if (!isSwapperAllowlisted(_swapper)) revert AccountIsNotSwapper(_swapper);
      _accountRole[_swapper] = Role.NONE;
      unchecked {
        i++;
      }
    }
    emit RemoveSwappersFromAllowlist(_swappers);
  }

  /// @inheritdoc ISwapperRegistry
  function allowSupplementaryAllowanceTargets(address[] calldata _allowanceTargets) external onlyRole(ADMIN_ROLE) {
    for (uint256 i = 0; i < _allowanceTargets.length; ) {
      address _allowanceTarget = _allowanceTargets[i];
      _assertAccountHasNoRole(_allowanceTarget);
      _accountRole[_allowanceTarget] = Role.SUPPLEMENTARY_ALLOWANCE_TARGET;
      unchecked {
        i++;
      }
    }
    emit AllowedSupplementaryAllowanceTargets(_allowanceTargets);
  }

  /// @inheritdoc ISwapperRegistry
  function removeSupplementaryAllowanceTargetsFromAllowlist(address[] calldata _allowanceTargets) external onlyRole(ADMIN_ROLE) {
    for (uint256 i = 0; i < _allowanceTargets.length; ) {
      address _allowanceTarget = _allowanceTargets[i];
      if (!isValidAllowanceTarget(_allowanceTarget)) revert AccountIsNotSupplementaryAllowanceTarget(_allowanceTarget);
      _accountRole[_allowanceTarget] = Role.NONE;
      unchecked {
        i++;
      }
    }
    emit RemovedAllowanceTargetsFromAllowlist(_allowanceTargets);
  }

  function _assertAccountHasNoRole(address _account) internal view {
    if (_accountRole[_account] != Role.NONE) revert AccountAlreadyHasRole(_account);
  }
}