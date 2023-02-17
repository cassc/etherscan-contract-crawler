// SPDX-License-Identifier: MIT


pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UnderwrldNFT is ERC721, Ownable {
  using Strings for uint256;

  //counters to regulate the current amount of NFT Toekns minted
  //using statment
  using Counters for Counters.Counter;


  
  Counters.Counter private supply;


//declare data strucure to store allow list member Addresses 
  mapping(address => bool) public allowList; 



  //Data structure to track mints per wallet
  mapping(address => uint256 ) private mintedPerWallet;


//BaseURI Declarations 
  string public uriPrefix = ""; //check
  string public uriSuffix = ".json";  //check
  string public hiddenMetadataUri; //check
  

//Supply & Pricing Declarations/Definitons
  uint256 public cost = 0.0025 ether;  //check 
  uint256 public freeCost = 0.0 ether;  //check  = 0.0 ether
  uint256 public allowListCost = 0.001 ether; //check = 0.001 ether
  uint256 public maxSupply ;  //check = 5000
  uint256 public freeSupply ; //check = 500
  uint256 public maxPublicMintSupply ; //check  = 4500
  uint256 public allowListSupply ;  //check = 0
  uint256 public maxMintAmountPerTx ;  //check  = 10


//Contract Control Declarations
  bool public paused = true; //check
  bool public publicMintOpen = false;  //check
  bool public allowListMintOpen = false;  //check
  bool public revealed = false;  //check





  constructor() ERC721("UNDRWRLD", "UDW") {
    setHiddenMetadataUri("ipfs://QmdCGQ8PYEprhHA1SmUQVN3ho4Lq9eaqQMY5Uno5MAiGX9/hidden.json"); 
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }


//saves gas by replacing the enummeration import 
  function totalSupply() public view returns (uint256) {
    return supply.current();
  }


//set adddress allowlist/.  populate allowlist 
  function setAllowList(address[] calldata addresses) external onlyOwner {
    for(uint256 i = 0; i < addresses.length; i++){
      allowList[addresses[i]] = true;
    }
  } 


  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(publicMintOpen, "Public Mint is not open!");
    require(mintedPerWallet[msg.sender] + _mintAmount <= 20, "you can only mint 20 per wallet");


      //mint 500 fee or mint first 1 free
    if(totalSupply() < freeSupply) {
        require(msg.value >= freeCost * _mintAmount, "Insufficient funds for free mint!");
        require(_mintAmount + totalSupply() <= freeSupply, "the amount you wish to mint will exceed the freesupply!! :(");
        require(totalSupply() <= freeSupply, "total supply exceeds the free supply, frees are gone!!");

        _mintLoop(msg.sender, _mintAmount);
         mintedPerWallet[msg.sender] += _mintAmount; 

    }
    else if (totalSupply() >= freeSupply) {
        require(totalSupply() >= freeSupply, "free mints are still Available ");
        require(msg.value >= cost * _mintAmount, "Free Mint Closed! - Insufficient funds!");
        _mintLoop(msg.sender, _mintAmount);
        mintedPerWallet[msg.sender] += _mintAmount; 

    }
      
  }


//Allow list Mint--  TODO:  Edit allowlist metrics and requirments 
  function AllowListMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(allowListMintOpen, "Allow List Mint is not open!");

    //require allow list membership 
    require(allowList[msg.sender], "You are not on the Allowlist");

    //mint 500 fee or mint first 1 free
    if(totalSupply() < freeSupply) {
      require(msg.value >= freeCost * _mintAmount, "Insufficient funds!");
      require(totalSupply() <= freeSupply, "total supply exceeds the free supply, frees are gome!!");
      require(_mintAmount + totalSupply() <= freeSupply, "the amount you wish to mint will exceed the freesupply!! :(");
      _mintLoop(msg.sender, _mintAmount);
    }
    else if (totalSupply() >= freeSupply) {
        require(totalSupply() >= freeSupply, "free mints are still Available ");
        require(msg.value >= allowListCost * _mintAmount, "Free Mint Closed! - Insufficient funds!");
        _mintLoop(msg.sender, _mintAmount);
    }
      
  }

  function editMintWindow(bool _publicMintOpen, bool _allowlistMintOpen) external onlyOwner {
    publicMintOpen = _publicMintOpen;
    allowListMintOpen = _allowlistMintOpen;
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
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

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

//general onlyOwner functions 



  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }
  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }
  function setFreeCost(uint256 _freeCost) public onlyOwner {
    freeCost = _freeCost;
  }
  function setAllowListCost(uint _allowListCost) public onlyOwner {
    allowListCost = _allowListCost;
  }
  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }
  function setPublicMaxSupply(uint256 _maxPublicMintSupply) public onlyOwner {
    maxPublicMintSupply =  _maxPublicMintSupply;
  }
  function setAllowListSupply(uint256 _allowListSupply) public onlyOwner {
    allowListSupply =  _allowListSupply;
  }
  function setFreeSupply(uint256 _freeSupply) public onlyOwner {
    freeSupply = _freeSupply;
  }
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }


  function withdraw() public onlyOwner {
  
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}