// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable no-inline-assembly

contract ConcentratorBase {
  /**********
   * Events *
   **********/

  /// @notice Emitted when the harvester contract is updated.
  /// @param _harvester The address of the harvester contract.
  event UpdateHarvester(address _harvester);

  /// @notice Emitted when the zap contract is updated.
  /// @param _zap The address of the zap contract.
  event UpdateZap(address _zap);

  /*************
   * Constants *
   *************/

  /// @dev The storage slot for harvester storage.
  bytes32 private constant CONCENTRATOR_STORAGE_POSITION = keccak256("concentrator.base.storage");

  /***********
   * Structs *
   ***********/

  struct BaseStorage {
    address harvester;
    uint256[100] gaps;
  }

  /**********************
   * Internal Functions *
   **********************/

  function baseStorage() internal pure returns (BaseStorage storage bs) {
    bytes32 position = CONCENTRATOR_STORAGE_POSITION;
    assembly {
      bs.slot := position
    }
  }

  function _updateHarvester(address _harvester) internal {
    baseStorage().harvester = _harvester;

    emit UpdateHarvester(_harvester);
  }

  function ensureCallerIsHarvester() internal view {
    address _harvester = baseStorage().harvester;

    require(_harvester == address(0) || _harvester == msg.sender, "only harvester");
  }
}