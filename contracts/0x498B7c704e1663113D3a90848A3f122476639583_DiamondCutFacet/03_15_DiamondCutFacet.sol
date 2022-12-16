// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import {IForwarderRegistry} from "./../../metatx/interfaces/IForwarderRegistry.sol";
import {IDiamondCut} from "./../interfaces/IDiamondCut.sol";
import {IDiamondCutBatchInit} from "./../interfaces/IDiamondCutBatchInit.sol";
import {DiamondStorage} from "./../libraries/DiamondStorage.sol";
import {ProxyAdminStorage} from "./../../proxy/libraries/ProxyAdminStorage.sol";
import {ForwarderRegistryContextBase} from "./../../metatx/base/ForwarderRegistryContextBase.sol";

/// @title Diamond Cut (facet version).
/// @dev See https://eips.ethereum.org/EIPS/eip-2535
/// @dev Note: This facet depends on {ProxyAdminFacet} and {InterfaceDetectionFacet}.
contract DiamondCutFacet is IDiamondCut, IDiamondCutBatchInit, ForwarderRegistryContextBase {
    using ProxyAdminStorage for ProxyAdminStorage.Layout;
    using DiamondStorage for DiamondStorage.Layout;

    constructor(IForwarderRegistry forwarderRegistry) ForwarderRegistryContextBase(forwarderRegistry) {}

    /// @notice Marks the following ERC165 interface(s) as supported: DiamondCut, DiamondCutBatchInit.
    /// @dev Reverts if the sender is not the proxy admin.
    function initDiamondCutStorage() external {
        ProxyAdminStorage.layout().enforceIsProxyAdmin(_msgSender());
        DiamondStorage.initDiamondCut();
    }

    /// @inheritdoc IDiamondCut
    /// @dev Reverts if the sender is not the proxy admin.
    function diamondCut(FacetCut[] calldata cuts, address target, bytes calldata data) external override {
        ProxyAdminStorage.layout().enforceIsProxyAdmin(_msgSender());
        DiamondStorage.layout().diamondCut(cuts, target, data);
    }

    /// @inheritdoc IDiamondCutBatchInit
    /// @dev Reverts if the sender is not the proxy admin.
    function diamondCut(FacetCut[] calldata cuts, Initialization[] calldata initializations) external override {
        ProxyAdminStorage.layout().enforceIsProxyAdmin(_msgSender());
        DiamondStorage.layout().diamondCut(cuts, initializations);
    }
}