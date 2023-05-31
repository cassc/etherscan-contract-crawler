// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IVanillaV1MigrationState {

    /// @notice The current Merkle tree root for checking the eligibility for token conversion
    /// @dev tree leaves are tuples of (VNLv1-owner-address, VNLv1-token-balance), ordered as keccak256(abi.encodePacked(tokenOwner, ":", amount))
    function stateRoot() external view returns (bytes32);

    /// @notice Gets the block.number which was used to calculate the `stateRoot()` (for off-chain verification)
    function blockNumber() external view returns (uint64);

    /// @notice Gets the current deadline for conversion as block.timestamp
    function conversionDeadline() external view returns (uint64);

    /// @notice Checks if `tokenOwner` owning `amount` of VNL v1s is eligible for token conversion. Needs a Merkle `proof`.
    /// @dev The proof must be generated from a Merkle tree where leaf data is formatted as "<address>:<VNL v1 balance>" before hashing,
    /// leaves and intermediate nodes are always hashed with keccak256 and then sorted.
    /// @param proof The proof that user is operating on the same state
    /// @param tokenOwner The address owning the VanillaV1Token01 tokens
    /// @param amount The amount of VanillaV1Token01 tokens (i.e. the balance of the tokenowner)
    /// @return true iff `tokenOwner` is eligible to convert `amount` tokens to VanillaV1Token02
    function verifyEligibility(bytes32[] memory proof, address tokenOwner, uint256 amount) external view returns (bool);

    /// @notice Updates the Merkle tree for provable ownership of convertible VNL v1 tokens. Only for the owner.
    /// @dev Moves also the internal deadline forward 30 days
    /// @param newStateRoot The new Merkle tree root for checking the eligibility for token conversion
    /// @param blockNum The block.number whose state was used to calculate the `newStateRoot`
    function updateConvertibleState(bytes32 newStateRoot, uint64 blockNum) external;

    /// @notice thrown if non-owners try to modify state
    error UnauthorizedAccess();

    /// @notice thrown if attempting to update migration state after conversion deadline
    error MigrationStateUpdateDisabled();
}

interface IVanillaV1Converter {
    /// @notice Gets the address of the migration state contract
    function migrationState() external view returns (IVanillaV1MigrationState);

    /// @dev Emitted when VNL v1.01 is converted to v1.02
    /// @param converter The owner of tokens.
    /// @param amount Number of converted tokens.
    event VNLConverted(address converter, uint256 amount);

    /// @notice Checks if all `msg.sender`s VanillaV1Token01's are eligible for token conversion. Needs a Merkle `proof`.
    /// @dev The proof must be generated from a Merkle tree where leaf data is formatted as "<address>:<VNL v1 balance>" before hashing, and leaves and intermediate nodes are always hashed with keccak256 and then sorted.
    /// @param proof The proof that user is operating on the same state
    /// @return convertible true if `msg.sender` is eligible to convert all VanillaV1Token01 tokens to VanillaV1Token02 and conversion window is open
    /// @return transferable true if `msg.sender`'s VanillaV1Token01 tokens are ready to be transferred for conversion
    function checkEligibility(bytes32[] memory proof) external view returns (bool convertible, bool transferable);

    /// @notice Converts _ALL_ `msg.sender`s VanillaV1Token01's to VanillaV1Token02 if eligible. The conversion is irreversible.
    /// @dev The proof must be generated from a Merkle tree where leaf data is formatted as "<address>:<VNL v1 balance>" before hashing, and leaves and intermediate nodes are always hashed with keccak256 and then sorted.
    /// @param proof The proof that user is operating on the same state
    function convertVNL(bytes32[] memory proof) external;

    /// @notice thrown when attempting to convert VNL after deadline
    error ConversionWindowClosed();

    /// @notice thrown when attempting to convert 0 VNL
    error NoConvertibleVNL();

    /// @notice thrown if for some reason VNL freezer balance doesn't match the transferred amount + old balance
    error FreezerBalanceMismatch();

    /// @notice thrown if for some reason user holds VNL v1 tokens after conversion (i.e. transfer failed)
    error UnexpectedTokensAfterConversion();

    /// @notice thrown if user provided incorrect proof for conversion eligibility
    error VerificationFailed();
}