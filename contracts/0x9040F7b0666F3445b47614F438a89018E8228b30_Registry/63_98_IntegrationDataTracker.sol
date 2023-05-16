// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import { Registry } from './registry/Registry.sol';

// This contract is a general store for when we need to store data that is relevant to an integration
// For example with GMX we must track what positions are open for each vault

contract IntegrationDataTracker {
    // Not sure if we should use an enum here because the integrations are not fixed
    // We could use a keccak("IntegrationName") instead, this contract will have to be upgraded if we add a new integration
    // Because solidity validates enum params at runtime
    enum Integration {
        GMXRequests,
        GMXPositions
    }

    mapping(Integration => mapping(address => bytes[])) internal trackedData; // used as the namespace for the data -> poolAddress -> data[]

    /**
     * @notice record new raw data
     * @param _integration used as the namespace for the data
     * @param _data the data track data to be recorded in storage
     */
    function pushData(Integration _integration, bytes memory _data) external {
        _pushData(_integration, msg.sender, _data);
    }

    /**
     * @notice record new raw data
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @param _data the data track data to be recorded in storage
     */
    function _pushData(
        Integration _integration,
        address _vault,
        bytes memory _data
    ) private {
        trackedData[_integration][_vault].push(_data);
    }

    /**
     * @notice delete data
     * @param _integration used as the namespace for the data
     * @param _index data index to be removed from storage
     */
    function removeData(Integration _integration, uint256 _index) external {
        _removeData(_integration, msg.sender, _index);
    }

    /**
     * @notice delete data
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @param _index data index to be removed from storage
     */
    function _removeData(
        Integration _integration,
        address _vault,
        uint256 _index
    ) private {
        uint256 length = trackedData[_integration][_vault].length;
        require(_index < length, 'invalid index');

        trackedData[_integration][_vault][_index] = trackedData[_integration][
            _vault
        ][length - 1];
        trackedData[_integration][_vault].pop();
    }

    /**
     * @notice returns tracked data by index
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @param _index the index of data track data
     * @return data the data track data of given NFT_TYPE & poolLogic & index
     */
    function getData(
        Integration _integration,
        address _vault,
        uint256 _index
    ) external view returns (bytes memory) {
        return trackedData[_integration][_vault][_index];
    }

    /**
     * @notice returns all tracked datas by NFT_TYPE & poolLogic
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @return data all tracked datas of given NFT_TYPE & poolLogic
     */
    function getAllData(
        Integration _integration,
        address _vault
    ) public view returns (bytes[] memory) {
        return trackedData[_integration][_vault];
    }

    /**
     * @notice returns all tracked datas by NFT_TYPE & poolLogic
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @return count all tracked datas count of given NFT_TYPE & poolLogic
     */
    function getDataCount(
        Integration _integration,
        address _vault
    ) public view returns (uint256) {
        return trackedData[_integration][_vault].length;
    }
}