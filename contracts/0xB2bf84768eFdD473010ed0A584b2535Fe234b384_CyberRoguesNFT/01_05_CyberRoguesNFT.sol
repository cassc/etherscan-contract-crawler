// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract CyberRoguesNFT is ERC721A, Ownable {
    uint256 public constant PRICE_PRESALE = 8 ether / 100;
    uint256 public constant PRICE = 15 ether / 100;
    uint256 public constant MAX_SUPPLY = 7802;
    uint256 public constant PRESALE_AMOUNT = 525;
    string public baseURI = "ipfs://bafybeigeschymnsatuunlf6vizueyhl5ukpcp3mytgzuryba624fe5o7hm/";

    receive() external payable {
        if (presaleLeft() > 0) {
            uint256 quantity = msg.value / PRICE_PRESALE;
            mintPresale(quantity);
        } else {
            uint256 quantity = msg.value / PRICE;
            mint(quantity);
        }
    }

    constructor() ERC721A("Cyber Rogues", "CR") {
        _safeMint(msg.sender, 25);
    }

    function mintPresale(uint256 quantity) public payable {
        require(msg.value == PRICE_PRESALE * quantity, "invalid payment amount");
        _safeMint(msg.sender, quantity);
        require(totalSupply() <= PRESALE_AMOUNT, "presale sold out");
        payable(owner()).transfer(msg.value);
    }

    function mint(uint256 quantity) public payable {
        require(msg.value == PRICE * quantity, "invalid payment amount");
        _safeMint(msg.sender, quantity);
        require(totalSupply() <= MAX_SUPPLY, "collection sold out");
        payable(owner()).transfer(msg.value);
    }

    function presaleLeft() public view returns (uint256) {
        uint256 supply = totalSupply();
        if (supply >= PRESALE_AMOUNT) return 0;
        else return PRESALE_AMOUNT - supply;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    function updateBaseURI(string calldata newURI) public onlyOwner {
        baseURI = newURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}