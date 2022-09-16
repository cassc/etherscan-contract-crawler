// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "../interfaces/IReweightableIndex.sol";

import "../BaseIndex.sol";

contract TestIndex is IReweightableIndex, BaseIndex {
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor() BaseIndex(msg.sender) {}

    function initialize(address[] calldata _assets, uint8[] calldata _weights) external {
        require(msg.sender == factory, "TestIndex: FORBIDDEN");

        for (uint i; i < _assets.length; ) {
            address asset = _assets[i];
            uint8 weight = _weights[i];
            assets.add(asset);
            weightOf[asset] = weight;
            emit UpdateAnatomy(asset, weight);

            unchecked {
                i = i + 1;
            }
        }
    }

    function testOnlyRole(bytes32 _role) external view onlyRole(_role) returns (bool) {
        return true;
    }

    function reweight() external override {}

    function replaceAsset(address _from, address _to) external {
        assets.remove(_from);
        inactiveAssets.add(_from);
        assets.add(_to);
        inactiveAssets.remove(_to);
        weightOf[_to] = weightOf[_from];
        weightOf[_from] = 0;
    }
}