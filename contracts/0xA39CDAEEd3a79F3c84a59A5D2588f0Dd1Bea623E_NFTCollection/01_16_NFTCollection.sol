// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "./interfaces/internal/INFTCollectionInitializer.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./libraries/AddressLibrary.sol";
import "./interfaces/internal/ICollectionFactory.sol";

/**
 * @title A collection of NFTs by a single creator.
 * @notice All NFTs from this contract are minted by the same creator.
 * A 10% royalty to the creator is included which may be split with collaborators on a per-NFT basis.
 * @author batu-inal & HardlyDifficult
 */
contract NFTCollection is
    Initializable,
    ERC721Upgradeable,
    ERC721BurnableUpgradeable
{
    //
    using AddressLibrary for address;
    using AddressUpgradeable for address;

    /**
     * @notice The baseURI to use for the tokenURI, if undefined then `ipfs://` is used.
     */
    string private baseURI_;
    address public admin;

    modifier onlyAdmin() {
        require(admin == _msgSender(), "Not Admin");
        _;
    }

    /**
     * @notice Stores hashes minted to prevent duplicates.
     * @dev 0 means not yet minted, set to 1 when minted.
     * For why using uint is better than using bool here:
     * github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/security/ReentrancyGuard.sol#L23-L27
     */
    mapping(string => uint256) private cidToMinted;

    /**
     * @dev Stores a CID for each NFT.
     */
    mapping(uint256 => string) private tokenCIDs;

    /**
     * @notice Emitted when the owner changes the base URI to be used for NFTs in this collection.
     * @param baseURI The new base URI to use.
     */
    event BaseURIUpdated(string baseURI);
    /**
     * @notice Emitted when a new NFT is minted.
     * @param creator The address of the collection owner at this time this NFT was minted.
     * @param tokenId The tokenId of the newly minted NFT.
     * @param indexedTokenCID The CID of the newly minted NFT, indexed to enable watching for mint events by the tokenCID.
     * @param tokenCID The actual CID of the newly minted NFT.
     */
    event Minted(
        address indexed creator,
        uint256 indexed tokenId,
        string indexed indexedTokenCID,
        string tokenCID
    );

    /**
     * @notice Called by the contract factory on creation.
     * @param _name The collection's `name`.
     * @param _symbol The collection's `symbol`.
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _admin
    ) external initializer {
        admin = _admin;
        __ERC721_init(_name, _symbol);
    }

    /**
     * @notice Allows the creator to burn a specific token if they currently own the NFT.
     * @param tokenId The ID of the NFT to burn.
     * @dev The function here asserts `onlyOwner` while the super confirms ownership.
     */
    function burn(uint256 tokenId) public override onlyAdmin {
        super.burn(tokenId);
    }

    /**
     * @notice Mint an NFT defined by its metadata path.
     * @dev This is only callable by the collection creator/owner.
     * @param tokenCID The CID for the metadata json of the NFT to mint.
     * @return tokenId The tokenId of the newly minted NFT.
     */
    function mint(string calldata tokenCID) external returns (uint256 tokenId) {
        tokenId = _mint(tokenCID);
    }

    /**
     * @notice Mint an NFT defined by its metadata path and approves the provided operator address.
     * @dev This is only callable by the collection creator/owner.
     * It can be used the first time they mint to save having to issue a separate approval
     * transaction before listing the NFT for sale.
     * @param tokenCID The CID for the metadata json of the NFT to mint.
     * @param operator The address to set as an approved operator for the creator's account.
     * @return tokenId The tokenId of the newly minted NFT.
     */
    function mintAndApprove(string calldata tokenCID, address operator)
        external
        returns (uint256 tokenId)
    {
        tokenId = _mint(tokenCID);
        setApprovalForAll(operator, true);
    }

    /**
     * @notice Allows the owner to assign a baseURI to use for the tokenURI instead of the default `ipfs://`.
     * @param baseURIOverride The new base URI to use for all NFTs in this collection.
     */
    function updateBaseURI(string calldata baseURIOverride) external onlyAdmin {
        baseURI_ = baseURIOverride;

        emit BaseURIUpdated(baseURIOverride);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        delete cidToMinted[tokenCIDs[tokenId]];
        delete tokenCIDs[tokenId];
        super._burn(tokenId);
    }

    function _mint(string calldata tokenCID)
        private
        onlyAdmin
        returns (uint256 tokenId)
    {
        require(
            bytes(tokenCID).length != 0,
            "NFTCollection: tokenCID is required"
        );
        require(
            cidToMinted[tokenCID] == 0,
            "NFTCollection: NFT was already minted"
        );
        // Number of tokens cannot realistically overflow 32 bits.
        tokenId++;
        cidToMinted[tokenCID] = 1;
        tokenCIDs[tokenId] = tokenCID;
        _safeMint(msg.sender, tokenId);
        emit Minted(msg.sender, tokenId, tokenCID, tokenCID);
    }

    /**
     * @notice The base URI used for all NFTs in this collection.
     * @dev The `tokenCID` is appended to this to obtain an NFT's `tokenURI`.
     *      e.g. The URI for a token with the `tokenCID`: "foo" and `baseURI`: "ipfs://" is "ipfs://foo".
     * @return uri The base URI used by this collection.
     */
    function baseURI() external view returns (string memory uri) {
        uri = _baseURI();
    }

    /**
     * @notice Checks if the creator has already minted a given NFT using this collection contract.
     * @param tokenCID The CID to check for.
     * @return hasBeenMinted True if the creator has already minted an NFT with this CID.
     */
    function getHasMintedCID(string calldata tokenCID)
        external
        view
        returns (bool hasBeenMinted)
    {
        hasBeenMinted = cidToMinted[tokenCID] != 0;
    }

    /**
     * @inheritdoc IERC721MetadataUpgradeable
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory uri)
    {
        require(
            _exists(tokenId),
            "NFTCollection: URI query for nonexistent token"
        );

        uri = string.concat(_baseURI(), tokenCIDs[tokenId]);
    }

    function _baseURI() internal view override returns (string memory uri) {
        uri = baseURI_;
        if (bytes(uri).length == 0) {
            uri = "ipfs://";
        }
    }
}