// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
    OSSubscribeFilter is a simple subscription for OpenSea's Filter Registry.
*/

interface iOperatorFilterRegistry {
    function isOperatorAllowed(address registrant_, address operator_) external 
        view returns (bool);
}

abstract contract OSSubscribeFilter {

    // Errors
    error OperatorNotAllowed(address operator);

    // Targets
    /** @dev Default OSRegistrantList is: 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6 */
    address public OSRegistrantList; 
    address public constant OSFilterRegistry =
        0x000000000000AAeB6D7670E522A718067333cd4E;

    // Setting the registrant list
    /** @dev Set the registrant_ to address(0) to disable OS Filtering. */
    function _setOSRegistrantList(address registrant_) internal {
        OSRegistrantList = registrant_;
    }

    // This is for TransferFroms
    modifier onlyAllowedOperator(address from_) virtual {
        // First, if from is the msg.sender, it is the owner and should be allowed.
        if (msg.sender == from_) {
            _;
            return;
        }

        // However, if from_ is not the msg.sender, means it's an approved operator
        // In this case, let's check if the operator is a smart contract.
        if (from_.code.length > 0) {
            // Here, we basically check if we have a Registrant List.
            // We don't subscribe, we just use someone else's subscription.
            address _OSRegistrant = OSRegistrantList;
            if (_OSRegistrant != address(0)) {
                // If we have a registrant list, let's check the filter registry
                // and read the list.
                if (!iOperatorFilterRegistry(OSFilterRegistry)
                    .isOperatorAllowed(_OSRegistrant, msg.sender)) {
                    // If the operator (msg.sender) is not allowed based on the list
                    // We revert with OperatorNotAllowed(address)
                    revert OperatorNotAllowed(msg.sender);
                }
            }
        }
        _;
    }

    // This is for Approves
    modifier onlyAllowedOperatorApproval(address operator_) virtual {
        // For an approval, we simply check the registry if the caller is able
        // to set any approval for the specified address.
        // Again, we use our checks to be able to disable and such.
        address _OSRegistrant = OSRegistrantList;
        if (_OSRegistrant != address(0)) {
            if (!iOperatorFilterRegistry(OSFilterRegistry)
                .isOperatorAllowed(_OSRegistrant, operator_)) {
                revert OperatorNotAllowed(operator_);
            }
        }
        _;
    }
}