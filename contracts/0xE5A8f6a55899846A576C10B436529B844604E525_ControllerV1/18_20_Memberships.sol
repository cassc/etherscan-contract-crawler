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

import {ERC721} from "@metalabel/solmate/src/tokens/ERC721.sol";
import {MerkleProofLib} from "@metalabel/solmate/src/utils/MerkleProofLib.sol";
import {SSTORE2} from "@metalabel/solmate/src/utils/SSTORE2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {INodeRegistry} from "./interfaces/INodeRegistry.sol";
import {Resource, AccessControlData} from "./Resource.sol";

/// @notice Immutable data stored per-collection.
/// @dev This is stored via SSTORE2 to save gas.
struct ImmutableCollectionData {
    string name;
    string symbol;
    string baseURI;
}

/// @notice Data required when doing a permissionless mint via proof.
struct MembershipMint {
    address to;
    uint16 sequenceId;
    bytes32[] proof;
}

/// @notice Data required when doing an admin mint.
/// @dev Admin mints do not require a providing a proof to keep gas down.
struct AdminMembershipMint {
    address to;
    uint16 sequenceId;
}

/// @notice Data for supply and next ID.
/// @dev Fits into a single storage slot to keep gas cost down during minting.
struct MembershipsState {
    uint128 totalSupply;
    uint128 totalMinted;
}

/// @notice Membership collections can have their metadata resolver set to an
/// external contract
/// @dev This is used to futureproof the membership collection -- if a squad
/// wants to move to a more onchain approach to membership metadata or have an
/// alternative renderer, this gives them the option
interface ICustomMetadataResolver {
    /// @notice Resolve the token URI for a collection / token.
    function tokenURI(address collection, uint256 tokenId)
        external
        view
        returns (string memory);

    /// @notice Resolve the collection URI for a collection.
    function contractURI(address collection)
        external
        view
        returns (string memory);
}

/// @notice An ERC721 collection of NFTs representing memberships.
/// - NFTs are non-transferable
/// - Each membership collection has a control node, determining who the admin is
/// - Admin can unilaterally mint and burn memberships, without proofs to keep
///   gas down.
/// - Admin can use a merkle root to set a large list of memberships that can be
///   minted by anyone with a valid proof to socialize gas
/// - Token URI computation defaults to baseURI + tokenID, but can be modified
///   by a future external metadata resolver contract that implements
///   ICustomMetadataResolver
/// - Each token stores the mint timestamp, as well as an arbitrary sequence ID.
///   Sequence ID has no onchain consequence, but can be set by the admin if
///   desired
contract Memberships is ERC721, Resource {
    // ---
    // Errors
    // ---

    /// @notice The init function was called more than once.
    error AlreadyInitialized();

    /// @notice Attempted to transfer a membership NFT.
    error TransferNotAllowed();

    /// @notice Attempted to mint an invalid membership.
    error InvalidMint();

    /// @notice Attempted to burn an invalid or unowned membership token.
    error InvalidBurn();

    /// @notice Attempted to admin transfer a membership to somebody who already has one.
    error InvalidTransfer();

    // ---
    // Events
    // ---

    /// @notice A new membership NFT was minted.
    /// @dev The underlying ERC721 implementation already emits a Transfer event
    /// on mint, this additional event announces the sequence ID and timestamp
    /// associated with that membership.
    event MembershipCreated(
        uint256 indexed tokenId,
        uint16 sequenceId,
        uint80 timestamp
    );

    /// @notice The merkle root of the membership list was updated.
    event MembershipListRootUpdated(bytes32 root);

    /// @notice The custom metadata resolver was updated.
    event CustomMetadataResolverUpdated(ICustomMetadataResolver resolver);

    /// @notice The owner address of this memberships collection was updated.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // ---
    // Storage
    // ---

    /// @notice Only for marketplace interop, can be set by owner of the control
    /// node.
    address public owner;

    /// @notice Merkle root of the membership list.
    bytes32 public membershipListRoot;

    /// @notice If a custom metadata resolver is set, it will be used to resolve
    /// tokenURI and collectionURI values
    ICustomMetadataResolver public customMetadataResolver;

    /// @notice Tracks total supply and next ID
    /// @dev These values are exposed via totalSupply and totalMinted views.
    MembershipsState internal membershipState;

    /// @notice The SSTORE2 storage pointer for immutable collection data.
    /// @dev These values are exposed via name/symbol/contractURI views.
    address internal immutableStoragePointer;

    // ---
    // Constructor
    // ---

    /// @dev Constructor only called during deployment of the implementation,
    /// all storage should be set up in init function which is called atomically
    /// after clone deployment
    constructor() {
        // Write dummy data to the immutable storage pointer to prevent
        // initialization of the implementation contract.
        immutableStoragePointer = SSTORE2.write(
            abi.encode(
                ImmutableCollectionData({name: "", symbol: "", baseURI: ""})
            )
        );
    }

    // ---
    // Clone init
    // ---

    /// @notice Initialize contract state.
    /// @dev Should be called immediately after deploying the clone in the same transaction.
    function init(
        address _owner,
        AccessControlData calldata _accessControl,
        string calldata _metadata,
        ImmutableCollectionData calldata _data
    ) external {
        if (immutableStoragePointer != address(0)) revert AlreadyInitialized();
        immutableStoragePointer = SSTORE2.write(abi.encode(_data));

        // Set ERC721 market interop.
        owner = _owner;
        emit OwnershipTransferred(address(0), owner);

        // Assign access control data.
        accessControl = _accessControl;

        // This memberships collection is a resource that can be cataloged -
        // emit the initial metadata value
        emit Broadcast("metadata", _metadata);
    }

    // ---
    // Admin functionality
    // ---

    /// @notice Change the owner address of this collection.
    /// @dev This is only here for market interop, access control is handled via
    /// the control node.
    function setOwner(address _owner) external onlyAuthorized {
        address previousOwner = owner;
        owner = _owner;
        emit OwnershipTransferred(previousOwner, _owner);
    }

    /// @notice Change the merkle root of the membership list. Only callable by
    /// the admin
    function setMembershipListRoot(bytes32 _root) external onlyAuthorized {
        membershipListRoot = _root;
        emit MembershipListRootUpdated(_root);
    }

    /// @notice Set the custom metadata resolver. Passing in address(0) will
    /// effectively clear the custom resolver. Only callable by the admin.
    function setCustomMetadataResolver(ICustomMetadataResolver _resolver)
        external
        onlyAuthorized
    {
        customMetadataResolver = _resolver;
        emit CustomMetadataResolverUpdated(_resolver);
    }

    /// @notice Issue or revoke memberships without having to provide proofs.
    /// Only callable by the admin.
    function batchMintAndBurn(
        AdminMembershipMint[] calldata mints,
        uint256[] calldata burns
    ) external onlyAuthorized {
        _mintAndBurn(mints, burns);
    }

    /// @notice Update the membership list root and burn / mint memberships.
    /// @dev This is a convenience function for the admin to update things all
    /// at once; when adding or removing members, we can update the root, and
    /// issue/revoke memberships for the changes.
    function updateMemberships(
        bytes32 _root,
        AdminMembershipMint[] calldata mints,
        uint256[] calldata burns
    ) external onlyAuthorized {
        membershipListRoot = _root;
        emit MembershipListRootUpdated(_root);
        _mintAndBurn(mints, burns);
    }

    /// @dev Admin (proofless) mint and burn implementation
    function _mintAndBurn(
        AdminMembershipMint[] memory mints,
        uint256[] memory burns
    ) internal {
        MembershipsState storage state = membershipState;
        uint128 minted = state.totalMinted;

        // mint new ones
        for (uint256 i = 0; i < mints.length; i++) {
            // enforce at-most-one membership per address
            if (balanceOf(mints[i].to) > 0) revert InvalidMint();
            _mint(
                mints[i].to,
                ++minted,
                mints[i].sequenceId,
                uint80(block.timestamp)
            );
            emit MembershipCreated(
                minted,
                mints[i].sequenceId,
                uint80(block.timestamp)
            );
        }

        // burn old ones - the underlying implementation will revert if tokenID
        // is invalid
        for (uint256 i = 0; i < burns.length; i++) {
            _burn(burns[i]);
        }

        // update state
        state.totalMinted = minted;
        state.totalSupply =
            state.totalSupply +
            uint128(mints.length) -
            uint128(burns.length);
    }

    // ---
    // Permissionless mint
    // ---

    /// @notice Mint any unminted memberships that are on the membership list.
    /// Can be called by anyone since each mint requires a proof.
    function mintMemberships(MembershipMint[] calldata mints) external {
        MembershipsState storage state = membershipState;
        uint128 minted = state.totalMinted;
        uint128 supply = state.totalSupply;

        // for each mint request, verify the proof and mint the token
        for (uint256 i = 0; i < mints.length; i++) {
            // enforce at-most-one membership per address
            if (balanceOf(mints[i].to) > 0) revert InvalidMint();
            bool isValid = MerkleProofLib.verify(
                mints[i].proof,
                membershipListRoot,
                keccak256(abi.encodePacked(mints[i].to, mints[i].sequenceId))
            );
            if (!isValid) revert InvalidMint();
            _mint(
                mints[i].to,
                ++minted,
                mints[i].sequenceId,
                uint80(block.timestamp)
            );
            emit MembershipCreated(
                minted,
                mints[i].sequenceId,
                uint80(block.timestamp)
            );
            supply++;
        }

        // Write new counts back to storage
        state.totalMinted = minted;
        state.totalSupply = supply;
    }

    // ---
    // Token holder functionality
    // ---

    /// @notice Burn a membership. Msg sender must own token.
    function burnMembership(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) revert InvalidBurn();
        _burn(tokenId);
        membershipState.totalSupply--;
    }

    // ---
    // ERC721 functionality - non-transferability / admin transfers
    // ---

    /// @notice Transfer is not allowed on this token.
    function transferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert TransferNotAllowed();
    }

    /// @notice Transfer an existing membership from one address to another. Only
    /// callable by the admin.
    function adminTransferFrom(
        address from,
        address to,
        uint256 id
    ) external onlyAuthorized {
        if (from == address(0)) revert InvalidTransfer();
        if (to == address(0)) revert InvalidTransfer();
        if (balanceOf(to) != 0) revert InvalidTransfer();
        if (from != _tokenData[id].owner) revert InvalidTransfer();

        //
        // The below code was copied from the solmate transferFrom source,
        // removing the checks (which we've already done above)
        //
        // --- START COPIED CODE ---
        //

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }

        _tokenData[id].owner = to;
        delete getApproved[id];
        emit Transfer(from, to, id);

        //
        // --- END COPIED CODE ---
        //
    }

    // ---
    // ERC721 views
    // ---

    /// @notice The collection name.
    function name() public view virtual returns (string memory value) {
        value = _resolveImmutableStorage().name;
    }

    /// @notice The collection symbol.
    function symbol() public view virtual returns (string memory value) {
        value = _resolveImmutableStorage().symbol;
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory uri)
    {
        // If a custom metadata resolver is set, use it to get the token URI
        // instead of the default behavior
        if (customMetadataResolver != ICustomMetadataResolver(address(0))) {
            return customMetadataResolver.tokenURI(address(this), tokenId);
        }

        // Form URI from base + collection + token ID
        uri = string.concat(
            _resolveImmutableStorage().baseURI,
            Strings.toHexString(address(this)),
            "/",
            Strings.toString(tokenId),
            ".json"
        );
    }

    /// @notice Get the collection URI
    function contractURI() public view virtual returns (string memory uri) {
        // If a custom metadata resolver is set, use it to get the collection
        // URI instead of the default behavior
        if (customMetadataResolver != ICustomMetadataResolver(address(0))) {
            return customMetadataResolver.contractURI(address(this));
        }

        // Form URI from base + collection
        uri = string.concat(
            _resolveImmutableStorage().baseURI,
            Strings.toHexString(address(this)),
            "/collection.json"
        );
    }

    // ---
    // Misc views
    // ---

    /// @notice Get a membership's sequence ID.
    function tokenSequenceId(uint256 tokenId)
        external
        view
        returns (uint16 sequenceId)
    {
        sequenceId = _tokenData[tokenId].sequenceId;
    }

    /// @notice Get a membership's mint timestamp.
    function tokenMintTimestamp(uint256 tokenId)
        external
        view
        returns (uint80 timestamp)
    {
        timestamp = _tokenData[tokenId].data;
    }

    /// @notice Get total supply of existing memberships.
    function totalSupply() public view virtual returns (uint256) {
        return membershipState.totalSupply;
    }

    /// @notice Get total count of minted memberships, including burned ones.
    function totalMinted() public view virtual returns (uint256) {
        return membershipState.totalMinted;
    }

    // ---
    // Internal views
    // ---

    function _resolveImmutableStorage()
        internal
        view
        returns (ImmutableCollectionData memory data)
    {
        data = abi.decode(
            SSTORE2.read(immutableStoragePointer),
            (ImmutableCollectionData)
        );
    }
}