// SPDX-License-Identifier: MIT

/*

Coded for Yearn Finance with ♥ by

██████╗░███████╗███████╗██╗  ░██╗░░░░░░░██╗░█████╗░███╗░░██╗██████╗░███████╗██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░
██╔══██╗██╔════╝██╔════╝██║  ░██║░░██╗░░██║██╔══██╗████╗░██║██╔══██╗██╔════╝██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗
██║░░██║█████╗░░█████╗░░██║  ░╚██╗████╗██╔╝██║░░██║██╔██╗██║██║░░██║█████╗░░██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║
██║░░██║██╔══╝░░██╔══╝░░██║  ░░████╔═████║░██║░░██║██║╚████║██║░░██║██╔══╝░░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║
██████╔╝███████╗██║░░░░░██║  ░░╚██╔╝░╚██╔╝░╚█████╔╝██║░╚███║██████╔╝███████╗██║░░██║███████╗██║░░██║██║░╚███║██████╔╝
╚═════╝░╚══════╝╚═╝░░░░░╚═╝  ░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

https://defi.sucks

*/

pragma solidity >=0.8.9 <0.9.0;

import './V2KeeperJob.sol';
import './utils/Pausable.sol';
import './utils/Keep3rMeteredPublicJob.sol';

contract TendV2Keep3rJob is IKeep3rJob, V2KeeperJob, Pausable, Keep3rMeteredPublicJob {
  constructor(
    address _governor,
    address _mechanicsRegistry,
    address _v2Keeper,
    uint256 _workCooldown,
    address _keep3r,
    address _keep3rHelper,
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age,
    bool _onlyEOA
  ) V2KeeperJob(_governor, _v2Keeper, _mechanicsRegistry, _workCooldown) {
    _setKeep3r(_keep3r);
    _setKeep3rHelper(_keep3rHelper);
    _setKeep3rRequirements(_bond, _minBond, _earned, _age);
    _setOnlyEOA(_onlyEOA);
  }

  // views

  /// @inheritdoc IV2KeeperJob
  function workable(address _strategy) external view returns (bool _isWorkable) {
    return _workable(_strategy);
  }

  // methods

  /// @inheritdoc IV2KeeperJob
  function work(address _strategy) external upkeepMetered notPaused {
    _workInternal(_strategy);
  }

  /// @inheritdoc IV2KeeperJob
  function forceWork(address _strategy) external onlyGovernorOrMechanic {
    _forceWork(_strategy);
  }

  // internals

  function _workable(address _strategy) internal view override returns (bool _isWorkable) {
    if (!super._workable(_strategy)) return false;
    return IBaseStrategy(_strategy).tendTrigger(_getCallCosts(_strategy));
  }

  function _work(address _strategy) internal override {
    v2Keeper.tend(_strategy);
  }
}