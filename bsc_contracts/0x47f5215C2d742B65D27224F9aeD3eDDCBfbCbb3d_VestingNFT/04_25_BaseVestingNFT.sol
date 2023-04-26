import "./ERC5725.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

abstract contract BaseVestingNFT is ERC5725, AccessControlEnumerable {

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");

    string private _baseTokenURI;

    bool public uriLocked = false;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    event BaseTokenUriChanged(string newUri);
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "BaseVestingNFT: Only admin role");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseTokenURI) external onlyAdmin {
        require(!uriLocked, "Not happening.");
        _baseTokenURI = baseTokenURI;
        emit BaseTokenUriChanged(_baseTokenURI);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return super.tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(hasRole(URI_SETTER_ROLE, _msgSender()), "BaseVestingNFT: Only uri setter role");
        _setTokenURI(tokenId, _tokenURI);
    }

        /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     * IERC5725 interfaceId = 0x7c89676d
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC5725)
        returns (bool supported)
    {
        return super.supportsInterface(interfaceId);
    }
}