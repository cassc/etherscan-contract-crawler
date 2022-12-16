// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IForwarderRegistry} from "./../../metatx/interfaces/IForwarderRegistry.sol";
import {PauseStorage} from "./../libraries/PauseStorage.sol";
import {ProxyAdminStorage} from "./../../proxy/libraries/ProxyAdminStorage.sol";
import {PauseBase} from "./../base/PauseBase.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ForwarderRegistryContextBase} from "./../../metatx/base/ForwarderRegistryContextBase.sol";

/// @title Pausing mechanism (facet version).
/// @dev This contract is to be used as a diamond facet (see ERC2535 Diamond Standard https://eips.ethereum.org/EIPS/eip-2535).
/// @dev Note: This facet depends on {ProxyAdminFacet} and {ContractOwnershipFacet}.
contract PauseFacet is PauseBase, ForwarderRegistryContextBase {
    using ProxyAdminStorage for ProxyAdminStorage.Layout;
    using PauseStorage for PauseStorage.Layout;

    constructor(IForwarderRegistry forwarderRegistry) ForwarderRegistryContextBase(forwarderRegistry) {}

    /// @notice Initializes the storage with an initial pause state.
    /// @notice Sets the proxy initialization phase to `1`.
    /// @dev Reverts if the caller is not the proxy admin.
    /// @dev Reverts if the proxy initialization phase is set to `1` or above.
    /// @dev Emits a {Paused} event if `isPaused` is true.
    /// @param isPaused The initial pause state.
    function initPauseStorage(bool isPaused) external {
        ProxyAdminStorage.layout().enforceIsProxyAdmin(_msgSender());
        PauseStorage.layout().proxyInit(isPaused);
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