// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

import "./ERC721.sol";
import "./Interfaces.sol";
import "./DataStructures.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*

██████████████████████████████████████████████████████████████████████████████████████████████████████████████████
█░░░░░░░░░░░░░░░░███░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█░░░░░░░░░░░░░░░░███░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█
█░░▄▀▄▀▄▀▄▀▄▀▄▀░░███░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀▄▀░░███░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█
█░░▄▀░░░░░░░░▄▀░░███░░▄▀░░░░░░▄▀░░█░░░░░░▄▀░░░░░░█░░▄▀░░░░░░░░▄▀░░███░░▄▀░░░░░░▄▀░░█░░▄▀░░░░░░░░░░█░░▄▀░░░░░░░░░░█
█░░▄▀░░████░░▄▀░░███░░▄▀░░██░░▄▀░░█████░░▄▀░░█████░░▄▀░░████░░▄▀░░███░░▄▀░░██░░▄▀░░█░░▄▀░░█████████░░▄▀░░█████████
█░░▄▀░░░░░░░░▄▀░░███░░▄▀░░░░░░▄▀░░█████░░▄▀░░█████░░▄▀░░░░░░░░▄▀░░███░░▄▀░░░░░░▄▀░░█░░▄▀░░█████████░░▄▀░░░░░░░░░░█
█░░▄▀▄▀▄▀▄▀▄▀▄▀░░███░░▄▀▄▀▄▀▄▀▄▀░░█████░░▄▀░░█████░░▄▀▄▀▄▀▄▀▄▀▄▀░░███░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░█████████░░▄▀▄▀▄▀▄▀▄▀░░█
█░░▄▀░░░░░░▄▀░░░░███░░▄▀░░░░░░▄▀░░█████░░▄▀░░█████░░▄▀░░░░░░▄▀░░░░███░░▄▀░░░░░░▄▀░░█░░▄▀░░█████████░░▄▀░░░░░░░░░░█
█░░▄▀░░██░░▄▀░░█████░░▄▀░░██░░▄▀░░█████░░▄▀░░█████░░▄▀░░██░░▄▀░░█████░░▄▀░░██░░▄▀░░█░░▄▀░░█████████░░▄▀░░█████████
█░░▄▀░░██░░▄▀░░░░░░█░░▄▀░░██░░▄▀░░█████░░▄▀░░█████░░▄▀░░██░░▄▀░░░░░░█░░▄▀░░██░░▄▀░░█░░▄▀░░░░░░░░░░█░░▄▀░░░░░░░░░░█
█░░▄▀░░██░░▄▀▄▀▄▀░░█░░▄▀░░██░░▄▀░░█████░░▄▀░░█████░░▄▀░░██░░▄▀▄▀▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█
█░░░░░░██░░░░░░░░░░█░░░░░░██░░░░░░█████░░░░░░█████░░░░░░██░░░░░░░░░░█░░░░░░██░░░░░░█░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█
██████████████████████████████████████████████████████████████████████████████████████████████████████████████████
A race to nowhere. It's a pointless race that everyone runs, but no one ever wins.
*/

contract RatRace is ERC721 {
  function name() external pure returns (string memory) {
    return "RatRace";
  }

  function symbol() external pure returns (string memory) {
    return "RAT";
  }

  using DataStructures for DataStructures.Rat;

  IERC1155Lite public nibbles;

  bool public isRace;
  bool public isBabyRat;
  bool public isRatList;
  bool private initialized;
  string public ratsLair;
  uint256 public specialRatsCount;
  uint256 public ratListAllowance;
  address kingRat;
  address public validator;
  bytes32 internal ketchup;
  uint256[12] public specialRats;

  mapping(uint256 => uint256) public rats; //memory slot for rats
  mapping(uint256 => uint256) public ratGene; //memory slot for rat gene index  
  mapping(bytes => uint256)  public usedSignatures; //memory slot for used signatures

  function initialize() public {
    require(!initialized, "Already initialized");
    initialized = true;
    kingRat = admin = msg.sender;
    ratsLair = "https://api.ratrace.wtf/api/rats/";
    maxSupply = 9999;
    ratListAllowance = 4;
    validator = 0xE9f85F77842b4bd536d6db14Cf8b9cBD4619b1b2;
  }

  event OnesWinners(uint256[] array);
  event OnesWinner(uint256 indexed tokenId, uint256 indexed specialId);

  function wlMint(uint256 qty, bytes memory signature) external returns (uint256 id) {

    isPlayer();
    address ratKeeper = msg.sender;  
    require(isRatList, "RR:NotRatList");  
    require(balanceOf[ratKeeper] < ratListAllowance, "RR:MaxAllowedExceeded");
    require(totalSupply + qty <= maxSupply, "RR:AllRatsReleased");    
    require(usedSignatures[signature] == 0, "Signature already used");   
    require(_isSignedByValidator(encodeSentinelForSignature(ratKeeper),signature), "incorrect signature");
    usedSignatures[signature] = 1;
    return _mintRat(ratKeeper, qty);
    
  }

  function unleashBabyRat(uint256 qty) external returns (uint256 id) {
    isPlayer();
    address ratKeeper = msg.sender;    
    require(isBabyRat, "RR:BabyRatNotOpen");
    require(totalSupply + qty <= maxSupply, "RR:AllRatsReleased");
    require(nibbles.balanceOf(ratKeeper, 4) >= qty, "RR:NotEnoughNibble!");
    nibbles.burn(ratKeeper, 4, qty);

    return _mintRat(ratKeeper, qty);
  }

  function unleashRat(uint256 qty) external payable returns (uint256 id) {
    isPlayer();
    raceActive();
    address ratKeeper = msg.sender;  
    require(qty <= 2, "RR:MaxAllowedExceeded");  
    require(balanceOf[ratKeeper] < 2, "RR:MaxAllowedExceeded");
    require(totalSupply + qty <= maxSupply, "RR:AllRatsReleased");
    return _mintRat(ratKeeper, qty);
  }

  function evolveRat(uint256 id, uint256 nibble) external {
    isPlayer();
    isRatKeeper(id);
    raceActive();
    require(nibble < 4, "RR:InvalidNibble");
    require(nibbles.balanceOf(msg.sender, nibble) >= 1, "RR:NotEnoughNibble!");
    nibbles.burn(msg.sender, nibble, 1);
    _evolveRat(id, nibble);
  }

/*  function specialRat(uint256 id) external {
    isPlayer();
    isRatKeeper(id);
    raceActive();
    require(specialRatsCount != 12, "RR:MaxUniqueExceeded");    
    require(nibbles.balanceOf(msg.sender, 3) >= 3, "RR:NotEnoughNibble!");
    nibbles.burn(msg.sender, 3, 3);
    _specialRat(id);
  }
*/
  //INTERNALS

  ///0x1aD42FB475192C8C0a2Fc7D0DF6faC4F71142c58

  function _mintRat(address _to, uint256 qty) private returns (uint16 id) {
    for (uint256 i = 0; i < qty; i++) {
      bool _exists = false;
      uint256 rand = _rand();
      uint256 chance = rand % 100;
      DataStructures.Rat memory rat;
      id = uint16(totalSupply + 1);
      uint256 count = id;

      while (!_exists) {
        rat.background = (uint16(_randomize(rand, "bg", count)) % 10) + 1;
        rat.body = (uint16(_randomize(rand, "bd", count)) % 25) + 1; //26,27,28 reserved for nibbles
        rat.accessories = chance < 12
          ? (uint16(_randomize(rand, "a", count)) % 11) + 1
          : 0; //12,13,14 reserved for nibbles);
        rat.ears = (uint16(_randomize(rand, "ea", count)) % 21) + 1;
        rat.head = (uint16(_randomize(rand, "he", count)) % 20) + 1;
        rat.leftEye = (uint16(_randomize(rand, "l", count)) % 18) + 1; //19, 20 reserved for nibbles
        rat.rightEye = (uint16(_randomize(rand, "r", count)) % 18) + 1; //19, 20 reserved for nibbles
        rat.mouth = (uint16(_randomize(rand, "m", count)) % 23) + 1;
        rat.nose = (uint16(_randomize(rand, "n", count)) % 22) + 1;
        rat.eyewear = chance < 10
          ? rat.nose <= 20 ? (uint16(_randomize(rand, "e", count)) % 7) + 1 : 0
          : 0;
        rat.headwear = chance < 35
          ? (uint16(_randomize(rand, "h", count)) % 9) + 1
          : 0; //10,11 reserved for nibbles
        rat.special = 0; //uint16(_randomize(rand, "s", id)) % 12 + 1;

        uint256 _ratGene = DataStructures.setRat(
          rat.id,
          rat.background,
          rat.body,
          rat.ears,
          rat.head,
          rat.leftEye,
          rat.rightEye,
          rat.mouth,
          rat.nose,
          rat.eyewear,
          rat.headwear,
          rat.accessories,
          rat.special
        );
        if (ratGene[_ratGene] == 0) {
          _exists = true;
          ratGene[_ratGene] = 1;
          rats[id] = _ratGene;
        } else {
          count++;
        }
      }

      nibbles.freebie(_to, id);
      _mint(_to, id);
    }
  }

  function _evolveRat(uint256 _id, uint256 _nibble) private {
    bool _exists = false;
    uint256 rand = _rand();
    uint256 chance = rand % 100;
    uint256 nibble = _nibble;

    DataStructures.Rat memory rat;
    rat = DataStructures.getRat(rats[_id]);

    uint256 count = _id;

    if(chance < 5){
      _burn(_id);
    }else{

    while (!_exists) {
      rat.background = (uint16(_randomize(rand, "bg", count)) % 11) + 1;
      rat.body = (uint16(_randomize(rand, "bd", count)) % 20) + 5 + nibble; //26,27,28 reserved for nibbles
      rat.accessories = chance < 50
        ? (uint16(_randomize(rand, "a", count)) % 8) + 3 + nibble
        : 0;
      rat.ears = (uint16(_randomize(rand, "ea", count)) % 21) + 1;
      rat.head = (uint16(_randomize(rand, "he", count)) % 20) + 1;
      rat.leftEye = (uint16(_randomize(rand, "l", count)) % 17) + nibble; //19, 20 reserved for nibbles
      rat.rightEye = (rat.leftEye == 19 || rat.leftEye == 20)
        ? rat.leftEye
        : (uint16(_randomize(rand, "r", count)) % 17) + 1; //19, 20 reserved for nibbles
      rat.mouth = (uint16(_randomize(rand, "m", count)) % 23) + 1;
      rat.nose = (uint16(_randomize(rand, "n", count)) % 22) + 1;
      rat.eyewear = (chance < (10 + (nibble * 10)) &&
        rat.leftEye != 19 &&
        rat.leftEye != 20)
        ? rat.nose <= 20 ? (uint16(_randomize(rand, "e", count)) % 7) + 1 : 0
        : 0;
      rat.headwear = (chance < (20 + (nibble * 10)) &&
        rat.leftEye != 19 &&
        rat.leftEye != 20)
        ? (uint16(_randomize(rand, "h", count)) % 8) + nibble
        : 0; //10,11 reserved for nibbles

      rat.special = rat.special;

      uint256 _ratGene = DataStructures.setRat(
        rat.id,
        rat.background,
        rat.body,
        rat.ears,
        rat.head,
        rat.leftEye,
        rat.rightEye,
        rat.mouth,
        rat.nose,
        rat.eyewear,
        rat.headwear,
        rat.accessories,
        rat.special
      );
      if (ratGene[_ratGene] == 0) {
        _exists = true;
        ratGene[_ratGene] = 1;
        rats[_id] = _ratGene;
      } else {
        count++;        
      }
    }
    }
  }

  function _specialRat(uint256 id) private {
    uint256 rand = _rand();
    uint256 chance = (uint16(_randomize(rand, "sp", id)) % 100);
    bool _exists = false;

    uint256 count = specialRatsCount;
    
    if (chance < 50) {
      while (!_exists && count < 12) {
        if (specialRats[count] == 0) {
          specialRats[count] = 1;
          _exists = true;

          DataStructures.Rat memory rat;
          rat = DataStructures.getRat(rats[id]);

          rat.special = count + 1;

          rat.body = 0;
          rat.ears = 0;
          rat.head = 0;
          rat.leftEye = 0;
          rat.rightEye = 0;
          rat.mouth = 0;
          rat.nose = 0;
          rat.eyewear = 0;
          rat.headwear = 0;
          rat.accessories = 0;

          rat.background = rat.special == 1
            ? 11
            : (uint16(_randomize(rand, "bg", count)) % 11) + 1;

          rats[id] = DataStructures.setRat(
            rat.id,
            rat.background,
            rat.body,
            rat.ears,
            rat.head,
            rat.leftEye,
            rat.rightEye,
            rat.mouth,
            rat.nose,
            rat.eyewear,
            rat.headwear,
            rat.accessories,
            rat.special
          );
          specialRatsCount++;
          emit OnesWinner(id, specialRatsCount);
        } else {
          count++;
        }
      }
    }
  }

  function IDKFA() external {
    onlyOwner();
    
    uint256 rand = _rand();
    uint256[] memory winners = new uint256[](12);
    uint256 startValue = specialRatsCount + 1;
    uint256 endValue = totalSupply - specialRatsCount;

    for (uint256 i = startValue; i <= 12; i++) {
      uint256 winner = ((_randomize(rand, "a", i)) % (endValue + i)) + 1;      

      DataStructures.Rat memory rat;

      rat = DataStructures.getRat(rats[winner]);

      rat.body = rat.ears = rat.head = rat.leftEye = rat
        .rightEye = rat.mouth = rat.nose = rat.eyewear = rat.headwear = rat
        .accessories = 0;
      
      rat.special = i;
      
      rat.background = rat.special == 1
            ? 11
            : (uint16(_randomize(rand, "bg", i)) % 11) + 1;     

      rats[winner] = DataStructures.setRat(
        rat.id,
        rat.background,
        rat.body,
        rat.ears,
        rat.head,
        rat.leftEye,
        rat.rightEye,
        rat.mouth,
        rat.nose,
        rat.eyewear,
        rat.headwear,
        rat.accessories,
        rat.special
      );
      winners[i - 1] = winner;
    }

    emit OnesWinners(winners);
  }

  function _randomize(
    uint256 ran,
    string memory dom,
    uint256 ness
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(ran, dom, ness)));
  }

  function _rand() internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            msg.sender,
            block.difficulty,
            block.timestamp,
            block.basefee,
            ketchup
          )
        )
      );
  }

  //PUBLIC VIEWS
  function tokenURI(uint256 _id) external view returns (string memory) {
    return
      string(
        abi.encodePacked(
          ratsLair,
          Strings.toString(rats[_id]),
          "?id=",
          Strings.toString(_id)
        )
      );
  }

  function isPlayer() internal {
    uint256 size = 0;
    address acc = msg.sender;
    assembly {
      size := extcodesize(acc)
    }
    require((msg.sender == tx.origin && size == 0));
    ketchup = keccak256(abi.encodePacked(acc, block.coinbase));
  }

  function onlyOwner() internal view {
    require(
      admin == msg.sender || kingRat == msg.sender,
      "RR:NotKingRat"
    );
  }

  function isRatKeeper(uint256 id) internal view {
    require(msg.sender == ownerOf[id], "RR:NotYourRat");
  }

  function raceActive() internal view {
    require(isRace, "RR:Race!Open");
  }

  //ADMIN Only
  function withdrawAll() public {
    onlyOwner();
    uint256 balance = address(this).balance;
    require(balance > 0);
    _withdraw(kingRat, balance);
  }

  //Internal withdraw
  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{ value: _amount }("");
    require(success);
  }

  function startRatRace() external {
    onlyOwner();
    isRace = !isRace;
  }

  function startBabyRat() external {
    onlyOwner();
    isBabyRat = !isBabyRat;
  }

  function startRatList() external {
    onlyOwner();
    isRatList = !isRatList;
  }
  
  function setRatListAllowance(uint256 _ratListAllowance) external {
    onlyOwner();
    ratListAllowance = _ratListAllowance;
  }
  

  function greed(uint256 _reserveAmount, address _to) public {
    onlyOwner();
    require(totalSupply + _reserveAmount <= maxSupply);
    _mintRat(_to, _reserveAmount);
  }

  function setAddresses(address _nibbles) public {
    onlyOwner();
    nibbles = IERC1155Lite(_nibbles);
  }

function setMaxSupply(uint256 _maxSupply) public {
    onlyOwner();
    maxSupply = _maxSupply;
  }
  

  function setRatsLair(string memory _ratsLair) public {
    onlyOwner();
    ratsLair = _ratsLair;
  }

  function setValidator(address _validator) public {
    onlyOwner();
    validator = _validator;
  }

  function encodeSentinelForSignature(address ratKeeper) public pure returns (bytes32) {
        return keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", 
                    keccak256(
                            abi.encodePacked(ratKeeper))
                            )
                        );
    } 


    function _isSignedByValidator(bytes32 _hash, bytes memory _signature) private view returns (bool) {
                
                bytes32 r;
                bytes32 s;
                uint8 v;
                    assembly {
                            r := mload(add(_signature, 0x20))
                            s := mload(add(_signature, 0x40))
                            v := byte(0, mload(add(_signature, 0x60)))
                        }
                    
                        address signer = ecrecover(_hash, v, r, s);
                        return signer == validator;
  
            }

}