// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/*
 *   @title:  Future-Quest Forge contract
 *
 *   @author: ahm3d.eth, ryado.eth
 *
 *       Built with ♥ by the ProductShop team
 *
 *                  -+=-.
 *                 .++++++=-.
 *                 +++++++++++=-.
 *                ++++++++++++++++=:.
 *               =++++++==++++++++++++=:.
 *              :++++++=   .:=++++++++++++-:.
 *             .+++++++        .-=++++++++++++-:
 *             +++++++.            .-=++++++++++
 *            =++++++:                 :=+++++++
 *           -++++++-                :-+++++++++
 *          :++++++=             .-=+++++++++++-
 *         .+++++++          .:=+++++++++++=:.
 *         +++++++.       :-++++++++++++-.
 *        =++++++:    .-=+++++++++++=:
 *       -++++++=    +++++++++++=:.
 *      :++++++=     ++++++++-.
 *     .+++++++      ++++=:
 *     =++++++.      --.
 *    =++++++-
 *   -++++++=
 *  .++++++=
 *  +++++++.
 *
 */

interface FutureQuest {
  function balanceOf(
    address account,
    uint256 id
  ) external view returns (uint256);

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external;

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) external;

  function create(uint256 _quantity) external returns (uint256);

  function mintOnBehalf(
    uint256 _artifactId,
    uint256 _quantity,
    address _user
  ) external;
}

contract FutureForge is AccessControl, ERC1155Holder {
  using Strings for uint256;
  using SafeMath for uint256;

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  FutureQuest public immutable _futureQuestContract;

  uint256 constant DRAGON_ID = 1;

  struct Artifact {
    uint8 mintedSupply;
    uint8 maxSupply;
    uint8 tier;
    uint8 id;
  }

  mapping(uint256 => Artifact) _tier3Artifacts;
  mapping(uint256 => Artifact) _tier2Artifacts;
  mapping(uint256 => Artifact) _tier1Artifacts;

  uint256 public tier1Supply = 0;
  uint256 public tier2Supply = 0;
  uint256 public tier3Supply = 0;

  uint256 constant TIER_1_MAP_LENGTH = 9;
  uint256 constant TIER_2_MAP_LENGTH = 6;
  uint256 constant TIER_3_MAP_LENGTH = 4;

  uint256 constant TIER_1_START_ID = 12;
  uint256 constant TIER_2_START_ID = 6;
  uint256 constant TIER_3_START_ID = 2;

  uint256 constant TIER_1_MAX_SUPPLY = 65;
  uint256 constant TIER_2_MAX_SUPPLY = 58;
  uint256 constant TIER_3_MAX_SUPPLY = 47;

  bool public _paused = true;

  constructor(address futureQuestContract) {
    _futureQuestContract = FutureQuest(futureQuestContract);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
    _initializeArtifacts();
  }

  // modifiers
  modifier onlyAdmin() {
    require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an Admin");
    _;
  }

  modifier isNotPaused() {
    require(!_paused, "The contract is paused");
    _;
  }

  function _initializeArtifacts() internal {
    // Tier 3 Artifacts
    _tier3Artifacts[2] = Artifact(0, 20, 3, 2); // Hover Drone Assistant of Skill
    _tier3Artifacts[3] = Artifact(0, 12, 3, 3); // Power Arm of Skill
    _tier3Artifacts[4] = Artifact(0, 5, 3, 4); // Robot Helper of Skill
    _tier3Artifacts[5] = Artifact(0, 10, 3, 5); // Elite Robotic Arm of Skill

    // Tier 2 Artifacts
    _tier2Artifacts[6] = Artifact(0, 20, 2, 6); // Small HoloGem of Fortune
    _tier2Artifacts[7] = Artifact(0, 12, 2, 7); // Medium HoloGem of Fortune
    _tier2Artifacts[8] = Artifact(0, 10, 2, 8); // Big HoloGem of Fortune
    _tier2Artifacts[9] = Artifact(0, 3, 2, 9); // Elite Crystal of Fortune
    _tier2Artifacts[10] = Artifact(0, 10, 2, 10); // Touch of Regen ($5k Grant!)
    _tier2Artifacts[11] = Artifact(0, 3, 2, 11); // Touch of Vanguard ($10k Grant!)

    // Tier 1 Artifacts
    _tier1Artifacts[12] = Artifact(0, 20, 1, 12); // Mutant Antilope
    _tier1Artifacts[13] = Artifact(0, 12, 1, 13); // Mutant Jelly Processor
    _tier1Artifacts[14] = Artifact(0, 12, 1, 14); // Wind Turbine
    _tier1Artifacts[15] = Artifact(0, 10, 1, 15); // Solar Array
    _tier1Artifacts[16] = Artifact(0, 15, 1, 16); // Smugglers Crate
    _tier1Artifacts[17] = Artifact(0, 5, 1, 17); // Future Horizon eVTOL mk1
    _tier1Artifacts[18] = Artifact(0, 5, 1, 18); // Interplanetary Survey Rig
    _tier1Artifacts[19] = Artifact(0, 5, 1, 19); // Space Mining Refinery Rig
    _tier1Artifacts[20] = Artifact(0, 5, 1, 20); // Astro Chip Upgrade
  }

  function createArtifacts() public onlyAdmin {
    for (uint256 i = 2; i <= 5; i++) {
      _futureQuestContract.create(_tier3Artifacts[i].maxSupply);
    }

    for (uint256 i = 6; i <= 11; i++) {
      _futureQuestContract.create(_tier2Artifacts[i].maxSupply);
    }

    for (uint256 i = 12; i <= 20; i++) {
      _futureQuestContract.create(_tier1Artifacts[i].maxSupply);
    }
  }

  function getRandomArtifactId(
    uint8 tier
  ) public view returns (uint256 artifactId) {
    uint256 totalWeight = 0;
    uint256 randomNum;

    if (tier == 1) {
      totalWeight = calculateTotalWeight(
        _tier1Artifacts,
        TIER_1_MAP_LENGTH,
        TIER_1_START_ID
      );

      randomNum =
        uint256(
          keccak256(abi.encodePacked(block.timestamp, block.difficulty))
        ) %
        totalWeight;

      for (
        uint256 i = TIER_1_START_ID;
        i < TIER_1_MAP_LENGTH + TIER_1_START_ID;
        i++
      ) {
        if (
          randomNum <
          (_tier1Artifacts[i].maxSupply - _tier1Artifacts[i].mintedSupply)
        ) {
          return _tier1Artifacts[i].id;
        }
        randomNum -= (_tier1Artifacts[i].maxSupply -
          _tier1Artifacts[i].mintedSupply);
      }
    } else if (tier == 2) {
      totalWeight = calculateTotalWeight(
        _tier2Artifacts,
        TIER_2_MAP_LENGTH,
        TIER_2_START_ID
      );

      randomNum =
        uint256(
          keccak256(abi.encodePacked(block.timestamp, block.difficulty))
        ) %
        totalWeight;

      for (
        uint256 i = TIER_2_START_ID;
        i < TIER_2_MAP_LENGTH + TIER_2_START_ID;
        i++
      ) {
        if (
          randomNum <
          (_tier2Artifacts[i].maxSupply - _tier2Artifacts[i].mintedSupply)
        ) {
          return _tier2Artifacts[i].id;
        }
        randomNum -= (_tier2Artifacts[i].maxSupply -
          _tier2Artifacts[i].mintedSupply);
      }
    } else if (tier == 3) {
      totalWeight = calculateTotalWeight(
        _tier3Artifacts,
        TIER_3_MAP_LENGTH,
        TIER_3_START_ID
      );

      randomNum =
        uint256(
          keccak256(abi.encodePacked(block.timestamp, block.difficulty))
        ) %
        totalWeight;

      for (
        uint256 i = TIER_3_START_ID;
        i < TIER_3_MAP_LENGTH + TIER_3_START_ID;
        i++
      ) {
        if (
          randomNum <
          (_tier3Artifacts[i].maxSupply - _tier3Artifacts[i].mintedSupply)
        ) {
          // console.log("forge _tier3Artifacts[i].id: %s", _tier3Artifacts[i].id);
          return _tier3Artifacts[i].id;
        }
        randomNum -= (_tier3Artifacts[i].maxSupply -
          _tier3Artifacts[i].mintedSupply);
      }
    } else {
      revert("Invalid tier");
    }
  }

  function calculateTotalWeight(
    mapping(uint256 => Artifact) storage artifacts,
    uint256 mapSize,
    uint256 startId
  ) internal view returns (uint256) {
    uint256 totalWeight = 0;

    for (uint8 i = 0; i < mapSize; i++) {
      totalWeight += (artifacts[i + startId].maxSupply -
        artifacts[i + startId].mintedSupply);
    }
    return totalWeight;
  }

  function forge(uint256 _dragonQuantity) public returns (uint256) {
    require(
      _dragonQuantity > 2,
      "Dragon quantity must be greater or equal than 3"
    );

    require(
      _futureQuestContract.balanceOf(msg.sender, DRAGON_ID) >= _dragonQuantity,
      "User does not have enough dragons"
    );

    uint256 tier = 1;

    if (_dragonQuantity > 6) {
      tier = 3;
    } else if (_dragonQuantity > 4) {
      tier = 2;
    }

    uint256 artifactId = getRandomArtifactId(uint8(tier));

    _futureQuestContract.safeTransferFrom(
      msg.sender,
      address(this),
      DRAGON_ID,
      _dragonQuantity - 1,
      ""
    );

    mintArtifact(msg.sender, artifactId, tier);

    return artifactId;
  }

  function mintArtifact(
    address _user,
    uint256 _artifactId,
    uint256 tier
  ) private {
    if (tier == 3) {
      _tier3Artifacts[_artifactId].mintedSupply += 1;
      tier3Supply++;
    } else if (tier == 2) {
      _tier2Artifacts[_artifactId].mintedSupply += 1;
      tier2Supply++;
    } else if (tier == 1) {
      _tier1Artifacts[_artifactId].mintedSupply += 1;
      tier1Supply++;
    }
    _futureQuestContract.mintOnBehalf(_artifactId, 1, _user);
  }

  function grantAdminRole(address user) external onlyAdmin {
    grantRole(ADMIN_ROLE, user);
  }

  function withdraw() external onlyAdmin {
    payable(msg.sender).transfer(address(this).balance);
  }

  function setPaused(bool paused) external onlyAdmin {
    _paused = paused;
  }

  function burnAllDragons() external onlyAdmin {
    uint256 balance = _futureQuestContract.balanceOf(address(this), DRAGON_ID);
    require(balance > 0, "No tokens to burn");
    _futureQuestContract.safeTransferFrom(
      address(this),
      address(0),
      DRAGON_ID,
      balance,
      ""
    );
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    virtual
    override(AccessControl, ERC1155Receiver)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}