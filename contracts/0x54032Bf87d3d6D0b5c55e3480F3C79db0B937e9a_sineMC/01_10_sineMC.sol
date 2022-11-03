// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/extensions/ERC4907A.sol";

contract sineMC is Ownable,  ReentrancyGuard, ERC721A, ERC4907A {
    uint256 public tokenCount;
    uint256 public batchSize = 1000;

    // 1st 
    uint256 public firstSaleMintPrice    = 0.04 ether; 
    // 2nd 
    uint256 public secondSaleMintPriceSP = 0.04 ether;
    uint256 public secondSaleMintPriceWL = 0.054 ether;
    uint256 public secondSaleMintPrice   = 0.06 ether;
    // 3rd
    
    uint256 public thirdSaleMintPriceSP  = 0.04 ether;
    uint256 public thirdSaleMintPriceWL  = 0.068 ether;
    uint256 public thirdSaleMintPrice    = 0.075 ether;

    // mint limit for each round for each addresses
    uint256 public firstSaleMintLimit = 5;
    uint256 public secondSaleMintLimit = 5;
    uint256 public thirdSaleMintLimit = 5;
    // 
    uint256 public totalMintLimit = 30;
    
    // 
    uint256 public ownerLimit = 1000; // 1000
    uint256 public firstSaleLimit = 3000;  // 2000
    uint256 public secondSaleLimit = 6000; // 3000
    uint256 public thirdSaleLimit = 10000;  // 4000

    //
    uint256 public _totalSupply = 10000;

    bool public firstSaleStart = false;
    bool public secondSaleStart = false;
    bool public thirdSaleStart = false;
    // 
    mapping(address => uint256) public totalMinted; // for all rounds
    mapping(address => uint256) public firstMinted; 
    mapping(address => uint256) public secondMinted; 
    mapping(address => uint256) public thirdMinted; 

    bytes32 public merkleRootWL;
    bytes32 public merkleRootSP;

    bool public revealed = false;
    address public manager;
    
    modifier onlyOwnerOrManager() {
        require(msg.sender == owner() || msg.sender == manager , "Not owner or manager ");
        _;
    }

  constructor(address _manager ) ERC721A("sineMC", "sineMC") {
      manager = _manager;
      tokenCount = 0;
  }

  // owner mint
  function ownerMint(uint256 quantity, address to) external onlyOwnerOrManager {
    require((quantity + tokenCount) <= (_totalSupply), "too many already minted before patner mint");
    require((quantity + tokenCount) <= (ownerLimit), "too many already minted before patner mint");
    _safeMint(to, quantity);
    tokenCount += quantity;
  }
  
  // 1st sale 
  function firstSaleMint(uint256 quantity, address to, bytes32[] calldata _merkleProof) public payable nonReentrant {
    require(firstSaleStart, "Sale Paused");
    require((quantity + tokenCount) <= (firstSaleLimit), "Sorry. No more NFTs for first sale");
    require(firstSaleMintLimit >= firstMinted[msg.sender] + quantity, "You have no Mint left");
    
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRootWL, leaf),"Your address is not eligible whiltelist.");
    refundIfOver(firstSaleMintPrice * quantity);
         
    totalMinted[msg.sender] += quantity;
    firstMinted[msg.sender] += quantity;
    _safeMint(to, quantity);
    tokenCount += quantity;
  }

  // 2nd sale 
  function secondSaleMint(uint256 quantity, address to, bytes32[] calldata _merkleProof) public payable nonReentrant {
    require(secondSaleStart, "Sale Paused");
    require((quantity + tokenCount) <= (secondSaleLimit), "Sorry. No more NFTs for second sale");
    require(totalMintLimit >= totalMinted[msg.sender] + quantity, "You have no Mint left ( totalMintLimit ) ");
    
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    if( MerkleProof.verify(_merkleProof, merkleRootSP, leaf)) {
      // SP Price 
      // require(msg.value == secondSaleMintPriceSP * quantity, "Value sent is not correct (SP) ");
      refundIfOver(secondSaleMintPriceSP * quantity);

      // Mint Limitation for SP 
      require(secondSaleMintLimit >= secondMinted[msg.sender] + quantity, "You have no Mint left");

    } else if( MerkleProof.verify(_merkleProof, merkleRootWL, leaf)) {
      // WL Price 
      // require(msg.value == secondSaleMintPriceWL * quantity, "Value sent is not correct (WL) ");
      refundIfOver(secondSaleMintPriceWL * quantity);

      // Mint Limitation for WL 
      require(secondSaleMintLimit >= secondMinted[msg.sender] + quantity, "You have no Mint left");
    } else {
      // Regular Price 
      // require(msg.value == secondSaleMintPrice * quantity, "Value sent is not correct");
      refundIfOver(secondSaleMintPrice * quantity);
    }

    require((quantity + tokenCount) <= (_totalSupply), "Sorry. No more NFTs");
        
    totalMinted[msg.sender] += quantity;
    secondMinted[msg.sender] += quantity;
    _safeMint(to, quantity);
    tokenCount += quantity;
  }

  // 3rd sale 
  function thirdSaleMint(uint256 quantity, address to, bytes32[] calldata _merkleProof) public payable nonReentrant {
    require(thirdSaleStart, "Sale Paused");

    require(totalMintLimit >= totalMinted[msg.sender] + quantity, "You have no Mint left ( totalMintLimit ) ");
    require((quantity + tokenCount) <= (thirdSaleLimit), "Sorry. No more NFTs for third sale");
    // same 
    require((quantity + tokenCount) <= (_totalSupply), "Sorry. No more NFTs");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    if( MerkleProof.verify(_merkleProof, merkleRootSP, leaf)) {
      // SP Price 
      // require(msg.value == thirdSaleMintPriceSP * quantity, "Value sent is not correct (SP) ");
      refundIfOver(thirdSaleMintPriceSP * quantity);

      // Mint Limitation for SP 
      require(thirdSaleMintLimit >= thirdMinted[msg.sender] + quantity, "You have no Mint left");
    } else if( MerkleProof.verify(_merkleProof, merkleRootWL, leaf)) {
      // WL Price 
      // require(msg.value == thirdSaleMintPriceWL * quantity, "Value sent is not correct (WL) ");
      refundIfOver(thirdSaleMintPriceWL * quantity);
      // Mint Limitation for WL 
      require(thirdSaleMintLimit >= thirdMinted[msg.sender] + quantity, "You have no Mint left");
    } else {
      // Regular Price 
      // require(msg.value == thirdSaleMintPrice * quantity, "Value sent is not correct");
      refundIfOver(thirdSaleMintPrice * quantity);
    }

    totalMinted[msg.sender] += quantity;
    thirdMinted[msg.sender] += quantity;
    _safeMint(to, quantity);
    tokenCount += quantity;
  }


  // check wl 
  function checkWL(address _addr, bytes32[] calldata _merkleProof) view external returns(bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_addr));
    return MerkleProof.verify(_merkleProof, merkleRootWL, leaf);
  }

  // check sp
  function checkSP(address _addr, bytes32[] calldata _merkleProof) view external  returns(bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_addr));
    return MerkleProof.verify(_merkleProof, merkleRootSP, leaf);
  }
  // check wl and sp
  function checkSPWL(address _addr, bytes32[] calldata _merkleProof) view external returns(bool wl, bool sp) {
    bytes32 leaf = keccak256(abi.encodePacked(_addr));
    wl = MerkleProof.verify(_merkleProof, merkleRootWL, leaf);
    sp = MerkleProof.verify(_merkleProof, merkleRootSP, leaf);
  }
  //  
  function switchFirstSale(bool _state) external onlyOwnerOrManager {
    firstSaleStart = _state;
  }
  function switchSecondSale(bool _state) external onlyOwnerOrManager {
    secondSaleStart = _state;
  }
  function switchThirdSale(bool _state) external onlyOwnerOrManager {
    thirdSaleStart = _state;
  }
  //
  function setFirstSaleMintLimit(uint256 newLimit) external onlyOwnerOrManager {
    // require(newLimit<=30, "too much");
    firstSaleMintLimit = newLimit;
  }
  function setSecondSaleMintLimit(uint256 newLimit) external onlyOwnerOrManager {
    // require(newLimit<=30, "too much");
    secondSaleMintLimit = newLimit;
  }
  function setThirdMintLimit(uint256 newLimit) external onlyOwnerOrManager {
    // require(newLimit<=30, "too much");
    thirdSaleMintLimit = newLimit;
  }
  function setTotalMintLimit(uint256 newLimit) external onlyOwnerOrManager {
    totalMintLimit = newLimit;
  }


  // first sale price 
  function setFirstSaleMintPrice(uint256 _price) external onlyOwnerOrManager {
    firstSaleMintPrice = _price;
  }
  // second sale prices 
  function setSecondSaleMintPrice(uint256 _price) external onlyOwnerOrManager {
    secondSaleMintPrice = _price;
  }

  function setSecondSaleMintPriceWL(uint256 _price) external onlyOwnerOrManager {
    secondSaleMintPriceWL = _price;
  }

  function setSecondSaleMintPriceSP(uint256 _price) external onlyOwnerOrManager {
    secondSaleMintPriceSP = _price;
  }
  // third sale prices 
  function setThirdMintPrice(uint256 _price) external onlyOwnerOrManager {
    thirdSaleMintPrice = _price;
  }
  function setThirdMintPriceWL(uint256 _price) external onlyOwnerOrManager {
    thirdSaleMintPriceWL = _price;
  }
  function setThirdMintPriceSP(uint256 _price) external onlyOwnerOrManager {
    thirdSaleMintPriceSP = _price;
  }


  function setMerkleRootWL(bytes32 _merkleRootWL) external onlyOwnerOrManager {
    merkleRootWL = _merkleRootWL;
  }

  function setMerkleRootSP(bytes32 _merkleRootSP) external onlyOwnerOrManager {
    merkleRootSP = _merkleRootSP;
  }

  function setMerkleRootSPWL(bytes32 _merkleRootSP, bytes32 _merkleRootWL) external onlyOwnerOrManager {
    merkleRootSP = _merkleRootSP;
    merkleRootWL = _merkleRootWL;
  }

  //URI
  string public baseURI;
  string public unrevealedTokenUri;
  string private ext;

  //retuen BaseURI.internal.
  function _baseURI() internal view override returns (string memory){
    return baseURI;
  }

  function setExtention(string calldata _ext) external onlyOwnerOrManager {
    ext = _ext;
  }

  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    require(_exists(_tokenId), "URI query for nonexistent token");
    if(revealed == false) {
      return unrevealedTokenUri;
    }
    return string(abi.encodePacked(_baseURI(), Strings.toString(_tokenId), ext));
  }
  

  //set URI
  function setBaseURI(string calldata _baseURI_) external onlyOwnerOrManager {
    baseURI = _baseURI_;
  }
  function setUnrevealedURI(string calldata uri_) public onlyOwnerOrManager {
    unrevealedTokenUri = uri_;
  }
  function setReveal(bool bool_) external onlyOwnerOrManager {
    revealed = bool_;
  }



  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  // withdraw 
  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
  // 
  function setManager(address _manager) external onlyOwner{
    manager = _manager;
  }



    // for ERC4907A

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC4907A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function explicitUserOf(uint256 tokenId) public view returns (address) {
        return _explicitUserOf(tokenId);
    }

}