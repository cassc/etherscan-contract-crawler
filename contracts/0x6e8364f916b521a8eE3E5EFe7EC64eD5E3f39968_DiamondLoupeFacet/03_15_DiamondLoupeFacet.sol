// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import {IForwarderRegistry} from "./../../metatx/interfaces/IForwarderRegistry.sol";
import {IDiamondLoupe} from "./../interfaces/IDiamondLoupe.sol";
import {DiamondStorage} from "./../libraries/DiamondStorage.sol";
import {ProxyAdminStorage} from "./../../proxy/libraries/ProxyAdminStorage.sol";
import {ForwarderRegistryContextBase} from "./../../metatx/base/ForwarderRegistryContextBase.sol";

/// @title Diamond Loupe (facet version).
/// @dev See https://eips.ethereum.org/EIPS/eip-2535
/// @dev Note: This facet depends on {ProxyAdminFacet} and {InterfaceDetectionFacet}.
contract DiamondLoupeFacet is IDiamondLoupe, ForwarderRegistryContextBase {
    using ProxyAdminStorage for ProxyAdminStorage.Layout;
    using DiamondStorage for DiamondStorage.Layout;

    constructor(IForwarderRegistry forwarderRegistry) ForwarderRegistryContextBase(forwarderRegistry) {}

    /// @notice Marks the following ERC165 interface(s) as supported: DiamondLoupe.
    /// @dev Reverts if the sender is not the proxy admin.
    function initDiamondLoupeStorage() external {
        ProxyAdminStorage.layout().enforceIsProxyAdmin(_msgSender());
        DiamondStorage.initDiamondLoupe();
    }

    /// @inheritdoc IDiamondLoupe
    function facets() external view override returns (IDiamondLoupe.Facet[] memory facets_) {
        facets_ = DiamondStorage.layout().facets();
    }

    /// @inheritdoc IDiamondLoupe
    function facetFunctionSelectors(address facet) external view override returns (bytes4[] memory facetFunctionSelectors_) {
        facetFunctionSelectors_ = DiamondStorage.layout().facetFunctionSelectors(facet);
    }

    /// @inheritdoc IDiamondLoupe
    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        facetAddresses_ = DiamondStorage.layout().facetAddresses();
    }

    /// @inheritdoc IDiamondLoupe
    function facetAddress(bytes4 functionSelector) external view override returns (address facetAddress_) {
        facetAddress_ = DiamondStorage.layout().facetAddress(functionSelector);
    }
}