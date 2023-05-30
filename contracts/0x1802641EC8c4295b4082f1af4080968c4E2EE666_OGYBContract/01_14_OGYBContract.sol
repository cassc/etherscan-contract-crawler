// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract OGYBContract is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    uint256 public maxBadges = 500;
    bool public isSaleHalted = false;
    string private baseURI = "ipfs://QmS8WzM9McUCpj1jcpn6pfWcTBWVwjxMyFEPDY6Kn72Me4";

    constructor() ERC721("The Order of the Golden Yacht Badge", "OGYB") {}

    function withdraw() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

    function reduceMaxBadges() public onlyOwner {
        maxBadges = totalSupply();
    }

    function flipSaleState() public onlyOwner {
        isSaleHalted = !isSaleHalted;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function mintBadge() public {
        require(!isSaleHalted, "Sale must be active to mint an OGY Badge");
        require(balanceOf(msg.sender) == 0, "OGY Badge already minted");
        require(totalSupply().add(1) <= maxBadges, "Purchase would exceed max supply of OGY Badges");

        uint mintIndex = totalSupply();
        if (totalSupply() < maxBadges) {
            _safeMint(msg.sender, mintIndex);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist.");
        return baseURI;
    }
}