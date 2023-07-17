pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "eth-token-recover/contracts/TokenRecover.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface ICreature {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract TravelingCreature is ERC721Enumerable, AccessControl, ReentrancyGuard, TokenRecover {

  // Event for generating assets:
  event TransferTravelingCreature(
    uint256 indexed travelingCreatureId,
    uint256 indexed tokenId,
    uint256 fromCreature,
    uint256 toCreature,
    bool nabbed
  );

  // Event for setting baseURI:
  event SetBaseUri(
    string newBaseUri
  );

  // Tracks next token ID:
  using Counters for Counters.Counter;
  Counters.Counter internal _currentTokenId;

  // Roles:
  bytes32 public constant NAB_ROLE = keccak256("NAB_ROLE");

  // Tracks current Creature being visited by each TC:
  mapping (uint256 => uint256) public currentlyVisitedCreature;

  // Base URI for token metadata:
  string internal _baseURIExtended;

  // Receives the nabbed NFTs:
  address internal nabTarget;

  // Creature World Contract:
  ICreature immutable internal _creatureWorld;

  // Tracks visited Creatures:
  mapping (uint256 => bool) public hasBeenVisited;

  constructor(
    ICreature creatureWorld_,
    address[5] memory initialOwners,
    uint256[5] memory initialCreatures,
    string memory baseURIExtended_
  ) ERC721("Traveling Creature", "TC") {
    require(initialOwners.length == initialCreatures.length, "TravelingCreature: initialOwners must be same length as initialCreatures!");

    // Set Creature World base contract:
    _creatureWorld = creatureWorld_;

    // Set initial baseURI:
    _baseURIExtended = baseURIExtended_;

    // Set initial nab target to deployer:
    nabTarget = msg.sender;

    // Set contract deployer to admin:
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    // Mint Traveling Creatures to initial owners:
    for (uint i = 0; i < 5; i++) {
      // Traveling Creature ID (10000-10004)
      uint256 tcid = 10000 + i;
      // Mint the Traveling Creature token to the intial owner:
      _safeMint(initialOwners[i], tcid);
      // Mark the currently visited Creature to the intial Creature target:
      currentlyVisitedCreature[tcid] = initialCreatures[i];
      // Mark the initial Creature as visited:
      hasBeenVisited[initialCreatures[i]] = true;
    }
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseURIExtended;
  }

  function setBaseURI(string memory baseURI_) external onlyRole(DEFAULT_ADMIN_ROLE) returns (string memory) {
    _baseURIExtended = baseURI_;
    emit SetBaseUri(baseURI_);
    return _baseURIExtended;
  }

  function setNabTarget(address nabTarget_) external onlyRole(DEFAULT_ADMIN_ROLE) {
    nabTarget = nabTarget_;
  }

  function _isTravelingCreature(uint256 id) internal pure returns (bool) {
    return id > 9999 && id < 10005;
  }

  function _sendTravelingCreature(address from, uint256 travelingCreatureId, uint256 creatureId, bool nabbed) internal returns (uint256) {
    // Check that the token being sent is a Traveling Creature:
    require(_isTravelingCreature(travelingCreatureId) == true, "TravelingCreature: Cannot send a non-traveling-creature!");
    // Check that the target Creature has not yet been visited:
    require(hasBeenVisited[creatureId] == false, "TravelingCreature: This Creature has already been visited!");
    // Find owner of target Creature:
    address owner = ICreature(_creatureWorld).ownerOf(creatureId);
    // Transfer TC to owner of target Creature:
    _safeTransfer(from, owner, travelingCreatureId, "");
    // Get current token ID:
    uint256 tokenId = _currentTokenId.current();
    // Mint to sender (or nabTarget if nabbed):
    _safeMint(nabbed ? nabTarget : msg.sender, tokenId);
    // Increment current token ID:
    _currentTokenId.increment();
    // Mark Creature as visited:
    hasBeenVisited[creatureId] = true;
    // Emit event for generating assets:
    emit TransferTravelingCreature(
      travelingCreatureId,
      tokenId,
      currentlyVisitedCreature[travelingCreatureId],
      creatureId,
      nabbed
    );
    // Track which Creature is currently being visited by TC:
    currentlyVisitedCreature[travelingCreatureId] = creatureId;
    // Return token ID:
    return tokenId;
  }

  function sendTravelingCreature(uint256 travelingCreatureId, uint256 creatureId) external nonReentrant {
    _sendTravelingCreature(msg.sender, travelingCreatureId, creatureId, false);
  }

  function nab(uint256 travelingCreatureId, uint256 creatureId) external onlyRole(NAB_ROLE) nonReentrant {
    _sendTravelingCreature(ownerOf(travelingCreatureId), travelingCreatureId, creatureId, true);
  }

  function getTravelingCreaturesOwners() public view returns (address[5] memory) {
    address[5] memory owners = [
      ownerOf(10000),
      ownerOf(10001),
      ownerOf(10002),
      ownerOf(10003),
      ownerOf(10004)
    ];
    return owners;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}