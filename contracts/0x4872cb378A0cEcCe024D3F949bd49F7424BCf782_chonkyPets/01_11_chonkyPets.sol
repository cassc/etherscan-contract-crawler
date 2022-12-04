//SPDX-License-Identifier: MIT

import "https://github.com/NeonJedi81/contracts/blob/main/dep.sol";

pragma solidity ^0.8.0;

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
    }
    
pragma solidity ^0.8.0;
        interface IMain {function balanceOf( address ) external  view returns (uint);}
     
    contract chonkyPets is ERC721A, DefaultOperatorFilterer , Ownable {
    using Strings for uint256;


  string private uriPrefix = "https://chonkypets.nyc3.digitaloceanspaces.com/metadata/";
  string private uriSuffix = ".json";
  string public hiddenURL = "";
  uint256 public cost = 0.0069 ether; // FreeMint for OG hodlers
  uint16 public  maxSupply = 3000;
  uint8 public maxMintAmountPerTx = 6;
  uint8 public maxMintAmountPerWallet = 6;
  uint8 public maxWLMintAmountPerWallet = 1;  
  bool public WLenabled = true;
  bool public paused = true;
  bool public reveal = true;
  mapping (address => uint8) public NFTPerWLAddress;
  mapping (address => uint8) public NFTPerAddress;
  address public ogContractAddress = 0x8FA600364B93C53e0c71C7A33d2adE21f4351da3; //Address of NFT contract that's the key for WL Mint
// Larva Chads        0x8FA600364B93C53e0c71C7A33d2adE21f4351da3
// CryptoDickButts S3 0x42069ABFE407C60cf4ae4112bEDEaD391dBa1cdB
  IMain Main = IMain(ogContractAddress); 

  
  constructor() ERC721A("chonkyPets", "CPET$") {}
  
        function setOgContractAddress(address contractAddr) external onlyOwner {
		ogContractAddress = contractAddr;
        Main= IMain(ogContractAddress);
	}  

     	function setMaxSupply(uint16 _maxSupply) external onlyOwner {
		maxSupply = _maxSupply;
    }  
 
  function publicMint(uint8 _mintAmount) external payable  {
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


  function whitelistMint(uint8 _mintAmount) external  {
           
    uint8 _txPerAddress = NFTPerWLAddress[msg.sender];
    uint bal = Main.balanceOf(msg.sender);
  
       require (_txPerAddress + _mintAmount <= maxWLMintAmountPerWallet, "Exceeds max nft allowed per address");
       require (bal > 0, "You need to hold at least 1 OG NFT to mint");
       require(WLenabled, "Whitelist minting is over!");
       
 

       uint16 totalSupply = uint16(totalSupply());
        require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");
        _safeMint(msg.sender , _mintAmount);
        NFTPerWLAddress[msg.sender] =_txPerAddress + _mintAmount;
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
 
   function setWLenabled(bool _state) public onlyOwner {
    WLenabled = _state;
  }
    

 function setMaxNftPerWlAddress(uint8 _limit) external onlyOwner{
    maxWLMintAmountPerWallet = _limit;
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