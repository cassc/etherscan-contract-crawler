pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract WoWNft is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, AccessControl {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string public _baseUri;

    mapping(uint256 => bool) private _transferBlock;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TRANSFER_BLOCK_ROLE = keccak256("TRANSFER_BLOCK_ROLE");

    constructor() ERC721("WOW Nft", "WOW") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setBaseURI(string memory baseUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseUri = baseUri;
    }

    function getURI(uint256 tokenId) pure private returns (string memory) {
        return string(abi.encodePacked(tokenId.toString(), ".json"));
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function blockTransfer(uint256 tokenId) external onlyRole(TRANSFER_BLOCK_ROLE) {
        require(ownerOf(tokenId) == _msgSender(), "Not owner");
        _transferBlock[tokenId] = true;
    }

    function unblockTransfer(uint256 tokenId) external onlyRole(TRANSFER_BLOCK_ROLE) {
        require(ownerOf(tokenId) == _msgSender(), "Not owner");
        _transferBlock[tokenId] = false;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function mint(address to) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, getURI(tokenId));
        _transferBlock[tokenId] = false;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    whenNotPaused
    override(ERC721, ERC721Enumerable)
    {
        require(!_transferBlock[tokenId], "Transfer blocked");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}