// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '../Keep3rAccountance.sol';
import '../Keep3rParameters.sol';
import '../../../interfaces/peripherals/IKeep3rKeepers.sol';

import '../../../interfaces/external/IKeep3rV1.sol';
import '../../../interfaces/external/IKeep3rV1Proxy.sol';

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

abstract contract Keep3rKeeperFundable is IKeep3rKeeperFundable, ReentrancyGuard, Keep3rParameters {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  /// @inheritdoc IKeep3rKeeperFundable
  function bond(address _bonding, uint256 _amount) external override nonReentrant {
    if (disputes[msg.sender]) revert Disputed();
    if (_jobs.contains(msg.sender)) revert AlreadyAJob();
    canActivateAfter[msg.sender][_bonding] = block.timestamp + bondTime;

    uint256 _before = IERC20(_bonding).balanceOf(address(this));
    IERC20(_bonding).safeTransferFrom(msg.sender, address(this), _amount);
    _amount = IERC20(_bonding).balanceOf(address(this)) - _before;

    hasBonded[msg.sender] = true;
    pendingBonds[msg.sender][_bonding] += _amount;

    emit Bonding(msg.sender, _bonding, _amount);
  }

  /// @inheritdoc IKeep3rKeeperFundable
  function activate(address _bonding) external override {
    if (disputes[msg.sender]) revert Disputed();
    if (canActivateAfter[msg.sender][_bonding] == 0) revert BondsUnexistent();
    if (canActivateAfter[msg.sender][_bonding] >= block.timestamp) revert BondsLocked();

    delete canActivateAfter[msg.sender][_bonding];

    uint256 _amount = _activate(msg.sender, _bonding);
    emit Activation(msg.sender, _bonding, _amount);
  }

  /// @inheritdoc IKeep3rKeeperFundable
  function unbond(address _bonding, uint256 _amount) external override {
    canWithdrawAfter[msg.sender][_bonding] = block.timestamp + unbondTime;
    bonds[msg.sender][_bonding] -= _amount;
    pendingUnbonds[msg.sender][_bonding] += _amount;

    emit Unbonding(msg.sender, _bonding, _amount);
  }

  /// @inheritdoc IKeep3rKeeperFundable
  function withdraw(address _bonding) external override nonReentrant {
    if (pendingUnbonds[msg.sender][_bonding] == 0) revert UnbondsUnexistent();
    if (canWithdrawAfter[msg.sender][_bonding] >= block.timestamp) revert UnbondsLocked();
    if (disputes[msg.sender]) revert Disputed();

    uint256 _amount = pendingUnbonds[msg.sender][_bonding];

    if (_bonding == keep3rV1) {
      IKeep3rV1Proxy(keep3rV1Proxy).mint(_amount);
    }

    delete pendingUnbonds[msg.sender][_bonding];
    delete canWithdrawAfter[msg.sender][_bonding];

    IERC20(_bonding).safeTransfer(msg.sender, _amount);

    emit Withdrawal(msg.sender, _bonding, _amount);
  }

  function _activate(address _keeper, address _bonding) internal returns (uint256 _amount) {
    if (firstSeen[_keeper] == 0) {
      firstSeen[_keeper] = block.timestamp;
    }
    _keepers.add(_keeper);
    _amount = pendingBonds[_keeper][_bonding];
    delete pendingBonds[_keeper][_bonding];

    // bond provided tokens
    bonds[_keeper][_bonding] += _amount;
    if (_bonding == keep3rV1) {
      IKeep3rV1(keep3rV1).burn(_amount);
    }
  }
}