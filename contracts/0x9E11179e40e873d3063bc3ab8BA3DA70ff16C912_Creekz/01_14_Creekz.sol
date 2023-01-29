// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import ".deps/npm/@openzeppelin/contracts/token/ERC721/ERC721A.sol";

contract Creekz is ERC721A, Ownable {

    using Strings for uint256;
    event ReceivedEth(uint256 amount);
    string private uriPrefix ;
    string private uriSuffix = ".json";
    string public hiddenURL = "ipfs://QmdTrSnVGZPZWS1gkvTHEfnSwgaAYu9KYRT9WZ5GKscRuZ/1.json";


  
  

    uint256 public cost = 0.0069 ether;
 
  

    uint16 public maxSupply = 2500;
    uint8 public maxMintAmountPerTx = 10;
    uint8 public maxFreeMintAmountPerWallet = 1;
                                                             
 
    bool public paused = true;
    bool public reveal = false;

    bool public onlyWhitelisted = true;
    address[] public whitelistedAddresses;

    mapping (address => uint8) public NFTPerPublicAddress;

    constructor() ERC721A("Creekz", "CRKZ") {
        _safeMint(msg.sender, 15);
    }

    /**
     * 1 FREE per wallet, then 0.0069 ETH each (10 per txn)
     */
    function mint(uint8 _mintAmount) external payable  {
     uint16 totalSupply = uint16(totalSupply());
     uint8 nft = NFTPerPublicAddress[msg.sender];
    require(totalSupply + _mintAmount <= maxSupply, "Sold Out.");
    require(_mintAmount + nft <= maxMintAmountPerTx, "Exceeds max per transaction.");

    require(!paused, "The contract is paused!");

    if (msg.sender != owner()) {
        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "user is not whitelisted");
            uint256 ownerMintedCount = NFTPerPublicAddress[msg.sender];
            require(ownerMintedCount + _mintAmount <= maxMintAmountPerTx, "max NFT per address exceeded");
        }
        if(nft >= maxFreeMintAmountPerWallet)
      {
      require(msg.value >= cost * _mintAmount, "Insufficient funds!");
      }

            else {
          uint8 costAmount = _mintAmount + nft;
          if(costAmount > maxFreeMintAmountPerWallet)
        {
          costAmount = costAmount - maxFreeMintAmountPerWallet;
          require(msg.value >= cost * costAmount, "Insufficient funds!");
        }
        
      }

    }
    
        


    _safeMint(msg.sender , _mintAmount);

    NFTPerPublicAddress[msg.sender] = _mintAmount + nft;
     
     delete totalSupply;
     delete _mintAmount;
  }
  
  function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

   function Reserve(uint16 _mintAmount, address _receiver) external onlyOwner {
     uint16 totalSupply = uint16(totalSupply());
    require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");
     _safeMint(_receiver , _mintAmount);
     delete _mintAmount;
     delete _receiver;
     delete totalSupply;
  }

  function  Airdrop(uint8 _amountPerAddress, address[] calldata addresses) external onlyOwner {
     uint16 totalSupply = uint16(totalSupply());
     uint totalAmount =   _amountPerAddress * addresses.length;
    require(totalSupply + totalAmount <= maxSupply, "Exceeds max supply.");
     for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], _amountPerAddress);
        }

     delete _amountPerAddress;
     delete totalSupply;
  }

 

  function setMaxSupply(uint16 _maxSupply) external onlyOwner {
      maxSupply = _maxSupply;
  }



   
  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
  
if ( reveal == false)
{
    return hiddenURL;
}
    

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString() ,uriSuffix))
        : "";
  }
 
 


 function setFreeMaxLimitPerAddress(uint8 _limit) external onlyOwner{
    maxFreeMintAmountPerWallet = _limit;
   delete _limit;

}

    
  

  function setUriPrefix(string memory _uriPrefix) external onlyOwner {
    uriPrefix = _uriPrefix;
  }
   function setHiddenUri(string memory _uriPrefix) external onlyOwner {
    hiddenURL = _uriPrefix;
  }


  function setPaused() external onlyOwner {
    paused = !paused;
   
  }

  function setCost(uint _cost) external onlyOwner{
      cost = _cost;

  }

 function setRevealed() external onlyOwner{
     reveal = !reveal;
 }

  function setMaxMintAmountPerTx(uint8 _maxtx) external onlyOwner{
      maxMintAmountPerTx = _maxtx;

  }

  function setOnlyWhitelisted(bool _state) public onlyOwner {
      onlyWhitelisted = _state;
    }
  
  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }
 

  function withdraw() external onlyOwner {
  uint _balance = address(this).balance;
     payable(msg.sender).transfer(_balance ); 
       
  }


  function _baseURI() internal view  override returns (string memory) {
    return uriPrefix;
  }

}