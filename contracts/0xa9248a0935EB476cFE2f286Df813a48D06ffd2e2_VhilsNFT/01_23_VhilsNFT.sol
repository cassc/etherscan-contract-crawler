// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { NFTEnumerable, IERC721 } from "./base/NFTEnumerable.sol";
import { ERC1155Holder, ERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//                                                                           %/
// %@@@            @@@@@/     @@@#   @@@    [email protected]@@@@@@@@(   @@@@@@@@@@@    @@@@ *@@@@
// %@@@           @@@ @@@      ,@@@@@@@     [email protected]@@          @@@     @@@    @@@@
// %@@@          @@@   @@@       @@@@       [email protected]@@@@@@@@    @@@@@@@@@@       @@@@@@@@
// %@@@         @@@@@@@@@@@      ,@@@       [email protected]@@          @@@     @@@   &@@(    @@@
// %@@@@@@@@%  *@@@      @@@     ,@@@       [email protected]@@@@@@@@(   @@@     @@@     @@@@@@@@

// Vhils + DRP + Pellar 2022

contract VhilsNFT is NFTEnumerable, ERC1155Holder {
  using Strings for uint256;

  enum LEVEL {
    BASE,
    TEAR_1,
    TEAR_2,
    TEAR_3
  }

  struct TokenInfo {
    LEVEL state;
    bool locked;
    uint8[4] tearIdUsed;
    uint64 name;
    string uri;
  }

  // constants
  uint256 public constant PRICE = 0.2 ether;
  uint8 public constant MAX_PER_WALLET = 5;
  uint8 public constant MAX_PER_TXN = 5;

  uint16 public constant MAX_SUPPLY = 10000;
  uint16 public constant PRESALE_SUPPLY = 9000;
  uint16 public constant TEAM_SUPPLY = 978;

  // variables
  uint16 public teamClaimed;
  uint16 public presaleClaimed;
  uint16 public saleClaimed;

  mapping(uint8 => mapping(uint8 => string)) public baseStateURI;

  mapping(uint8 => bool) public tearActive;
  mapping(address => uint16) public tokenClaimed;
  mapping(uint16 => TokenInfo) public tokens;

  event TEAR(address indexed from, uint16 indexed tokenId, uint8 tearId, uint256 blockNumber, uint256 timestamp);
  event LOCK(address indexed from, uint16 indexed tokenId, bool status, uint256 blockNumber, uint256 timestamp);

  constructor() NFTEnumerable() {
    defaultURI = 'ipfs://QmeUuVjpM9zrYiz2nMKo41T3wjRRnr4qp4Shn7ngHgfSVX/';
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(NFTEnumerable, ERC1155Receiver) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /** View */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "Non exists token");

    // fallback uri
    if (!isBlank(backupURI)) {
      return string(abi.encodePacked(backupURI, _tokenId.toString()));
    }

    // specific uri
    if (!isBlank(tokens[uint16(_tokenId)].uri)) {
      return tokens[uint16(_tokenId)].uri;
    }

    // state uri
    if (tokens[uint16(_tokenId)].name > 0) {
      uint8 state = uint8(tokens[uint16(_tokenId)].state);
      uint8 tearId = tokens[uint16(_tokenId)].tearIdUsed[state];
      return string(abi.encodePacked(baseStateURI[state][tearId], Strings.toString(tokens[uint16(_tokenId)].name)));
    }

    // default
    return string(abi.encodePacked(defaultURI, _tokenId.toString()));
  }


  function getTokenInfo(uint16 _tokenId) public view returns (TokenInfo memory) {
    return tokens[_tokenId];
  }

  /** User */
  function presaleMint(uint16 _maxAmount, bytes calldata _signature, uint16 _amount) external payable {
    require(tx.origin == msg.sender, "Not allowed"); // no contract
    require(presaleActive, "Not active"); // sale active
    require(_amount <= MAX_PER_TXN, "Exceed txn"); // txn limit
    require(eligibleByWhitelist(_maxAmount, msg.sender, _signature, _amount), "Not eligible"); // eligible to claim
    require(presaleClaimed + saleClaimed + _amount + TEAM_SUPPLY <= MAX_SUPPLY, "Exceed supply"); // supply limit
    require(presaleClaimed + _amount <= PRESALE_SUPPLY, "Exceed supply"); // supply limit
    require(msg.value >= PRICE * _amount, "Insufficient ether");

    uint16 claimed = presaleClaimed + saleClaimed;

    uint16 tearReward = _amount;
    for (uint16 i = 0; i < _amount; i++) {
      uint16 tokenId = claimed + i;
      _mint(msg.sender, tokenId);

      if ((tokenId * 10 % 75) == 0) {
        tearReward += 2;
      } else if (tokenId % 10 == 0) {
        tearReward += 1;
      }
    }
    ITEAR(tearContract).safeTransferFrom(address(this), msg.sender, 1, tearReward, ""); // transfer alpha token

    presaleClaimed += _amount;
    tokenClaimed[msg.sender] += _amount;
  }

  function mint(uint16 _amount) external payable {
    require(tx.origin == msg.sender, "Not allowed"); // no contract
    require(saleActive, "Not active"); // sale active
    require(_amount <= MAX_PER_TXN, "Exceed txn"); // txn limit
    require(tokenClaimed[msg.sender] + _amount <= MAX_PER_WALLET, "Exceed wallet"); // wallet limit
    require(presaleClaimed + saleClaimed + _amount + TEAM_SUPPLY <= MAX_SUPPLY, "Exceed supply"); // supply limit
    require(msg.value >= PRICE * _amount, "Insufficient ether"); // fee

    uint16 claimed = presaleClaimed + saleClaimed;
    uint16 tearReward = _amount;
    for (uint16 i = 0; i < _amount; i++) {
      uint16 tokenId = claimed + i;
      _mint(msg.sender, tokenId);

      if ((tokenId * 10 % 75) == 0) {
        tearReward += 2;
      } else if (tokenId % 10 == 0) {
        tearReward += 1;
      }
    }
    ITEAR(tearContract).safeTransferFrom(address(this), msg.sender, 1, tearReward, ""); // transfer alpha token

    saleClaimed += _amount;
    tokenClaimed[msg.sender] += _amount;
  }

  function tear(uint16 _tokenId, uint8 _tearId, uint64 _name, bytes calldata _signature) external {
    uint8 tearUnit = 1;
    uint8 newLevel = uint8(tokens[_tokenId].state) + tearUnit;
    require(ownerOf(_tokenId) == msg.sender, "Not allowed");
    require(eligibleTear(_tokenId), "Not eligible");
    bytes32 message = keccak256(abi.encodePacked(hashKey, newLevel, _tokenId, _name, msg.sender));
    require(validSignature(message, _signature), "Signature eligible");

    ITEAR(tearContract).safeTransferFrom(msg.sender, address(this), _tearId, tearUnit, "");
    tokens[_tokenId].name = _name;
    tokens[_tokenId].state = LEVEL(newLevel);
    tokens[_tokenId].tearIdUsed[newLevel] = _tearId;

    emit TEAR(msg.sender, _tokenId, _tearId, block.number, block.timestamp);
  }

  function lockToken(uint16 _tokenId, bool _status) external {
    require(msg.sender == ownerOf(_tokenId), "Not allowed");

    tokens[_tokenId].locked = _status;
    emit LOCK(msg.sender, _tokenId, _status, block.number, block.timestamp);
  }

  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(_from, _to, _tokenId);
    require(!tokens[uint16(_tokenId)].locked, "Token locked");
  }

  function eligibleTear(uint16 _tokenId) public view returns (bool) {
    uint8 newLevel = uint8(tokens[_tokenId].state) + 1;
    if (newLevel > uint8(LEVEL.TEAR_3)) {
      return false;
    }
    return tearActive[newLevel];
  }

  function eligibleByWhitelist(uint16 _maxAmount, address _account, bytes memory _signature, uint16 _amount) internal view returns (bool) {
    bytes32 message = keccak256(abi.encodePacked(hashKey, _maxAmount, _account));
    return validSignature(message, _signature) && tokenClaimed[_account] + _amount <= MAX_PER_WALLET && tokenClaimed[_account] + _amount <= _maxAmount;
  }

  function setTokenURI(uint16 _tokenId, string calldata _uri) external onlyOwner {
    tokens[_tokenId].uri = _uri;
  }

  function setTokenURIName(uint16 _tokenId, uint64 _name) external onlyOwner {
    tokens[_tokenId].name = _name;
  }

  function setBaseStateURI(LEVEL _stage, uint8 _tearId, string calldata _uri) external onlyOwner {
    baseStateURI[uint8(_stage)][_tearId] = _uri;
  }

  function toggleTear(LEVEL _tear, bool _status) external onlyOwner {
    tearActive[uint8(_tear)] = _status;
  }

  function withdrawTEAR(uint8 _tearId) external onlyOwner {
    uint256 balance = ITEAR(tearContract).balanceOf(address(this), _tearId);
    ITEAR(tearContract).safeTransferFrom(address(this), msg.sender, _tearId, balance, "");
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    uint256 balanceA;
    uint256 balanceB;
    uint256 balanceC;
    if (balance > 2 ether) {
      balance = balance - 2 ether;
      balanceA = balance * 25 / 100;
      balanceB = balance * 60 / 100;
      balanceC = balance - balanceA - balanceB + 2 ether;
    } else {
      balanceA = balance * 25 / 100;
      balanceB = balance * 60 / 100;
      balanceC = balance - balanceA - balanceB;
    }
    (bool successA, ) = 0xDAEcAcCBA76EcCaAD1ca3398dC324e04da72De77.call{value: balanceA}("");
    if (!successA) {
      payable(msg.sender).transfer(balanceA);
    }
    (bool successB, ) = 0x7b5e2f53bdbbbFb7fcd1f0792d671040081D4342.call{value: balanceB}("");
    if (!successB) {
      payable(msg.sender).transfer(balanceB);
    }
    (bool successC, ) = 0x58F58f15A0D080932218D65beb8bBd83978677d7.call{value: balanceC}("");
    if (!successC) {
      payable(msg.sender).transfer(balanceC);
    }
  }

  function forceWithdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function teamClaim(address _receiver, uint16 _amount) external onlyOwner {
    require(teamClaimed < TEAM_SUPPLY, "Exceed max");
    uint16 start = MAX_SUPPLY - TEAM_SUPPLY + teamClaimed;
    uint16 max = start + _amount;
    for (uint16 i = start; i < max; i ++) {
      _mint(_receiver, i);
    }
    teamClaimed += _amount;
  }
}

interface ITEAR {
  function balanceOf(address, uint256) external view returns (uint256);

  function safeTransferFrom(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) external;
}