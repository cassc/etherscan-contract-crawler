// SPDX-License-Identifier: MIT


//  ______   ______     ______   ______     ______   ______     ______     ______    
// /\  == \ /\  __ \   /\__  _\ /\  __ \   /\__  _\ /\  __ \   /\  ___\   /\___  \   
// \ \  _-/ \ \ \/\ \  \/_/\ \/ \ \  __ \  \/_/\ \/ \ \ \/\ \  \ \  __\   \/_/  /__  
//  \ \_\    \ \_____\    \ \_\  \ \_\ \_\    \ \_\  \ \_____\  \ \_____\   /\_____\ 
//   \/_/     \/_____/     \/_/   \/_/\/_/     \/_/   \/_____/   \/_____/   \/_____/ 
//                                                                                   


pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Potatoez is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string _baseUri;
    string _contractUri;
    
    uint public maxFreeMintPerWallet = 2;
    uint public maxFreeMint = 145;
    uint public price = 0.008 ether;
    uint public constant MAX_SUPPLY = 4500;
    bool public isSalesActive = false;
    
    mapping(address => uint) public addressToFreeMinted;

    constructor() ERC721("Potatoez", "PTTZ") {
        _contractUri = "ipfs://QmauCDqCR5uRxbd2eSSCJB7LJ1SLPJvBZNka6sc6YLFUup";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    
    function freeMint() external {
        require(isSalesActive, "Potatoez sale is not active yet");
        require(totalSupply() < maxFreeMint, "There's no more free mint left");
        require(addressToFreeMinted[msg.sender] < maxFreeMintPerWallet, "Sorry, already minted for free");
        
        addressToFreeMinted[msg.sender]++;
        safeMint(msg.sender);
    }
    
    function mint(uint quantity) external payable {
        require(isSalesActive, "Potatoez sale is not active yet");
        require(quantity <= 35, "max mints per transaction exceeded");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Potatoez Sold Out");
        require(msg.value >= price * quantity, "ether send is under price");
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
    
    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }
    
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }
    
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseUri = newBaseURI;
    }
    
    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractUri = newContractURI;
    }
    
    function toggleSales() external onlyOwner {
        isSalesActive = !isSalesActive;
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}