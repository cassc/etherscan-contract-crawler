// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IForwarderRegistry} from "./../../../metatx/interfaces/IForwarderRegistry.sol";
import {ERC20PermitStorage} from "./../libraries/ERC20PermitStorage.sol";
import {ProxyAdminStorage} from "./../../../proxy/libraries/ProxyAdminStorage.sol";
import {ERC20PermitBase} from "./../base/ERC20PermitBase.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ForwarderRegistryContextBase} from "./../../../metatx/base/ForwarderRegistryContextBase.sol";

/// @title ERC20 Fungible Token Standard, optional extension: Permit (facet version).
/// @dev This contract is to be used as a diamond facet (see ERC2535 Diamond Standard https://eips.ethereum.org/EIPS/eip-2535).
/// @dev Note: This facet depends on {ProxyAdminFacet}, {InterfaceDetectionFacet} and {ERC20DetailedFacet}.
contract ERC20PermitFacet is ERC20PermitBase, ForwarderRegistryContextBase {
    using ERC20PermitStorage for ERC20PermitStorage.Layout;
    using ProxyAdminStorage for ProxyAdminStorage.Layout;

    constructor(IForwarderRegistry forwarderRegistry) ForwarderRegistryContextBase(forwarderRegistry) {}

    /// @notice Marks the following ERC165 interface(s) as supported: ERC20Permit.
    /// @dev Reverts if the sender is not the proxy admin.
    function initERC20PermitStorage() external {
        ProxyAdminStorage.layout().enforceIsProxyAdmin(_msgSender());
        ERC20PermitStorage.init();
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