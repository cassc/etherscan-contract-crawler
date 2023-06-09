//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "../interfaces/IProviderRegistry.sol";
import "./Adminable.sol";

abstract contract ProviderRegistry is IProviderRegistry, Adminable {
    mapping(bytes4 => address) private _providers;
    bytes4[] private _allProviderIDs;

    function setProvider(bytes4 id, address provider) external override onlyAdmin {
        _setProvider(id, provider);
    }

    function setProviders(bytes4[] calldata ids, address[] calldata providers) external override onlyAdmin {
        require(ids.length == providers.length, "ProviderRegistry: ids and providers length mismatch");
        for (uint256 i = 0; i < ids.length; i++) {
            _setProvider(ids[i], providers[i]);
        }
    }

    function _setProvider(bytes4 id, address provider) internal {
        if (_providers[id] == address(0)) {
            _allProviderIDs.push(id);
        }
        _providers[id] = provider;
        emit ProviderChanged(id, provider);
    }

    function removeProvider(bytes4 id) external override onlyAdmin {
        _removeProvider(id);
    }

    function removeProviders(bytes4[] calldata ids) external override onlyAdmin {
        for (uint256 i = 0; i < ids.length; i++) {
            _removeProvider(ids[i]);
        }
    }

    function _removeProvider(bytes4 id) internal {
        for (uint256 i = 0; i < _allProviderIDs.length; i++) {
            if (_allProviderIDs[i] == id) {
                _allProviderIDs[i] = _allProviderIDs[_allProviderIDs.length - 1];
                _allProviderIDs.pop();
                break;
            }
        }
        delete _providers[id];
        emit ProviderChanged(id, address(0));
    }

    function getProvider(bytes4 id) external view override returns (address provider) {
        return _providers[id];
    }

    function getProviders() external view override returns (bytes4[] memory ids, address[] memory providers) {
        ids = _allProviderIDs;
        providers = new address[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            providers[i] = _providers[ids[i]];
        }
    }

    function _getProvider(bytes4 id) internal view returns (address provider) {
        return _providers[id];
    }
}