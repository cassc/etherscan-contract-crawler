// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../zone/tlds/Pepe.sol";
import "../zone/tlds/Ape.sol";
import "./Signable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PepeRegistrar is Ownable, Signable {
  event DepositWithdrawn(uint256 amount, address to);

  using SafeMath for uint8;
  using SafeMath for uint256;

  PepeZone private _zoneContract;
  ERC20 private _pepeToken;
  ApeZone private _apeContract;

  uint256 private _halfPrice;

  using Strings for uint256;
  using Counters for Counters.Counter;

  bool public onlyAllowlister;
  Counters.Counter private _tokenIds;
  mapping(bytes32 => bool) public specialPepes;

  constructor(
    PepeZone zoneContract,
    ERC20 pepeToken,
    ApeZone apeContract,
    bytes32[] memory selectedSpecialPepes,
    uint256 halfPrice
  ) Signable(zoneContract) {
    onlyAllowlister = true;
    _zoneContract = zoneContract;
    _pepeToken = pepeToken;
    _apeContract = apeContract;
    for (uint256 i = 0; i < selectedSpecialPepes.length; i++) {
      specialPepes[selectedSpecialPepes[i]] = true;
    }
    _halfPrice = halfPrice;
  }

  function setOnlyAllowlister(bool _onlyAllowlister) public onlyOwner {
    onlyAllowlister = _onlyAllowlister;
  }

  function setPepeToken(ERC20 pepeToken) public onlyOwner {
    _pepeToken = pepeToken;
  }

  function getPepeToken() public view returns (ERC20) {
    return _pepeToken;
  }

  function setApeContract(ApeZone apeContract) public onlyOwner {
    _apeContract = apeContract;
  }

  function getApeContract() public view returns (ApeZone) {
    return _apeContract;
  }

  function addSpecialPepes(bytes32[] memory selectedSpecialPepes)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < selectedSpecialPepes.length; i++) {
      specialPepes[selectedSpecialPepes[i]] = true;
    }
  }

  function removeSpecialPepes(bytes32[] memory selectedSpecialPepes)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < selectedSpecialPepes.length; i++) {
      specialPepes[selectedSpecialPepes[i]] = false;
    }
  }

  function getHalfPrice() public view returns (uint256) {
    return _halfPrice;
  }

  function setHalfPrice(uint256 halfPrice) public onlyOwner {
    _halfPrice = halfPrice;
  }

  function allowlistPurchase(
    address to,
    string memory label,
    bytes32 parent,
    bytes memory signature
  ) public returns (bytes32 namehash) {
    require(!specialPepes[keccak256(bytes(label))], "special pepe");
    require(!startsWithSad(label), "sad- is reserved");
    require(onlyAllowlister, "not only allowlister");
    require(
      validateSignature(
        msg.sender,
        signature,
        hex"5b0ff7c1d5683bef738838377aa985128bbc5c6d2c0aaa42cd72a1a09c34e624"
      ),
      "invalid signature"
    );
    return purchase(to, label, parent);
  }

  function standardPurchase(
    address to,
    string memory label,
    bytes32 parent
  ) public returns (bytes32 namehash) {
    require(!specialPepes[keccak256(bytes(label))], "special pepe");
    require(!onlyAllowlister, "only allowlister");
    require(!startsWithSad(label), "sad- is reserved");
    return purchase(to, label, parent);
  }

  function specialPurchase(
    address to,
    bytes32 ape,
    bytes32 pepe,
    string[] memory selectedSpecialPepes,
    bytes32[] memory selectedSpecialPepesHashes
  ) public returns (bytes32 namehash) {
    string memory label = tryForSpecial(
      ape,
      pepe,
      selectedSpecialPepes,
      selectedSpecialPepesHashes
    );

    uint256 value = _halfPrice * 4;

    payWithPepe(value);

    return
      _zoneContract.register(
        to,
        hex"5b0ff7c1d5683bef738838377aa985128bbc5c6d2c0aaa42cd72a1a09c34e624",
        label
      );
  }

  function purchase(
    address to,
    string memory label,
    bytes32 parent
  ) private returns (bytes32 namehash) {
    uint256 price = getPrice(label);

    payWithPepe(price);

    return _zoneContract.register(to, parent, label);
  }

  function withdraw(address to) public onlyOwner {
    uint256 balance = _pepeToken.balanceOf(address(this));
    bool success = _pepeToken.transfer(to, balance);
    require(success, "Transfer failed.");
  }

  function payWithPepe(uint256 amount) private {
    uint256 allowance = _pepeToken.allowance(msg.sender, address(this));

    require(allowance >= amount, "not enough $pepe");

    bool success = _pepeToken.transferFrom(msg.sender, address(this), amount);
    require(success, "Transfer failed.");
  }

  function getPrice(string memory label) public view returns (uint256 value) {
    // $10 / $0.000001418 = 7,052,613.4 * (10^18) $PEPE (11th of May 2021 4:40pm CST)

    uint256 letters = bytes(label).length;

    require(letters > 0, "must have label");

    uint256 half = _halfPrice;

    if (letters < 8) {
      half = half * (2**(8 - letters));
    }

    value = half * 2;

    return value;
  }

  function tryForSpecial(
    bytes32 ape,
    bytes32 pepe,
    string[] memory selectedSpecialPepes,
    bytes32[] memory selectedSpecialPepesHashes
  ) private returns (string memory label) {
    uint256 chance = 0;
    if (ape != 0x0 && _apeContract.ownerOf(uint256(ape)) == msg.sender) {
      chance += 25;
    }
    if (pepe != 0x0 && _zoneContract.ownerOf(uint256(pepe)) == msg.sender) {
      chance += 25;
    }

    uint256 littleCount = 0;

    for (uint256 i = 0; i < selectedSpecialPepes.length; i++) {
      if (specialPepes[selectedSpecialPepesHashes[i]]) {
        littleCount++;
      }
      if (littleCount == 2) {
        chance += 1;
        littleCount = 0;
      }
    }

    if (chance > 0) {
      uint256 random = uint256(
        keccak256(abi.encodePacked(block.timestamp, msg.sender))
      ) % 100;

      if (random < chance) {
        if (!specialPepes[selectedSpecialPepesHashes[random]]) {
          uint256 selectedDomain = 0;
          while (
            !specialPepes[selectedSpecialPepesHashes[selectedDomain]] &&
            selectedDomain < 100
          ) {
            selectedDomain++;
          }

          require(
            keccak256(bytes(selectedSpecialPepes[selectedDomain])) ==
              selectedSpecialPepesHashes[selectedDomain],
            "string does not match hash"
          );
          specialPepes[
            keccak256(bytes(selectedSpecialPepes[selectedDomain]))
          ] = false;
          return selectedSpecialPepes[selectedDomain];
        }

        require(
          keccak256(bytes(selectedSpecialPepes[random])) ==
            selectedSpecialPepesHashes[random],
          "string does not match hash"
        );
        specialPepes[keccak256(bytes(selectedSpecialPepes[random]))] = false;
        return selectedSpecialPepes[random];
      }
    }

    uint256 newTokenId = _tokenIds.current();
    label = string(abi.encodePacked("sad-", Strings.toString(newTokenId)));
    _tokenIds.increment();

    return label;
  }

  function startsWithSad(string memory str) public pure returns (bool) {
    bytes memory b = bytes(str);
    bytes memory sadPrefix = "sad-";

    // Check if the input string is long enough to have the prefix
    if (b.length < sadPrefix.length) {
      return false;
    }

    // Compare each byte of the input string and the prefix
    for (uint256 i = 0; i < sadPrefix.length; i++) {
      if (b[i] != sadPrefix[i]) {
        return false;
      }
    }

    // If the loop completes, the input string starts with the prefix
    return true;
  }
}