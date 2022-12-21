// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { IGSWVersionsRegistry } from "../interfaces/IGSWVersionsRegistry.sol";
import { IGaslessSmartWallet } from "../interfaces/IGaslessSmartWallet.sol";

error GaslessSmartWallet__InvalidParams();

/// @title      VariablesV1
/// @notice     Contains storage variables for GSW.
abstract contract VariablesV1 is IGaslessSmartWallet {
    /// @notice address of the GSW logic / implementation contract. IMPORTANT: SAME STORAGE SLOT AS FOR PROXY
    /// @dev    IMPORTANT: DO NOT MOVE THIS VARIABLE
    ///         _gswImpl MUST ALWAYS be the first declared variable here in the logic contract and in the proxy!
    ///         when upgrading, the storage at memory address 0x0 is upgraded (first slot).
    address internal _gswImpl;

    /// @notice  registry holding the valid versions (addresses) for GSW implementation contracts
    ///          The registry is used to verify a valid version before upgrading
    ///          immutable but could be updated in the logic contract when a new version of GSW is deployed
    IGSWVersionsRegistry public immutable gswVersionsRegistry;

    /// @notice address of the GSWForwarder (proxy) that is allowed to forward tx with valid
    ///         signatures to this contract
    ///         immutable but could be updated in the logic contract when a new version of GSW is deployed
    address public immutable gswForwarder;

    /// @notice owner of the smart wallet
    /// @dev theoretically immutable, can only be set in initialize (at proxy clone factory deployment)
    address public owner;

    /// @notice nonce that it is incremented for every `cast` transaction with valid signature
    uint256 public gswNonce;

    /// @notice constructor sets the immutable gswVersionsRegistry address
    /// @dev    setting this on the logic contract at deployment is ok because the
    ///         GSWVersionsRegistry is upgradeable so the address set here is the proxy address
    ///         which really shouldn't change. Even if it would change then worst case
    ///         a new GaslessSmartWallet logic contract has to be deployed pointing to a new registry
    /// @param gswVersionsRegistry_    address of the gswVersionsRegistry contract
    /// @param gswForwarder_           address of the gswForwarder (proxy) contract
    ///                                to forward tx with valid signatures. must be valid version in GSWVersionsRegistry.
    constructor(IGSWVersionsRegistry gswVersionsRegistry_, address gswForwarder_) {
        if (address(gswVersionsRegistry_) == address(0)) {
            revert GaslessSmartWallet__InvalidParams();
        }
        gswVersionsRegistry = gswVersionsRegistry_;

        gswVersionsRegistry.requireValidGSWForwarderVersion(gswForwarder_);
        gswForwarder = gswForwarder_;
    }
}