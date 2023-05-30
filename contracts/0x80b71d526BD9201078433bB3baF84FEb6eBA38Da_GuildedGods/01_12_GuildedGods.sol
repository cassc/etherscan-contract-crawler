// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract GuildedGods is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string _baseUri;
    string _contractUri;
    
    uint public maxSupply = 5910;
    uint public price = 0.06 ether;
    uint public maxFreeMint = 1000;
    uint public maxFreeMintPerWallet = 2;
    uint public salesStartTimestamp = 1642114800;
    
    mapping(address => uint) public addressToFreeMinted;

    constructor() ERC721("Guilded Gods", "GG") {
        _contractUri = "ipfs://QmVUiMSmuicdQRdjUqegsPmghHYjYvJP69BJ9UwSUw5vvG";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    
    function freeMint() external {
        require(isSalesActive(), "sale is not active");
        require(totalSupply() < maxFreeMint, "theres no free mints remaining");
        require(addressToFreeMinted[msg.sender] < maxFreeMintPerWallet, "caller already minted for free");
        
        addressToFreeMinted[msg.sender]++;
        safeMint(msg.sender);
    }
    
    function mint(uint quantity) external payable {
        require(isSalesActive(), "sale is not active");
        require(quantity <= 20, "max mints per transaction exceeded");
        require(totalSupply() + quantity <= maxSupply, "sold out");
        require(msg.value >= price * quantity, "ether send is under price");
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }
    
    function batchMint(address[] memory receivers, uint[] memory quantities) external onlyOwner {
        require(receivers.length == quantities.length, "receivers and quantities must be the same length");
        for (uint i = 0; i < receivers.length; i++) {
            for (uint j = 0; j < quantities[i]; j++) {
                safeMint(receivers[i]);
            }
        }
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function updateFreeMint(uint maxFree, uint maxPerWallet) external onlyOwner {
        maxFreeMint = maxFree;
        maxFreeMintPerWallet = maxPerWallet;
    }
    
    function updateMaxSupply(uint newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    function isSalesActive() public view returns (bool) {
        return salesStartTimestamp <= block.timestamp;
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
    
    function setSalesStartTimestamp(uint newTimestamp) external onlyOwner {
        salesStartTimestamp = newTimestamp;
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}