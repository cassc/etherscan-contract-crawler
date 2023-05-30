// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/governance/TimelockController.sol';
import './Governess.sol';
import './FemErecter.sol';

/**
 * @notice Deployer for Fem governance contracts and FemErecter.
 * Deploys governance in an unusable state, then activates the
 * contracts once the sale is successful.
 */
contract GovernessActivator {
  TimelockController public immutable timelockController;
  Governess public immutable governess;
  IFem public immutable fem;
  FemErecter public immutable femErecter;

  constructor(
    address _fem,
    address _devAddress,
    uint256 _devTokenBips,
    uint32 _saleStartTime,
    uint32 _saleDuration,
    uint32 _timeToSpend,
    uint256 _minimumEthRaised
  ) {
    fem = IFem(_fem);
    Governess _governess = new Governess(_fem, address(this), type(uint256).max);
    governess = _governess;
    address[] memory proposers = new address[](1);
    address[] memory executors = new address[](1);
    proposers[0] = address(_governess);
    executors[0] = address(_governess);
    TimelockController timelock = new TimelockController(2 days, proposers, executors);
    timelockController = timelock;
    timelockController.renounceRole(keccak256('TIMELOCK_ADMIN_ROLE'), address(this));
    femErecter = new FemErecter(
      address(timelock),
      _devAddress,
      _devTokenBips,
      _fem,
      _saleStartTime,
      _saleDuration,
      _timeToSpend,
      _minimumEthRaised
    );
  }

  function activateGoverness() external {
    require(
      femErecter.state() == IFemErecter.SaleState.FUNDS_PENDING,
      'Can not activate governess before sale succeeds'
    );
    uint256 finalSupply = (fem.totalSupply() * (10000 + femErecter.devTokenBips())) / 10000;
    uint256 proposalThreshold = finalSupply / 100;
    governess.setProposalThreshold(proposalThreshold);
    governess.updateTimelock(timelockController);
  }
}