// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IForwarderRegistry} from "./../../metatx/interfaces/IForwarderRegistry.sol";
import {ProxyAdminStorage} from "./../libraries/ProxyAdminStorage.sol";
import {ProxyAdminBase} from "./../base/ProxyAdminBase.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ForwarderRegistryContextBase} from "./../../metatx/base/ForwarderRegistryContextBase.sol";

/// @title ERC1967 Standard Proxy Storage Slots, Admin Address (facet version).
/// @dev See https://eips.ethereum.org/EIPS/eip-1967
/// @dev This contract is to be used as a diamond facet (see ERC2535 Diamond Standard https://eips.ethereum.org/EIPS/eip-2535).
contract ProxyAdminFacet is ProxyAdminBase, ForwarderRegistryContextBase {
    using ProxyAdminStorage for ProxyAdminStorage.Layout;

    constructor(IForwarderRegistry forwarderRegistry) ForwarderRegistryContextBase(forwarderRegistry) {}

    /// @notice Initializes the storage with an initial admin.
    /// @notice Sets the proxy initialization phase to `1`.
    /// @dev Reverts if the proxy initialization phase is set to `1` or above.
    /// @dev Emits an {AdminChanged} event if `initialAdmin` is not the zero address.
    /// @param initialAdmin The initial payout wallet.
    function initProxyAdminStorage(address initialAdmin) external {
        ProxyAdminStorage.layout().proxyInit(initialAdmin);
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