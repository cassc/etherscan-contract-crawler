// SPDX-License-Identifier: MIT    



pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NoPanties is ERC721A, Ownable {
    string _baseUri;
    string _contractUri;
    
    uint public maxPerWallet = 10;
    uint public salesStartTimestamp = 1500000000;
    uint public maxSupply = 5000;
    
    mapping(address => uint) public addressToFreeMinted;

    constructor() ERC721A("No Panties", "NPTS") {
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    
    function freeMint(uint quantity) external {
        require(isSalesActive(), "sale is not active");
        require(totalSupply() <= maxSupply, "sold out");
        require(addressToFreeMinted[msg.sender] + quantity <= maxPerWallet, "caller already minted for free");
        
        addressToFreeMinted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
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
    
    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}