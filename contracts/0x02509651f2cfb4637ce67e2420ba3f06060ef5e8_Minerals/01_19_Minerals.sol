//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Minerals is
    Ownable,
    ERC721Enumerable,
    ERC721Burnable,
    ReentrancyGuard
{
    event List(uint256 indexed tokenId, uint256 value);
    event Delist(uint256 indexed tokenId);

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_MINERALS = 100;
    uint256 public constant MINT_FEE = 69 * 10**16;
    string public constant IPFS_METADATA_BASIC_URL =
        "https://gateway.pinata.cloud/ipfs/Qmem6btto6zgrSwK9tdzcMVan7NgndfmV8SXqG9xgwdLhk";
    string private _baseTokenURI = IPFS_METADATA_BASIC_URL;

    address public constant DEV = 0xFC3FECe05129cB90A4Df58BA45236B3a4f982c27;

    mapping(uint256 => uint256) public listings; // id to price

    bool public opened;

    constructor() ERC721("Minerals", "ORE") {}

    function open() public onlyOwner {
        require(opened == false, "Already opened");

        // Dev wants some minerals too.
        _preMint(DEV);
        _preMint(DEV);

        opened = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _preMint(address account) private {
        uint256 nextId = _tokenIdTracker.current();
        _safeMint(account, nextId);
        _tokenIdTracker.increment();
    }

    function mint() public payable virtual {
        require(opened == true, "Not opened");
        uint256 nextId = _tokenIdTracker.current();
        require(
            nextId < MAX_MINERALS,
            "Minerals are rare, and they're finished now."
        );
        require(msg.value >= MINT_FEE, "price is low, bid moar.");

        _safeMint(msg.sender, nextId);
        _tokenIdTracker.increment();
    }

    function withdraw() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        listings[tokenId] = 0;
        emit Delist(tokenId);
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function listMineral(uint256 tokenId, uint256 price) public {
        require(
            msg.sender == ownerOf(tokenId),
            "You must own a Mineral to sell it."
        );
        require(price > 0);

        listings[tokenId] = price;
        emit List(tokenId, price);
    }

    function delistMineral(uint256 tokenId) public {
        require(
            msg.sender == ownerOf(tokenId),
            "You must own a Mineral to delist it."
        );

        listings[tokenId] = 0;
        emit Delist(tokenId);
    }

    function buyMineral(uint256 tokenId) public payable nonReentrant {
        require(
            msg.sender != ownerOf(tokenId),
            "I appreciate the effort to pump it but it's yours already."
        );
        require(listings[tokenId] > 0, "Mineral must be for sale to buy.");
        require(
            msg.value >= listings[tokenId],
            "You have to bid more for this Mineral."
        );

        address oldOwner = ownerOf(tokenId);
        _transfer(oldOwner, msg.sender, tokenId);
        listings[tokenId] = 0;

        (bool success, ) = oldOwner.call{value: msg.value}("");
        require(success);
    }
}