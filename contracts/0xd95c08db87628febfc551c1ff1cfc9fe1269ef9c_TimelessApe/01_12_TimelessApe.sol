// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";


contract TimelessApe is ERC721A, Ownable {
    using Strings for uint256;
    
    uint256 public PRESALE_PRICE = 0.07 ether;
    uint256 public PUBLIC_PRICE = 0.1 ether;
    uint256 public MAX_PER_TX = 20;
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public PRESALE_SUPPLY = 1000;
    uint256 public reserved = 200;

    bool public presaleOpen = false;
    bool public publicSaleOpen = false;
    string public baseExtension = '.json';
    string private _baseTokenURI;
    string public PROVENANCE;

    mapping(address => uint256) public _presaleWallets;

    constructor() ERC721A("Timeless Ape Club", "TIMELESS") {}

    function presaleMint(uint256 quantity) external payable {
        require(presaleOpen, "Pre-sale is not open");
        require(quantity > 0, "quantity of tokens cannot be less than or equal to 0");
        require(quantity <= 5 - _presaleWallets[msg.sender], "exceeded max per wallet");
        require(totalSupply() + quantity <= PRESALE_SUPPLY, "exceeded presale supply");
        require(totalSupply() + quantity <= MAX_SUPPLY - reserved, "exceed max supply of tokens");
        require(msg.value >= PRESALE_PRICE * quantity, "insufficient ether value");

        _presaleWallets[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function mintApe(uint256 quantity) external payable {
        require(publicSaleOpen, "Public Sale is not open");
        require(quantity > 0, "quantity of tokens cannot be less than or equal to 0");
        require(quantity <= MAX_PER_TX, "exceed max per transaction");
        require(totalSupply() + quantity <= MAX_SUPPLY - reserved, "exceed max supply of tokens");
        require(msg.value >= PUBLIC_PRICE * quantity, "insufficient ether value");

        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenID) public view virtual override returns (string memory) {
        require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");
        string memory base = _baseURI();
        require(bytes(base).length > 0, "baseURI not set");
        return string(abi.encodePacked(base, tokenID.toString(), baseExtension));
    }

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseExtension(string memory _newExtension) public onlyOwner {
        baseExtension = _newExtension;
    }

    /* *************** */
    /* OWNER FUNCTIONS */
    /* *************** */
    function giveAway(address to, uint256 quantity) external onlyOwner {
        require(quantity <= reserved);
        reserved -= quantity;
        _safeMint(to, quantity);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function updatePresaleSupply(uint256 newLimit) external onlyOwner {
        PRESALE_SUPPLY = newLimit;
    }

    function togglePresale() external onlyOwner {
        presaleOpen = !presaleOpen;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleOpen = !publicSaleOpen;
    }

    function changePresalePrice(uint256 price) external onlyOwner {
        PRESALE_PRICE = price;
    }

    function changePublicSalePrice(uint256 price) external onlyOwner {
        PUBLIC_PRICE = price;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}