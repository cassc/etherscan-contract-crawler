// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

//import "./ERC721A.sol";
import "erc721a/contracts/ERC721A.sol";

// Import this file to use console.log
import "hardhat/console.sol";

contract Vincents is Ownable, ERC721A, ReentrancyGuard, Pausable{

    address private _withdrawalWallet;
    address private _signerWallet;
    uint16 private collectionSize = 6000;
    uint16 private maxBatchSize = 5;
    bool private _isRevealed = false;
    
    string private _blindboxURI; 

 
    string  private _baseTokenURI;
    address private crossmintAddress = 0xdAb1a1854214684acE522439684a145E62505233;
    

    struct SaleStatus {
        uint32 startTime;
        uint64 price;
        uint16 maxSupply;
    }
    
    mapping (uint8 => SaleStatus) saleStages;
    /* 
        Sale Stages:
        0- crossmint sale
        1 - whitelist sale
        2 - public sale
    */

    constructor(string memory name,
        string memory symbol, address signer, string memory blindbox, string memory baseUri) ERC721A(name, symbol) {
        _withdrawalWallet = owner();
        _signerWallet = signer;
        _blindboxURI = blindbox;
        _baseTokenURI = baseUri;
       saleStages[0].startTime = 1668650400;
       saleStages[0].price = 0.11 ether;
       saleStages[0].maxSupply = collectionSize;
       saleStages[1].startTime = 1668650400;
       saleStages[1].price = 0.11 ether;
       saleStages[1].maxSupply = collectionSize;
       saleStages[2].startTime = 1668819600;
       saleStages[2].price = 0.11 ether;
       saleStages[2].maxSupply = collectionSize;

      
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    modifier isUserWallet() {
        require(tx.origin == msg.sender, "I don't like bots");
        _;
    }


    function setSaleTime(uint8 stage, uint32 time) public onlyOwner {
        saleStages[stage].startTime = time;
    }

    function setSalePrice(uint8 stage, uint64 price) public onlyOwner {
        saleStages[stage].price = price;
    }

    function setSaleSupply(uint8 stage, uint16 supply) public onlyOwner {
        saleStages[stage].maxSupply = supply;
    }

    function isSaleActive(uint8 stage) public view returns (bool) {
        return saleStages[stage].startTime > 0 && block.timestamp >= saleStages[stage].startTime;
    }

    function getSaleStatus(uint8 stage) public view returns (SaleStatus memory) {
        return saleStages[stage];
    }

    function devMint(uint256 qty)
    external onlyOwner {
        require(totalSupply() + qty <= collectionSize, 
        "Max Supply Reached");

        _safeMint(msg.sender, qty);
    }
    
    function mint(uint256 qty) external payable isUserWallet  {
         require(totalSupply() + qty <= saleStages[2].maxSupply, "Max supply reached");
         require(totalSupply() + qty <= collectionSize, "Sold Out!");
        require(numberMinted(msg.sender) + qty <= maxBatchSize, "exceed max no. of NFT"); 
         require (saleStages[2].startTime > 0 && block.timestamp >= saleStages[2].startTime, "Sale has not started yet");
          require(msg.value >= saleStages[2].price*qty, "Not enough Eth");  
        _safeMint(msg.sender, qty);
      
    }

    function whitelistMint (uint256 qty, bytes32 hash, bytes memory signature) external payable isUserWallet  {
         require(totalSupply() + qty <= saleStages[1].maxSupply, "Max supply reached");
         require(totalSupply() + qty <= collectionSize, "Sold Out!");
         require(numberMinted(msg.sender) + qty <= maxBatchSize, "exceed max no. of NFT");
         require (saleStages[1].startTime > 0 && block.timestamp >= saleStages[1].startTime, "Sale has not started yet");
          require(msg.value >= saleStages[1].price*qty, "Not enough Eth");  
        require(verifySignature(hash, signature) == true, "Incorrect Signature");
         _safeMint(msg.sender, qty);

    }

    function setBatchSize(uint16 _batchSize) external onlyOwner {
        maxBatchSize = _batchSize;
    }

    function getBatchSize() external view returns (uint16) {
        return maxBatchSize;
    }

    function openVincentBlindbox(bool isOpen) external onlyOwner {
        _isRevealed = isOpen;
    }

    function numberMinted(address owner) 
    public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setWithdrawalWallet(address newAddress) 
    external onlyOwner {
       _withdrawalWallet = newAddress;
    }

     function _setSignerWallet (address newAddress) external onlyOwner {
        _signerWallet = newAddress;
     }

    function getCollectionSize() external view returns (uint16) {
        return collectionSize;
    }

    function setCollectionSize(uint16 newSize) external onlyOwner {
        collectionSize = newSize;
    }

    function verifySignature (bytes32 hash, bytes memory signature) public view returns (bool) {      
        bytes32 requestHash = keccak256(abi.encodePacked(msg.sender));
        bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", 
            hash));
        return requestHash == hash && ECDSA.recover(messageDigest, signature) == _signerWallet;
    }

    
   

    function _baseURI() 
    internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBlindboxUri(string memory newUri) external onlyOwner {
        _blindboxURI = newUri;
    }

    function setBaseURI(string memory newBaseURI) 
    external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if(!_isRevealed) {
        return _blindboxURI;
    } else {

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"))
        : _blindboxURI;
    }
  }

    function onwerAddress(uint256 tokenId)
    external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }


    function withdraw () external onlyOwner nonReentrant {
        require(_withdrawalWallet != address(0), "Withdrawal wallet not set");
       (bool success, ) = msg.sender.call{value: address(this).balance}("");
       require (success, "Withdrawal Failed");
    }

  /*crossmint */
  function crossmint(address _to, uint16 count) public payable {
    require(msg.value >= saleStages[0].price, "Incorrect ETH value sent");
    require(saleStages[0].startTime > 0 && block.timestamp >= saleStages[0].startTime, "Sale has not started yet");
    require(totalSupply() + count <= saleStages[0].maxSupply, "Max supply reached");
    require(totalSupply() + count <= collectionSize, "Sold Out!");
    require(msg.sender == crossmintAddress,
      "This function is for Crossmint only."
    );
    _safeMint(_to, count);
  }
  
  
     function setCrossmintAddress(address _crossmintAddress) public onlyOwner {
    crossmintAddress = _crossmintAddress;
  }

}