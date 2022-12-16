// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {ProxyInitialization} from "./../../proxy/libraries/ProxyInitialization.sol";

library PayoutWalletStorage {
    using PayoutWalletStorage for PayoutWalletStorage.Layout;

    struct Layout {
        address payable wallet;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.payment.PayoutWallet.storage")) - 1);
    bytes32 internal constant PROXY_INIT_PHASE_SLOT = bytes32(uint256(keccak256("animoca.core.payment.PayoutWallet.phase")) - 1);

    event PayoutWalletSet(address payoutWallet);

    /// @notice Initializes the storage with an initial payout wallet (immutable version).
    /// @dev Note: This function should be called ONLY in the constructor of an immutable (non-proxied) contract.
    /// @dev Reverts if `initialPayoutWallet` is the zero address.
    /// @dev Emits a {PayoutWalletSet} event.
    /// @param initialPayoutWallet The initial payout wallet.
    function constructorInit(Layout storage s, address payable initialPayoutWallet) internal {
        s.setPayoutWallet(initialPayoutWallet);
    }

    /// @notice Initializes the storage with an initial payout wallet (proxied version).
    /// @notice Sets the proxy initialization phase to `1`.
    /// @dev Note: This function should be called ONLY in the init function of a proxied contract.
    /// @dev Reverts if the proxy initialization phase is set to `1` or above.
    /// @dev Reverts if `initialPayoutWallet` is the zero address.
    /// @dev Emits a {PayoutWalletSet} event.
    /// @param initialPayoutWallet The initial payout wallet.
    function proxyInit(Layout storage s, address payable initialPayoutWallet) internal {
        ProxyInitialization.setPhase(PROXY_INIT_PHASE_SLOT, 1);
        s.setPayoutWallet(initialPayoutWallet);
    }

    /// @notice Sets the payout wallet.
    /// @dev Reverts if `newPayoutWallet` is the zero address.
    /// @dev Emits a {PayoutWalletSet} event.
    /// @param newPayoutWallet The payout wallet.
    function setPayoutWallet(Layout storage s, address payable newPayoutWallet) internal {
        require(newPayoutWallet != address(0), "PayoutWallet: zero address");
        s.wallet = newPayoutWallet;
        emit PayoutWalletSet(newPayoutWallet);
    }

    /// @notice Gets the payout wallet.
    /// @return wallet The payout wallet.
    function payoutWallet(Layout storage s) internal view returns (address payable) {
        return s.wallet;
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}