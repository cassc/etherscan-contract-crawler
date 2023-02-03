// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import {IVersioned} from "../../../interfaces/IVersioned.sol";
import {ImplementationRepository as Repo} from "./ImplementationRepository.sol";

contract VersionedImplementationRepository is Repo {
  /// @dev abi encoded version -> implementation address
  /// @dev we use bytes here so only a single storage slot is used
  mapping(bytes => address) internal _byVersion;

  // // EXTERNAL //////////////////////////////////////////////////////////////////

  /// @notice get an implementation by a version tag
  /// @param version `[major, minor, patch]` version tag
  /// @return implementation associated with the given version tag
  function getByVersion(uint8[3] calldata version) external view returns (address) {
    return _byVersion[abi.encodePacked(version)];
  }

  /// @notice check if a version exists
  /// @param version `[major, minor, patch]` version tag
  /// @return true if the version is registered
  function hasVersion(uint8[3] calldata version) external view returns (bool) {
    return _hasVersion(version);
  }

  // // INTERNAL //////////////////////////////////////////////////////////////////

  function _append(address implementation, uint256 lineageId) internal override {
    uint8[3] memory version = IVersioned(implementation).getVersion();
    _insertVersion(version, implementation);
    return super._append(implementation, lineageId);
  }

  function _createLineage(address implementation) internal override returns (uint256) {
    uint8[3] memory version = IVersioned(implementation).getVersion();
    _insertVersion(version, implementation);
    uint256 lineageId = super._createLineage(implementation);
    return lineageId;
  }

  function _remove(address toRemove, address previous) internal override {
    uint8[3] memory version = IVersioned(toRemove).getVersion();
    _removeVersion(version);
    return super._remove(toRemove, previous);
  }

  function _insertVersion(uint8[3] memory version, address impl) internal {
    require(!_hasVersion(version), "exists");
    _byVersion[abi.encodePacked(version)] = impl;
    emit VersionAdded(version, impl);
  }

  function _removeVersion(uint8[3] memory version) internal {
    address toRemove = _byVersion[abi.encode(version)];
    _byVersion[abi.encodePacked(version)] = INVALID_IMPL;
    emit VersionRemoved(version, toRemove);
  }

  function _hasVersion(uint8[3] memory version) internal view returns (bool) {
    return _byVersion[abi.encodePacked(version)] != INVALID_IMPL;
  }

  event VersionAdded(uint8[3] indexed version, address indexed impl);
  event VersionRemoved(uint8[3] indexed version, address indexed impl);
}