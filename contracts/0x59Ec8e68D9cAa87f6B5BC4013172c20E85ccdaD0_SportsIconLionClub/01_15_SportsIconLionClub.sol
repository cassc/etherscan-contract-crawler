// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SportsIconLionClub is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable
{
    using SafeMath for uint256;

    // Lion price 0.04 ETH
    uint256 public constant lionPrice = 40000000000000000;

    // Maximum purchase at once
    uint256 public constant maxPurchase = 20;

    // Maximum supply
    uint256 public constant maxLions = 9000;

    // Reserve max 350 tokens for founding NFT owners, giveaways, partners, marketing and team
    uint256 public reserve = 350;

    // Sale state
    bool public saleIsActive = false;

    // Provenance hash
    string public provenanceHash = "";

    // Limit single reserve amount
    uint256 private reserveLimit = 30;

    // Base URI
    string private baseURI;

    // Events
    event AssetMinted(address indexed to, uint256 indexed tokenId);

    constructor() ERC721("SportsIcon Lion Club", "SLC") {}

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function mintLion(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint lions");
        require(numberOfTokens > 0, "At least one lion must be minted");
        require(
            numberOfTokens <= maxPurchase,
            "Maximum 20 lions can be minted at once"
        );
        require(
            totalSupply().add(numberOfTokens) <= maxLions,
            "Purchase would exceed the max supply of lions"
        );
        require(
            msg.value >= lionPrice.mul(numberOfTokens),
            "ETH value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();

            if (mintIndex < maxLions) {
                _safeMint(msg.sender, mintIndex);
                emit AssetMinted(msg.sender, mintIndex);
            }
        }
    }

    function reserveLions(address to, uint256 numberOfTokens) public onlyOwner {
        uint256 supply = totalSupply();

        require(numberOfTokens > 0, "At least one lion must be reserved");
        require(
            numberOfTokens <= reserve,
            "There's not enough lions left in reserve"
        );
        require(
            numberOfTokens <= reserveLimit,
            "Only maximum 30 lions can be reserved at once"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(to, supply + i);
        }

        reserve = reserve.sub(numberOfTokens);
    }

    function withdraw() public onlyOwner {
        address payable to = payable(msg.sender);
        uint256 balance = address(this).balance;

        to.transfer(balance);
    }

    function setProvenanceHash(string memory provenance) public onlyOwner {
        provenanceHash = provenance;
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount > 0) {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;

            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }

            return result;
        }

        return new uint256[](0);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
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
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}