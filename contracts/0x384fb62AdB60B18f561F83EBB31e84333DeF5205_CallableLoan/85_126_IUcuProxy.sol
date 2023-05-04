// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import {IERC173} from "./IERC173.sol";
import {IImplementationRepository as IRepo} from "./IImplementationRepository.sol";

/// @title User Controlled Upgrade (UCU) Proxy
///
/// The UCU Proxy contract allows the owner of the proxy to control _when_ they
/// upgrade their proxy, but not to what implementation.  The implementation is
/// determined by an externally controlled {ImplementationRepository} contract that
/// specifices the upgrade path. A user is able to upgrade their proxy as many
/// times as is available until they're reached the most up to date version
interface IUcuProxy is IERC173 {
  // ///////////////////// EXTERNAL ///////////////////////////////////////////////////////////////////////////

  /// @notice upgrade the proxy implementation
  /// @dev reverts if the repository has not been initialized or if there is no following version
  function upgradeImplementation() external;

  /// @notice Returns the associated {Repo}
  ///   contract used for fetching implementations to upgrade to
  function getRepository() external view returns (IRepo);

  // /////////////////////// EVENTS ///////////////////////////////////////////////////////////////////////////

  /// @dev Emitted when the implementation is upgraded.
  event Upgraded(address indexed implementation);
}