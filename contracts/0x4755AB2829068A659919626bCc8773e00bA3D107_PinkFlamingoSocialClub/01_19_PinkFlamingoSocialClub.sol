// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "ERC721Burnable.sol";

import "Pausable.sol";
import "Ownable.sol";
import "Strings.sol";

import "Whitelisted.sol";
import "Minters.sol";

/**
 * @author Bruce Wang
 * @notice Pink Flamingo Social Club: Ethereum
 */
contract PinkFlamingoSocialClub is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    Pausable,
    Ownable,
    Whitelisted,
    Minters
{
    /**
     * @dev events
     */
    event Mint(address indexed _to, uint256 indexed _tokenId);
    event Migration(address indexed _to, uint256 indexed _tokenId);

    /**
     * @dev callback mapping for VRF (requestId => minter address)
     */
    mapping(uint256 => address) public requestIdToSender;

    /**
     * @dev anySwap
     */
    address public router;

    /**
     * @dev mint specs
     */
    string private _baseURIextended;
    string private _contractURIextended;

    uint256 public whitelistPriceInWei;
    uint256 public publicPriceInWei;

    uint16 internal nextTokenId;
    uint16 internal maxTokenId;

    constructor(
        uint16 _premint,
        uint16 _nextTokenId,
        uint16 _mintLength,
        uint256 _whitelistPriceInWei,
        uint256 _publicPriceInWei,
        string memory _baseUri,
        string memory _contractUri,
        bytes32 _merkleRoot,
        address _router
    ) ERC721("Pink Flamingo Social Club", "PFSC") {
        nextTokenId = _nextTokenId;
        maxTokenId = _mintLength + _nextTokenId;

        whitelistPriceInWei = _whitelistPriceInWei;
        publicPriceInWei = _publicPriceInWei;

        _baseURIextended = _baseUri;
        _contractURIextended = _contractUri;

        // merkle root hash
        merkleRoot = _merkleRoot;

        // anySwap
        router = _router;

        for (uint16 i = 0; i < _premint; i++) {
            mintFlamingo(msg.sender);
        }

        // pause mint initially
        _pause();
    }

    /**
     * @dev can't mint more than mintedTokens
     */
    modifier availableToMint(uint16 qty) {
        require(qty > 0, "Must mint 1 or more");
        require(nextTokenId + qty <= maxTokenId, "Unable to mint quantity");
        _;
    }

    /**
     * @dev will pay publicPriceInWei
     */
    modifier isPublicPrice(uint16 qty) {
        require(msg.value >= publicPriceInWei * qty, "Insuffcient Wei");
        _;
    }

    /**
     * @dev will pay whitelistPriceInWei
     */
    modifier isWhitelistPrice(uint16 qty) {
        require(msg.value >= whitelistPriceInWei * qty, "Insuffcient Wei");
        _;
    }

    function contractURI() public view returns (string memory) {
        return _contractURIextended;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _baseURIextended = uri;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            "Withdraw Failed"
        );
        require(success);
    }

    function publicMint(uint16 qty)
        public
        payable
        whenNotPaused
        whenNotWhitelistOnly
        availableToMint(qty)
        withinPublicLimit(qty)
        isPublicPrice(qty)
    {
        for (uint256 i = 1; i <= qty; i++) {
            minters[msg.sender].publicMints += 1;
            mintFlamingo(msg.sender);
        }
    }

    function whitelistMint(bytes32[] calldata merkleProof, uint16 qty)
        public
        payable
        whenNotPaused
        whenWhitelistOnly
        verifyWhitelist(merkleProof)
        availableToMint(qty)
        withinWhitelistLimit(qty)
        isWhitelistPrice(qty)
    {
        for (uint256 i = 1; i <= qty; i++) {
            minters[msg.sender].whitelistMints += 1;
            mintFlamingo(msg.sender);
        }
    }

    function mintFlamingo(address to) internal {
        uint256 _nextTokenId = uint256(nextTokenId);
        ++nextTokenId;
        _safeMint(to, _nextTokenId);
        emit Mint(to, _nextTokenId);
    }

    function migrateFlamingo(
        address _router,
        uint256 tokenId,
        address to
    ) internal {
        _safeMint(_router, tokenId);
        emit Migration(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev anySwap
     */

    function updateRouter(address _router) external onlyOwner {
        router = _router;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721, IERC721) {
        if (
            _msgSender() == router &&
            from == router &&
            to != router &&
            !_exists(tokenId)
        ) {
            require(tokenId > 0, "Token ID invalid");
            migrateFlamingo(router, tokenId, to);
        }
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, data);
    }
}