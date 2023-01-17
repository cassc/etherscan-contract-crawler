// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract GeneCards is ERC1155, AccessControl {
  uint256 public constant CARD = 0;

  uint256 public constant TOP_N = 1;
  uint256 public constant TOPLEFT_N = 2;
  uint256 public constant TOPRIGHT_N = 3;
  uint256 public constant MID_N = 4;
  uint256 public constant LEFT_N = 5;
  uint256 public constant RIGHT_N = 6;
  uint256 public constant BOTTOM_N = 7;
  uint256 public constant BOTTOMLEFT_N = 8;
  uint256 public constant BOTTOMRIGHT_N = 9;

  uint256 public constant TOP_R = 10;
  uint256 public constant TOPLEFT_R = 11;
  uint256 public constant TOPRIGHT_R = 12;
  uint256 public constant MID_R = 13;
  uint256 public constant LEFT_R = 14;
  uint256 public constant RIGHT_R = 15;
  uint256 public constant BOTTOM_R = 16;
  uint256 public constant BOTTOMLEFT_R = 17;
  uint256 public constant BOTTOMRIGHT_R = 18;

  uint256 public constant TOP_S = 19;
  uint256 public constant TOPLEFT_S = 20;
  uint256 public constant TOPRIGHT_S = 21;
  uint256 public constant MID_S = 22;
  uint256 public constant LEFT_S = 23;
  uint256 public constant RIGHT_S = 24;
  uint256 public constant BOTTOM_S = 25;
  uint256 public constant BOTTOMLEFT_S = 26;
  uint256 public constant BOTTOMRIGHT_S = 27;

  uint256 public constant TOP_SR = 28;
  uint256 public constant TOPLEFT_SR = 29;
  uint256 public constant TOPRIGHT_SR = 30;
  uint256 public constant MID_SR = 31;
  uint256 public constant LEFT_SR = 32;
  uint256 public constant RIGHT_SR = 33;
  uint256 public constant BOTTOM_SR = 34;
  uint256 public constant BOTTOMLEFT_SR = 35;
  uint256 public constant BOTTOMRIGHT_SR = 36;


  uint256 public constant CARD_BASE = 100;
  uint256 public constant CARD_N = 100;
  uint256 public constant CARD_R = 101;
  uint256 public constant CARD_S = 102;
  uint256 public constant CARD_SR = 103;

  bytes32 public constant ROOT_ROLE = keccak256("ROOT");
  bytes32 public constant MANAGER = keccak256("MANAGER");

  uint public cardBagSupply;
  // N, R, S, SR - order
  uint[37] public fragSupply;
  uint[4] public cardSupply;

  event CardFragMint(address recipient, uint cardType, uint amount);
  event CreditFragMint(address recipient, uint cardType, uint amount);
  event UsdtFragMint(address recipient, uint cardType, uint amount);
  event CardFragBurnt(address recipient, uint cardType, uint amount);

  uint randNonce = 0;

  constructor() ERC1155("https://static.geneplayer.io/{id}.json") {
    _setupRole(ROOT_ROLE, msg.sender);
    _setupRole(MANAGER, msg.sender);
    _setRoleAdmin(MANAGER, ROOT_ROLE);

    cardBagSupply = 39654;
    cardSupply = [7113, 1199, 400, 100];
    for(uint i=1; i<=36; i++) {
      if(i<=9) fragSupply[i] = 7113;
      else if(i<=18) fragSupply[i] = 1199;
      else if(i<=27) fragSupply[i] = 400;
      else if(i<=36) fragSupply[i] = 100;
    }
  }

  function rollLevel() internal returns (uint256) {
    uint256 N_MAX =  8072;
    uint256 R_MAX =  8072+1361;
    uint256 S_MAX =  8072+1361+454;
    uint256 SR_MAX = 10000;

    uint256 num4level = randInRange(0, 10000);
    uint256 level = 0; // level N

    if(num4level < N_MAX) level = 0;
    if(N_MAX < num4level && num4level < R_MAX) level = 1;
    if(R_MAX < num4level && num4level < S_MAX) level = 2;
    if(S_MAX < num4level && num4level < SR_MAX) level = 3;

    return level;
  }

  function getOne(address recipient) private {
    uint256 level;
    uint256 pos;
    uint256 frag2award = level*9 + pos + 1;

    do {
      level = rollLevel();
    } while(levelCount(level) == 0);

    do {
      pos = randInRange(0, 8);
      frag2award = level*9 + pos + 1;
    } while(fragSupply[frag2award] == 0);

    _mint(recipient, frag2award, 1, "");
    fragSupply[frag2award] -= 1;
    emit CardFragMint(recipient, frag2award, 1);
  }

  function levelCount(uint256 level) public view returns (uint256) {
    require(level < 4, "level must lower than 4");
    uint256 res = 0;

    for(uint i=level*9+1; i<(level+1)*9+1; i++) {
      res += fragSupply[i];
    }

    return res;
  } 

  function fragsCount() public view returns (uint256) {
    uint256 res = 0;
    for(uint i=1; i<=36; i++) {
      res += fragSupply[i]; 
    }

    return res;
  }

  function makeOneLottery() public {
    require(balanceOf(msg.sender, CARD) > 0, "insufficient balance");
    require(fragsCount() >= 2, "no frags left");
    _burn(msg.sender, CARD, 1);
    emit CardFragBurnt(msg.sender, CARD, 1);

    getOne(msg.sender);
    getOne(msg.sender);
  }

  function lotteryAll() public {
    require(balanceOf(msg.sender, CARD) > 0, "insufficient balance");

    uint256 balance = balanceOf(msg.sender, CARD);
    for(uint i=0; i<balance; i++) {
      getOne(msg.sender);
      getOne(msg.sender);
    }

    _burn(msg.sender, CARD, balance);
    emit CardFragBurnt(msg.sender, CARD, balance);
  }

  function dispenseSpecific(address recipient, uint256 _type, uint256 amount) public onlyRole(MANAGER) {
    if(_type == 0) {
      require(cardBagSupply >= amount, "no card bag is available");
      cardBagSupply -= amount;
    } else if(0 < _type && _type < 37) {
      require(fragSupply[_type] >= amount, "no fragment is available");
      fragSupply[_type] -= amount;
    } else if (99 < _type && _type < 104) {
      require(cardSupply[_type - CARD_BASE] >= amount, "no fragment is available");
      cardSupply[_type - CARD_BASE] -= amount;
    }

    _mint(recipient, _type, amount, "");
    emit CardFragMint(recipient, _type, amount);
  }

  function creditDispenseCardFrag(address recipient, uint256 amount) public onlyRole(MANAGER) {
    require(cardBagSupply >= amount, "insufficient balance");
    _mint(recipient, CARD, amount, "");
    cardBagSupply -= amount;
    emit CreditFragMint(recipient, CARD, amount);
  }

  function usdtDispenseCardFrag(address recipient, uint256 amount) public onlyRole(MANAGER) {
    require(cardBagSupply >= amount, "insufficient balance");
    _mint(recipient, CARD, amount, "");
    cardBagSupply -= amount;
    emit UsdtFragMint(recipient, CARD, amount);
  }

  function dispenseCardFrag(address recipient, uint256 amount) public onlyRole(MANAGER) {
    require(cardBagSupply >= amount, "insufficient balance");
    _mint(recipient, CARD, amount, "");
    cardBagSupply -= amount;
    emit CardFragMint(recipient, CARD, amount);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function randMod(uint modulus) internal returns(uint) {
    // increase nonce
    randNonce++; 
    return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % modulus;
  }

  function realizeCards() public {
    uint256[9] memory balance;
    uint256 minCountOfFrag = 1000000000000;

    for(uint8 levelAcc=0; levelAcc<4; levelAcc++) {
      // reset count of frag at each level
      minCountOfFrag = 1000000000000;
      for(uint8 i=0; i<9; i++) {
        uint256 item = levelAcc*9 + i + 1;
        balance[i] = balanceOf(msg.sender, item);       
        if(balance[i] < minCountOfFrag) {
          minCountOfFrag = balance[i];
        }
      }

      if(minCountOfFrag > 0) {
        _mint(msg.sender, CARD_BASE + levelAcc, minCountOfFrag, "");
        cardSupply[levelAcc] -= minCountOfFrag;
        emit CardFragMint(msg.sender, CARD_BASE + levelAcc, minCountOfFrag);

        for(uint8 i=0; i<9; i++) {
          uint256 item = levelAcc*9 + i + 1;
          _burn(msg.sender, item, minCountOfFrag);
          emit CardFragBurnt(msg.sender, item, minCountOfFrag);
        }
      }

    }
  }

  function realizeOne(uint16 kind, uint256 amount) public {
    uint256[9] memory balance;
    uint256 minCountOfFrag = 1000000000000;
    for(uint8 i=0; i<9; i++) {
      uint256 item = kind*9 + i + 1;
      balance[i] = balanceOf(msg.sender, item);       
      if(balance[i] < minCountOfFrag) {
        minCountOfFrag = balance[i];
      }
    }

    if(minCountOfFrag >= amount) {
      _mint(msg.sender, CARD_BASE + kind, amount, "");
      cardSupply[kind] -= amount;
      emit CardFragMint(msg.sender, CARD_BASE + kind, amount);

      for(uint8 i=0; i<9; i++) {
        uint256 item = kind*9 + i + 1;
        _burn(msg.sender, item, amount);
        emit CardFragBurnt(msg.sender, item, amount);
      }
    } else {
      revert("insufficient amount of card fragments");
    }
  }

  function randInRange(uint start, uint stop) private returns (uint) {
    return randMod(stop-start+1) + start;
  }
}