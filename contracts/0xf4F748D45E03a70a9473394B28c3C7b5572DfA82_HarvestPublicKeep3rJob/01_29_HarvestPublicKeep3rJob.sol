// SPDX-License-Identifier: MIT

/*

Coded for Yearn Finance with ♥ by

██████╗░███████╗███████╗██╗░░░██╗░░░░░░░██╗░█████╗░███╗░░██╗██████╗░███████╗██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░
██╔══██╗██╔════╝██╔════╝██║░░░██║░░██╗░░██║██╔══██╗████╗░██║██╔══██╗██╔════╝██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗
██║░░██║█████╗░░█████╗░░██║░░░╚██╗████╗██╔╝██║░░██║██╔██╗██║██║░░██║█████╗░░██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║
██║░░██║██╔══╝░░██╔══╝░░██║░░░░████╔═████║░██║░░██║██║╚████║██║░░██║██╔══╝░░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║
██████╔╝███████╗██║░░░░░██║░░░░╚██╔╝░╚██╔╝░╚█████╔╝██║░╚███║██████╔╝███████╗██║░░██║███████╗██║░░██║██║░╚███║██████╔╝
╚═════╝░╚══════╝╚═╝░░░░░╚═╝░░░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

https://defi.sucks

*/

pragma solidity >=0.8.9 <0.9.0;

import './PublicKeeperJob.sol';
import './utils/Pausable.sol';
import './utils/Keep3rMeteredPublicJob.sol';

contract HarvestPublicKeep3rJob is IKeep3rJob, PublicKeeperJob, Pausable, Keep3rJob {
  using EnumerableSet for EnumerableSet.AddressSet;

  constructor(
    address _governor,
    address _mechanicsRegistry,
    address _publicKeeper,
    address _vaultRegistry,
    uint256 _workCooldown,
    address _keep3r
  ) PublicKeeperJob(_governor, _publicKeeper, _mechanicsRegistry, _vaultRegistry, _workCooldown) {
    _setKeep3r(_keep3r);
  }

  // views

  /// @inheritdoc IPublicKeeperJob
  function workable(address _strategy) external view returns (bool _isWorkable) {
    return _workable(_strategy);
  }

  function _isValidStrategy(address _strategy) internal view virtual override returns (bool _isValid) {
    address _vault = IBaseStrategy(_strategy).vault();
    return
      IVaultRegistry(vaultRegistry).isVaultEndorsed(_vault) &&
      ITokenVault(_vault).strategies(_strategy).activation > 0 &&
      !_ignoredStrategies.contains(_strategy);
  }

  // methods

  /// @inheritdoc IPublicKeeperJob
  function work(address _strategy) external upkeep notPaused {
    _workInternal(_strategy);
  }

  /// @inheritdoc IPublicKeeperJob
  function forceWork(address _strategy) external onlyGovernorOrMechanic {
    _forceWork(_strategy);
  }

  // internals

  function _workable(address _strategy) internal view override returns (bool _isWorkable) {
    if (!super._workable(_strategy)) return false;
    return IBaseStrategy(_strategy).harvestTrigger(0);
  }

  function _work(address _strategy) internal override {
    publicKeeper.harvest(_strategy);
  }
}