// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "./Administrable.sol";
import "./Lockable.sol";
import "./Toggleable.sol";
import "./EIP712Common.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import { Base64 } from "./Base64.sol";
import { Utils } from "./Utils.sol";

error ExceedsMaxPerWallet();
error AlreadyOnTheList();
error InvalidTokenId();
error InsufficientPayment();
error MaxSupplyReached();
error InvalidAmount();
error NotInAllowList();
error MaxAllowMintReached();
error NonExistingToken();
error InvalidLength();
error MaxMintableSupplyReached();
error EmptyAllowList();

contract WGMIIOAllAccessBetaPass is ERC721A, ERC721ABurnable, Lockable, Toggleable, Administrable, EIP712Common{
  using EnumerableSet for EnumerableSet.UintSet;
  using Strings for uint256;

  uint256 public maxPerWallet = 5;
  uint256 public tokenPrice = 0.2 ether;
  uint256 public allowListPrice = 0.15 ether;
  uint256 public constant maxSupply = 6000;
  uint256 private mintableSupply;
  uint256 firstAllowLisLimit;
  uint256 secondAllowLisLimit;
  uint256 thirdAllowLisLimit;
  
  // The maximum TokenID that is currently active
  uint256 public currentMaximum;
  address[] allowlist1;
  address[] allowlist2;
  address[] allowlist3;
  // This is the list of tokens which we have moved to the front of the line.
  // It is intended for one-off usage vs en-mass line skipping.

  address private treasuryAddress;

  constructor (
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _baseImageURI,
    address _treasuryAddress,
    uint256 _mintableSupply
  ) ERC721A(_tokenName, _tokenSymbol) {
    baseImageURI = _baseImageURI;
    treasuryAddress = _treasuryAddress;
    mintableSupply = _mintableSupply;
  }

  // ------ MINTING -----------------------------------------------------------

  function mint(uint256 _count) external payable noContracts requireActiveSale requireActiveContract {
    if(_count + totalSupply() >= maxSupply) revert MaxSupplyReached();
    if (_count + totalSupply() > mintableSupply) revert MaxMintableSupplyReached();
    if(_numberMinted(msg.sender) + _count > maxPerWallet) revert ExceedsMaxPerWallet();
    if(msg.value < tokenPrice * _count) revert InsufficientPayment();
    

    _mint(msg.sender, _count);
  }

  // ------ AIRDROPS ----------------------------------------------------------

  function airdrop(uint256 _count, address _recipient) external requireActiveContract onlyOperatorsAndOwner {
    if(_count + totalSupply() >= maxSupply) revert MaxSupplyReached();
    _mint(_recipient, _count);
  }

  function airdropBatch(uint256[] calldata _counts, address[] calldata _recipients) external requireActiveContract onlyOperatorsAndOwner {
    if (_counts.length != _recipients.length){revert InvalidLength();}
    for (uint256 i; i < _recipients.length;) {
    if(_counts[i] + totalSupply() > maxSupply ){revert MaxSupplyReached();}
      _mint(_recipients[i], _counts[i]);
      unchecked { ++i; }
    }
  }

  // ------ AllOWLIST ----------------------------------------------------------

 function allowListMint(uint256 _count) external payable requireActiveAllowlist {
  address[] memory cacheList1 = allowlist1;
  address[] memory cacheList2 = allowlist2;
  address[] memory cacheList3 = allowlist3;
  if(totalSupply() + _count > maxSupply) revert MaxSupplyReached();
  if(cacheList1.length <= 0 ||cacheList2.length <=0 || cacheList3.length <=0) revert EmptyAllowList();
  if(msg.value < allowListPrice * _count) revert InvalidAmount();


  uint256 allowedmint;
  for(uint256 i = 0; i < cacheList1.length; i++){
    if(cacheList1[i] == msg.sender){
      allowedmint = firstAllowLisLimit;
    }
  }

  for(uint256 i = 0; i < cacheList2.length; i++){
    if(cacheList2[i] == msg.sender){
      allowedmint = secondAllowLisLimit;
    }
  }

  for(uint256 i = 0; i < cacheList3.length; i++){
    if(cacheList3[i] == msg.sender){
      allowedmint = thirdAllowLisLimit;
    }
  }
  if(allowedmint <= 0) revert NotInAllowList();
  if(balanceOf(msg.sender) >= allowedmint) revert MaxAllowMintReached();
    _mint(msg.sender, _count);

 }

 function isAllowed(address _address) external view returns(bool, uint256){
   address[] memory cacheList1 = allowlist1;
  address[] memory cacheList2 = allowlist2;
  address[] memory cacheList3 = allowlist3;
   for(uint256 i = 0; i < cacheList1.length; i++){
    if(cacheList1[i] == _address){
     return  (true, 1);
    }
  }

  for(uint256 i = 0; i < cacheList2.length; i++){
    if(cacheList2[i] == _address){
      return (true,2);
    }
  }

  for(uint256 i = 0; i < cacheList3.length; i++){
    if(cacheList3[i] == _address){
      return (true,3);
    }
  }
  return (false,0);
 }

  // ------ ADMINISTRATION ----------------------------------------------------

  function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
    maxPerWallet = _maxPerWallet;
  }

  function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
    tokenPrice = _tokenPrice;
  }

  function setAllowListPrice(uint256 _tokenPrice) external onlyOwner {
    allowListPrice = _tokenPrice;
  }

  function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
    treasuryAddress = _treasuryAddress;
  }

  function getTreasuryAddress() public view returns (address) {
    return treasuryAddress;
  }

  // ------ TOKEN METADATA ----------------------------------------------------

  string private baseImageURI;
  string private imageExtension = ".jpg";
  

  function getBaseImageURI() public view returns (string memory) {
    return baseImageURI;
  }


  function getImageExtension() public view returns (string memory) {
    return imageExtension;
  }


  function setBaseImageURI(string memory _baseImageURI) external onlyOwner {
    baseImageURI = _baseImageURI;
  }

  

  function setImageExtension(string memory _imageExtension) external onlyOwner {
    imageExtension = _imageExtension;
  }


  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    if(!_exists(tokenId)){revert NonExistingToken();}
    return
      string(
        abi.encodePacked(
          string(abi.encodePacked(baseImageURI))
        )
      );
  }

  function release() external onlyOwner {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(owner()), balance);
  }

  function updateAllowList(address[] calldata _allowlist1, address[] calldata _allowlist2, address[] calldata _allowlist3)external onlyOwner{
      require(_allowlist1.length > 0 || _allowlist1.length > 0 || _allowlist3.length > 0);
      for(uint256 i = 0; i < _allowlist1.length; i++){
        allowlist1.push(_allowlist1[i]);
      }
      for(uint256 i = 0; i < _allowlist2.length; i++){
        allowlist2.push(_allowlist2[i]);
      }
      for(uint256 i = 0; i < _allowlist3.length; i++){
        allowlist3.push(_allowlist3[i]);
      }
  }

  function setAllowListLimit(uint256 _allowlist1, uint256 _allowlist2, uint256 _allowlist3) external onlyOwner{
      firstAllowLisLimit = _allowlist1;
      secondAllowLisLimit = _allowlist2;
      thirdAllowLisLimit = _allowlist3;
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC721A, AccessControlEnumerable) returns (bool) {
    return ERC721A.supportsInterface(interfaceId);
  }
}