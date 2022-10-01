// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract MSFIT is ERC721, Ownable, IERC2981 {
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    address public AuctionContract;
    address public LaunchpadContract;

    uint256 internal totalMinted = 0;

    struct GiftMint {
        address to;
        uint256 count;
    }

    struct TokenURIBase {
        uint256 _tokenId;
        string _metadata;
    }

    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    RoyaltyInfo private _royalties;

    event RegisterExtension(address extension, string extensionType);

    constructor() ERC721("Magnificent Misfits of the Chelsea Hotel", "MSFIT") {}

    modifier extensionPermission() {
        require(
            msg.sender == LaunchpadContract || msg.sender == AuctionContract
        );
        _;
    }

    // admin ----------------------------------------------------------------------

    function setAuctionContract(address _auctionContract) external onlyOwner {
        AuctionContract = _auctionContract;
        emit RegisterExtension(_auctionContract, "auction contract");
    }

    function setLaunchpadContract(address _launchpadContract)
        external
        onlyOwner
    {
        LaunchpadContract = _launchpadContract;
        emit RegisterExtension(_launchpadContract, "launchpad contract");
    }

    function setRoyalties(address recipient, uint256 value) external onlyOwner {
        require(value <= 10000, "Too high. Must be less than 10k");
        _royalties = RoyaltyInfo(recipient, uint24(value));
    }

    function adminMint(GiftMint[] calldata _recipient) external onlyOwner {
        for (uint256 i = 0; i < _recipient.length; i++) {
            for (uint256 j = 0; j < _recipient[i].count; j++) {
                _safeMint(_recipient[i].to, totalMinted + 1);
                totalMinted++;
            }
        }
    }

    // external -------------------------------------------------------------------

    function mint(address _to, uint256 _id) external extensionPermission {
        _safeMint(_to, _id);
        totalMinted++;
    }

    function setTokenURIs(TokenURIBase[] calldata tokenURIs_)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < tokenURIs_.length; i++) {
            _setTokenURI(tokenURIs_[i]._tokenId, tokenURIs_[i]._metadata);
        }
    }

    function burnToken(uint256 tokenId) external {
        require(_exists(tokenId), "ERC721: token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        _burn(tokenId);
    }

    // view -----------------------------------------------------------------------

    function getTotalMinted() external view returns (uint256) {
        return totalMinted;
    }

    // override -------------------------------------------------------------------

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}