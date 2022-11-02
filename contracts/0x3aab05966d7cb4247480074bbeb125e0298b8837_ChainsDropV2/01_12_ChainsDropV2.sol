//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { ECDSA, Strings } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// Contract by @backseats_eth

contract ChainsDropV2 is ERC1155, Ownable {
  using ECDSA for bytes32;
  using Strings for uint256;

  uint public price = 0.025 ether;

  uint private constant LEGENDARY = 1;
  uint private constant MEGA_DIAMOND_PENDANT = 2;
  uint private constant MEGA_DIAMOND_WHALE = 3;
  uint private constant DIAMOND_ETH_RING = 4;
  uint private constant DIAMOND_INGOT = 5;
  uint private constant PLATINUM_ETH_RING = 6;
  uint private constant PLATINUM_INGOT = 7;
  uint private constant GOLD_CHAIN_RING = 8;
  uint private constant GOLD_ETH_RING = 9;
  uint private constant BASE = 10;
  uint private constant PUBLIC_FREE = 11;
  uint private constant PUBLIC_PAID = 12;

  uint private constant PUBLIC_FREE_MAX_SUPPLY = 10_000;
  uint private constant PUBLIC_PAID_MAX_SUPPLY = 1_000;

  uint public freeClaimCount;
  uint public publicPaidCount;

  bool public claimIsOpen;
  bool public freeClaimIsOpen;
  bool public paidMintIsOpen;
  bool teamDidMint;

  address public  systemAddress;
  address private teamAddress = 0x746D5df50a47a1aFc06Fa2B4841809123250C5bD;

  mapping (address => bool) public addressHasFreeClaimed;
  mapping (address => bool) public addressHasClaimed;

  string public _baseURI;

  // Constructor

  constructor() ERC1155("") {}

  // Claim

  function claim(
    uint _ownedCount,
    bool _mdWhale,
    bool _diamondRing,
    bool _platinumRing,
    bool _goldChainRing,
    bytes calldata _signature
  ) external {
    require(claimIsOpen, "Claim closed");
    require(addressHasClaimed[msg.sender] == false, "Already claimed");

    addressHasClaimed[msg.sender] = true;

    require(isValidSignature(keccak256(abi.encodePacked(msg.sender, _ownedCount)), _signature), "Invalid signature");

    if (_ownedCount > 49) {
      mintLegendary(_mdWhale, _diamondRing, _platinumRing, _goldChainRing);

    } else if (_ownedCount >= 30 && _ownedCount < 50) {
      mintMegaDiamond(_mdWhale, _diamondRing, _platinumRing, _goldChainRing);

    } else if (_ownedCount >= 10 && _ownedCount < 30) {
      mintDiamond(_diamondRing, _platinumRing, _goldChainRing);

    } else if (_ownedCount >= 6 && _ownedCount < 10) {
      mintPlatinum(_platinumRing, _goldChainRing);

    } else if (_ownedCount >= 3 && _ownedCount < 6) {
      mintGold(_goldChainRing);

    } else {
      mintBase();
    }
  }

  // Private Functions

  function mintLegendary(bool _megaDiamondWhale, bool _diamondRing, bool _platEthRing, bool _goldChainRing) private {
    mint(LEGENDARY);
    mintMegaDiamond(_megaDiamondWhale, _diamondRing, _platEthRing, _goldChainRing);
  }

  function mintMegaDiamond(bool _megaDiamondWhale, bool _diamondRing, bool _platEthRing, bool _goldChainRing) private {
    mint(_megaDiamondWhale ? MEGA_DIAMOND_WHALE : MEGA_DIAMOND_PENDANT);
    mintDiamond(_diamondRing, _platEthRing, _goldChainRing);
  }

  function mintDiamond(bool _diamondRing, bool _platEthRing, bool _goldChainRing) private {
    mint(_diamondRing ?  DIAMOND_ETH_RING : DIAMOND_INGOT);
    mintPlatinum(_platEthRing, _goldChainRing);
  }

  function mintPlatinum(bool _platEthRing, bool _goldChainRing) private {
    mint(_platEthRing ? PLATINUM_ETH_RING : PLATINUM_INGOT);
    mintGold(_goldChainRing);
  }

  function mintGold(bool _goldChainRing) private {
    mint(_goldChainRing ? GOLD_CHAIN_RING : GOLD_ETH_RING);
    mintBase();
  }

  function mintBase() private {
    mint(BASE);
  }

  function mint(uint _type) private {
    _mint(msg.sender, _type, 1, "");
  }

  // Free Claim

  function freeClaim() external {
    require(freeClaimIsOpen, "Free claim closed");
    require(tx.origin == msg.sender, "C'mon");
    require(freeClaimCount + 1 <= PUBLIC_FREE_MAX_SUPPLY, "Free claim sold out");
    require(addressHasFreeClaimed[msg.sender] == false, "Already claimed");

    addressHasFreeClaimed[msg.sender] = true;

    unchecked { ++freeClaimCount; }

    _mint(msg.sender, PUBLIC_FREE, 1, "");
  }

  // Paid Mint

  function paidMint(uint _amount) external payable {
    require(paidMintIsOpen, "Paid mint closed");
    require(publicPaidCount + _amount <= PUBLIC_PAID_MAX_SUPPLY, "Paid mint sold out");
    require(_amount > 0 && _amount < 11, "Mint 1-10");
    require(_amount * price == msg.value, "Wrong price");

    unchecked { publicPaidCount += _amount; }

    _mint(msg.sender, PUBLIC_PAID, _amount, "");
  }

  // Airdrop

  // _idToMint should either be 11 or 12
  function airdrop(address[] calldata _addresses, uint _idToMint) external onlyOwner {
    for (uint i; i < _addresses.length;) {
      // Mint the address 1 of the ID of the token
      _mint(_addresses[i], _idToMint, 1, "");
      unchecked { ++i; }
    }
  }

  // Team Mints

  function teamMint() external onlyOwner {
    require(!teamDidMint);
    _mint(teamAddress, PUBLIC_FREE, 150, "");
    _mint(teamAddress, PUBLIC_PAID, 50, "");
    teamDidMint = true;
  }

  // Setters

  function setPrice(uint _wei) external onlyOwner {
    price = _wei;
  }

  function openMint(bool _val) external onlyOwner {
    claimIsOpen = _val;
    freeClaimIsOpen = _val;
    paidMintIsOpen = _val;
  }

  function setClaimIsOpen(bool _val) external onlyOwner {
    claimIsOpen = _val;
  }

  function setFreeClaimIsOpen(bool _val) external onlyOwner {
    freeClaimIsOpen = _val;
  }

  function setPaidMintIsOpen(bool _val) external onlyOwner {
    paidMintIsOpen = _val;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseURI = baseURI;
  }

  function setSystemAddress(address _systemAddress) external onlyOwner {
    systemAddress = _systemAddress;
  }

  // View

  function uri(uint256 tokenId) public view virtual override returns (string memory) {
    return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : "";
  }

  // Signatures

  function isValidSignature(bytes32 hash, bytes calldata signature) internal view returns (bool) {
    require(systemAddress != address(0), "Missing system address");
    bytes32 signedHash = hash.toEthSignedMessageHash();
    return signedHash.recover(signature) == systemAddress;
  }

  // Withdraw

  function withdraw() external onlyOwner {
    (bool success, ) = payable(teamAddress).call{value: address(this).balance}("");
    require(success, "Withdraw failed");
  }

}