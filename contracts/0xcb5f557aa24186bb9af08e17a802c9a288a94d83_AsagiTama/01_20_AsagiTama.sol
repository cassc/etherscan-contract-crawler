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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface Asagi{
    function ownerOf(uint256 _tokenId) external view returns (address);
    function walletOfOwner(address _address) external view returns (uint256[] memory);
}

contract AsagiTama is ERC721Enumerable,ERC2981,Ownable,Pausable,ReentrancyGuard{
  using Strings for uint256;
  string baseURI = "";
  string notAwakeningUri= "";
  uint256 public tokenCount;
  bool public awakening = false;

  bool public mintStart = false;
  bool public stakeStart = false;
  bool public burnFlag = false;
  uint256 constant maxSupply = 3000;
  uint256 constant mintLimit = 6;
  uint256 public stakeMintCost = 2592000;

  address public royaltyAddress = 0xC341575cc758840f7Fdd102474c4d0e81c8DeD98;
  uint96 public royaltyFee = 1000;

  bytes32 public merkleRoot;

  mapping(address => uint256) public minted;
  mapping(address => uint256) public dailyPointMap;
  mapping(uint256 => address) public stampOwnerMap;
  mapping(uint256 => uint256) public timeStampMap;
  mapping(address => bool) public isFirstMinted;

  constructor() ERC721("AsagiTama", "ASAGITAMA") {
    _setDefaultRoyalty(royaltyAddress, royaltyFee);
    tokenCount = 0;
  }
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }
  function stakeMint(uint256 quantity) public nonReentrant {
    require(mintStart);
    require(mintLimit >= quantity, "limit over");
    require(mintLimit >= minted[msg.sender] + quantity, "You have no Mint left");
    require((quantity + tokenCount) <= (maxSupply), "Sorry. No more NFTs");
    require(dailyPointMap[msg.sender] >= quantity*stakeMintCost);
    decreasePoint(quantity*stakeMintCost);
    for (uint256 i = 1; i <= quantity; i++) {
      _safeMint(msg.sender, tokenCount + i);
    }
    minted[msg.sender] += quantity;
    tokenCount += quantity;
  }
  function firstMint(bytes32[] calldata _merkleProof, uint256[] memory list) public nonReentrant {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(mintStart);
    require(mintLimit >= minted[msg.sender] + 1, "You have no Mint left");
    require((1 + tokenCount) <= (maxSupply), "Sorry. No more NFTs");
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),"Invalid Merkle Proof");
    require(isFirstMinted[msg.sender]==false);
    _safeMint(msg.sender, tokenCount + 1);
    minted[msg.sender] += 1;
    tokenCount += 1;
    isFirstMinted[msg.sender]=true;
    stake(list);
  }

  function ownerMint(address _address, uint256 quantity) public onlyOwner {
    require(quantity + tokenCount <= maxSupply,"Total supply cannot exceed maxSupply");

    for (uint256 i = 1; i <= quantity; i++) {
      _safeMint(msg.sender, tokenCount + i);
      safeTransferFrom(msg.sender, _address, tokenCount + i);
    }
    tokenCount += quantity;
  }
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    if(awakening == false) {
      uint256 attribute = tokenId % 6;
      uint256 variation = uint256(keccak256(abi.encodePacked(tokenId))) % 5;
      return string(abi.encodePacked(notAwakeningUri, attribute.toString(),"/",variation.toString(), ".json"));
    }
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI,tokenId.toString(),".json")): "";
  }
  function switchMintStart(bool _state) public onlyOwner {
    mintStart = _state;
  }
  function switchStakeStart(bool _state) public onlyOwner {
    stakeStart = _state;
  }
  function switchBurnFlag(bool _state) public onlyOwner {
    burnFlag = _state;
  }
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
  function setNotAwakeningUri(string memory _newURI) public onlyOwner {
    notAwakeningUri = _newURI;
  }
  function pause() public onlyOwner {
    _pause();
  }
  function unpause() public onlyOwner {
    _unpause();
  }
  function burn(uint256 id) public{
    require(msg.sender == ownerOf(id));
    require(burnFlag);
    _burn(id);
  }

  function walletOfOwner(address _address) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_address);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_address, i);
    }
    return tokenIds;
  }

  function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  Asagi at_Contract = Asagi(0xDD510ce28dfD085d9cf58F5402cA6d63985e83C0);
  function setAtAdress(address _address) external onlyOwner {
    at_Contract = Asagi(_address);
  }

  function stake(uint256[] memory list) public{
    require(stakeStart);
    dailyPointMap[msg.sender]=dailyPointMap[msg.sender]+checkStakePoint(msg.sender,list);
    for (uint i = 0; i < list.length; i++) {
      require(at_Contract.ownerOf(list[i])==msg.sender);
      timeStampMap[list[i]]=block.timestamp;
      stampOwnerMap[list[i]]=msg.sender;
    }
  }

  function setAwakening() public onlyOwner {
    awakening = true;
  }

  function decreasePoint(uint256 _point) public{
    require(dailyPointMap[msg.sender] >= _point);
    dailyPointMap[msg.sender]=dailyPointMap[msg.sender]-_point;
  }
  function checkStakePoint(address _address, uint256[] memory list) public view returns (uint256) {
      uint256 point = 0;
      for (uint i = 0; i < list.length; i++) {
        require(at_Contract.ownerOf(list[i])==_address);
        if (stampOwnerMap[list[i]] == _address){
          point=point+(block.timestamp-timeStampMap[list[i]]);
        }
      }
    return point;
  }
  function setStakeMintCost(uint256 _newPoint) public onlyOwner {
        stakeMintCost = _newPoint;
  }
  function forcedOwnerMapChanges(uint256 id, address _address) public onlyOwner {
    stampOwnerMap[id]=_address;
  }
  function forcedStampMapChanges(uint256 id, uint256  _time) public onlyOwner {
    timeStampMap[id]=_time;
  }
  function wooOfAsagi(address _address) public view returns (uint256[] memory) {
    return at_Contract.walletOfOwner(_address);
  }

}