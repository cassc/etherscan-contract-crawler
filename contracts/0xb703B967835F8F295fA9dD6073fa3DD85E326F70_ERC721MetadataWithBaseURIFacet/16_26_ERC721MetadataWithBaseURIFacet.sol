// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IForwarderRegistry} from "./../../../metatx/interfaces/IForwarderRegistry.sol";
import {ERC721ContractMetadataStorage} from "./../libraries/ERC721ContractMetadataStorage.sol";
import {TokenMetadataWithBaseURIStorage} from "./../../metadata/libraries/TokenMetadataWithBaseURIStorage.sol";
import {ProxyAdminStorage} from "./../../../proxy/libraries/ProxyAdminStorage.sol";
import {ERC721MetadataWithBaseURIBase} from "./../base/ERC721MetadataWithBaseURIBase.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ForwarderRegistryContextBase} from "./../../../metatx/base/ForwarderRegistryContextBase.sol";

/// @title ERC721 Non-Fungible Token Standard, optional extension: Metadata (facet version).
/// @dev This contract is to be used as a diamond facet (see ERC2535 Diamond Standard https://eips.ethereum.org/EIPS/eip-2535).
/// @dev Note: This facet depends on {ProxyAdminFacet}, {ContractOwnershipFacet} and {InterfaceDetectionFacet}.
contract ERC721MetadataWithBaseURIFacet is ERC721MetadataWithBaseURIBase, ForwarderRegistryContextBase {
    using ProxyAdminStorage for ProxyAdminStorage.Layout;
    using ERC721ContractMetadataStorage for ERC721ContractMetadataStorage.Layout;
    using TokenMetadataWithBaseURIStorage for TokenMetadataWithBaseURIStorage.Layout;

    constructor(IForwarderRegistry forwarderRegistry) ForwarderRegistryContextBase(forwarderRegistry) {}

    /// @notice Initializes the storage with a name and a symbol.
    /// @notice Sets the proxy initialization phase for ERC721ContractMetadataStorage to `1`.
    /// @notice Marks the following ERC165 interface(s) as supported: ERC721Metadata.
    /// @dev Reverts if the sender is not the proxy admin.
    /// @dev Reverts if the proxy initialization phase for ERC721ContractMetadataStorage is set to `1` or above.
    /// @param tokenName The token name
    /// @param tokenSymbol The token symbol
    function initERC721MetadataStorage(string calldata tokenName, string calldata tokenSymbol) external {
        ProxyAdminStorage.layout().enforceIsProxyAdmin(_msgSender());
        ERC721ContractMetadataStorage.layout().proxyInit(tokenName, tokenSymbol);
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