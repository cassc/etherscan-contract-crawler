// SPDX-License-Identifier: MIT

 //   _____          _             _    _     
 //  /__   \___ _ __(_)_   _  __ _| | _(_)___ 
 //    / /\/ _ \ '__| | | | |/ _` | |/ / / __|
 //   / / |  __/ |  | | |_| | (_| |   <| \__ \
 //   \/   \___|_|  |_|\__, |\__,_|_|\_\_|___/
 //                    |___/                  
   
pragma solidity ^0.8.2;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Teriyakis is ERC721A, Ownable {
    string _baseUri;
    string _contractUri;
    
    uint public price = 0.044 ether;
    uint public maxFreeMint = 10;
    uint public maxFreeMintPerWallet = 10;
    uint public salesStartTimestamp = 1644812836;
    uint public maxSupply = 4444;
    
    mapping(address => uint) public addressToFreeMinted;

    constructor() ERC721A("Teriyakis", "PEW") {
        _contractUri = "ipfs://QmVeNJs9LfX4HgJ4ipyF8HLSDGBb2uQk9jiWSTLx1vP1pJ";
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