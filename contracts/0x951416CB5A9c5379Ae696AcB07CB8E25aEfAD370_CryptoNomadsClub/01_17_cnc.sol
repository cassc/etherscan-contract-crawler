// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract CryptoNomadsClub is
    ERC721,
    ERC2981,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    ReentrancyGuard
{
    uint256 private constant MAX_TOKENS = 3000;

    // PUBLIC TOKENS AMOUNT = 2900;
    // SOUL BOUND TOKENS AMOUNT = 100;

    uint256 private publicAmount;
    uint256 private soulBoundCounter;

    uint256 public availableToMint;
    uint256 public price;
    address public allowList;

    mapping(string => bool) public CITIES;

    constructor() ERC721("Crypto Nomads Club", "CNC") {
        soulBoundCounter = 2900;

        // create a map of city names so we know which names can be minted
        CITIES["AMSTERDAM"] = true;
        CITIES["AUSTIN"] = true;
        CITIES["BALI"] = true;
        CITIES["BARCELONA"] = true;
        CITIES["BUENOS_AIRES"] = true;
        CITIES["DENVER"] = true;
        CITIES["DUBAI"] = true;
        CITIES["LISBON"] = true;
        CITIES["LONDON"] = true;
        CITIES["LOS_ANGELES"] = true;
        CITIES["MIAMI"] = true;
        CITIES["NEW_YORK"] = true;
        CITIES["PARIS"] = true;
        CITIES["RIO_DE_JANEIRO"] = true;
        CITIES["SINGAPORE"] = true;
    }

    function setSaleBatch(
        uint256 batchSize,
        uint256 batchPrice,
        address batchAllowList
    ) external onlyOwner {
        availableToMint = batchSize;
        price = batchPrice;
        allowList = batchAllowList;
    }

    function mint(string[] memory cities) external payable nonReentrant {
        require(
            availableToMint >= cities.length,
            "Not enough available to mint"
        );
        require(
            cities.length > 0 && cities.length <= 5,
            "Invalid amount of cities selected"
        );
        require(
            publicAmount + cities.length < 2900,
            "Not enough public tokens available"
        );
        require(price * cities.length <= msg.value, "Insufficient ETH");
        require(
            allowList == address(0) ||
                ERC721(allowList).balanceOf(msg.sender) > 0,
            "Requires allow list NFT"
        );

        for (uint256 i = 0; i < cities.length; i++) {
            require(CITIES[cities[i]], "Invalid city");
            _safeMint(msg.sender, publicAmount + i);
            string memory finalTokenURI = string(
                abi.encodePacked(cities[i], ".json")
            );
            _setTokenURI(publicAmount + i, finalTokenURI);
        }

        publicAmount += cities.length;
        availableToMint -= cities.length;
    }

    function gift(address receiver, string memory city) external onlyOwner {
        require(soulBoundCounter < 3000, "Run out of soul bound tokens");
        require(CITIES[city], "Invalid city");

        _mint(receiver, soulBoundCounter);
        string memory finalTokenURI = string(abi.encodePacked(city, ".json"));
        _setTokenURI(soulBoundCounter, finalTokenURI);
        soulBoundCounter++;
    }

    function withdrawAll() external {
        payable(owner()).transfer(address(this).balance);
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    // Overriding _baseURI

    function _baseURI()
        internal
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        return "ipfs://QmRgvuYv5Y4qjQfXz7KshzQpSne1kM5dP4jAWuFyyTzZGH/";
    }

    // Overriding transfer hook to check for soulbound

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        // if sender is a 0 address, this is a mint transaction, not a transfer
        require(
            tokenId < 2900 || from == address(0),
            "ERROR: TOKEN IS SOUL BOUND"
        );

        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Necessary overrides for interface extensions

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
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }
}