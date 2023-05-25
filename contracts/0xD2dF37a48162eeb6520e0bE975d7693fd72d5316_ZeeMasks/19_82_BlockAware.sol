// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IBlockAware.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @notice The implementer contract will always know at which block it was created.
abstract contract BlockAware is IBlockAware, Initializable {
    bytes32 private constant _DEPLOYMENT_BLOCK_NUMBER_SLOT =
        bytes32(uint256(keccak256("zee-game.block-aware.deployment-block")) - 1);

    // solhint-disable-next-line func-name-mixedcase
    function __BlockAware_init() internal onlyInitializing {
        StorageSlot.getUint256Slot(_DEPLOYMENT_BLOCK_NUMBER_SLOT).value = block.number;
    }

    /// @inheritdoc IBlockAware
    function getDeploymentBlockNumber() external view returns (uint256) {
        // solhint-disable-previous-line ordering
        return StorageSlot.getUint256Slot(_DEPLOYMENT_BLOCK_NUMBER_SLOT).value;
    }
}