// SPDX-License-Identifier: MIT
/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@           @@              @@         @@                     @@      @@@@@@@@@@
@@@@@@@@@@@@@@@            @@              @@          @@                    @@      @@@@@@@@@@
@@@@@@@@@@@@@@             @@     @@@@@@@@@@@           @@     @@@@@@@@@@@@@@@@      @@@@@@@@@@
@@@@@@@@@@@@@      @       @@     @@@@@@@@@@@       @    @@     @@@@@@@@@@@@@@@      @@@@@@@@@@
@@@@@@@@@@@@      @@       @@     @@@@@@@@@@@       @@    @@     @           @@      @@@@@@@@@@
@@@@@@@@@@@      @@@       @@              @@       @@@    @@     @          @@      @@@@@@@@@@
@@@@@@@@@@     @           @@              @@          @    @@     @@@@@@    @@      @@@@@@@@@@
@@@@@@@@@     @            @@@@@@@@@@@     @@           @    @@     @@@@@    @@      @@@@@@@@@@
@@@@@@@@     @@@@@@@       @@@@@@@@@@@     @@       @@@@@@    @@     @@@@    @@      @@@@@@@@@@
@@@@@@@     @@@@@@@@       @@@@@@@@@@@     @@       @@@@@@@    @@     @@@    @@      @@@@@@@@@@
@@@@@@     @@@@@@@@@       @@              @@       @@@@@@@@    @@           @@      @@@@@@@@@@
@@@@@     @@@@@@@@@@       @@              @@       @@@@@@@@@    @@          @@      @@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface balanceOfInterface {
  function balanceOf(address addr) external view returns (
      uint256 holds
  );
}

interface IERC20 {
    function owner() external view returns (address);
    function balanceOf(address add) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external;
}

interface AsagiTama {
    function walletOfOwner(address _address) external view returns (uint256[] memory);
}

contract Asagi is Ownable, ERC721A, ReentrancyGuard, ERC2981{
    uint256 public tokenCount;
    uint256 public batchSize = 100;
    uint256 private wLMintPrice = 0.03 ether;
    uint256 private mintPrice = 0.05 ether;
    uint256 public MintLimit = 3;
    uint256 public _totalSupply = 1500;
    bool public wlSaleStart = false;
    bool public saleStart = false;
    mapping(address => uint256) public Minted; 
    bytes32 public merkleRoot;

    address public royaltyAddress;
    uint96 public royaltyFee = 1000;
    bool public revealed = false;
    
  constructor(
  ) ERC721A("Asagi", "ASAGI",batchSize, _totalSupply) {
     tokenCount = 0;
  }
  function ownerMint(uint256 quantity, address to) external onlyOwner {
    require((quantity + tokenCount) <= (_totalSupply), "too many already minted before patner mint");
    _safeMint(to, quantity);
    tokenCount += quantity;
  }
  
  function wlMint(uint256 quantity, bytes32[] calldata _merkleProof) public payable nonReentrant {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

    require(MintLimit >= quantity, "limit over");
    require(MintLimit >= Minted[msg.sender] + quantity, "You have no Mint left");
    require(msg.value == wLMintPrice * quantity, "Value sent is not correct");
    require((quantity + tokenCount) <= (_totalSupply), "Sorry. No more NFTs");
    require(wlSaleStart, "Sale Paused");    
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),"Invalid Merkle Proof");
         
    Minted[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
    tokenCount += quantity;
  }
  function psMint(uint256 quantity) public payable nonReentrant {
    require(MintLimit >= quantity, "limit over");
    require(MintLimit >= Minted[msg.sender] + quantity, "You have no Mint left");
    require(msg.value == mintPrice * quantity, "Value sent is not correct");
    require((quantity + tokenCount) <= (_totalSupply), "Sorry. No more NFTs");
    require(saleStart, "Sale Paused");
         
    Minted[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
    tokenCount += quantity;
  }

  function withdrawRevenueShare() external onlyOwner {
    uint256 sendAmount = address(this).balance;

    address artist = payable(0xC341575cc758840f7Fdd102474c4d0e81c8DeD98);
    address engineer = payable(0x253058B7F0fF2C6218dB7569cE1d399F7183E355);
    address marketer = payable(0xf2fd31926B3bc3fB47C108B31cC0829F20DeE4c0);
    address manager = payable(0x2064f95A4537a7e9ce364384F55A2F4bBA3F0346);
    bool success;

    (success, ) = artist.call{value: (sendAmount * 650/1000)}("");
    require(success, "Failed to withdraw Ether");
    (success, ) = engineer.call{value: (sendAmount * 200/1000)}("");
    require(success, "Failed to withdraw Ether");
    (success, ) = marketer.call{value: (sendAmount * 50/1000)}("");
    require(success, "Failed to withdraw Ether");
    (success, ) = manager.call{value: (sendAmount * 100/1000)}("");
    require(success, "Failed to withdraw Ether");
  }

  function switchWlSale(bool _state) external onlyOwner {
    wlSaleStart = _state;
  }
  function switchSale(bool _state) external onlyOwner {
    saleStart = _state;
  }
  function setWlLimit(uint256 newLimit) external onlyOwner {
    MintLimit = newLimit;
  }
  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function walletOfOwner(address _address) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_address);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
      for (uint256 i; i < ownerTokenCount; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(_address, i);
      }
    return tokenIds;
  }

  //set Default Royalty._feeNumerator 500 = 5% Royalty
  function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
    royaltyFee = _feeNumerator;
    _setDefaultRoyalty(royaltyAddress, royaltyFee);
  }

  //Change the royalty address where royalty payouts are sent
  function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
    royaltyAddress = _royaltyAddress;
    _setDefaultRoyalty(royaltyAddress, royaltyFee);
  }
  
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  //Implementation on wear change from here down.
  //URI
  string public _baseTokenURI;
  string private revealUri;

  //style Map
  mapping(uint256 => uint256) public mapTokenMode;
  //TokenModeToURI
  mapping(uint256 => string) public TokenModeToUriMap;
  //AsagiTama
  mapping(uint256 => uint256) public TokenID2AtMode;

  //key Project
  address public x1_address;
  address public x2_address;
  address public x3_address;
  address public x4_address;
  address public x5_address;
  address public at_adress; 
  balanceOfInterface x1_Contract;
  balanceOfInterface x2_Contract;
  IERC20 x3_SAL;
  balanceOfInterface x4_Contract;
  balanceOfInterface x5_Contract;
  AsagiTama at_Contract;

  address private treasuryaddy;
  uint256 public SalCost = 30 ether;  //able to change

  bool public releaseX1=false;
  bool public releaseX2=false;
  bool public releaseX3=false;
  bool public releaseX4=false;
  bool public releaseX5=false;
  bool public releaseAT=false;

  //retuen BaseURI.internal.
  function _baseURI(uint256 tokenId) internal view returns (string memory){
    if(mapTokenMode[tokenId] == 0) {
      return _baseTokenURI;
    }
    if(mapTokenMode[tokenId] == 1) {
      return TokenModeToUriMap[1];
    }
    if(mapTokenMode[tokenId] == 2) {
      return TokenModeToUriMap[2];
    }
    if(mapTokenMode[tokenId] == 3) {
      return TokenModeToUriMap[3];
    }
    if(mapTokenMode[tokenId] == 4) {
      return TokenModeToUriMap[4];
    }
    if(mapTokenMode[tokenId] == 5) {
      return TokenModeToUriMap[5];
    }
    if(mapTokenMode[tokenId] == 6) {
      uint256 x = TokenID2AtMode[tokenId]+6;
      return TokenModeToUriMap[x];
    }
      return _baseTokenURI;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "URI query for nonexistent token");
    if(revealed == false) {
      return revealUri;
      }
    return string(abi.encodePacked(_baseURI(_tokenId), Strings.toString(_tokenId), ".json"));
  }

  //change mode for holder
  function ModeBase(uint256 tokenId) public{
    require(ownerOf(tokenId) == msg.sender, "You are not the holder of this token.");
    mapTokenMode[tokenId] = 0;
  }
  function ModeX1(uint256 tokenId) public{
    require(ownerOf(tokenId) == msg.sender, "You are not the holder of this token.");
    require(releaseX1);
    require(0<x1_Contract.balanceOf(msg.sender), "You don't have collaboration token.");
    mapTokenMode[tokenId] = 1;
  }
  function ModeX2(uint256 tokenId) public{
    require(ownerOf(tokenId) == msg.sender, "You are not the holder of this token.");
    require(releaseX2);
    require(0<x2_Contract.balanceOf(msg.sender), "You don't have collaboration token.");
    mapTokenMode[tokenId] = 2;
  }
  //Wearable change with token//
  function ModeX3(uint256 tokenId) public{
    require(ownerOf(tokenId) == msg.sender, "You are not the holder of this token.");
    require(releaseX3);
    require(x3_SAL.balanceOf(msg.sender) >= SalCost,  "You don't have enough $SAL");
  //transfer//
    x3_SAL.transferFrom(msg.sender, treasuryaddy, SalCost);
    mapTokenMode[tokenId] = 3;
  }
  function ModeX4(uint256 tokenId) public{
    require(ownerOf(tokenId) == msg.sender, "You are not the holder of this token.");
    require(0<x4_Contract.balanceOf(msg.sender), "You don't have collaboration token.");
    require(releaseX4);
    mapTokenMode[tokenId] = 4;
  }
  function ModeX5(uint256 tokenId) public{
    require(ownerOf(tokenId) == msg.sender, "You are not the holder of X token.");
    require(releaseX5);
    require(0<x5_Contract.balanceOf(msg.sender), "You don't have collaboration token.");
    mapTokenMode[tokenId] = 5;
  }
  function ModeAT(uint256 tokenId, uint256 AtNumber) public{
    require(ownerOf(tokenId) == msg.sender, "You are not the holder of X token.");
    require(releaseAT);
    require(AtNumber<6);
    bool check = false;
    for (uint256 i; i < at_Contract.walletOfOwner(msg.sender).length; i++) {
      if (at_Contract.walletOfOwner(msg.sender)[i]%6 == AtNumber){
        check = true;
      }
    }
    require(check);
    mapTokenMode[tokenId] = 6;
    TokenID2AtMode[tokenId]=AtNumber;
  }
  function ModeResetByOwner(uint256[] memory list) public onlyOwner{
    for (uint i = 0; i < list.length; i++) {
      mapTokenMode[i] = 0;
    }
  }

  //set URI
  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }
  function setExtraURI(string calldata baseURI, uint256 TokenMode) external onlyOwner {
    TokenModeToUriMap[TokenMode] = baseURI;
  }
  function setHiddenBaseURI(string memory uri_) public onlyOwner {
    revealUri = uri_;
  }
  function setreveal(bool bool_) external onlyOwner {
    revealed = bool_;
  }
  //set x address
  function setX1Adress(address _address) external onlyOwner {
    x1_address = _address;
    x1_Contract = balanceOfInterface(x1_address);
  }
  function setX2Adress(address _address) external onlyOwner {
    x2_address = _address;
    x2_Contract = balanceOfInterface(x2_address);
  }

  //Wearable functionality using $SAL by 0xSumo & SOCO//
  //Can you keep it to yourself?//
  function setX3Adress(address _address) external onlyOwner {
    x3_address = _address;
    x3_SAL = IERC20(x3_address);
  }
  function setTreasury(address _address) external onlyOwner {
    treasuryaddy = _address;
  }
  function setCost(uint256 _Cost) external onlyOwner {
    SalCost = _Cost;
  }

  //You ain't heard nothin' yet!//
  function setX4Adress(address _address) external onlyOwner {
    x4_address = _address;
    x4_Contract = balanceOfInterface(x4_address);
  }
  function setX5Adress(address _address) external onlyOwner {
    x5_address = _address;
    x5_Contract = balanceOfInterface(x5_address);
  }

  //Can you keep a secret?//
  function setAtAdress(address _address) external onlyOwner {
    at_adress = _address;
    at_Contract = AsagiTama(at_adress);
  }
  //set release flag
  function releaseX1Flag(bool bool_) external onlyOwner {
    releaseX1 = bool_;
  }
  function releaseX2Flag(bool bool_) external onlyOwner {
    releaseX2 = bool_;
  }
  function releaseX3Flag(bool bool_) external onlyOwner {
    releaseX3 = bool_;
  }
  function releaseX4Flag(bool bool_) external onlyOwner {
    releaseX4 = bool_;
  }
  function releaseX5Flag(bool bool_) external onlyOwner {
    releaseX5 = bool_;
  }
  function releaseATFlag(bool bool_) external onlyOwner {
    releaseAT = bool_;
  }

  function wearAuthOfOwner(address _address) public view returns (uint256[] memory) {
    uint256[] memory wearAuthList = new uint256[](11);
    if (x1_address != 0x0000000000000000000000000000000000000000){
      wearAuthList[0]=x1_Contract.balanceOf(_address);
    }
    if (x2_address != 0x0000000000000000000000000000000000000000){
      wearAuthList[1]=x2_Contract.balanceOf(_address);
    }
    if (x3_address != 0x0000000000000000000000000000000000000000){
      wearAuthList[2]=x3_SAL.balanceOf(_address);
    }
    if (x4_address != 0x0000000000000000000000000000000000000000){
      wearAuthList[3]=x4_Contract.balanceOf(_address);
    }
    if (x5_address != 0x0000000000000000000000000000000000000000){
      wearAuthList[4]=x5_Contract.balanceOf(_address);
    }
    if (at_adress != 0x0000000000000000000000000000000000000000){
      for (uint256 i; i < at_Contract.walletOfOwner(_address).length; i++) {
        if (at_Contract.walletOfOwner(_address)[i]%6 == 0){
          wearAuthList[5]=wearAuthList[5]+1;
        }
        if (at_Contract.walletOfOwner(_address)[i]%6 == 1){
          wearAuthList[6]=wearAuthList[6]+1;
        }
        if (at_Contract.walletOfOwner(_address)[i]%6 == 2){
          wearAuthList[7]=wearAuthList[7]+1;
        }
        if (at_Contract.walletOfOwner(_address)[i]%6 == 3){
          wearAuthList[8]=wearAuthList[8]+1;
        }
        if (at_Contract.walletOfOwner(_address)[i]%6 == 4){
          wearAuthList[9]=wearAuthList[9]+1;
        }
        if (at_Contract.walletOfOwner(_address)[i]%6 == 5){
          wearAuthList[10]=wearAuthList[10]+1;
        }
      }
    }
    return wearAuthList;
  }

}