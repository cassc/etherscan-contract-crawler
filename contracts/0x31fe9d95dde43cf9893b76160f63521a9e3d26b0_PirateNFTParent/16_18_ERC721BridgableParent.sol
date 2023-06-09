// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./interfaces/IERC721BridgableParent.sol";

/// @notice ERC721 contract on mainnet. Can be bridged to Polygon
contract ERC721BridgableParent is
    IERC721BridgableParent,
    ERC721Enumerable,
    AccessControl
{
    using Strings for uint256;

    // @dev Used by the Polygon bridge to mint on mainnet
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    // @dev Used by the Raffle contract to originally mint NFTs
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // @notice Serialized token URI data for the token
    mapping(uint256 => bytes) _tokenData;

    // @notice Base token URI, tokenId is appended to create the final URI.
    // @dev This is only used if the metadataEnabled flag is false or the token lacks encoded metadata
    string private _baseTokenURI;

    // @notice Whether or not metadata should be returned by the tokenURI function
    bool public metadataEnabled;

    // @notice Max supply for this NFT. If zero, it is unlimited supply.
    uint256 public immutable maxSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, _msgSender());

        metadataEnabled = true;
        _baseTokenURI = "";
        maxSupply = _maxSupply;
    }

    /**
     * Mints a token. Can be called by minting contract or by bridge
     *
     * @param to         Account to mint to
     * @param tokenId    Id of the token to mint
     */
    function mint(address to, uint256 tokenId) external override {
        // Either the raffle contract or the PREDICATE can call this
        require(
            hasRole(PREDICATE_ROLE, _msgSender()) ||
                hasRole(MINTER_ROLE, _msgSender()),
            "MISSING_ROLE: Only MINTER_ROLE or PREDICATE_ROLE can call."
        );

        _safeMint(to, tokenId);
    }

    /**
     * Mints a token and also sets metadata from L2
     *
     * @param to        Address to mint to
     * @param tokenId   Id of the token to mint
     * @param metadata  ABI encoded tokenURI for the token
     */
    function mint(
        address to,
        uint256 tokenId,
        bytes calldata metadata
    ) external override onlyRole(PREDICATE_ROLE) {
        _safeMint(to, tokenId);
        _setTokenMetadata(tokenId, metadata);
    }

    /**
     * @param tokenId token id to check
     * @return Whether or not the given tokenId has been minted
     */
    function exists(uint256 tokenId) external view override returns (bool) {
        return _exists(tokenId);
    }

    /** Sets the new base token URI for the contract */
    function setBaseURI(string calldata newURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseTokenURI = newURI;
    }

    /** @return Base URI for the tokenURI function */
    function getBaseURI() external view returns (string memory) {
        return _baseTokenURI;
    }

    /** Enables or disables the use of stored metadata, used as a safety mechanism incase metadata gets corrupted for some reason */
    function setMetadataEnabled(bool enabled)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        metadataEnabled = enabled;
    }

    /**
     * Sets the metadata for a given token, only callable by bridge
     *
     * @param tokenId  Id of the token to set metadata for
     * @param data     Metadata for the token
     */
    function setTokenMetadata(uint256 tokenId, bytes calldata data)
        external
        override
        onlyRole(PREDICATE_ROLE)
    {
        _setTokenMetadata(tokenId, data);
    }

    /** PUBLIC **/

    /**
     * @inheritdoc ERC721
     * @dev This version of tokenURI uses the serialized tokenURI data if it exists.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        // Return encoded per-token metadata/URI if there is some set
        if (metadataEnabled && _tokenData[tokenId].length > 0) {
            return abi.decode(_tokenData[tokenId], (string));
        }

        // Use base implementation: Generate URI by appending tokenId, error if token has not been minted
        return super.tokenURI(tokenId);
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC721BridgableParent).interfaceId ||
            ERC721Enumerable.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    /** INTERNAL **/

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * If you're attempting to bring metadata associated with token
     * from L2 to L1, you must implement this method, to be invoked
     * when minting token back on L1, during exit
     */
    function _setTokenMetadata(uint256 tokenId, bytes memory data)
        internal
        virtual
    {
        _tokenData[tokenId] = data;
    }

    /**
     * Mint token to recipient
     * @notice This override checks to make sure the tokenId is valid
     *
     * @param to        The recipient of the token
     * @param tokenId   Id of the token to mint
     */
    function _safeMint(address to, uint256 tokenId) internal override {
        require(
            maxSupply == 0 || tokenId <= maxSupply,
            "TOKEN_ID_EXCEEDS_MAX_SUPPLY: tokenId exceeds max supply for this NFT"
        );
        require(
            tokenId > 0,
            "TOKEN_MUST_BE_GREATER_THAN_ZERO: tokenId must be greater than 0"
        );

        super._safeMint(to, tokenId);
    }
}