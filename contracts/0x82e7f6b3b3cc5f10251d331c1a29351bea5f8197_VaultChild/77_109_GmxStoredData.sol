// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Registry } from '../registry/Registry.sol';
import { VaultBaseExternal } from '../vault-base/VaultBaseExternal.sol';
import { IntegrationDataTracker, Integration } from '../integration-data-tracker/IntegrationDataTracker.sol';

import { IGmxRouter } from '../interfaces/IGmxRouter.sol';
import { IGmxPositionRouter } from '../interfaces/IGmxPositionRouter.sol';
import { IGmxPositionRouterCallbackReceiver } from '../interfaces/IGmxPositionRouterCallbackReceiver.sol';
import { IGmxVault } from '../interfaces/IGmxVault.sol';

library GmxStoredData {
    struct GMXRequestData {
        address _inputToken;
        address _outputToken;
        address _collateralToken;
        address _indexToken;
        bool _isLong;
    }

    struct GMXPositionData {
        address _collateralToken;
        address _indexToken;
        bool _isLong;
    }

    /// @notice Pushes a GmxRequestData to storage
    /// @dev can only be called by the vault
    function pushRequest(
        bytes32 key,
        GMXRequestData memory requestData,
        uint maxRequest
    ) internal {
        Registry registry = VaultBaseExternal(address(this)).registry();
        IntegrationDataTracker dataTracker = registry.integrationDataTracker();
        require(
            address(dataTracker) != address(0),
            'no dataTracker configured'
        );

        require(
            dataTracker.getDataCount(Integration.GMXRequests, address(this)) <=
                maxRequest,
            'max requests reached'
        );
        dataTracker.pushData(
            Integration.GMXRequests,
            abi.encode(key, requestData)
        );
    }

    /// @notice removes a GmxRequestData in storage by the index
    /// @dev index is returned by findRequest
    function removeRequest(Registry registry, int index) internal {
        IntegrationDataTracker dataTracker = registry.integrationDataTracker();
        require(
            address(dataTracker) != address(0),
            'no dataTracker configured'
        );

        dataTracker.removeData(Integration.GMXRequests, uint(index));
    }

    /// @notice removes the GMXPositionData at the given index
    ///         for the calling vault if the GMX position is empty
    function removePositionIfEmpty(
        GMXPositionData memory keyData,
        uint index
    ) internal {
        Registry registry = VaultBaseExternal(address(this)).registry();
        IntegrationDataTracker dataTracker = registry.integrationDataTracker();
        require(
            address(dataTracker) != address(0),
            'no dataTracker configured'
        );

        (uint256 size, , , , , , , ) = IGmxVault(registry.gmxConfig().vault())
            .getPosition(
                address(this),
                keyData._collateralToken,
                keyData._indexToken,
                keyData._isLong
            );

        if (size == 0) {
            dataTracker.removeData(Integration.GMXPositions, index);
        }
    }

    /// @notice removes the GMXPositionData in storage for the calling vault if the GMX position is empty
    function removePositionIfEmpty(GMXPositionData memory keyData) internal {
        Registry registry = VaultBaseExternal(address(this)).registry();
        IntegrationDataTracker dataTracker = registry.integrationDataTracker();
        require(
            address(dataTracker) != address(0),
            'no dataTracker configured'
        );

        (uint256 size, , , , , , , ) = IGmxVault(registry.gmxConfig().vault())
            .getPosition(
                address(this),
                keyData._collateralToken,
                keyData._indexToken,
                keyData._isLong
            );

        if (size == 0) {
            uint count = dataTracker.getDataCount(
                Integration.GMXPositions,
                address(this)
            );

            for (uint256 i = 0; i < count; i++) {
                GMXPositionData memory positionData = abi.decode(
                    dataTracker.getData(
                        Integration.GMXPositions,
                        address(this),
                        i
                    ),
                    (GMXPositionData)
                );
                if (
                    keyData._collateralToken == positionData._collateralToken &&
                    keyData._indexToken == positionData._indexToken &&
                    keyData._isLong == positionData._isLong
                ) {
                    dataTracker.removeData(Integration.GMXPositions, i);
                }
            }
        }
    }

    /// @notice Can only be called from the vault
    /// @dev If we're not tracking the position adds it, during this function we checked tracked position are still open
    /// @dev And if not remove them (they have likely been liquidated)
    function updatePositions(
        address _indexToken,
        address _collateralToken,
        bool _isLong,
        uint256 maxPositionsAllowed
    ) internal {
        Registry registry = VaultBaseExternal(address(this)).registry();
        IntegrationDataTracker dataTracker = registry.integrationDataTracker();
        require(
            address(dataTracker) != address(0),
            'no dataTracker configured'
        );

        bytes[] memory positionData = dataTracker.getAllData(
            Integration.GMXPositions,
            address(this)
        );
        bool positionIsTracked;
        for (uint256 i = 0; i < positionData.length; i++) {
            GMXPositionData memory keyData = abi.decode(
                positionData[i],
                (GMXPositionData)
            );
            if (
                _indexToken == keyData._indexToken &&
                _collateralToken == keyData._collateralToken &&
                _isLong == keyData._isLong
            ) {
                positionIsTracked = true;
            }
            // Remove positions that are no longer open
            else {
                removePositionIfEmpty(keyData, i);
            }
        }

        require(
            positionIsTracked ||
                dataTracker.getDataCount(
                    Integration.GMXPositions,
                    address(this)
                ) <
                maxPositionsAllowed,
            'max gmx positions reached'
        );

        if (!positionIsTracked) {
            dataTracker.pushData(
                Integration.GMXPositions,
                abi.encode(
                    GMXPositionData({
                        _collateralToken: _collateralToken,
                        _indexToken: _indexToken,
                        _isLong: _isLong
                    })
                )
            );
        }
    }

    /// @notice finds a GmxRequestData in storage by the key
    function findRequest(
        address vault,
        bytes32 key
    ) internal view returns (GMXRequestData memory, int256 index) {
        Registry registry = VaultBaseExternal(vault).registry();
        IntegrationDataTracker dataTracker = registry.integrationDataTracker();
        require(
            address(dataTracker) != address(0),
            'no dataTracker configured'
        );

        bytes[] memory positionData = dataTracker.getAllData(
            Integration.GMXRequests,
            vault
        );
        for (uint256 i = 0; i < positionData.length; i++) {
            (bytes32 storedKey, GMXRequestData memory keyData) = abi.decode(
                positionData[i],
                (bytes32, GMXRequestData)
            );

            if (storedKey == key) {
                return (keyData, int(i));
            }
        }
        return (
            GMXRequestData(
                address(0),
                address(0),
                address(0),
                address(0),
                false
            ),
            -1
        );
    }

    /// @notice gets all GMXPositionData in storage for the vault
    function getStoredPositions(
        address vault
    ) internal view returns (GMXPositionData[] memory) {
        Registry registry = VaultBaseExternal(vault).registry();
        IntegrationDataTracker dataTracker = registry.integrationDataTracker();
        require(
            address(dataTracker) != address(0),
            'no dataTracker configured'
        );

        bytes[] memory positionData = registry
            .integrationDataTracker()
            .getAllData(Integration.GMXPositions, vault);
        GMXPositionData[] memory positions = new GMXPositionData[](
            positionData.length
        );
        for (uint256 i = 0; i < positionData.length; i++) {
            positions[i] = abi.decode(positionData[i], (GMXPositionData));
        }
        return positions;
    }
}