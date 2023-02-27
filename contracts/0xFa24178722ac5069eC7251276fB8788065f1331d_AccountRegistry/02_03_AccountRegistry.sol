// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*

███╗   ███╗███████╗████████╗ █████╗ ██╗      █████╗ ██████╗ ███████╗██╗
████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██║     ██╔══██╗██╔══██╗██╔════╝██║
██╔████╔██║█████╗     ██║   ███████║██║     ███████║██████╔╝█████╗  ██║
██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║     ██╔══██║██╔══██╗██╔══╝  ██║
██║ ╚═╝ ██║███████╗   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗███████╗
╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝


Deployed by Metalabel with 💖 as a permanent application on the Ethereum blockchain.

Metalabel is a growing universe of tools, knowledge, and resources for
metalabels and cultural collectives.

Our purpose is to establish the metalabel as key infrastructure for creative
collectives and to inspire a new culture of creative collaboration and mutual
support.

OUR SQUAD

Anna Bulbrook (Curator)
Austin Robey (Community)
Brandon Valosek (Engineer)
Ilya Yudanov (Designer)
Lauren Dorman (Engineer)
Rob Kalin (Board)
Yancey Strickler (Director)

https://metalabel.xyz

*/

import {Owned} from "@metalabel/solmate/src/auth/Owned.sol";
import {IAccountRegistry} from "./interfaces/IAccountRegistry.sol";

/// @notice The account registry manages mappings from an address to an account
/// ID.
/// - Accounts are identified by a uint64 ID
/// - Accounts are owned by an address
/// - Accounts can broadcast arbitrary strings, keyed by a topic, as blockchain
///   events
/// - Account issuance starts permissioned, but can be made permanently public
///   once the contract owner is removed
contract AccountRegistry is IAccountRegistry, Owned {
    // ---
    // Events
    // ---

    /// @notice A new account was created
    event AccountCreated(
        uint64 indexed id,
        address indexed subject,
        string metadata
    );

    /// @notice Broadcast a message from an account
    event AccountBroadcast(uint64 indexed id, string topic, string message);

    /// @notice An account's address has changed
    event AccountTransferred(uint64 indexed id, address newOwner);

    /// @notice A new address has been authorized or un-authorized to issue
    /// accounts
    event AccountIssuerSet(address indexed issuer, bool authorized);

    // ---
    // Errors
    // ---

    /// @notice No account exists for msg.sender
    error NoAccount();

    /// @notice An account was created for an address that already has one.
    error AccountAlreadyExists();

    /// @notice Account issuance is not yet public and a non-issuer attempted to
    /// create an account.
    error NotAuthorizedAccountIssuer();

    // ---
    // Storage
    // ---

    /// @notice Total number of created accounts
    uint64 public totalAccountCount;

    /// @notice Mapping of addresses to account IDs.
    mapping(address => uint64) public accountIds;

    /// @notice Mapping from an address to a boolean indicating whether it is
    /// authorized to issue accounts.
    mapping(address => bool) public isAccountIssuer;

    // ---
    // Constructor
    // ---

    constructor(address _contractOwner) Owned(_contractOwner) {}

    // ---
    // Owner functionality
    // ---

    /// @notice Authorize or unauthorize an address to issue accounts.
    function setAccountIssuer(address issuer, bool authorized)
        external
        onlyOwner
    {
        isAccountIssuer[issuer] = authorized;
        emit AccountIssuerSet(issuer, authorized);
    }

    // ---
    // Account creation functionality
    // ---

    /// @inheritdoc IAccountRegistry
    function createAccount(address subject, string calldata metadata)
        external
        returns (uint64 id)
    {
        if (accountIds[subject] != 0) revert AccountAlreadyExists();

        // So long as an owner is set, account issuance is permissioned and
        // msg.sender must be an approved account issuer
        if (owner != address(0) && !isAccountIssuer[msg.sender]) {
            revert NotAuthorizedAccountIssuer();
        }

        // We don't care who msg.sender is if account issuance is open. This
        // means that anyone can create an account on behalf of another user,
        // but this has no security implications. Interacting with the protocol
        // still needs to come from the correct address, accounts in a way are
        // mostly to establish an abstraction around identity and reduce storage
        // costs.

        id = ++totalAccountCount;
        accountIds[subject] = id;
        emit AccountCreated(id, subject, metadata);
    }

    // ---
    // Account functionality
    // ---

    /// @notice Broadcast a message as an account.
    /// @dev This has no onchain functionality - it's a way to allow accounts to
    /// emit information on the blockchain that can be indexed and used in
    /// external applications.
    function broadcast(string calldata topic, string calldata message)
        external
    {
        uint64 id = accountIds[msg.sender];
        if (id == 0) revert NoAccount();

        emit AccountBroadcast(id, topic, message);
    }

    /// @notice Transfer the account to another address. Other address must not
    /// have an account, and msg.sender must currently own the account.
    function transferAccount(address newOwner) external {
        uint64 id = accountIds[msg.sender];
        if (id == 0) revert NoAccount();
        if (accountIds[newOwner] != 0) revert AccountAlreadyExists();

        accountIds[newOwner] = id;
        delete accountIds[msg.sender];
        emit AccountTransferred(id, newOwner);
    }

    // ---
    // Views
    // ---

    /// @inheritdoc IAccountRegistry
    function resolveId(address subject) external view returns (uint64 id) {
        id = accountIds[subject];
        if (id == 0) revert NoAccount();
    }

    /// @inheritdoc IAccountRegistry
    function unsafeResolveId(address subject)
        external
        view
        returns (uint64 id)
    {
        id = accountIds[subject];
    }
}