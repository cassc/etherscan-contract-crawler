//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract NoLoveInLife is ERC721A, Ownable {

    uint256 public MAX_SUPPLY = 250;
    uint256 public PRICE = 0.005 ether;

    string private BASE_URI;
    uint256 public maxPerWallet = 20;
    bool public mintEnabled;

    address private ADDR1 = 0xa43eE0DdAC31bF684c2d0A678964402322AD7210;    
    address private ADDR2 = 0x356C3D192E749CDaD330B9258E1AB98FcB3345cF;

    struct History {
        uint256 minted;
    }

    mapping(address => History) public history;
    
    constructor() ERC721A("No Love In Life", "LIFE") {}

    function toggleMinting() public onlyOwner {
      mintEnabled = !mintEnabled;
    }

    function setPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
    }

    function updateBaseUri(string memory baseUri) public onlyOwner {
        BASE_URI = baseUri;
    }

    function updateMaxPerWallet(uint256 newMaxPerWallet) public onlyOwner {
        maxPerWallet = newMaxPerWallet;
    }
    
    function _ownerMint(address to, uint256 numberOfTokens) private {
        require(
            totalSupply() + numberOfTokens <= MAX_SUPPLY,
            "Not enough tokens left"
        );

            _safeMint(to, numberOfTokens);
        }

    function ownerMint(address to, uint256 numberOfTokens) public onlyOwner {
        _ownerMint(to, numberOfTokens);
    }


    function mint(uint256 quantity) external payable {
        require(
            mintEnabled, 
            "Mint is not live yet"
        );
       require(
            PRICE * quantity <= msg.value,   
            "Insufficient funds sent"
        );
        require(
            quantity > 0, 
            "Quantity cannot be zero"
        );
        require(
            totalSupply() + quantity < MAX_SUPPLY, 
            "No items left to mint"
        );
        require(
           history[msg.sender].minted + quantity <= maxPerWallet,
            "Too many tokens for one wallet"
        );
        _safeMint(msg.sender, quantity);
        history[msg.sender].minted = history[msg.sender].minted + quantity;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(ADDR1).transfer(balance * 60 / 100); // 60%
        payable(ADDR2).transfer(balance * 40 / 100); // 40%
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }
}