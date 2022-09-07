//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Marimo is Ownable, ERC721AQueryable {
  string baseURI;
  uint256 public immutable maxPerAddressDuringMint;
  uint256 public immutable collectionSize;
  mapping(uint256 => uint256) private _generatedAt;
  mapping(uint256 => uint256) private _lastWaterChangedAt;
  mapping(uint256 => uint16) private _lastSize;

  uint256 private constant _MINT_PRICE = 0.01 ether;
  uint256 private _historyIndex;

  struct Stats {
    uint8 power;
    uint8 speed;
    uint8 stamina;
    uint8 luck;
  }
  struct ChangeWaterHistory {
    address changer;
    uint256 changedAt;
  }
  event ChangedStats(
    uint256 indexed _tokenId
  );
  event ChangedWater(
    uint256 indexed _tokenId,
    address indexed _changer,
    uint256 _historyIndex,
    uint256 _changedAt
  );
  mapping(uint256 => Stats) public tokenStats; // token id => stats
  mapping(uint256 => uint256[]) public tokenHistoryIndexes; // token id => historyIndexes
  ChangeWaterHistory[] public changeWaterHistories;
  bytes32 public merkleRoot;
  bool public publicSale;
  bool public preSale;
  bool public endOfSale;

  function getHistoryIndexes(uint256 tokenId) external view returns (uint256[] memory) {
    return tokenHistoryIndexes[tokenId];
  }

  constructor(uint256 maxBatchSize_, uint256 collectionSize_) ERC721A("Marimo", "MRM") {
    maxPerAddressDuringMint = maxBatchSize_;
    collectionSize = collectionSize_;
  }

  function getAge(uint256 tokenId) external view returns (uint256) {
    require(_exists(tokenId), "no token");
    return block.timestamp - _generatedAt[tokenId];
  }

  function getElapsedTimeFromLastWaterChanged(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId), "no token");
    return block.timestamp - _lastWaterChangedAt[tokenId];
  }

  function getLastSize(uint256 tokenId) internal view returns (uint16) {
    require(_exists(tokenId), "no token");
    return _lastSize[tokenId] > 0 ? _lastSize[tokenId] : 250;
  }

  function getCurrentSize(uint256 tokenId) public view returns (uint16) {
    require(_exists(tokenId), "no token");
    uint256 elapsedTime = getElapsedTimeFromLastWaterChanged(tokenId);
    uint256 coefficient = 90000 minutes;
    // add constacont(1440, 33840, 79920, 94320) as the initial value when elapsedTime is zero in each cases
    if (elapsedTime <= 20 days) {
      return uint16((100 * elapsedTime) / coefficient  + getLastSize(tokenId));
    } else if (elapsedTime <= 50 days) {
      return uint16((95 * elapsedTime + 1440 * 60 * 100) / coefficient +  getLastSize(tokenId));
    } else if (elapsedTime <= 80 days) {
      return uint16((50 * elapsedTime + 33840 * 60 * 100) / coefficient + getLastSize(tokenId));
    } else if (elapsedTime <= 100 days) {
      return uint16((10 * elapsedTime + 79920 * 60 * 100) / coefficient + getLastSize(tokenId));
    } else {
      return uint16(getLastSize(tokenId) + (94320 * 60 * 100 / coefficient));
    }
  }

  function changeWater(uint256 tokenId) external {
    require(_exists(tokenId), "no token");
    require(_lastSize[tokenId] == 0 || block.timestamp - _lastWaterChangedAt[tokenId] > 1 days, "only once a day");
    _lastSize[tokenId] = getCurrentSize(tokenId); // update lastSize before update lastWaterChangedAt
    _lastWaterChangedAt[tokenId] = block.timestamp;
    changeWaterHistories.push(ChangeWaterHistory(msg.sender, block.timestamp));
    tokenHistoryIndexes[tokenId].push(_historyIndex);
    emit ChangedWater(tokenId, msg.sender, _historyIndex, block.timestamp);
    _historyIndex += 1;
  }

  function publicMint(uint256 quantity) payable external returns (uint256) {
    require(publicSale, "inactive");
    require(!endOfSale, "end of sale");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(_numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "wrong num");
    require(msg.value == _MINT_PRICE * quantity, "wrong price");

    uint256 nextTokenId = _nextTokenId();
    for (uint256 i = nextTokenId; i < nextTokenId + quantity; i++) {
      _generatedAt[i] = block.timestamp;
      _lastWaterChangedAt[i] = block.timestamp;
      tokenStats[i] = _computeStats(i);
      emit ChangedStats(i);
    }
    _mint(msg.sender, quantity);
    return nextTokenId;
  }

  function isWhiteListed(bytes32[] calldata _merkleProof) public view returns(bool) {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
  }

  function numberMinted() external view returns (uint256) {
    return _numberMinted(msg.sender);
  }

  function preMint(uint256 quantity, bytes32[] calldata _merkleProof) payable external returns(uint256) {
    require(preSale, "inactive");
    require(!endOfSale, "end of sale");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(_numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "wrong num");
    require(msg.value == _MINT_PRICE * quantity, "wrong price");
    require(isWhiteListed(_merkleProof), "invalid proof");

    uint256 nextTokenId = _nextTokenId();
    for (uint256 i = nextTokenId; i < nextTokenId + quantity; i++) {
      _generatedAt[i] = block.timestamp;
      _lastWaterChangedAt[i] = block.timestamp;
      tokenStats[i] = _computeStats(i);
      emit ChangedStats(i);
    }
    _mint(msg.sender, quantity);

    return nextTokenId;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  function setPreSale(bool _preSale) external onlyOwner {
    preSale = _preSale;
  }

  function setPublicSale(bool _publicSale) external onlyOwner {
    publicSale = _publicSale;
  }

  function setEndOfSale(bool _endOfSale) external onlyOwner {
    endOfSale = _endOfSale;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
      merkleRoot = _merkleRoot;
  }

  function _computeStats(uint256 tokenId) internal view returns (Stats memory) {
    uint256 pseudorandomness = uint256(
      keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
    );

    uint8 power   = uint8(pseudorandomness) % 10 + 1;
    uint8 speed   = uint8(pseudorandomness >> 8 * 1) % 10 + 1;
    uint8 stamina = uint8(pseudorandomness >> 8 * 2) % 10 + 1;
    uint8 luck    = uint8(pseudorandomness >> 8 * 3) % 10 + 1;
    return Stats(power, speed, stamina, luck);
  }
}