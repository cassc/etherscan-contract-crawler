// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Prerelease Contracts
import './IFlavorInfo.sol';

/**
 * @title FlavorInfoManager
 * @author @NFTCulture
 */
abstract contract FlavorInfoManager is IFlavorInfo {
    // Storage for Token Flavors
    mapping(uint256 => FlavorInfo) private _flavorInfo;

    uint64[] private _flavorIds;

    uint256 private _maxSupply;

    constructor() {
        _initializeFlavors();

        _maxSupply = _computeMaxSupply();
    }

    function _initializeFlavors() private {
        FlavorInfo[] memory initialTokenFlavors = _getInitialFlavors();

        for (uint256 idx = 0; idx < initialTokenFlavors.length; idx++) {
            FlavorInfo memory current = initialTokenFlavors[idx];

            _createFlavorInfo(current);
        }
    }

    function _getInitialFlavors() internal virtual returns (FlavorInfo[] memory);

    function getFlavorInfo(uint256 flavorId) external view returns (FlavorInfo memory) {
        return _getFlavorInfo(flavorId);
    }

    function _getFlavorInfo(uint256 flavorId) internal view returns (FlavorInfo memory) {
        return _flavorInfo[flavorId];
    }

    function getFlavors() external view returns (uint64[] memory) {
        return _getFlavors();
    }

    function _getFlavors() internal view returns (uint64[] memory) {
        return _flavorIds;
    }

    function _createFlavorInfo(FlavorInfo memory tokenFlavor) internal {
        // This allows expanding the collection, so we should eventually restrict it.
        _flavorInfo[tokenFlavor.flavorId] = tokenFlavor;
        _flavorIds.push(tokenFlavor.flavorId);
    }

    function _updateFlavorInfo(FlavorInfo memory tokenFlavor) internal {
        // This allows editing max supply, so we should eventually restrict it.
        _flavorInfo[tokenFlavor.flavorId] = tokenFlavor;
    }

    function _saveFlavorInfo(FlavorInfo memory tokenFlavor) internal {
        _flavorInfo[tokenFlavor.flavorId].totalMinted = tokenFlavor.totalMinted;
    }

    function computeMaxSupply() external view returns (uint256) {
        return _computeMaxSupply();
    }

    function _computeMaxSupply() internal view returns (uint256) {
        uint256 maxSupply;

        for (uint256 idx = 0; idx < _flavorIds.length; idx++) {
            FlavorInfo memory current = _flavorInfo[_flavorIds[idx]];
            maxSupply += current.maxSupply;
        }

        return maxSupply;
    }

    function _incrementMaxSupply(uint256 amount) internal {
        _maxSupply += amount;
    }

    function _decrementMaxSupply(uint256 amount) internal {
        require(amount > _maxSupply, 'Cannot decrement');

        _maxSupply -= amount;
    }

    function _getMaxSupply() internal view returns (uint256) {
        return _maxSupply;
    }
}