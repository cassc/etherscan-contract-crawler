// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IAccountBoundToken
/// @author Clique
/// @custom:coauthor Ollie (eillo.eth)
/// @custom:coauthor Depetrol
interface IAccountBoundToken {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error AccountBound();
    error Revoked(address account, uint256 id);
    error AlreadyIssued(address account, uint256 id);
    error AccessRestricted(address account);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev This emits when a new token is created and bound to an account by
    /// any mechanism.
    event Attest(address indexed to, uint256 indexed tokenId);

    /// @dev This emits when an existing ABT is revoked from an account and
    /// burnt.
    event Revoke(address indexed to, uint256 indexed tokenId);

    /// @dev This emits when updating the credential URL of an ABT.
    /// @param account The account that owns the ABT.
    /// @param id The ID of the ABT.
    /// @param credentialURL The new credential URL.
    event UpdateCredential(
        address indexed account,
        uint256 indexed id,
        string credentialURL
    );

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    EXTERNAL FUNCTIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Issues an ABT with the given id to the given account.
    /// @param account The account to issue the ABT to.
    /// @param id The id of the ABT being issued.
    /// @param credentialURL The URL of the credential that the ABT is bound to.
    function issue(
        address account,
        uint256 id,
        string memory credentialURL
    ) external;

    /// @notice Updates the credential URL of an ABT.
    /// @param account The account that owns the ABT.
    /// @param id The id of the ABT to be updated.
    /// @param credentialURL The new credential URL.
    function update(
        address account,
        uint256 id,
        string memory credentialURL
    ) external;

    /// @notice Burns token with given id. At any time, an ABT
    /// receiver must be able to disassociate themselves from an ABT
    /// publicly through calling this function.
    /// @dev Must emit a `event Revoke` with the `address to` field pointing to
    ///  the zero address.
    /// @param account The address of the owner of the ABT.
    /// @param id The identifier for an ABT
    function burn(address account, uint256 id) external;

    /// @notice Checks if an account is an owner of a token.
    /// @param account The address of the owner
    /// @param tokenId The identifier for an ABT
    /// @return The address of the owner bound to the ABT
    function ownerOf(address account, uint256 tokenId)
        external
        view
        returns (bool);
}