// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAvoWalletV2 {
    /// @notice an executable action via low-level call, including operation (call or delegateCall), target, data and value
    struct Action {
        address target; // the targets to execute the actions on
        bytes data; // the data to be passed to the call for each target
        uint256 value; // the msg.value to be passed to the call for each target. set to 0 if none
        uint256 operation; // 0 -> .call; 1 -> .delegateCall, 2 -> flashloan (via .call), id must be 0 or 2
    }

    struct CastParams {
        /// @param validUntil     As EIP-2770: the highest block number the request can be forwarded in, or 0 if request validity is not time-limited
        ///                       Protects against relayers executing a certain transaction at a later moment not intended by the user, where it might
        ///                       have a completely different effect. (Given that the transaction is not executed right away for some reason)
        uint256 validUntil;
        /// @param gas            As EIP-2770: an amount of gas limit to set for the execution
        ///                       Protects gainst potential gas griefing attacks / the relayer getting a reward without properly executing the tx completely
        ///                       See https://ronan.eth.limo/blog/ethereum-gas-dangers/
        uint256 gas;
        /// @param source         Source like e.g. referral for this tx
        address source;
        /// @param id             id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall), 20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
        uint256 id;
        /// @param metadata       Optional metadata for future flexibility
        bytes metadata;
    }

    /// @notice struct containing variables in storage for a snapshot
    struct StorageSnapshot {
        address avoWalletImpl;
        uint88 avoSafeNonce;
        address owner;
    }

    /// @notice             AvoSafe Owner
    function owner() external view returns (address);

    /// @notice             Domain separator name for signatures
    function DOMAIN_SEPARATOR_NAME() external view returns (string memory);

    /// @notice             Domain separator version for signatures
    function DOMAIN_SEPARATOR_VERSION() external view returns (string memory);

    /// @notice             incrementing nonce for each valid tx executed (to ensure unique)
    function avoSafeNonce() external view returns (uint88);

    /// @notice             initializer called by AvoFactory after deployment
    /// @param owner_       the owner (immutable) of this smart wallet
    function initialize(address owner_) external;

    /// @notice                     initialize contract and set new AvoWallet version
    /// @param owner_               the owner (immutable) of this smart wallet
    /// @param avoWalletVersion_    version of AvoWallet logic contract to deploy
    function initializeWithVersion(address owner_, address avoWalletVersion_) external;

    /// @notice             returns the domainSeparator for EIP712 signature
    /// @return             the bytes32 domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice               Verify the transaction is valid and can be executed.
    ///                       Does not revert and returns successfully if the input is valid.
    ///                       Reverts if any validation has failed. For instance, if params or either signature or avoSafeNonce are incorrect.
    /// @param actions_       the actions to execute (target, data, value)
    /// @param params_        Cast params: validUntil, gas, source, id and metadata
    /// @param signature_     the EIP712 signature, see verifySig method
    /// @return               returns true if everything is valid, otherwise reverts
    function verify(
        Action[] calldata actions_,
        CastParams calldata params_,
        bytes calldata signature_
    ) external view returns (bool);

    /// @notice               executes arbitrary actions according to datas on targets
    ///                       if one action fails, the transaction doesn't revert. Instead the CastFailed event is emitted
    ///                       and all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                  validates EIP712 signature then executes a .call or .delegateCall for every action.
    /// @param actions_       the actions to execute (target, data, value)
    /// @param params_        Cast params: validUntil, gas, source, id and metadata
    /// @param signature_     the EIP712 signature, see verifySig method
    /// @return success       true if all actions were executed succesfully, false otherwise.
    /// @return revertReason  revert reason if one of the actions fail
    function cast(
        Action[] calldata actions_,
        CastParams calldata params_,
        bytes calldata signature_
    ) external payable returns (bool success, string memory revertReason);
}