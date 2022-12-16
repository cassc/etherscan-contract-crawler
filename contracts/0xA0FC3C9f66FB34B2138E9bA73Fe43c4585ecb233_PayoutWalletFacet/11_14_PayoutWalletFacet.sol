// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IForwarderRegistry} from "./../../metatx/interfaces/IForwarderRegistry.sol";
import {PayoutWalletStorage} from "./../libraries/PayoutWalletStorage.sol";
import {ProxyAdminStorage} from "./../../proxy/libraries/ProxyAdminStorage.sol";
import {PayoutWalletBase} from "./../base/PayoutWalletBase.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ForwarderRegistryContextBase} from "./../../metatx/base/ForwarderRegistryContextBase.sol";

/// @title Payout wallet (facet version).
/// @dev This contract is to be used as a diamond facet (see ERC2535 Diamond Standard https://eips.ethereum.org/EIPS/eip-2535).
/// @dev Note: This facet depends on {ProxyAdminFacet} and {ContractOwnershipFacet}.
contract PayoutWalletFacet is PayoutWalletBase, ForwarderRegistryContextBase {
    using ProxyAdminStorage for ProxyAdminStorage.Layout;
    using PayoutWalletStorage for PayoutWalletStorage.Layout;

    constructor(IForwarderRegistry forwarderRegistry) ForwarderRegistryContextBase(forwarderRegistry) {}

    /// @notice Initializes the storage with an initial payout wallet.
    /// @notice Sets the proxy initialization phase to `1`.
    /// @dev Reverts if the sender is not the proxy admin.
    /// @dev Reverts if the proxy initialization phase is set to `1` or above.
    /// @dev Reverts if `initialPayoutWallet` is the zero address.
    /// @dev Emits a {PayoutWalletSet} event.
    /// @param initialPayoutWallet The initial payout wallet.
    function initPayoutWalletStorage(address payable initialPayoutWallet) external {
        ProxyAdminStorage.layout().enforceIsProxyAdmin(_msgSender());
        PayoutWalletStorage.layout().proxyInit(initialPayoutWallet);
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