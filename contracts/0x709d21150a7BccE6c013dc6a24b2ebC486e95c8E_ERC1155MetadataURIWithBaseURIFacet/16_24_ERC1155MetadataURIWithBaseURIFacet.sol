// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IForwarderRegistry} from "./../../../metatx/interfaces/IForwarderRegistry.sol";
import {ERC1155Storage} from "./../libraries/ERC1155Storage.sol";
import {TokenMetadataWithBaseURIStorage} from "./../../metadata/libraries/TokenMetadataWithBaseURIStorage.sol";
import {ProxyAdminStorage} from "./../../../proxy/libraries/ProxyAdminStorage.sol";
import {ERC1155MetadataURIWithBaseURIBase} from "./../base/ERC1155MetadataURIWithBaseURIBase.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ForwarderRegistryContextBase} from "./../../../metatx/base/ForwarderRegistryContextBase.sol";

/// @title ERC1155 Multi Token Standard, optional extension: Metadata URI (facet version).
/// @notice ERC1155MetadataURI implementation where tokenURIs are the concatenation of a base metadata URI and the token identifier (decimal).
/// @dev This contract is to be used as a diamond facet (see ERC2535 Diamond Standard https://eips.ethereum.org/EIPS/eip-2535).
/// @dev Note: This facet depends on {ProxyAdminFacet}, and {InterfaceDetectionFacet}.
contract ERC1155MetadataURIWithBaseURIFacet is ERC1155MetadataURIWithBaseURIBase, ForwarderRegistryContextBase {
    using TokenMetadataWithBaseURIStorage for TokenMetadataWithBaseURIStorage.Layout;
    using ProxyAdminStorage for ProxyAdminStorage.Layout;

    constructor(IForwarderRegistry forwarderRegistry) ForwarderRegistryContextBase(forwarderRegistry) {}

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155MetadataURI.
    /// @dev Reverts if the sender is not the proxy admin.
    function initERC1155MetadataURIStorage() external {
        ProxyAdminStorage.layout().enforceIsProxyAdmin(_msgSender());
        ERC1155Storage.initERC1155MetadataURI();
    }

    /// @inheritdoc ForwarderRegistryContextBase
    function _msgSender() internal view virtual override(Context, ForwarderRegistryContextBase) returns (address) {
        return ForwarderRegistryContextBase._msgSender();
    }

    /// @inheritdoc ForwarderRegistryContextBase
    function _msgData() internal view virtual override(Context, ForwarderRegistryContextBase) returns (bytes calldata) {
        return ForwarderRegistryContextBase._msgData();
    }
}