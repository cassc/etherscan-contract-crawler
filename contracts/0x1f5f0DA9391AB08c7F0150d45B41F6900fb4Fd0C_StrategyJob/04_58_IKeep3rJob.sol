//SPDX-License-Identifier: MIT
pragma solidity >=0.8.8 <0.9.0;

import {IGovernable} from '@defi-wonderland/solidity-utils/solidity/interfaces/IGovernable.sol';
import {IKeep3r} from '@defi-wonderland/keep3r-v2/solidity/interfaces/IKeep3r.sol';

interface IKeep3rJob is IGovernable {
  // STATE VARIABLES

  /// @return _keep3r Address of the Keep3r contract
  function keep3r() external view returns (IKeep3r _keep3r);

  // EVENTS

  /// @notice Emitted when a new Keep3r contract is set
  /// @param _keep3r Address of the new Keep3r contract
  event Keep3rSet(IKeep3r _keep3r);

  // ERRORS

  /// @notice Throws when a keeper fails the validation
  error KeeperNotValid();

  // FUNCTIONS

  /// @notice Allows governor to set a new Keep3r contract
  /// @param _keep3r Address of the new Keep3r contract
  function setKeep3r(IKeep3r _keep3r) external;
}