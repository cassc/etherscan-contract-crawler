//SPDX-License-Identifier: MIT

import "https://github.com/NeonJedi81/contracts/blob/main/dep.sol";

pragma solidity ^0.8.17;

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
    }
    
pragma solidity ^0.8.0;
        interface IMain {function balanceOf( address ) external  view returns (uint);}
     
    contract GangsOfSkate is ERC721A, DefaultOperatorFilterer , Ownable {
    using Strings for uint256;


  string private uriPrefix = "https://gangs-of-skate.fra1.digitaloceanspaces.com/json/";
  string private uriSuffix = ".json";
  string public hiddenURL = "";
  uint256 public cost = 0.02 ether;
  uint16 public  maxSupply = 2022;
  uint8 public maxMintAmountPerTx = 10;
  uint8 public maxMintAmountPerWallet = 20;
  uint8 public maxFreeClaimAmountPerWallet = 1;  
  bool public freeClaimEnabled = true;
  bool public paused = false;
  bool public reveal = true;
  mapping (address => uint8) public maxFreeClaim;
  mapping (address => uint8) public NFTPerAddress;
  uint16 public  freeClaimUntil = 200;
  constructor() ERC721A("GangsOfSkate", "SK8") {}
  
 
 
  function Mint(uint8 _mintAmount) external payable  {
     uint16 totalSupply = uint16(totalSupply());
       uint8 _txPerAddress = NFTPerAddress[msg.sender];
    require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");
    require(_mintAmount <= maxMintAmountPerTx, "Exceeds max nft limit per transaction.");
    require(_txPerAddress + _mintAmount <= maxMintAmountPerWallet, "Exceeds max nft limit per wallet.");
    require(!paused, "The contract is paused!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

    _safeMint(msg.sender , _mintAmount);
    NFTPerAddress[msg.sender] = _txPerAddress + _mintAmount;
     
    delete totalSupply;
    delete _mintAmount;
    }


  function freeClaim(uint8 _mintAmount) external  {
           
    uint8 _txPerAddress = maxFreeClaim[msg.sender];
    
    require (_txPerAddress + _mintAmount <= maxFreeClaimAmountPerWallet, "Exceeds max nft allowed per address");
    require(freeClaimEnabled, "FreeClaim minting is over!");
    uint16 totalSupply = uint16(totalSupply());
    
        require(totalSupply + _mintAmount <= freeClaimUntil, "Exceeds max free claim supply.");
        _safeMint(msg.sender , _mintAmount);
        maxFreeClaim[msg.sender] =_txPerAddress + _mintAmount;
        delete totalSupply;
        delete _mintAmount;
        delete _txPerAddress;
    }
  
    function airDrop(uint16 _mintAmount, address _receiver) external onlyOwner {
    uint16 totalSupply = uint16(totalSupply());
        require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");
        _safeMint(_receiver , _mintAmount);
        delete _mintAmount;
        delete _receiver;
        delete totalSupply;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)
   
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
 
   function setFreeClaimEnabled(bool _state) public onlyOwner {
    freeClaimEnabled = _state;
  }
    

 function setmaxFreeClaim(uint8 _limit) external onlyOwner{
    maxFreeClaimAmountPerWallet = _limit;
   delete _limit;
    }

function setMaxNFTPerAddress(uint8 _limit) external onlyOwner{
    maxMintAmountPerWallet = _limit;
   delete _limit;
    }

  function setUriPrefix(string memory _uriPrefix) external onlyOwner {
    uriPrefix = _uriPrefix;
    }

   function setHiddenUri(string memory _uriPrefix) external onlyOwner {
    hiddenURL = _uriPrefix; 
    }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setCost(uint _cost) external onlyOwner{
      cost = _cost;
    }

    function setMaxSupply(uint16 _maxSupply) external onlyOwner{
      maxSupply = _maxSupply;
    }

      function setFreeClaimUntil(uint16 _freeClaimUntil) external onlyOwner{
      freeClaimUntil = _freeClaimUntil;
    }


 function setRevealed() external onlyOwner{
     reveal = !reveal;
    }  

  function setMaxMintAmountPerTx(uint8 _maxtx) external onlyOwner{
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