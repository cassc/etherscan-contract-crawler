// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

import {ERC721Base} from "./mixins/ERC721Base.sol";
import {CollectionRoyalties} from "./mixins/CollectionRoyalties.sol";
import {CollectionFactory} from "./mixins/CollectionFactory.sol";
import {MintApproval} from "./mixins/MintApproval.sol";

import {IERC2981Royalties} from "./interfaces/IERC2981Royalties.sol";
import {ICollectionInitializer} from "./interfaces/ICollectionInitializer.sol";

contract Collection is
    CollectionFactory,
    Initializable,
    ERC721Upgradeable,
    MintApproval,
    ERC721Base,
    CollectionRoyalties
{
    /**
     * @notice Base URI of the collection
     * @dev We always default to ipfs
     */
    string public constant baseURI = "ipfs://";

    /**
     * @dev Stores a CID for each NFT.
     */
    mapping(uint256 tokenId => string tokenCID) private _tokenCIDs;

    /**
     * @notice Emitted when NFT is minted
     * @param tokenId The tokenId of the newly minted NFT.
     * @param artistId The address of the creator
     * @param tokenCID Token CID
     */
    event Minted(
        uint256 indexed tokenId,
        address indexed artistId,
        string indexed tokenCID
    );

    /**
     * @notice Emitted when batch of NFTs is minted
     * @param startTokenId The tokenId of the first minted NFT in the batch
     * @param endTokenId The tokenId of the last minted NFT in the batch
     * @param artistId The address of the creator
     * @param tokenCIDs Token CIDs
     */
    event BatchMinted(
        uint256 indexed startTokenId,
        uint256 indexed endTokenId,
        address indexed artistId,
        string[] tokenCIDs
    );

    error CallerNotTokenOwner();
    error URIQueryForNonexistentToken();

    /**
     * @notice Initialize imutable variables
     * @param _collectionFactory The factory which is used to create new collections
     */
    constructor(
        address _collectionFactory
    ) CollectionFactory(_collectionFactory) {}

    function initialize(
        address creator,
        string memory name,
        string memory symbol,
        uint256 royalties,
        address administrator
    ) external onlyCollectionFactory initializer {
        _transferOwnership(creator);
        __ERC721_init_unchained(name, symbol);
        __EIP712_init_unchained(name, "1");
        __Administrated_init(administrator);
        __CollectionRoyalties_init(creator, royalties);
    }

    function mint(
        address recipient,
        string calldata tokenCID,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 nonce
    ) external onlyOwner {
        // Check if mint approval is required
        if (mintApprovalRequired) {
            // Make sure that mint is approved
            _checkMintApproval(owner(), tokenCID, v, r, s, nonce);
        }

        // Mint token to the recipient
        _mintBase(recipient, tokenCID);
    }

    function batchMint(
        address recipient,
        string[] calldata tokenCIDs,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 nonce
    ) external onlyOwner {
        // Check if mint approval is required
        if (mintApprovalRequired) {
            // Make sure that mint is approved
            _checkBatchMintApproval(owner(), tokenCIDs, v, r, s, nonce);
        }

        // Mint tokens to the recipient
        _batchMintBase(recipient, tokenCIDs);
    }

    function mintAndApprove(
        address recipient,
        string calldata tokenCID,
        address operator,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 nonce
    ) external onlyOwner {
        // Check if mint approval is required
        if (mintApprovalRequired) {
            // Make sure that mint is approved
            _checkMintApproval(owner(), tokenCID, v, r, s, nonce);
        }

        // Mint token to the recipient
        _mintBase(recipient, tokenCID);

        // Approve operator to access tokens
        setApprovalForAll(operator, true);
    }

    function batchMintAndApprove(
        address recipient,
        string[] calldata tokenCIDs,
        address operator,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 nonce
    ) external onlyOwner {
        // Check if mint approval is required
        if (mintApprovalRequired) {
            // Make sure that mint is approved
            _checkBatchMintApproval(owner(), tokenCIDs, v, r, s, nonce);
        }

        // Mint tokens to the recipient
        _batchMintBase(recipient, tokenCIDs);

        // Approve operator to access tokens
        setApprovalForAll(operator, true);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return string(abi.encodePacked(_baseURI(), _tokenCIDs[tokenId]));
    }

    function setRoyalties(address recipient, uint256 value) external onlyOwner {
        _setRoyalties(recipient, value);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(CollectionRoyalties, ERC721Upgradeable)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            type(IERC165Upgradeable).interfaceId == interfaceId ||
            type(IERC721Upgradeable).interfaceId == interfaceId ||
            type(IERC721MetadataUpgradeable).interfaceId == interfaceId;
    }

    function _mintBase(address recipient, string calldata tokenCID) internal {
        // Create new token ID
        uint256 tokenId = ++latestTokenId;

        // Mint token ID to the recipient
        _mint(recipient, tokenId);

        // Save token URI
        _tokenCIDs[tokenId] = tokenCID;

        // Emit mint event
        emit Minted(tokenId, owner(), tokenCID);
    }

    function _batchMintBase(address recipient, string[] calldata tokenCIDs) internal {
        // Retrieve latest token ID
        uint256 currentTokenId = latestTokenId;
        // Calculate start token ID for the batch
        uint256 startTokenId = currentTokenId + 1;

        for (uint256 i = 0; i < tokenCIDs.length; ) {
            // Mint current token ID to the recipient
            _mint(recipient, ++currentTokenId);

            // Save token URI
            _tokenCIDs[currentTokenId] = tokenCIDs[i];

            unchecked {
                ++i;
            }
        }

        // Update latest token ID
        latestTokenId = currentTokenId;

        // Emit batch mint event
        emit BatchMinted(startTokenId, currentTokenId, owner(), tokenCIDs);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721Base) {
        delete _tokenCIDs[tokenId];
        super._burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}