pragma solidity ^0.8.0;

import "./IRedlionStudios.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC2981.sol";

contract RedlionStudios is IRedlionStudios, Ownable, ERC2981, AccessControlEnumerable, ERC721Enumerable {

    using BitMaps for BitMaps.BitMap;

    event MintedPublication(address user, uint publication, uint tokenId);

    struct Publication {
        uint128 circulating;
        uint128 max;
        string uriSuffix;
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping (uint => Publication) public publications;
    mapping (uint => uint) public tokenIdToPublication;

    string private _baseTokenURI;
    uint private royaltyFee = 1000; // 10000 * percentage (ex : 0.5% -> 0.005)
    BitMaps.BitMap private _isPublicationPaused;
    BitMaps.BitMap private _isPublicationActive;

    constructor(
        string memory name,
        string memory symbol, 
        string memory baseTokenURI,
        address admin
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function pause(uint publication, bool shouldPause) onlyOwner public {
        if (shouldPause) _isPublicationPaused.set(publication);
        else _isPublicationPaused.unset(publication);
    }

    modifier whenNotPaused(uint publication) {
        require(!_isPublicationPaused.get(publication), "PUBLICATION PAUSED");
        _;
    }

    modifier whenActive(uint publication) {
        require(_isPublicationActive.get(publication), "PUBLICATION INACTIVE");
        _;
    }
    
    function changeBaseURI(string memory baseTokenURI) onlyOwner public {
        _baseTokenURI = baseTokenURI;
    }

    function setRoyaltyFee(uint fee) onlyOwner public {
        royaltyFee = fee;
    }

    function setURISuffix(uint publication, string memory uriSuffix) onlyOwner public {
        publications[publication].uriSuffix = uriSuffix;
    }

    function setMinter(address minter) onlyRole(DEFAULT_ADMIN_ROLE) public {
        grantRole(MINTER_ROLE, minter);
    }

    function unsetMinter(address minter) onlyRole(DEFAULT_ADMIN_ROLE) public {
        revokeRole(MINTER_ROLE, minter);
    }

    function launchNewPublication(
        uint256 publication,
        uint128 max,
        string memory uriSuffix) onlyOwner public {
        publications[publication].max = max;
        publications[publication].uriSuffix = uriSuffix;
        _isPublicationActive.set(publication);
        _isPublicationPaused.set(publication); //pause by default

    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public override view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        return (owner(), (_salePrice*royaltyFee)/10000);
    }

    function internalMint(uint256 publication, uint128 amount, address to) internal {
        for(uint128 i = 0; i < amount; i++) {
            uint256 tokenId = (publication * (10**6)) + (publications[publication].circulating++);
            tokenIdToPublication[tokenId] = publication;
            _safeMint(to, tokenId);
            emit MintedPublication(to, publication, tokenId);
        }
    }

    function ownerMint(uint publication, address[] calldata recipients) onlyOwner public {
        for(uint i = 0; i < recipients.length; i++) {
            internalMint(publication, 1, recipients[i]);
        }
    }
    
    function mint(uint256 publication, uint128 amount, address to)
    onlyRole(MINTER_ROLE)
    whenActive(publication)
    whenNotPaused(publication)
    public override {
        internalMint(publication, amount, to);
    }

    function isPublicationPaused(uint publication) public view returns (bool) {
        return _isPublicationPaused.get(publication);
    }

    function isPublicationActive(uint publication) public view returns (bool) {
        return _isPublicationActive.get(publication);
    }

    function tokenURI(uint256 tokenId) public override(ERC721) view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), publications[tokenIdToPublication[tokenId]].uriSuffix));
    }
    
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721Enumerable, AccessControlEnumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}