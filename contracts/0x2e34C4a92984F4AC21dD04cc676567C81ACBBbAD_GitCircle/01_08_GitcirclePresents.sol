// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 


contract GitCircle is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;

    // CONFIG
    mapping(address => uint) public mintedPerAddress;
    string internal baseUri = "ipfs://bafybeicrx5ytx4h6zshkiyq7pcuy7d7m2rrrmwzmu3qqjv2ck3sp24hotq/";
    uint256 public mintCost = 0.003 ether;
    uint256 public maxSupply = 4610;
    uint256 public maxPerTXN = 10;
    bool private saleStarted = false;
    
    constructor() ERC721A("GitCircle Presents", "GCP") {}
    
    // MINTING
    function mint(uint256 _amount) external payable nonReentrant {
        require(saleStarted, "Sale hasn't started yet.");
        mintModifier(_amount);
    }

    function mintModifier(uint256 _amount) internal {
        require(_amount <= maxPerTXN && _amount > 0, "Max 20 per TXN.");
        uint256 free = mintedPerAddress[msg.sender] == 0 ? 1 : 0;
        require(msg.value >= mintCost * (_amount - free), "1 NFT is free, remaining 0.005 per nft");
        mintedPerAddress[msg.sender] += _amount;
        sendMint(_msgSender(), _amount);
    }

    function sendMint(address _wallet, uint256 _amount) internal {
        require(_amount + totalSupply() <= maxSupply, "There's not enough supply left.");
        _mint(_wallet, _amount);
    }
    
    function devMint(address _wallet, uint256 _amount) public onlyOwner {
  	    uint256 totalMinted = totalSupply();
	    require(totalMinted + _amount <= maxSupply);
        _mint(_wallet, _amount);
    }
    
    // CONFIG
    function setSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }
    
    function setMaxPerTXN(uint256 _max) external onlyOwner {
        maxPerTXN = _max;
    }

    function toggleSale() external onlyOwner {
        saleStarted = !saleStarted;
    }
    
    function setCost(uint256 newCost) external onlyOwner {
        mintCost = newCost;
    }

    // METADATA
    function setMetadata(string calldata newUri) external onlyOwner {
        baseUri = newUri;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseUri;
    }

    

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
            : '';
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    

    // ADMIN
    function trasnferFunds() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
    
}