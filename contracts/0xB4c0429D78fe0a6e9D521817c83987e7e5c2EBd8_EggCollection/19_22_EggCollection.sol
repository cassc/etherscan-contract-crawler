// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
//access control
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./DefaultOperatorFilterer.sol";

interface IEggs {
  // function eggIdToMint(uint randomSet)external view returns(uint);
  function individualTokenUri(
    uint itemId
  ) external view returns (string memory);

  function individualTokenUriRevealed(
    uint itemId
  ) external view returns (string memory);

  function pickRevealItem(
    uint eggId,
    uint eggsCount
  ) external view returns (uint);

  // function okToMint(uint eggId)external view returns(bool);
  // function eggPrice(uint eggId)external view returns(uint);
  function okToAttach(uint eggId, uint avType) external view returns (bool);

  function namePet(uint revId, string calldata newName) external;
}

interface IAvatars {
  function attachEggItem(uint _avatarId, uint _eggId) external;

  function getAvType(uint avTokenId) external view returns (uint);
}

contract EggCollection is
  ERC721Enumerable,
  AccessControl,
  Ownable,
  DefaultOperatorFilterer
{
  bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
  bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
  bytes32 public constant BALANCE_ROLE = keccak256("BALANCE_ROLE");

  IEggs Eggs;
  IAvatars Avatars;

  address private _paymentSplit;

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  mapping(uint => uint) tokenIdToEggId;
  mapping(uint => uint) tokenIdToRevealId;
  mapping(uint => bool) tokenIdToRevealed;
  mapping(uint => bool) tokenIdToRedeemed;

  mapping(uint => string) ipfsLock; // store the IPFS version of the metadata
  mapping(uint => bool) ipfsLocekd; //store if the ipfs is added.

  mapping(address => uint) _mintsPerWallet;
  mapping(address => bool) _onWhiteList;

  uint _price = 0.5 ether;
  uint _paidMintId = 8;
  mapping(uint => uint) _paidMintLimit;
  mapping(uint => uint) _paidMints;
  uint maxPerWallet = 2;

  mapping(uint => bool) _revealsAllowed;

  bool publicMint = false;
  bool mintsOpen = false;

  // bool _userMintAllowed = true;
  // bool _passportRequired = false;

  constructor() ERC721("Metropolis World Ethereals", "MWE") {
    _tokenIds.increment();
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(UPDATER_ROLE, msg.sender);
    _setupRole(CONTRACT_ROLE, msg.sender);
    _setupRole(BALANCE_ROLE, msg.sender);
  }

  // opensea secondary blocks
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  //os

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    virtual
    override(ERC721Enumerable, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function setUpInterfaces(
    address _eggsAddress,
    address _avatarsAddress
  ) external onlyRole(UPDATER_ROLE) {
    Eggs = IEggs(_eggsAddress);
    Avatars = IAvatars(_avatarsAddress);
  }

  function internalMint(address to, uint eggId) internal {
    uint currentId = _tokenIds.current();
    _safeMint(to, currentId);
    tokenIdToEggId[currentId] = eggId;
    tokenIdToRevealed[currentId] = false;
    _tokenIds.increment();
  }

  function bulkAirdrop(address[] memory tos, uint eggId)external onlyRole(UPDATER_ROLE){
    for(uint i; i<tos.length;i++){
      internalMint(tos[i], eggId);
    }
  }

  function airdropMint(address to, uint eggId) external onlyRole(UPDATER_ROLE) {
    internalMint(to, eggId);
  }

  function paidMint(address to, uint[] calldata eggIds) external payable {
    require(mintsOpen, "mints not open yet");
    require(msg.value >= _price * eggIds.length, "not paid enough");
    if (!publicMint){
      require(_onWhiteList[to], "Not on the WL");
    }
    require(_mintsPerWallet[to] + eggIds.length <= maxPerWallet, "wallet limit reached");

    for (uint i = 0; i < eggIds.length; i++) {
      require(eggIds[i] > 7, "can't paid mint the free ones");
      require(_paidMints[eggIds[i]] < _paidMintLimit[eggIds[i]], "Mint limit reached");
      internalMint(to, eggIds[i]);
      
      _paidMints[eggIds[i]] += 1;
      _mintsPerWallet[to] += 1;
    }
    
  }


  function openPaidMints()external onlyRole(UPDATER_ROLE){
    mintsOpen = true;
  }

  function closePaidMints()external onlyRole(UPDATER_ROLE){
    mintsOpen = false;
  }

  function addToWL(address[] calldata wl) external onlyRole(UPDATER_ROLE) {
    for (uint i = 0; i < wl.length; i++) {
      _onWhiteList[wl[i]] = true;
    }
  }

  function redeemMyDarkEgg(uint tokenId)external {
    require(ownerOf(tokenId) == msg.sender, "you must own the egg to redeem it");
    require(tokenIdToEggId[tokenId] == 8, "only the 8th egg can be redeemed");
    require(tokenIdToRedeemed[tokenId] != true, "this egg has been redeemed");
    tokenIdToRedeemed[tokenId] = true;
  }

  function hasBeenRedeemed(uint tokenId)external view returns(bool){
    if(tokenIdToRedeemed[tokenId] != true){
      //not redeemed yet
      return false;
    }else{
      // has been redeemed
      return true; 
    }
  }

  function setMaxPerWallet(uint _maxPerWallet) external onlyRole(UPDATER_ROLE) {
    maxPerWallet = _maxPerWallet;
  }

  function setPrice(uint newPrice) external onlyRole(UPDATER_ROLE) {
    _price = newPrice;
  }

  function getPrice()external view returns(uint){
    return _price;
  }

  function setPublicMint(bool onOff)external onlyRole(UPDATER_ROLE){
    publicMint =  onOff;
  }

  function setPaidMintLimitPerEgg(
    uint eggId,
    uint limit
  ) external onlyRole(UPDATER_ROLE) {
    _paidMintLimit[eggId] = limit;
  }

  function mintsSoFar(uint eggId) external view returns (uint) {
    return _paidMints[eggId];
  }

  function maxPaidMints(uint eggId) external view returns (uint) {
    return _paidMintLimit[eggId];
  }

  function allowReveals(uint eggId) external onlyRole(UPDATER_ROLE) {
    _revealsAllowed[eggId] = true;
  }

  function stopReveals(uint eggId) external onlyRole(UPDATER_ROLE) {
    _revealsAllowed[eggId] = false;
  }

  function areRevealsAllowed(uint eggId)external view returns(bool){
    return _revealsAllowed[eggId];
  }

  function revealMyEgg(uint tokenId) external {
    require(ownerOf(tokenId) == msg.sender, "You have to own it to reveal it");
    uint eggId = tokenIdToEggId[tokenId];
    require(_revealsAllowed[eggId], "Reveals not allowed yet for this egg");
    tokenIdToRevealId[tokenId] = Eggs.pickRevealItem(
      eggId,
      _tokenIds.current() - 1
    );
    tokenIdToRevealed[tokenId] = true;
  }

  function bulkRevealAllMyEggs() external {
    uint owned = balanceOf(msg.sender);
    require(owned > 0, "you need to own some eggs");
    for (uint i; i < owned; i++) {
      //check which they own and reveal them??
      uint tokenId = tokenOfOwnerByIndex(msg.sender, i);
      uint eggId = tokenIdToEggId[tokenId];
      tokenIdToRevealId[tokenId] = Eggs.pickRevealItem(
        eggId,
        _tokenIds.current() - 1
      );
      tokenIdToRevealed[tokenId] = true;
    }
  }

  struct listOwned{
    uint id;
    string eggCreature;
  }

  function getMyNfts(address owner)external view returns(listOwned[] memory){
    uint256 bal = balanceOf(owner);
    listOwned[] memory x = new listOwned[](bal);
    for (uint256 i = 0; i < bal; i++) {
        uint tokenId = tokenOfOwnerByIndex(owner,i);
        if (tokenIdToRevealed[tokenId]){
          x[i] = listOwned({ id: tokenIdToRevealId[tokenId], eggCreature: "creature"});
        }else{
          x[i] = listOwned({ id:tokenIdToEggId[tokenId], eggCreature:"egg"});
        }
    }
    return x;
  }

  function getRevIdFromTokenId(uint eggTokenId) external view returns (uint) {
    return tokenIdToRevealId[eggTokenId];
  }

  function namePet(uint eggTokenId, string calldata newName) external {
    require(ownerOf(eggTokenId) == msg.sender, "You have to own it to name it");
    Eggs.namePet(tokenIdToRevealId[eggTokenId], newName);
  }

  function attachToAvatar(
    uint _tokenId,
    uint _avatarId
  ) external {
    require(
      tokenIdToRevealed[_tokenId],
      "You egg must be revealed before being attached"
    );
    uint avType = Avatars.getAvType(_avatarId);
    require(
      Eggs.okToAttach(_tokenId, avType),
      "wrong avatar type"
    );
    uint _eggId = tokenIdToEggId[_tokenId];
    Avatars.attachEggItem(_avatarId, _eggId);

    _transfer(msg.sender, address(Avatars), _tokenId);
  }

  function addIpfsOnNft(
    uint _tokenId,
    string calldata ipfs
  ) external onlyRole(UPDATER_ROLE) {
    ipfsLock[_tokenId] = ipfs;
    ipfsLocekd[_tokenId] = true;
  }

  function tokenURI(
    uint256 _tokenId
  ) public view override returns (string memory) {
    uint itemId = tokenIdToEggId[_tokenId];
    bool revealed = tokenIdToRevealed[_tokenId];
    if (revealed) {
      if (ipfsLocekd[_tokenId] != true) {
        uint revId = tokenIdToRevealId[_tokenId];
        return
          string(
            abi.encodePacked(
              "https://metadata.metropolisworld.link/api/creature/",
              Strings.toString(revId)
            )
          );
      } else {
        return ipfsLock[_tokenId];
      }
    } else {
      return Eggs.individualTokenUri(itemId);
    }
  }

  function withdraw(address to)external onlyRole(BALANCE_ROLE){
    uint256 balance = address(this).balance;
    Address.sendValue(payable(to), balance);
  }
}