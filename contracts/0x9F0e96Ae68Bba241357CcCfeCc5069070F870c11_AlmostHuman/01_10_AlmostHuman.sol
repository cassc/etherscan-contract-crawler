// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//@title AlmostHuman Collection

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../src/artifacts/Blacklist/DefaultOperatorFilterer.sol";

contract AlmostHuman is ERC721A, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;

    uint256 MAX_MINTS = 15;
    uint256 MAX_SUPPLY = 10000;
    uint256 public mintRate = 0.03 ether;

    string public baseURI = "ipfs://bafybeib4xxmxcme7bbqn7y7tuzl3wzk3i67ymsddmzfqdh7p7bcsv7labi/";

    bool public publicSale;
    bool public teamMinted;

    constructor() ERC721A("Almost Human", "AH") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "Sale not active yet.");
        require(_quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(msg.value >= (mintRate * _quantity), "Not enough ether sent");
        _safeMint(msg.sender, _quantity);
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }
    //20 nfts for the team and 280 nfts for community giveaways, contests, etc..
    function teamMint() external onlyOwner{
        require(!teamMinted, "Team has already minted");
        teamMinted = true;
        _safeMint(msg.sender, 300);
    }
   
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }
    
    function setMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }

    function withdraw() external onlyOwner{
        // 20% to team
        uint256 withdrawAmount_team = address(this).balance * 20/100;
        // 80% split between 2 community wallet
        uint256 withdrawAmount_community1 = address(this).balance * 40/100;
        uint256 withdrawAmount_community2 = address(this).balance * 40/100;
        payable(0xcAE402d0573062920E4910E7B915e4fFbFF4995C).transfer(withdrawAmount_team);
        payable(0xf23702a8C6Db2277ccAd467803434152a8C7761e).transfer(withdrawAmount_community1);
        payable(0x32B8D4dd1b52a8108f0c049401ea06660BD7F982).transfer(withdrawAmount_community2);
        payable(msg.sender).transfer(address(this).balance);
    }
}