// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./IMigrateContract.sol";

import "./LaCollectionAccess.sol";

interface INewContract {
    function migrateTokens(uint256[] calldata tokenIds, address to) external;
}

/**
 * @title LaCollection
 */
contract LaCollection is ERC721URIStorage, Pausable, LaCollectionAccess {
    using SafeMath for uint256;

    INewContract public newContract;

    modifier onlyLeftEdition(uint256 _artworkNumber) {
        require(
            artworkNumberToArtworkDetails[_artworkNumber].totalLeft > 0,
            "LaCollection: No more editions left to mint"
        );
        _;
    }

    // Object for edition details
    struct ArtworkDetails {
        // Identifiers
        uint256 artworkNumber; // the range e.g. 10000
        uint8 scarcity; // e.g. 1 = Unique, 2 = Super-Rare...
        // Counters
        uint16 totalMinted; // Total purchases or mints
        uint16 totalLeft; // Total number available to be purchased based on scarcity
        // Config
        string tokenUri; // IPFS hash - see base URI
        bool active; // Root control - on/off for the artwork
    }

    // Emitted on every artwork creation
    event ArtworkCreated(uint256 indexed artworkNumber, uint8 indexed scarcity);

    // Emitted on every mint edition
    event ArtworkEditionMinted(
        uint256 indexed tokenId,
        uint256 indexed artworkNumber,
        address indexed buyer
    );

    // simple counter to keep track of the highest artwork number used
    uint256 public highestArtworkNumber;

    mapping(uint256 => ArtworkDetails) internal artworkNumberToArtworkDetails;
    // _tokenId : _artworkNumber
    mapping(uint256 => uint256) internal tokenIdToArtworkNumber;

    // _artworkNumber : [_tokenId, _tokenId]
    mapping(uint256 => uint256[]) internal artworkNumberToTokenIds;

    constructor() ERC721("LaCollection", "LAC") {}

    /// @dev Set the potential next version contract
    function setNewContract(address newContractAddress) external onlyOwner {
        require(
            address(newContract) == address(0),
            "LaCollection: NewContract already set"
        );
        newContract = INewContract(newContractAddress);
    }

    /// @dev Creates a new Artwork
    function createArtwork(
        uint256 _artworkNumber,
        uint8 _scarcity,
        string memory _tokenUri,
        uint16 _totalLeft,
        bool _active
    ) external whenNotPaused onlyMinter returns (bool) {
        return
            _createArtwork(
                _artworkNumber,
                _scarcity,
                _tokenUri,
                _totalLeft,
                _active
            );
    }

    /// @dev Creates a new Artwork and mint an edition
    function createArtworkAndMintEdition(
        uint256 _artworkNumber,
        uint8 _scarcity,
        string memory _tokenUri,
        uint16 _totalLeft,
        bool _active,
        address _to
    ) external whenNotPaused onlyMinter returns (uint256) {
        _createArtwork(
            _artworkNumber,
            _scarcity,
            _tokenUri,
            _totalLeft,
            _active
        );

        // Create the token
        return
            _mintEdition(
                _to,
                _artworkNumber,
                artworkNumberToArtworkDetails[_artworkNumber].tokenUri
            );
    }

    /// @dev Mints a token for an existing artwork
    function mint(address _to, uint256 _artworkNumber)
        external
        whenNotPaused
        onlyMinter
        onlyLeftEdition(_artworkNumber)
        returns (uint256)
    {
        // Create the token
        return
            _mintEdition(
                _to,
                _artworkNumber,
                artworkNumberToArtworkDetails[_artworkNumber].tokenUri
            );
    }

    /// @dev Get artwork details from artworkNumber
    function getArtwork(uint256 artworkNumber)
        external
        view
        returns (
            uint8 scarcity,
            uint16 totalMinted,
            uint16 totalLeft,
            string memory tokenUri,
            bool active
        )
    {
        ArtworkDetails storage a = artworkNumberToArtworkDetails[artworkNumber];
        scarcity = a.scarcity;
        totalMinted = a.totalMinted;
        totalLeft = a.totalLeft;
        tokenUri = a.tokenUri;
        active = a.active;
    }

    /// @dev Get artwork number from tokenId
    function getArtworkNumber(uint256 tokenId) external view returns (uint256) {
        return tokenIdToArtworkNumber[tokenId];
    }

    /// @dev Return token ids for an artwork
    function getTokenIds(uint256 artworkNumber)
        external
        view
        returns (uint256[] memory)
    {
        return artworkNumberToTokenIds[artworkNumber];
    }

    /**
     * @dev Internal factory method for building artworks
     */
    function _createArtwork(
        uint256 _artworkNumber,
        uint8 _scarcity,
        string memory _tokenUri,
        uint16 _totalLeft,
        bool _active
    ) internal returns (bool) {
        // Prevent missing edition number
        require(
            _artworkNumber >= 1,
            "LaCollection: Artwork number not provided or must be greater than 1"
        );

        // Prevent artwork number lower than last one used
        require(
            _artworkNumber > highestArtworkNumber,
            "LaCollection: Artwork number must be greater than previously used"
        );

        // Check previously edition plus total available is less than new edition number
        require(
            highestArtworkNumber.add(
                artworkNumberToArtworkDetails[highestArtworkNumber].totalLeft
            ) <= _artworkNumber,
            "LaCollection: Artwork number must be greater than previously used plus total available"
        );

        // Prevent missing token URI
        require(
            bytes(_tokenUri).length != 0,
            "LaCollection: Token URI is missing"
        );

        // Prevent duplicate editions
        require(
            artworkNumberToArtworkDetails[_artworkNumber].artworkNumber == 0,
            "LaCollection: Edition Artwork already in existence"
        );

        artworkNumberToArtworkDetails[_artworkNumber] = ArtworkDetails({
            artworkNumber: _artworkNumber,
            scarcity: _scarcity,
            tokenUri: _tokenUri,
            totalMinted: 0, // default to all available
            totalLeft: _totalLeft,
            active: _active
        });

        emit ArtworkCreated(_artworkNumber, _scarcity);

        // Update the edition pointer if needs be
        highestArtworkNumber = _artworkNumber + _totalLeft;

        return true;
    }

    /**
     * @dev Internal factory method to generate an new tokenId based
     * @dev based on artwork number
     */
    function _getNextTokenId(uint256 _artworkNumber)
        internal
        view
        returns (uint256)
    {
        ArtworkDetails storage _artworkDetails = artworkNumberToArtworkDetails[
            _artworkNumber
        ];

        // Build next token ID e.g. 100000 + (1 - 1) = ID of 100001 (this first in the edition set)
        return _artworkDetails.artworkNumber.add(_artworkDetails.totalMinted);
    }

    /**
     * @dev Internal factory method to mint a new edition
     * @dev for an artwork
     */
    function _mintEdition(
        address _to,
        uint256 _artworkNumber,
        string memory _tokenUri
    ) internal returns (uint256) {
        // Construct next token ID e.g. 100000 + 1 = ID of 100001 (this first in the edition set)
        uint256 _tokenId = _getNextTokenId(_artworkNumber);

        // Mint new base token
        super._mint(_to, _tokenId);
        super._setTokenURI(_tokenId, _tokenUri);

        // Maintain mapping for tokenId to artwork for lookup
        tokenIdToArtworkNumber[_tokenId] = _artworkNumber;

        // Maintain mapping of edition to token array for "edition minted tokens"
        artworkNumberToTokenIds[_artworkNumber].push(_tokenId);

        ArtworkDetails storage _artworkDetails = artworkNumberToArtworkDetails[
            _artworkNumber
        ];
        // Increase number totalMinted
        _artworkDetails.totalMinted += 1;
        // Decrease number totalLeft
        _artworkDetails.totalLeft -= 1;

        // Emit minted event
        emit ArtworkEditionMinted(_tokenId, _artworkNumber, _to);
        return _tokenId;
    }

    /// @dev Migrates tokens to a potential new version of this contract
    /// @param tokenIds - list of tokens to transfer
    function migrateTokens(uint256[] calldata tokenIds) external {
        require(
            address(newContract) != address(0),
            "LaCollection: New contract not set"
        );

        for (uint256 index = 0; index < tokenIds.length; index++) {
            transferFrom(_msgSender(), address(this), tokenIds[index]);
        }

        newContract.migrateTokens(tokenIds, _msgSender());
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}