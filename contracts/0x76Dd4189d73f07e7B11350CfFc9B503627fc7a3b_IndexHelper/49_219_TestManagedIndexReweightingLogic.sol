// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.13;

import "../interfaces/IManagedIndexReweightingLogic.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract TestManagedIndexReweightingLogic is IManagedIndexReweightingLogic, ERC165 {
    // test implementation which reverts
    function reweight(address[] calldata _updatedAssets, uint8[] calldata _updatedWeights) external override {
        revert();
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IManagedIndexReweightingLogic).interfaceId || super.supportsInterface(_interfaceId);
    }
}