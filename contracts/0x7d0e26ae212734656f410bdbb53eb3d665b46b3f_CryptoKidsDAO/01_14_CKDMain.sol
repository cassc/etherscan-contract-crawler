// SPDX-License-Identifier: GPL-3.0

//Developer:FazelPejmanfar , Twitter:@Pejmanfarfazel || [email protected]



pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";



  contract CryptoKidsDAO is ERC721A, Ownable {
  using Strings for uint256;
 
 uint256 supply = totalSupply();

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public preSaleCost = 0 ether;
  uint256 public cost = 0 ether;
  uint256 public maxSupply = 5055;
  uint256 public preSaleMaxSupply = 5055;
  uint256 public maxMintAmountPresale = 5;
  uint256 public maxsize = 20 ; // max mint per tx, this cannot be changed after deploy
  uint256 public nftPerAddressLimitPresale = 5;
  uint256 public nftPerAddressLimit = 5;
  uint256 public preSaleDate = 1650188880;
  uint256 public preSaleEndDate = 1650322800;
  uint256 public publicSaleDate = 1650326400;
  bytes32 public merkleRoot = 0xdf0b572df57cfa352bb3574873e829550dc38fbf27d55036878882399ff267fa;
  bool public paused = false;
  bool public revealed = false;

  
  constructor(
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721A("Crypto Kids DAO", "CKD", maxsize) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  //MODIFIERS
  modifier notPaused {
    require(!paused, "the contract is paused");
    _;
  }

  modifier saleStarted {
    require(block.timestamp >= publicSaleDate, "Sale has not started yet");
    _;
  }

    modifier presasaleStarted {
    require(block.timestamp >= preSaleDate, "PreSale has not started yet");
    _;
  }

  modifier minimumMintAmount(uint256 _mintAmount) {
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    _;
  }

  // INTERNAL
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }



  /// @dev PUBLICMINT
     function mint(uint256 _mintAmount)
    public
    payable
    notPaused
    saleStarted
  {
    uint256 ownerTokenCount = balanceOf(msg.sender);
    require(ownerTokenCount + _mintAmount <= nftPerAddressLimit, "max NFT per Wallet exceeded");
    require(_mintAmount <= maxsize, "max mint amount per transaction exceeded");
    require(supply + _mintAmount <= 5055, "MaxSupply exceeded");

     _safeMint(_msgSender(), _mintAmount);
  }
     /// @dev PRESALEMINT
     function mintPresale(uint256 _mintAmount, bytes32[] calldata merkleProof) 
     public 
     payable 
     notPaused 
     presasaleStarted {
        uint256 ownerMintCount = balanceOf(msg.sender);
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "You are not eligible for the presale");
        require(ownerMintCount + _mintAmount <= nftPerAddressLimitPresale, "Presale limit for this wallet reached");
        require(_mintAmount <= maxMintAmountPresale, "Cannot purchase this many NFT in a transaction");
        require(supply + _mintAmount <= preSaleMaxSupply, "Minting would exceed Presale max supply");
        require(_mintAmount > 0, "Must mint at least one token");
        require(msg.value >= preSaleCost * _mintAmount, "ETH amount is low");

        _safeMint(_msgSender(), _mintAmount);
    }

   function mintForOwner(uint256 _mintAmount) public onlyOwner {
    require(!paused);
    require(_mintAmount > 0);
    require(supply + _mintAmount <= maxSupply);
    
    _safeMint(_msgSender(), _mintAmount);
  }



 
  
  function gift(uint256 _mintAmount, address destination) public onlyOwner {
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

   _safeMint(destination, _mintAmount);
  }

  //PUBLIC VIEWS


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

    if (!revealed) {
      return notRevealedUri;
    } else {
      string memory currentBaseURI = _baseURI();
      return
        bytes(currentBaseURI).length > 0
          ? string(
            abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)
          )
          : "";
    }
  }
  


  //ONLY OWNER VIEWS
  function getBaseURI() public view onlyOwner returns (string memory) {
    return baseURI;
  }

      function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

  function getContractBalance() public view onlyOwner returns (uint256) {
    return address(this).balance;
  }

  //ONLY OWNER SETTERS
  function reveal(bool _state) public onlyOwner {
    revealed = _state;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setNftPerAddressLimitPreSale(uint256 _limit) public onlyOwner {
    nftPerAddressLimitPresale = _limit;
  }

  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

  function setPresaleCost(uint256 _newCost) public onlyOwner {
    preSaleCost = _newCost;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmountPreSale(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmountPresale = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setPresaleMaxSupply(uint256 _newPresaleMaxSupply) public onlyOwner {
    preSaleMaxSupply = _newPresaleMaxSupply;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setPreSaleDate(uint256 _preSaleDate) public onlyOwner {
    preSaleDate = _preSaleDate;
  }

  function setPreSaleEndDate(uint256 _preSaleEndDate) public onlyOwner {
    preSaleEndDate = _preSaleEndDate;
  }

  function setPublicSaleDate(uint256 _publicSaleDate) public onlyOwner {
    publicSaleDate = _publicSaleDate;
  }


  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}