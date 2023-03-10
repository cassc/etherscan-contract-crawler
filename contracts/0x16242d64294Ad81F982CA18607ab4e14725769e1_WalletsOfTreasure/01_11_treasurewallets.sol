//SPDX-License-Identifier: MIT


     /*------------------------------------------------------------*\
    |                    Wallets of Treasure                         |
    |  About 15% of these seed phrases give access to real wallets   |
    |  but only 10 of them contain the treasure - Happy hunting!     |
     \*------------------------------------------------------------*/

 

import "./wot.sol";

pragma solidity ^0.8.17;

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
    }
    
pragma solidity ^0.8.0;
        interface IMain {function balanceOf( address ) external  view returns (uint);}
     
    contract WalletsOfTreasure is ERC721A, DefaultOperatorFilterer , Ownable {
    using Strings for uint256;


  string private uriPrefix = "https://walletsoftreasure.fra1.digitaloceanspaces.com/"; 
  string private uriSuffix = ".json";
  uint256 public cost = 0.01 ether; // 1000000000000000000 wei cost
  uint256 public  maxSupply = 100000;
  uint256 public maxMintAmountPerTx = 100;
  bool public paused = false;

// Treasure Wallets
  address tw1 = 0xfE95C530Fa36e5465e03c63AD1B81d21B8112823; 
  address tw2 = 0xea7E109BFC1e25517A3848c78d570e5571c5eDa8; 
  address tw3 = 0x5036674Dc438c04916DB19daDD93E9C3Da09EFdE; 
  address tw4 = 0xD39DD026B6f701a0aC4c07DF97cc6cd0eC6a073E; 
  address tw5 = 0xaa4a3807357FE95E6a44b329429b3fF6CF97BF04; 
  address tw6 = 0x66307a62753Eb618a8Eb3C12fe1792b730d8f80a; 
  address tw7 = 0x09EB28b33463e6298407168C29d688d831CB70bd; 
  address tw8 = 0x482930b9f79C0Bf3DaDe52e7987599C9a7783fad; 
  address tw9 = 0xdDcE3e6f156D42f805f8F433D45eeCe7bE09616f; 
  address tw10 = 0x7E4547080EEedC3796F2eB1A78e5fb81Dbf648d2; 

  constructor() ERC721A("Wallets of Treasure", "WOT") {}
  
 
  function Mint(uint256 _mintAmount) external payable  {
     uint256 totalSupply = uint256(totalSupply());
    require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");
    require(_mintAmount <= maxMintAmountPerTx, "Exceeds max nft limit per transaction.");
    require(!paused, "The contract is paused!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

    _safeMint(msg.sender , _mintAmount);
     
    delete totalSupply;
    delete _mintAmount;
    }

    function TreasureFill() external onlyOwner {
    uint _balance = address(this).balance;
     payable(tw1).transfer(_balance * 9 / 100 ); 
     payable(tw2).transfer(_balance * 9 / 100 ); 
     payable(tw3).transfer(_balance * 9 / 100 ); 
     payable(tw4).transfer(_balance * 9 / 100 ); 
     payable(tw5).transfer(_balance * 9 / 100 ); 
     payable(tw6).transfer(_balance * 9 / 100 ); 
     payable(tw7).transfer(_balance * 9 / 100 ); 
     payable(tw8).transfer(_balance * 9 / 100 ); 
     payable(tw9).transfer(_balance * 9 / 100 ); 
     payable(tw10).transfer(_balance * 9 / 100 ); 
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)
   
    {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
   
    

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString() ,uriSuffix))
        : "";
    }
 

  function setUriPrefix(string memory _uriPrefix) external onlyOwner {
    uriPrefix = _uriPrefix;
    }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setCost(uint _cost) external onlyOwner{
      cost = _cost;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner{
      maxSupply = _maxSupply;
    }

 

  function setMaxMintAmountPerTx(uint256 _maxtx) external onlyOwner{
      maxMintAmountPerTx = _maxtx;
    }

  function withdraw() external onlyOwner {
  uint _balance = address(this).balance;
     payable(msg.sender).transfer(_balance * 100 / 100 ); 
    }

   
  
  function _baseURI() internal view  override returns (string memory) {
    return uriPrefix;
    }
  
  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}