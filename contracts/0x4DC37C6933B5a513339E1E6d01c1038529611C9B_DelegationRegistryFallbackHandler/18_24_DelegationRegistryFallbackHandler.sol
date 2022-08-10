// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "./CompatibilityFallbackHandler.sol";
import "../interfaces/IDelegationRegistry.sol";
import {ECDSA} from "@openzeppelin/contracts/cryptography/ECDSA.sol";

/// @title Delegation Registry Fallback Handler - fallback handler to provider delegate ownership of a safe to 3rd parties
/// @author Emiliano Bonassi - <[email protected]>
contract DelegationRegistryFallbackHandler is CompatibilityFallbackHandler {

    using ECDSA for bytes32;

    address public immutable delegationRegistry;

    constructor(address delegationRegistry_) {
        delegationRegistry = delegationRegistry_;
    }

    /**
     * Implementation EIP-1271 checking Delegation Registry
     * @dev check if anyone is delegated, if not fallback on usual implementation
     * @param _dataHash Hash of the data signed on the behalf of address(msg.sender)
     * @param _signature Signature byte array associated with _dataHash
     * @return a bool upon valid or invalid signature with corresponding _dataHash
     */
    function isValidSignature(bytes32 _dataHash, bytes calldata _signature) public view override virtual returns (bytes4) {
        // get delegate from the registry
        address delegate = IDelegationRegistry(delegationRegistry).delegateOf(msg.sender);

        if (delegate != address(0)) {
            // check signature and if corresponds to delegate returns *true*
            address signer = _dataHash.recover(_signature);
            return delegate == signer ? UPDATED_MAGIC_VALUE : bytes4(0);
        } else {
            // no delegate set, previous flow
            return super.isValidSignature(_dataHash, _signature);
        }
    }
}