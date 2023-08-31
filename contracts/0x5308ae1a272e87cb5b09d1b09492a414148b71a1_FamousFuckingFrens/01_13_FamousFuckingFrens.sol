// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol"; 
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";  
 
//........................................................................
//........................................................................
//...||     ||     ||     ||  || ||||||    |||||||| ||||||   |||||| |||   ||  ||||||
//...|||| ||||    ||||    || ||  ||        ||       ||   ||  ||     ||||  || ||
//...||  || ||   ||  ||   ||||   |||||     |||||||  ||||||   |||||  || || ||  |||||
//...||     ||  ||||||||  || ||  ||        ||       ||   ||  ||     ||  ||||      ||
//...||     || ||      || ||  || ||||||    ||       ||    || |||||| ||   ||| ||||||
//...
//...||    ||    ||||  ||||||||    ||          ||     ||      ||||||
//...|||   ||   ||  ||    ||        ||   ||   ||     ||||     ||   ||
//...|| || ||  ||    ||   ||         || ||| |||     ||  ||    ||||||
//...||  ||||   ||  ||    ||          |||  |||     ||||||||   ||   ||
//...||    ||    ||||     ||           ||  ||     ||      ||  ||    ||
//........................................................................
//...........................................................made with <3  
//........................................................................

contract FamousFuckingFrens is Ownable, ERC721A  { 
  using ECDSA for bytes32;
  using Strings for uint256; 
  string _baseTokenURI;  
  uint256 private _price = 0.0 ether;  
  bool public _paused = true;     
  bool public _pausedWL = true;   
  uint256 private nLimitPerWallet = 4;
  uint256 private nLimitPerTx = 5;
  address private _signatureAddress = 0x527866865Bf4a75fe9c293E342F46BF52f9d7C31;
  mapping(string => bool) private _mintedNonces; 
  mapping(address => uint256) public mintedAddress;
  uint256 public immutable maxPerQtyPerMint;

  constructor(
    string memory name,
    string memory symbol,
    string memory baseURI,
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) 
  ERC721A(name,symbol, maxBatchSize_, collectionSize_) {
    maxPerQtyPerMint = maxBatchSize_; 
    setBaseURI(baseURI); 
  } 
  modifier notContract() {
    require(tx.origin == msg.sender, "9");
    _;
  }
  function giveAway(address _to, uint256 _amount) external onlyOwner() {
      uint256 supply = totalSupply(); 
      require( supply + _amount < 8889,  "Exceeds maximum Frens supply" ); 
      mintedAddress[msg.sender] += _amount; 
      _safeMint(_to, _amount);
  } 
  function AlistersOnly(uint256 num, bytes memory signature, string memory nonce) public payable  {
      uint256 supply = totalSupply();  
      require( !_pausedWL, "1" );
      require( supply + num < 8889,"Exceeds maximum Frens supply" );
      require( num < nLimitPerTx, "Frens per tx reached" );
      require( matchAddresSignature(hashTransaction(msg.sender, num, nonce), signature),   "4");
      require(!_mintedNonces[nonce], "5");  
      require( balanceOf(msg.sender) + num <= nLimitPerWallet, "Frens per wallet reached"); 
      mintedAddress[msg.sender] += num; 
      _safeMint(msg.sender, num); 
      _mintedNonces[nonce] = true;  
  }  
  function WhoDoYouKnowHereMint(uint256 num) public payable notContract {
      uint256 supply = totalSupply(); 
      require( !_paused, "1" );
      require( num < nLimitPerTx, "Frens per tx reached" );
      require( supply + num < 8889, "Exceeds maximum Frens supply" );
      require( balanceOf(msg.sender) + num <= nLimitPerWallet, "Frens per wallet reached"); 
      mintedAddress[msg.sender] += num; 
      _safeMint(msg.sender, num);
  }  
  function hashTransaction(address sender, uint256 qty, string memory nonce) private pure returns(bytes32) {
      bytes32 hash = keccak256(abi.encodePacked(
          "\x19Ethereum Signed Message:\n32",
          keccak256(abi.encodePacked(sender, qty, nonce)))
      ); 
      return hash;
  }
  function matchAddresSignature(bytes32 hash, bytes memory signature) private view returns(bool) {
      return _signatureAddress == hash.recover(signature);
  }
  function setSignatureAddress(address addr) external onlyOwner {
      _signatureAddress = addr;
  }
  function walletOfOwner(address _owner) public view returns(uint256[] memory) {
      uint256 tokenCount = balanceOf(_owner); 
      uint256[] memory tokensId = new uint256[](tokenCount);
      for(uint256 i; i < tokenCount; i++){
          tokensId[i] = tokenOfOwnerByIndex(_owner, i);
      }
      return tokensId;
  }
  function setLimitPerWallet(uint256 _limit) public onlyOwner() {
      nLimitPerWallet = _limit;
  }
   function getLimitPerWallet() public view returns (uint256){
     return nLimitPerWallet; 
  }
  function setLimitPerTx(uint256 _limit) public onlyOwner() {
      nLimitPerTx = _limit;
  }
   function getLimitPerTx() public view returns (uint256){
     return nLimitPerTx; 
  }
  function setPrice(uint256 _nPrice) public onlyOwner() {
      _price = _nPrice;
  }
  function getPrice() public view returns (uint256){
      return _price;
  }
  function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
  }
  function setBaseURI(string memory baseURI) public onlyOwner {
      _baseTokenURI = baseURI;
  }
  function pause(bool val) public onlyOwner {
      _paused = val;
  }
  function pauseWhitelist(bool val) public onlyOwner {
      _pausedWL = val;
  }   
  function bestfrensfunds() public payable onlyOwner { 
    uint256 _eth = address(this).balance;
    require(payable(msg.sender).send(_eth));
  }
}