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
import {MerkleProofLib} from "@metalabel/solmate/src/utils/MerkleProofLib.sol";
import {IAccountRegistry} from "./interfaces/IAccountRegistry.sol";
import {INodeRegistry, NodeType} from "./interfaces/INodeRegistry.sol";
import {SequenceData} from "./interfaces/IEngine.sol";
import {CollectionFactory, CreateCollectionConfig} from "./CollectionFactory.sol";
import {MembershipsFactory, CreateMembershipsConfig} from "./MembershipsFactory.sol";
import {Memberships, AdminMembershipMint} from "./Memberships.sol";
import {Collection} from "./Collection.sol";

/// @notice Information provided by the Metalabel core team when issuing a new
/// account via this controller
struct IssueAccountConfig {
    address subject;
    string metadata;
}

/// @notice Information provided when setting up a metalabel
struct SetupMetalabelConfig {
    uint64 metalabelNodeId;
    string subdomain;
    string collectionName;
    string collectionSymbol;
    string collectionContractURI;
    string collectionMetadata;
    string membershipsName;
    string membershipsSymbol;
    string membershipsBaseURI;
    string membershipsMetadata;
    bytes32 membershipsListRoot;
    AdminMembershipMint[] members;
    bytes32[] proof;
}

/// @notice Data used when configuring new sequences when publishing a release
struct SequenceConfig {
    SequenceData sequenceData;
    bytes engineData;
}

/// @notice Information provided when publishing a new release
struct PublishReleaseConfig {
    uint64 metalabelNodeId;
    string releaseMetadata;
    Collection recordCollection;
    SequenceConfig[] sequences;
}

/// @notice Controller that batches steps required for launching a metalabel,
/// publishing a release, and allowlisting new accounts.
contract ControllerV1 is Owned {
    // ---
    // Errors
    // ---

    /// @notice Happens if a metalabel is attempted to be setup more than once
    error SubdomainAlreadyReserved();

    /// @notice An invalid merkle proof was provided
    error InvalidProof();

    /// @notice An action was attempted by a msg.sender that is not authorized
    /// for a node.
    error NotAuthorized();

    // ---
    // Events
    // ---

    /// @notice A subdomain was reserved for a metalabel
    event SubdomainReserved(uint64 indexed metalabelNodeId, string subdomain);

    /// @notice The allowlist root was updated
    event AllowlistRootUpdated(bytes32 allowlistRoot);

    // ---
    // Storage
    // ---

    /// @notice Reference to the node registry of the protocol.
    INodeRegistry public immutable nodeRegistry;

    /// @notice Reference to the account registry of the protocol.
    IAccountRegistry public immutable accountRegistry;

    /// @notice Reference to the collection factory of the protocol.
    CollectionFactory public immutable collectionFactory;

    /// @notice Reference to the memberships factory of the protocol.
    MembershipsFactory public immutable membershipsFactory;

    /// @notice Mapping of subdomains to metalabel node IDs - used to check if
    /// the subdomain has already been reserved
    mapping(string => uint64) public subdomains;

    /// @notice The merkle root of the allowlist tree
    bytes32 public allowlistRoot;

    constructor(
        INodeRegistry _nodeRegistry,
        IAccountRegistry _accountRegistry,
        CollectionFactory _collectionFactory,
        MembershipsFactory _membershipsFactory,
        address _contractOwner
    ) Owned(_contractOwner) {
        nodeRegistry = _nodeRegistry;
        accountRegistry = _accountRegistry;
        collectionFactory = _collectionFactory;
        membershipsFactory = _membershipsFactory;
    }

    // ---
    // Admin / owner functionality
    // ---

    /// @notice Update the allowlist root and issue any accounts. This method is
    /// called by the metalabel core team to create new accounts for admins and
    /// allowlist setting up their metalabels.
    /// @dev This contract will be added as an authorized account issuer in
    /// AccountRegistry. This means whoever is the owner of this contract can
    /// use this function to issue accounts to _any_ address they want, which is
    /// fine (both will be controlled internally by the same address).
    /// This is only needed because account issuance in AccountRegistry is
    /// currently permissioned. If the protocol is switched to permissionless
    /// account issuance, this method will no longer be needed
    function updateAllowlist(
        bytes32 _allowlistRoot,
        IssueAccountConfig[] calldata accountsToIssue
    ) external onlyOwner {
        // Update root
        allowlistRoot = _allowlistRoot;
        emit AllowlistRootUpdated(_allowlistRoot);

        for (uint256 i = 0; i < accountsToIssue.length; i++) {
            accountRegistry.createAccount(
                accountsToIssue[i].subject,
                accountsToIssue[i].metadata
            );
        }
    }

    // ---
    // Metalabel functionality
    // ---

    /// @notice Setup a metalabel. Happens after the admin has already had an
    /// account created for this and has created the metalabel node themselves
    /// by directly interacting with NodeRegistry. The admin must have this
    /// contract set as an authorized controller for this method to work.
    /// - Assert msg.sender and subdomain are on the allowlist via merkle proof
    /// - Assert msg.sender can manage the metalabel node
    /// - Mark the subdomain as reserved
    /// - Launch the record collection
    /// - Launch the memberships collection (if merkle root is not zero)
    /// - Mint initial membership NFTs (if merkle root is not zero)
    function setupMetalabel(SetupMetalabelConfig calldata config)
        external
        returns (Collection recordCollection, Memberships memberships)
    {
        // Assert setup is allowed - sender must provide a merkle proof of their
        // (subdomain, admin) pair.
        bool isValid = MerkleProofLib.verify(
            config.proof,
            allowlistRoot,
            keccak256(abi.encodePacked(config.subdomain, msg.sender))
        );
        if (!isValid) {
            revert InvalidProof();
        }

        // Assert that msg.sender can manage the metalabel. Since this is an
        // authorized controller, we cannot skip checking authorization since
        // several nodes may have authorized this address
        if (
            !nodeRegistry.isAuthorizedAddressForNode(
                config.metalabelNodeId,
                msg.sender
            )
        ) {
            revert NotAuthorized();
        }

        // Assert not yet setup and mark the subdomain as reserved for this
        // metalabel. This is read offchain for the frontend to know what
        // subdomain belongs to what metalabel.
        if (subdomains[config.subdomain] != 0) {
            revert SubdomainAlreadyReserved();
        }
        subdomains[config.subdomain] = config.metalabelNodeId;
        emit SubdomainReserved(config.metalabelNodeId, config.subdomain);

        // Deploy the record collection. We already know msg.sender is
        // authorized to manage the metalabel node, so no additional checks are
        // required here. The control node is set to the metalabel, so access
        // control is inherited from the metalabel.
        recordCollection = collectionFactory.createCollection(
            CreateCollectionConfig({
                name: config.collectionName,
                symbol: config.collectionSymbol,
                contractURI: config.collectionContractURI,
                owner: msg.sender,
                controlNodeId: config.metalabelNodeId,
                metadata: config.collectionMetadata
            })
        );

        // If the memberships list root is 0, then skip deploying the membership
        // collection
        if (config.membershipsListRoot == 0) {
            // memberships will be the zero address since it wasn't deployed
            return (recordCollection, memberships);
        }

        // Deploy the memberships collection. We already know msg.sender is
        // authorized to manage the metalabel node, so no additional checks are
        // required here. The control node is set to the metalabel, so access
        // control is inherited from the metalabel security.
        memberships = membershipsFactory.createMemberships(
            CreateMembershipsConfig({
                name: config.membershipsName,
                symbol: config.membershipsSymbol,
                baseURI: config.membershipsBaseURI,
                owner: msg.sender,
                controlNodeId: config.metalabelNodeId,
                metadata: config.membershipsMetadata
            })
        );

        // Admin mint the initial memberships and set the starting Merkle root.
        // Members could be empty if instead individual members will mint their
        // own memberships (using a Merkle proof). This contract can call this
        // function because its authorized to manage the membership's control
        // node (the metalabel).
        memberships.updateMemberships(
            config.membershipsListRoot,
            config.members,
            new uint256[](0)
        );
    }

    /// @notice Publish a release and configure a new DropEngineV2 sequence.
    /// This happens after a metalabel has already been launched by an admin and
    /// setup using the above method. The admin must have this contract set as
    /// an authorized controller for this method to work.
    function publishRelease(PublishReleaseConfig calldata config)
        external
        returns (uint64 releaseNodeId)
    {
        // Ensure that msg.sender can actually manage the metalabel node. Since
        // this is an authorized controller, we cannot skip checking
        // authorization since several nodes may have authorized this address
        if (
            !nodeRegistry.isAuthorizedAddressForNode(
                config.metalabelNodeId,
                msg.sender
            )
        ) {
            revert NotAuthorized();
        }

        // Create the release node as a child node to the metalabel. Node owner
        // is set to zero while group node is set to the metalabel, allowing
        // access control to be inherited from the metalabel node.
        // Also not adding this controller to the list of controllers for the
        // node - we are fully relying on the group node for access control.
        // We already checked that msg.sender is authorized to manage the
        // metalabel, so no additional checks are required for this call.
        releaseNodeId = nodeRegistry.createNode(
            NodeType.RELEASE,
            0, /* no owner - access control comes from the group */
            config.metalabelNodeId, /* parent = metalabel */
            config.metalabelNodeId, /* group = metalabel */
            new address[](0), /* no controllers, access control comes from the group */
            config.releaseMetadata
        );

        // Assert sender can manage the record collection. Similar to above, we
        // must do this check since this controller may be authorized by several
        // metalabels. If the sender used setupMetalabel, then this check will
        // always return true, but we still check in case there was another
        // collection setup outside of this controller.
        if (
            !nodeRegistry.isAuthorizedAddressForNode(
                config.recordCollection.controlNode(),
                msg.sender
            )
        ) {
            revert NotAuthorized();
        }

        // A release may have zero or more sequences created at the same time
        // the catalog node is created.
        for (uint256 i = 0; i < config.sequences.length; i++) {
            // Overrwrite the release node ID to reference the release node we
            // just created, attaching this sequence to the new release. We do
            // this instead of allowing the caller to specify the release node
            // to ensure the sequences created via publishRelease are always
            // attached to the release node created by this method.
            SequenceData memory sequenceData = config.sequences[i].sequenceData;
            sequenceData.dropNodeId = releaseNodeId;

            // Setup the new drop. We don't need to do any access checks since
            // the drop node is the new release node. Since the release node has
            // the metalabel as a group node, the release node inherits the same
            // access control (so this controller can create a new drop for it).
            config.recordCollection.configureSequence(
                sequenceData,
                config.sequences[i].engineData
            );
        }
    }
}