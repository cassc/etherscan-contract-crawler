// SPDX-License-Identifier: MIT
         
   
pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Trybo is ERC721A, Ownable {
    string _baseUri;
    string _contractUri;
    
    uint public price = 0.03 ether;
    uint public maxFreeMint = 100;
    uint public maxFreeMintPerWallet = 10;
    uint public salesStartTimestamp = 1644812836;
    uint public maxSupply = 4444;
    
    mapping(address => uint) public addressToFreeMinted;

    constructor() ERC721A("Trybo", "TRB") {
        _contractUri = "ipfs://QmQouTLr9Cn63ZsNkCQ29NrSQXyMMkN6EeacKymrmTW9hZ";
        _baseUri = "ipfs://QmbFSfNQNXEjvaA8YZDXoqAB8LDvdG9B3MXfMb9CXRrjaJ/";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    
    function freeMint(uint quantity) external {
        require(isSalesActive(), "sale is not active");
        require(totalSupply() + quantity <= maxFreeMint, "theres no free mints remaining");
        require(addressToFreeMinted[msg.sender] + quantity <= maxFreeMintPerWallet, "caller already minted for free");
        
        addressToFreeMinted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }
    
    function mint(uint quantity) external payable {
        require(isSalesActive(), "sale is not active");
        require(quantity <= 20, "max mints per transaction exceeded");
        require(totalSupply() + quantity <= maxSupply, "sold out");
        require(msg.value >= price * quantity, "ether send is under price");
        
        _safeMint(msg.sender, quantity);
    }
    
    function batchMint(address[] memory receivers, uint[] memory quantities) external onlyOwner {
        require(receivers.length == quantities.length, "receivers and quantities must be the same length");
        for (uint i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], quantities[i]);
        }
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
    
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function BaseURI() public view returns (string memory) {
        return _baseUri;
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