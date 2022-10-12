// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "./interfaces/IBridgeAdapter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Manages a list of supported bridges
 * @author lionelhoho
 */
abstract contract BridgeRegistry is Ownable {
    event SupportedBridgesUpdated(string[] _bridgeProviders, address[] _bridgeAdapters);

    mapping(bytes32 => IBridgeAdapter) public bridges;

    // to disable a bridge, set the bridge addr of the corresponding provider to address(0)
    function setSupportedBridges(
        string[] calldata _bridgeProviders,
        address[] calldata _bridgeAdapters
    ) external onlyOwner {
        require(_bridgeProviders.length == _bridgeAdapters.length, "params size mismatch");
        for (uint256 i = 0; i < _bridgeProviders.length; i++) {
            bridges[keccak256(bytes(_bridgeProviders[i]))] = IBridgeAdapter(_bridgeAdapters[i]);
        }
        emit SupportedBridgesUpdated(_bridgeProviders, _bridgeAdapters);
    }
}