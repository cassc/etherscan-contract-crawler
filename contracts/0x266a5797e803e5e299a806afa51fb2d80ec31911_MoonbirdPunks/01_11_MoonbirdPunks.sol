// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MoonbirdPunks is ERC721A, Ownable {
    uint256 MAX_PER_TX = 10;
    uint256 MAX_SUPPLY = 2469;
    uint256 public MINT_PRICE = 0.02469 ether;
    
    bool public presale = true;
    bool public saleIsActive = false;

    mapping(address => uint8) private _freeAllowList;

    string public baseURI = "https://oofcollective.xyz/assets/mbp/metadata/";

    constructor() ERC721A("MoonbirdPunks", "MBP") {}

    function mintPunk(uint8 quantity) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(!presale, "Still in pre-sale");
        require(saleIsActive, "Sale must be active to mint");
        require(quantity > 0 && quantity <= MAX_PER_TX, "Max per transaction reached");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
        require(msg.value >= MINT_PRICE * quantity, "Not enough ETH for transaction");

        _safeMint(msg.sender, quantity);
    }

    function freeMint(uint8 quantity) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(quantity <= _freeAllowList[msg.sender], "Exceeded max available to purchase");
        require(saleIsActive, "Sale must be active to mint");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
        
        _freeAllowList[msg.sender] -= quantity; //tracking minted
        _safeMint(msg.sender, quantity);
    }

    function ownerMint(address[] calldata addresses, uint256 quantity) external onlyOwner
    {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], quantity, "");
        }
    }

    function setFreeAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _freeAllowList[addresses[i]] = numAllowedToMint;
        }
    }

    function freeAvailableToMint(address addr) external view returns (uint8) {
        return _freeAllowList[addr];
    }

    function setPrice(uint256 price) external onlyOwner 
    {
        MINT_PRICE = price;
    }

    function flipSaleState() external onlyOwner
    {
        saleIsActive = !saleIsActive;
    }

    function flipPresaleState() external onlyOwner
    {
        presale = !presale;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

}