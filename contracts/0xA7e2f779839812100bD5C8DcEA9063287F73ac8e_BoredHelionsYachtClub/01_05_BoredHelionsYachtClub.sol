// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BoredHelionsYachtClub is ERC721A, Ownable {
    
    uint256 public constant MAX_SUPPLY = 4444;
    bool public saleIsActive = false;

    uint256 public price;
    uint256 public maxMintPerTx;
    uint256 public maxFree;

    string public baseUri;

    constructor() ERC721A("Bored Helions Yacht Club", "BHYC") {
        price = 0.005 ether;
        maxMintPerTx = 25;
        maxFree = 1;
    }

    // Get mint cost
    function getMintCost(uint256 amount, address _owner) public view returns (uint256) {
        uint256 minted = _numberMinted(_owner);
        uint256 freeAmount = minted < maxFree ? maxFree - minted : 0;
        uint256 mintCost = price * (amount - freeAmount);
        return mintCost;
    }

    // Minting
    function mint(uint256 amount) external payable {
        require(tx.origin == msg.sender, "Sender is smart contract");
        require(saleIsActive, "Sale must be active to mint");
        require(amount <= maxMintPerTx, "Amount is too large");
        require(totalSupply() + amount <= MAX_SUPPLY, "Purchase would exceed max supply.");

        uint256 mintCost = getMintCost(amount, msg.sender);
        require(msg.value >= mintCost, "Sent Ether is too low");

        _safeMint(msg.sender, amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxMintPerTx(uint256 _maxMintPerTx) external onlyOwner {
        maxMintPerTx = _maxMintPerTx;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseUri = _newBaseURI;
    }

    function setMaxFree(uint256 _maxFree) external onlyOwner {
        maxFree = _maxFree;
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function allowlistMint(uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Purchase would exceed max supply.");
        _safeMint(msg.sender, amount);
    }

    function airdrop(uint256 amount, address[] memory recipients) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Airdrop would exceed max supply.");

        uint256 amountPerAddress = amount / recipients.length;
        uint256 remainder = amount % recipients.length;

        for (uint256 i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], amountPerAddress);
        }

        if (remainder > 0) {
            _safeMint(recipients[0], remainder);
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // Overrides:

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // Add .json file extension to tokenURI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }
}