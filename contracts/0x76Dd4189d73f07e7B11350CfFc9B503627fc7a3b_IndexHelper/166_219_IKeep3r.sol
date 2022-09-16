// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./peripherals/IKeep3rJobs.sol";
import "./peripherals/IKeep3rKeepers.sol";
import "./peripherals/IKeep3rAccountance.sol";
import "./peripherals/IKeep3rRoles.sol";
import "./peripherals/IKeep3rParameters.sol";

// solhint-disable-next-line no-empty-blocks

/// @title Keep3rV2 contract
/// @notice This contract inherits all the functionality of Keep3rV2
interface IKeep3r is IKeep3rJobs, IKeep3rKeepers, IKeep3rAccountance, IKeep3rRoles, IKeep3rParameters {

}