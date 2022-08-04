// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import {ICrossDomainMessenger} from "./interfaces/ICrossDomainMessenger.sol";

/// @dev Helper contract for contracts performing cross-domain communications
contract CrossDomainEnabled {
    /// @notice Messenger contract used to send and receive messages from the other domain
    ICrossDomainMessenger public immutable messenger;

    /// @param messenger_ Address of the CrossDomainMessenger on the current layer
    constructor(address messenger_) {
        messenger = ICrossDomainMessenger(messenger_);
    }

    /// @dev Sends a message to an account on another domain
    /// @param crossDomainTarget_ Intended recipient on the destination domain
    /// @param message_ Data to send to the target (usually calldata to a function with
    ///     `onlyFromCrossDomainAccount()`)
    /// @param gasLimit_ gasLimit for the receipt of the message on the target domain.
    function sendCrossDomainMessage(
        address crossDomainTarget_,
        uint32 gasLimit_,
        bytes memory message_
    ) internal {
        messenger.sendMessage(crossDomainTarget_, message_, gasLimit_);
    }

    /// @dev Enforces that the modified function is only callable by a specific cross-domain account
    /// @param sourceDomainAccount_ The only account on the originating domain which is
    ///     authenticated to call this function
    modifier onlyFromCrossDomainAccount(address sourceDomainAccount_) {
        if (msg.sender != address(messenger)) {
            revert ErrorUnauthorizedMessenger();
        }
        if (messenger.xDomainMessageSender() != sourceDomainAccount_) {
            revert ErrorWrongCrossDomainSender();
        }
        _;
    }

    error ErrorUnauthorizedMessenger();
    error ErrorWrongCrossDomainSender();
}