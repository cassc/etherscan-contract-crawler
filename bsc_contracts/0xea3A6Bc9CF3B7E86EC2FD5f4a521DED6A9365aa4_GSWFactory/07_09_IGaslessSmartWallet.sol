// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IGaslessSmartWallet {
    /// @notice an executable action via low-level call, including target, data and value
    struct Action {
        address target; // the targets to execute the actions on
        bytes data; // the data to be passed to the .call for each target
        uint256 value; // the msg.value to be passed to the .call for each target. set to 0 if none
    }

    /// @notice             GSW owner
    function owner() external view returns (address);

    /// @notice             Domain separator name for signatures
    function DOMAIN_SEPARATOR_NAME() external view returns (string memory);

    /// @notice             Domain separator version for signatures
    function DOMAIN_SEPARATOR_VERSION() external view returns (string memory);

    /// @notice             incrementing nonce for each valid tx executed (to ensure unique)
    function gswNonce() external view returns (uint256);

    /// @notice             initializer called by GSWFactory after deployment
    /// @param owner_       the owner (immutable) of this smart wallet
    function initialize(address owner_) external;

    /// @notice             returns the domainSeparator for EIP712 signature
    /// @return             the bytes32 domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice             Verify the transaction is valid and can be executed.
    ///                     Does not revert and returns successfully if the input is valid.
    ///                     Reverts if any validation has failed. For instance, if params or either signature or gswNonce are incorrect.
    /// @param actions_     the actions to execute (target, data, value)
    /// @param validUntil_  As EIP-2770: the highest block number the request can be forwarded in, or 0 if request validity is not time-limited
    ///                     Protects against relayers executing a certain transaction at a later moment not intended by the user, where it might
    ///                     have a completely different effect. (Given that the transaction is not executed right away for some reason)
    /// @param gas_         As EIP-2770: an amount of gas limit to set for the execution
    ///                     Protects gainst potential gas griefing attacks / the relayer getting a reward without properly executing the tx completely
    ///                     See https://ronan.eth.limo/blog/ethereum-gas-dangers/
    /// @param source_      Source like e.g. referral for this tx
    /// @param metadata_    Optional metadata for future flexibility
    /// @param signature_   the EIP712 signature, see verifySig method
    /// @return             returns true if everything is valid, otherwise reverts
    function verify(
        Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) external view returns (bool);

    /// @notice               executes arbitrary actions according to datas on targets
    ///                       if one action fails, the transaction doesn't revert. Instead the CastFailed event is emitted
    ///                       and all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                  validates EIP712 signature then executes a .call for every action.
    /// @param actions_       the actions to execute (target, data, value)
    /// @param validUntil_    As EIP-2770: the highest block number the request can be forwarded in, or 0 if request validity is not time-limited
    ///                       Protects against relayers executing a certain transaction at a later moment not intended by the user, where it might
    ///                       have a completely different effect. (Given that the transaction is not executed right away for some reason)
    /// @param gas_           As EIP-2770: an amount of gas limit to set for the execution
    ///                       Protects gainst potential gas griefing attacks / the relayer getting a reward without properly executing the tx completely
    ///                       See https://ronan.eth.limo/blog/ethereum-gas-dangers/
    /// @param source_        Source like e.g. referral for this tx
    /// @param metadata_      Optional metadata for future flexibility
    /// @param signature_     the EIP712 signature, see verifySig method
    /// @return success       true if all actions were executed succesfully, false otherwise.
    /// @return revertReason  revert reason if one of the actions fail
    function cast(
        Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) external payable returns (bool success, string memory revertReason);
}