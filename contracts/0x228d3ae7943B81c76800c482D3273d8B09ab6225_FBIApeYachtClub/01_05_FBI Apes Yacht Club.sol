// SPDX-License-Identifier: MIT                                     

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FBIApeYachtClub is ERC721A, Ownable {
    string _baseUri;
    string _contractUri;
    
    uint public maxFreeMintPerWallet = 1;
    uint public salesStartTimestamp = 1665812422;
    uint public maxSupply = 10000;
    uint public price = 0.003 ether;
    
    mapping(address => uint) public addressToFreeMinted;

    constructor() ERC721A("FBI Ape Yacht Club", "FBI") {
        _contractUri = "ipfs://QmXXqJUaX652hzdyQbPengu4HaSL5Gfzzk6zfdFvgCaaon";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    
    function freeMint(uint quantity) external {
        require(isSalesActive(), "sale is not active");
        require(addressToFreeMinted[msg.sender] + quantity <= maxFreeMintPerWallet, "caller already minted for free");
        
        addressToFreeMinted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }
    
    function mint(uint quantity) external payable {
        require(isSalesActive(), "sale is not active");
        require(quantity <= 10, "max mints per transaction exceeded");
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

    function updateFreeMint(uint maxPerWallet) external onlyOwner {
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