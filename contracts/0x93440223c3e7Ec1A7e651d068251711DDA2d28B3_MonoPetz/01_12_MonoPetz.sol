////////////////////////////////////////////////////////////////////////////////////
//________________________________________________________________________________//
//________________________________________________________________________________//
//________________________________________________________________________________//
//____________________________MONOMONOMONOMONOMONOMONO____________________________//
//____________________________PETZPETZPETZPETZPETZPETZ____________________________//
//________________________ONOM________________________MONO________________________//
//________________________PETZ________________________PETZ________________________//
//____________________MONO________________________________MONO____________________//
//____________________PETZ________________________________PETZ____________________//
//____________________MONO________________________________MONO____________________//
//____________________PETZ________________________________PETZ____________________//
//____________________MONO________________________________MONO____________________//
//____________________PETZ________MONO____________MONO____PETZ____________________//
//____________________MONO________PETZ____________PETZ____MONO____________________//
//____________________PETZ________MONO____________MONO____PETZ____________________//
//____________________MONO________PETZ____________PETZ____MONO____________________//
//____________________PETZ________________________________PETZ____________________//
//____________________MONO________________________________MONO____________________//
//________________________PETZ________________________PETZ________________________//
//________________________MONO________________________MONO________________________//
//____________________________PETZPETZPETZPETZPETZPETZ____________________________//
//____________________________MONOMONOMONOMONOMONOMONO____________________________//
//________________________________________________________________________________//
//________________________________________________________________________________//
//________________________________________________________________________________//
////////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT
 
pragma solidity >=0.8.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract MonoPetz is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;
 
  string public _baseTokenURI;
  string public hiddenMetadataUri;
  string public baseExtension = ".json";
 
  uint256 public cost = 0 ether;
  uint256 public maxSupply = 6969;
  uint256 public maxForSale = 6969;
  uint256 public maxForClaim = 6969;
  uint256 public claimed=0;
  uint256 public sold =0;
  uint256 public maxMintAmountPerTx = 300;
 
  bool public pausedSale=true;
  bool public pausedClaim=true;
  bool public revealed;
  mapping(address => uint256) private claimed_done;
  

  ERC721A private monoBitz=ERC721A(0xbfd2030a15dF8Dd65F4dd9Cce4690A312bEda820);
  constructor(
    string memory _hiddenMetadataUri
  ) ERC721A("MonoPetz", "MONOPETZ") {
    setHiddenMetadataUri(_hiddenMetadataUri);
  }
 
  function mint(uint256 _mintAmount) public payable nonReentrant {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(sold + _mintAmount <= maxForSale, "Max supply for sale exceeded!");
    require(!pausedSale, "The sale is paused!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
     _safeMint(_msgSender(), _mintAmount);
    sold+=_mintAmount;
  }
 
 function claim() public nonReentrant {
    uint256 amount=unclaimed(_msgSender());
    if (claimed + amount > maxForClaim) {
        amount=maxForClaim - claimed;
    }
    require(claimed_done[_msgSender()]==0, "You already claimed!");
    require(claimed + amount <= maxForClaim, "Max supply for claim exceeded!");
    require(!pausedClaim, "The claim is paused!");
    claimed_done[_msgSender()]=amount;
    _safeMint( _msgSender(), amount);
    claimed+=amount;
    
  }
 
  function unclaimed(address user) public view returns(uint256){
      if (claimed_done[user] > 0 ) return 0;
      return monoBitz.balanceOf(user);
  }
 
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
 
  function revealTheKrakenz() public onlyOwner {
    revealed = true;
  }
 
  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }
 
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }
 
  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }
  function setMaxForSale(uint256 supply) public onlyOwner {
    maxForSale = supply;
  }
  function setMaxForClaim(uint256 supply) public onlyOwner {
    maxForClaim = supply;
  }
  
  function setPausedSale(bool _state) public onlyOwner {
    pausedSale = _state;
  }
  function setPausedClaim(bool _state) public onlyOwner {
    pausedClaim = _state;
  }
  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
 
  // METADATA HANDLING
 
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }
 
  function setBaseURI(string calldata baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }
 
  function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
  }
 
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId), "URI does not exist!");
 
      if (revealed) {
          return string(abi.encodePacked(_baseURI(), _tokenId.toString(), baseExtension));
      } else {
          return hiddenMetadataUri;
      }
  }
  
}