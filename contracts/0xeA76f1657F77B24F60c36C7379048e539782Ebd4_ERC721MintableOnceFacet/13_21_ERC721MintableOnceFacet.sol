// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IForwarderRegistry} from "./../../../metatx/interfaces/IForwarderRegistry.sol";
import {ERC721Storage} from "./../libraries/ERC721Storage.sol";
import {ProxyAdminStorage} from "./../../../proxy/libraries/ProxyAdminStorage.sol";
import {ERC721MintableOnceBase} from "./../base/ERC721MintableOnceBase.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ForwarderRegistryContextBase} from "./../../../metatx/base/ForwarderRegistryContextBase.sol";

/// @title ERC721 Non-Fungible Token Standard, optional extension: Mintable (facet version).
/// @notice ERC721Mintable implementation where burnt tokens cannot be minted again.
/// @dev This contract is to be used as a diamond facet (see ERC2535 Diamond Standard https://eips.ethereum.org/EIPS/eip-2535).
/// @dev Note: This facet depends on {ProxyAdminFacet}, {InterfaceDetectionFacet} and {AccessControlFacet}.
contract ERC721MintableOnceFacet is ERC721MintableOnceBase, ForwarderRegistryContextBase {
    using ProxyAdminStorage for ProxyAdminStorage.Layout;

    constructor(IForwarderRegistry forwarderRegistry) ForwarderRegistryContextBase(forwarderRegistry) {}

    /// @notice Marks the following ERC165 interface(s) as supported: ERC721Mintable.
    /// @dev Reverts if the sender is not the proxy admin.
    function initERC721MintableOnceStorage() external {
        ProxyAdminStorage.layout().enforceIsProxyAdmin(_msgSender());
        ERC721Storage.initERC721Mintable();
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