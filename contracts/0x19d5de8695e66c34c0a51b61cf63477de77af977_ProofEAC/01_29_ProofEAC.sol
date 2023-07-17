// SPDX-License-Identifier: MIT
// Copyright 2023 Proof Holdings Inc.
pragma solidity >=0.8.19;

import {Strings} from "openzeppelin-contracts/utils/Strings.sol";
import {IERC721Metadata} from "openzeppelin-contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC2981} from "openzeppelin-contracts/interfaces/IERC2981.sol";
import {SafeCast} from "openzeppelin-contracts/utils/math/SafeCast.sol";

import {ERC721A, ERC721ACommon} from "ethier/erc721/ERC721ACommon.sol";
import {OperatorFilterOS} from "ethier/erc721/OperatorFilterOS.sol";

interface ProofEACEvents {
    event NewProject(uint32 projectId);
    event ProjectMinted(uint32 indexed projectId, uint64 startTokenId, uint64 startEdition, uint64 num);
    event ProjectEditionBurned(uint32 indexed projectId, uint64 edition);
}

/**
 * @notice PROOF Experimental Artist Contract.
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 * @custom:reviewer Josh Laird (@jbmlaird)
 */
contract ProofEAC is ERC721ACommon, OperatorFilterOS, ProofEACEvents {
    // =================================================================================================================
    //                          Errors
    // =================================================================================================================

    /**
     * @notice Thrown on attempts to operate on a nonexistent project.
     */
    error NonExistentProject(uint32 projectId);

    /**
     * @notice Thrown on attempts to operate on a locked project.
     */
    error ProjectLocked(uint32 projectId);

    /**
     * @notice Thrown on attempts to set a royalty receiver to the zero address.
     */
    error ZeroAddress();

    /**
     * @notice Thrown on attempts to set a royalty basis points value > 10000.
     */
    error RoyaltyBasisPointsOutOfBounds();

    /**
     * @notice Thrown on attempts to query info for a nonexistent token.
     */
    error NonExistentToken(uint256);

    // =================================================================================================================
    //                          Types
    // =================================================================================================================

    /**
     * @notice Batch of tokens minted for a project.
     * @param projectId Project ID.
     * @param startTokenId First token ID minted in the batch. The next batch (independent of project)
     * will start at `startTokenId + size`.
     * @param startEdition First edition minted in the batch. The next batch of the same project will start at
     * `startEdition + size`.
     * @param size Number of tokens minted.
     */
    struct Batch {
        uint32 projectId;
        uint64 startTokenId;
        uint64 startEdition;
        uint64 size;
    }

    /**
     * @notice Configuration of a project.
     * @param locked Whether the project is locked.
     * @param numMinted Number of tokens minted for the project.
     * @param royaltyReceiver Address to receive royalties.
     * @param royaltyBasisPoints Royalty fraction in basis points (0.01%).
     * @param baseTokenURI Base token URI used as a prefix by {tokenURI}.
     */
    struct Project {
        bool locked;
        uint64 numMinted;
        uint64 numBurned;
        address royaltyReceiver;
        uint16 royaltyBasisPoints;
        string baseTokenURI;
    }

    // =================================================================================================================
    //                          Constants
    // =================================================================================================================

    /**
     * @notice Role required to mint tokens and set up projects.
     */
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // =================================================================================================================
    //                          Storage
    // =================================================================================================================

    /**
     * @notice Minted batches of tokens.
     * @dev We store the batchId (index in the array) for the minted tokens using ERC721A's {_extraTokenData} which
     * allows us to store the metadata for all tokens in the batch in O(1).
     */
    Batch[] internal _batches;

    /**
     * @notice The project configurations.
     * @dev Indexed by projectID.
     */
    Project[] internal _projects;

    // =================================================================================================================
    //                          Construction
    // =================================================================================================================

    struct ConstructorParams {
        address admin;
        address steerer;
    }

    constructor(ConstructorParams memory params)
        // disabling default royalties as we will handle them on a per-project basis
        ERC721ACommon(params.admin, params.steerer, "PROOF EAC", "EAC", payable(address(0xFEE)), 0)
    {
        _setRoleAdmin(OPERATOR_ROLE, DEFAULT_STEERING_ROLE);
    }

    // =================================================================================================================
    //                          Steering
    // =================================================================================================================

    /**
     * @notice Mints a batch of tokens for a project.
     * @dev Reverts if the project does not exist or is locked.
     */
    function _mintProject(address to, uint32 projectId, uint32 num)
        internal
        onlyExistingProject(projectId)
        onlyUnlockedProject(projectId)
    {
        uint64 startTokenId = SafeCast.toUint64(_nextTokenId());
        Batch memory b = Batch({
            projectId: projectId,
            startTokenId: startTokenId,
            startEdition: _projects[projectId].numMinted,
            size: num
        });
        _batches.push(b);
        emit ProjectMinted(projectId, b.startTokenId, b.startEdition, num);

        _projects[projectId].numMinted += num;
        _mint(to, num);

        // Storing the index of the batch information in the extra data.
        _setExtraDataAt(startTokenId, SafeCast.toUint24(_batches.length - 1));
    }

    /**
     * @notice Adds a new project and mints a batch of tokens for it.
     * @param to Address to mint the tokens to.
     * @param num Number of tokens to mint.
     * @param royaltyReceiver Address to receive royalties.
     * @param royaltyBasisPoints Royalty fraction in basis points (0.01%).
     * @param baseTokenURI Base token URI used as a prefix by {tokenURI}.
     */
    function mintNewProject(
        address to,
        uint16 num,
        address royaltyReceiver,
        uint16 royaltyBasisPoints,
        string calldata baseTokenURI
    ) external onlyRole(OPERATOR_ROLE) onlyValidRoyaltySettings(royaltyReceiver, royaltyBasisPoints) {
        _projects.push(
            Project({
                locked: false,
                numMinted: 0,
                numBurned: 0,
                royaltyBasisPoints: royaltyBasisPoints,
                royaltyReceiver: royaltyReceiver,
                baseTokenURI: baseTokenURI
            })
        );
        uint32 projectId = SafeCast.toUint32(_projects.length - 1);
        emit NewProject(projectId);

        _mintProject(to, projectId, num);
    }

    /**
     * @notice Mints a batch of tokens for an existing project.
     * @dev Reverts if the project does not exist or is locked.
     * @param to Address to mint the tokens to.
     * @param projectId Project ID to mint the tokens for.
     * @param num Number of tokens to mint.
     */
    function mintExistingProject(address to, uint32 projectId, uint16 num) external onlyRole(OPERATOR_ROLE) {
        _mintProject(to, projectId, num);
    }

    /**
     * @notice Burns an existing token.
     * @dev Reverts if the project is locked.
     */
    function burn(uint256 tokenId) external onlyRole(OPERATOR_ROLE) {
        (uint32 projectId, uint64 edition) = tokenIdToProjectIdAndEdition(tokenId);
        _requireUnlockedProject(projectId);

        _projects[projectId].numBurned++;
        emit ProjectEditionBurned(projectId, edition);
        _burn(tokenId);
    }

    // =================================================================================================================
    //                          Steering
    // =================================================================================================================

    /**
     * @notice Locks a project preventing further minting and burning.
     */
    function lockProject(uint32 projectId) external onlyRole(OPERATOR_ROLE) onlyExistingProject(projectId) {
        _projects[projectId].locked = true;
    }

    /**
     * @notice Sets the base token URI prefix for a given project.
     */
    function setBaseTokenURI(uint32 projectId, string memory baseTokenURI)
        external
        onlyRole(OPERATOR_ROLE)
        onlyExistingProject(projectId)
    {
        _projects[projectId].baseTokenURI = baseTokenURI;
    }

    /**
     * @notice Sets the base token URI prefix for a given project.
     */
    function setRoyaltySettings(uint32 projectId, address royaltyReceiver, uint16 royaltyBasisPoints)
        external
        onlyRole(OPERATOR_ROLE)
        onlyExistingProject(projectId)
        onlyValidRoyaltySettings(royaltyReceiver, royaltyBasisPoints)
    {
        _projects[projectId].royaltyReceiver = royaltyReceiver;
        _projects[projectId].royaltyBasisPoints = royaltyBasisPoints;
    }

    // =================================================================================================================
    //                          Metadata
    // =================================================================================================================

    /**
     * @notice Returns the project ID and edition for a given token ID.
     * @dev The edition is a continuous counter for all tokens of a project. The first token of a project has edition 0,
     * @dev Reverts if the token does not exist.
     */
    function tokenIdToProjectIdAndEdition(uint256 tokenId) public view virtual returns (uint32, uint64) {
        if (!_exists(tokenId)) {
            revert NonExistentToken(tokenId);
        }

        Batch memory b = _batches[_ownershipOf(tokenId).extraData];
        return (b.projectId, SafeCast.toUint64(tokenId - b.startTokenId + b.startEdition));
    }

    /**
     * @notice Returns the token URI for a given token ID.
     * @dev Uses the base URI stored in the project configuration as prefix and the token's edition as suffix.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        (uint32 projectId, uint64 edition) = tokenIdToProjectIdAndEdition(tokenId);
        return string.concat(_projects[projectId].baseTokenURI, Strings.toString(edition));
    }

    /**
     * @notice Returns the project configuration for a given projectId.
     */
    function project(uint32 projectId) public view onlyExistingProject(projectId) returns (Project memory) {
        return _projects[projectId];
    }

    /**
     * @notice Returns the number of projects.
     */
    function numProjects() public view returns (uint256) {
        return _projects.length;
    }

    /**
     * @notice Returns the batch configuration for a given batch index.
     * @dev Indended to be used by off-chain services to reconstruct the token ID for a given project + edition.
     */
    function batch(uint256 index) public view returns (Batch memory) {
        return _batches[index];
    }

    /**
     * @notice Returns the number of batches.
     */
    function numBatches() public view returns (uint256) {
        return _batches.length;
    }

    // =================================================================================================================
    //                          Royalties
    // =================================================================================================================

    /**
     * @inheritdoc IERC2981
     * @dev Informs marketplaces about the royalties due on secondary sales (receiver and amount).
     * @param tokenId Token ID to query the royalty info for.
     * @param salePrice Sale price of the token.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view virtual override returns (address, uint256) {
        (uint32 projectId,) = tokenIdToProjectIdAndEdition(tokenId);
        Project storage p = _projects[projectId];

        uint256 royaltyAmount = (salePrice * p.royaltyBasisPoints) / 10_000;
        return (p.royaltyReceiver, royaltyAmount);
    }

    /**
     * @notice Validates the royalty settings.
     * @dev Reverts if the royalty receiver is the zero address or if the royalty basis points are out of bounds.
     */
    modifier onlyValidRoyaltySettings(address royaltyReceiver, uint16 royaltyBasisPoints) {
        if (royaltyReceiver == address(0)) {
            revert ZeroAddress();
        }
        if (royaltyBasisPoints > 10_000) {
            revert RoyaltyBasisPointsOutOfBounds();
        }
        _;
    }

    // =================================================================================================================
    //                          Internal
    // =================================================================================================================

    /**
     * @notice Stores the batch ID on mint, and propagates it on transfers.
     * @dev ERC721A specific override to manage the "extra data" stored for each token.
     */
    function _extraData(address, address, uint24 previousExtraData) internal view virtual override returns (uint24) {
        return previousExtraData;
    }

    /**
     * @notice Ensures that a project exists.
     */
    modifier onlyExistingProject(uint32 projectId) {
        if (projectId >= _projects.length) {
            revert NonExistentProject(projectId);
        }
        _;
    }

    /**
     * @notice Reverts if a project is locked.
     */
    function _requireUnlockedProject(uint32 projectId) internal view {
        if (_projects[projectId].locked) {
            revert ProjectLocked(projectId);
        }
    }

    /**
     * @notice Ensures that a project is not locked.
     */
    modifier onlyUnlockedProject(uint32 projectId) {
        _requireUnlockedProject(projectId);
        _;
    }

    // =================================================================================================================
    //                          Inheritance resolution
    // =================================================================================================================

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721A, OperatorFilterOS) {
        OperatorFilterOS.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable virtual override(ERC721A, OperatorFilterOS) {
        OperatorFilterOS.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
    {
        OperatorFilterOS.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
    {
        OperatorFilterOS.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
    {
        OperatorFilterOS.safeTransferFrom(from, to, tokenId, data);
    }
}