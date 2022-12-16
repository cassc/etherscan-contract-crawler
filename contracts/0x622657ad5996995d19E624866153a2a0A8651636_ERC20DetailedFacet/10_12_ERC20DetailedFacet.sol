// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IForwarderRegistry} from "./../../../metatx/interfaces/IForwarderRegistry.sol";
import {ERC20DetailedStorage} from "./../libraries/ERC20DetailedStorage.sol";
import {ProxyAdminStorage} from "./../../../proxy/libraries/ProxyAdminStorage.sol";
import {ERC20DetailedBase} from "./../base/ERC20DetailedBase.sol";
import {ForwarderRegistryContextBase} from "./../../../metatx/base/ForwarderRegistryContextBase.sol";

/// @title ERC20 Fungible Token Standard, optional extension: Detailed (facet version).
/// @dev This contract is to be used as a diamond facet (see ERC2535 Diamond Standard https://eips.ethereum.org/EIPS/eip-2535).
/// @dev Note: This facet depends on {ProxyAdminFacet} and {InterfaceDetectionFacet}.
contract ERC20DetailedFacet is ERC20DetailedBase, ForwarderRegistryContextBase {
    using ERC20DetailedStorage for ERC20DetailedStorage.Layout;
    using ProxyAdminStorage for ProxyAdminStorage.Layout;

    constructor(IForwarderRegistry forwarderRegistry) ForwarderRegistryContextBase(forwarderRegistry) {}

    /// @notice Initializes the storage with the token details.
    /// @notice Sets the proxy initialization phase to `1`.
    /// @notice Marks the following ERC165 interface(s) as supported: ERC20Detailed.
    /// @dev Reverts if the sender is not the proxy admin.
    /// @dev Reverts if the proxy initialization phase is set to `1` or above.
    /// @param tokenName The token name.
    /// @param tokenSymbol The token symbol.
    /// @param tokenDecimals The token decimals.
    function initERC20DetailedStorage(string calldata tokenName, string calldata tokenSymbol, uint8 tokenDecimals) external {
        ProxyAdminStorage.layout().enforceIsProxyAdmin(_msgSender());
        ERC20DetailedStorage.layout().proxyInit(tokenName, tokenSymbol, tokenDecimals);
    }
}