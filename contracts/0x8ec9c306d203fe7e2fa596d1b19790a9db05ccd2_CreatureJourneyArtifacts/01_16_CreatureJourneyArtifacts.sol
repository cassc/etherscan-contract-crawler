// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "eth-token-recover/contracts/TokenRecover.sol";

interface ICreature {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract CreatureJourneyArtifacts is ERC721Enumerable, ReentrancyGuard, Ownable, TokenRecover {

  mapping(uint256 => address) private _claimedBy;

  // Base URI for token metadata:
  string private _baseURIExtended;

  // Event for setting baseURI:
  event SetBaseUri(
    string newBaseUri
  );

  ICreature immutable internal _creatureWorld;

  constructor(ICreature creatureWorld_) ERC721("Creature Journey Artifacts", "ARTIFACT") {
    _creatureWorld = creatureWorld_;
    setBaseURI("https://creature.mypinata.cloud/ipfs/HASH/");
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseURIExtended;
  }

  function setBaseURI(string memory baseURI_) public onlyOwner returns (string memory) {
    _baseURIExtended = baseURI_;
    emit SetBaseUri(baseURI_);
    return _baseURIExtended;
  }

  function isClaimed(uint256 id) public view returns (bool) {
    // Default value for mapping is 0x0, check if default or set:
    return _claimedBy[id] != address(0x0);
  }

  function mint(uint256 creatureId) external nonReentrant {

    // Validate creature ownership:
    require(msg.sender == _creatureWorld.ownerOf(creatureId), "You are not the owner of this creature!");

    // Validate only one mint per Creature:
    require(!isClaimed(creatureId), "This Creature has already been claimed!");

    // Set claimed Creatures:
    _claimedBy[creatureId] = msg.sender;

    // Mint to sender:
    _safeMint(msg.sender, creatureId);
  }

}