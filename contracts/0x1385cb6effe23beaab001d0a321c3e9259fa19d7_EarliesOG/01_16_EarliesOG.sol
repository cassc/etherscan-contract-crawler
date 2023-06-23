// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./extensions/ERC721ABurnable.sol";
import "./Earlies.sol";

/*
 * @title Earlies Society OG ERC721A Non-Fungible Token
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 * ███████╗ █████╗ ██████╗ ██╗     ██╗███████╗███████╗
 * ██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔════╝
 * █████╗  ███████║██████╔╝██║     ██║█████╗  ███████╗
 * ██╔══╝  ██╔══██║██╔══██╗██║     ██║██╔══╝  ╚════██║
 * ███████╗██║  ██║██║  ██║███████╗██║███████╗███████║
 * ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝╚══════╝
*/
                                                   

contract EarliesOG is ERC721ABurnable, Ownable, ReentrancyGuard {
  using MerkleProof for bytes32[];
  using Strings for uint256;

  Earlies TESFounderCardSC;

  uint256 public maxSupply = 200;
  string public _baseTokenURI = "ipfs://QmWrSpdpCYxLiEUMznHGoLKGfPvTX6UpdoCitiZznZVt7s/";
  bool public eventMintOpen = false;

  mapping (string => bytes32) merkleRoots;
  mapping (address => bool) eventMinted;
  mapping (address => bool) mintDelegates;

  struct MintOGPayload {
    bytes32[] proof;
    uint256 tokenId;
    string districtName;
  }

  constructor() ERC721A("TES - OG Cards", "TESOG") {
    merkleRoots["mindfulness"] = 0x275ca69347872c60300f7572b1234074c4469bd75d15ca8675933b74f83d9213;
    merkleRoots["mastermind"] = 0x56ec9f127419d100d2edcd1e1e63850c8079478e880f146788fdd36a5a2d1460;
    merkleRoots["gaming"] = 0xd4f80840b81347077a61354db1e71198a50b3d5daa98688dbef08d1436cf48e3;
    merkleRoots["casino"] = 0x96956ff45decbe581b60641245909907ea52689da743b506322e21633c93eeae;
    merkleRoots["festival"] = 0x99498f6ca119f27f332791102b92201522e0224dd5adbdeeffad510e19a9e397;
    TESFounderCardSC = Earlies(0xa9ee01AEe0704bEF7076d6E42c311d4fCf633444);
  }

  function hashToken(string memory tokenId) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(tokenId));
  }

  function checkDistrict(MintOGPayload memory payload) private view returns (bool) {
    require(payload.tokenId >= 0 && payload.tokenId <= 2000, "Invalid Token ID.");
    require(payload.proof.verify(
        merkleRoots[payload.districtName], 
        hashToken(payload.tokenId.toString())
      ),
     "Invalid Proof.");
    TokenOwnership memory ownerShipData = TESFounderCardSC.getOwnershipData(payload.tokenId);
    require(ownerShipData.addr == msg.sender, "You are not the owner of this token.");
    require(!ownerShipData.burned, "This token has been burned.");
    return true;
  }

  function compareStrings(string memory a, string memory b) private pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }

  function eventMint(MintOGPayload[] memory payload) public {
    require(eventMintOpen, "Event Minting is not open.");
    require(!eventMinted[msg.sender], "You have already minted a card through the event.");
    require(TESFounderCardSC.isApprovedForAll(msg.sender, address(this)), "You need to approve the contract to mint.");
    require(TESFounderCardSC.balanceOf(msg.sender) >= 11, "You need to have at least 11 TES cards to partecipate to the event.");

    bool mindfulnessSent = false;
    bool mastermindSent = false;
    bool gamingSent = false;
    bool casinoSent = false;
    bool festivalSent = false;

    for(uint256 i = 0; i < payload.length; i++) {
      if(compareStrings(payload[i].districtName, "mindfulness")) {
        require(!mindfulnessSent, "Mindfulness district sent more than once.");
        checkDistrict(payload[i]);
        mindfulnessSent = true;
      } else if(compareStrings(payload[i].districtName, "mastermind")) {
        require(!mastermindSent, "Mastermind district sent more than once.");
        checkDistrict(payload[i]);
        mastermindSent = true;
      } else if(compareStrings(payload[i].districtName, "gaming")) {
        require(!gamingSent, "Gaming district sent more than once.");
        checkDistrict(payload[i]);
        gamingSent = true;
      } else if(compareStrings(payload[i].districtName, "casino")) {
        require(!casinoSent, "Casino district sent more than once.");
        checkDistrict(payload[i]);
        casinoSent = true;
      } else if(compareStrings(payload[i].districtName, "festival")) {
        require(!festivalSent, "Festival district sent more than once.");
        checkDistrict(payload[i]);
        festivalSent = true;
      } else {
        require(false, "Invalid district.");
      }
    }

    require(mindfulnessSent, "Mindfulness district not sent.");
    require(mastermindSent, "Mastermind district not sent.");
    require(gamingSent, "Gaming district not sent.");
    require(casinoSent, "Casino district not sent.");
    require(festivalSent, "Festival district not sent.");

    for(uint256 i = 0; i < payload.length; i++) {
      TESFounderCardSC.burn(payload[i].tokenId);
    }

    eventMinted[msg.sender] = true;
    _safeMint(msg.sender, 1);
  }

  /**
  * @dev Mint fn that will be used by $TES SC
  */
  function delegateMint(address receiver, uint256 qty) public {
    require(mintDelegates[msg.sender], "Permission denied.");
    _safeMint(receiver, qty);
  }

  /**
  * Backup mint function in case of emergency.
  */
  function ownerMint(address receiver, uint256 qty) public onlyOwner {
    _safeMint(receiver, qty);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function setTESSC(address target) external onlyOwner {
    TESFounderCardSC = Earlies(target);
  }

  function setDelegate(address delegate, bool allowed) external onlyOwner {
    mintDelegates[delegate] = allowed;
  }

  function setMerkleRoot(string memory district, bytes32 value) external onlyOwner {
    merkleRoots[district] = value;
  }

  function setEventMintState(bool state) external onlyOwner {
    eventMintOpen = state;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
  
}