// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./IMGear.sol";
import "./Ownable.sol";
import "./BattleStats.sol";
import "./ERC721Enumerable.sol";
import "./IOnChainPixelArtv2.sol";
import "./MFiendsAssets.sol";
import "./MFiendCharacteristics.sol";

contract MFiends is Ownable, ERC721Enumerable, BattleStats, MFiendsAssets, MFiendCharacteristics {
  IMGear private mineableGear;
  IOnChainPixelArtv2 private onChainPixelArt;

  uint256 private DIFFICULTY;

  struct Stats {
    uint64 ruin;
    uint64 guard;
    uint64 vigor;
    uint64 celerity;
  }

  uint8 private constant RUIN = 0;
  uint8 private constant GUARD = 1;
  uint8 private constant VIGOR = 2;
  uint8 private constant CELERITY = 3;

  //7 bits for 128: 0111 1111
  uint8 private constant ROLL_MASK = 0x7f;
  //16/128

  uint8 private constant CRIT_SHIFT = 7;
  uint8 private constant MISS_SHIFT = 14;
  uint8 private constant BLOCK_SHIFT = 21;
  uint8 private constant ATTACK_SHIFT = 23;
  uint8 private constant BASE_ROLL = 16;

  uint8 private constant TURN_SHIFT = 25;

  uint8 private constant TRAIT_MASK = 0xF;
  uint32 private constant TRAITS_MASK = 0xFFFFFFFF;

  mapping(uint256 => bool) public traits;
  uint256[] tokenIdToData;

  mapping(address => uint256)[4] public equipped;
  mapping(address => Stats) public stats;
  mapping(uint256 => address) public equippedBy;

  // stat buffs are stored [ruin][guard][vigor][celerity][ruin][guard][vigor][celerity]

  // 0, 0, 0, 0,   0, 0, 0, 0,   3, 0, 0, 1,   0, 1, 0, 3,   0, 2, 2, 0,   3, 3, 0, 0,   0, 0, 3, 4,   3, 2, 2, 2
  uint8[32] affinityToStatBuff = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    3,
    0,
    0,
    1,
    0,
    1,
    0,
    3,
    0,
    2,
    2,
    0,
    3,
    3,
    0,
    0,
    0,
    0,
    3,
    4,
    3,
    2,
    2,
    2
  ];

  constructor(
    IMGear _mineableGear,
    IOnChainPixelArtv2 _onChainPixelArt,
    uint256 _difficulty
  ) ERC721("MFiends", "MFIENDS") MFiendsAssets(_onChainPixelArt) Ownable() {
    mineableGear = _mineableGear;
    onChainPixelArt = _onChainPixelArt;
    DIFFICULTY = _difficulty;
  }

  function addOrSubtract(
    uint256 initial,
    uint256 amount,
    bool add
  ) internal pure returns (uint64) {
    if (add) {
      return uint64(initial + amount);
    }
    return uint64(initial - amount);
  }

  function updateStat(
    uint256 statType,
    bool equip,
    uint256 amount,
    address player
  ) internal {
    if (statType == RUIN) {
      stats[player].ruin = addOrSubtract(stats[player].ruin, amount, equip);
    }
    if (statType == GUARD) {
      stats[player].guard = addOrSubtract(stats[player].guard, amount, equip);
    }
    if (statType == VIGOR) {
      stats[player].vigor = addOrSubtract(stats[player].vigor, amount, equip);
    }
    if (statType == CELERITY) {
      stats[player].celerity = addOrSubtract(stats[player].celerity, amount, equip);
    }
  }

  function manageItem(
    uint256 mgear,
    address equippee,
    bool equip
  ) internal {
    uint8 itemMajorType = BattleStats.getMajorType(mgear);
    uint8 itemMinor1Type = BattleStats.getMinorType1(mgear);
    uint8 itemMinor2Type = BattleStats.getMinorType2(mgear);

    if (equip) {
      // there's always a major stat
      updateStat(itemMajorType, true, BattleStats.getMajorValue(mgear), equippee);
      // 5 means no stat
      if (itemMinor1Type < 5) {
        updateStat(itemMinor1Type, true, BattleStats.getMinorValue1(mgear), equippee);
      }

      if (itemMinor2Type < 5) {
        updateStat(itemMinor2Type, true, BattleStats.getMinorValue2(mgear), equippee);
      }
    } else {
      updateStat(itemMajorType, false, BattleStats.getMajorValue(mgear), equippee);

      if (itemMinor1Type < 5) {
        updateStat(itemMinor1Type, false, BattleStats.getMinorValue1(mgear), equippee);
      }

      if (itemMinor2Type < 5) {
        updateStat(itemMinor2Type, false, BattleStats.getMinorValue2(mgear), equippee);
      }
    }
  }

  function unequipItem(
    uint256 itemSlot,
    uint256 mgearId,
    address equippee
  ) internal {
    uint256 equippedItem = equipped[itemSlot][equippee];
    // only unequip if we have one equipped already
    if (equippedItem > 0) {
      uint256 mgearToUnequip = mineableGear.tokenIdToMGear(equippedItem);
      manageItem(mgearToUnequip, equippee, false);
      equipped[itemSlot][equippee] = 0;
      equippedBy[mgearId] = address(0);
    }
  }

  function equipItem(
    uint256 mgearId,
    address equippee,
    uint256 itemSlot
  ) internal {
    uint256 mgear = mineableGear.tokenIdToMGear(mgearId);

    // if mgearId is the same as equipped, no op
    if (mgearId > 0) {
      // only transact if it's a different mgearId from equipped
      if (mgearId != equipped[itemSlot][equippee]) {
        uint8 itemMajorType = BattleStats.getMajorType(mgear);
        // make sure the item is actually the specified type
        require(itemMajorType == itemSlot, "slot");
        // make sure they own the mgear
        require(mineableGear.ownerOf(mgearId) == equippee, "own");
        // unequip current slot
        unequipItem(itemMajorType, mgearId, equippee);

        // apply new stats
        manageItem(mgear, equippee, true);
        // track who has it equipped
        equipped[itemMajorType][equippee] = mgearId;
        equippedBy[mgearId] = equippee;
      }
    } else {
      unequipItem(itemSlot, mgearId, equippee);
    }
  }

  function equipItems(
    uint256 ruinItemId,
    uint256 guardItemId,
    uint256 vigorItemId,
    uint256 celerityItemId
  ) external {
    // initialize if not yet
    if (stats[msg.sender].vigor == 0) {
      stats[msg.sender] = Stats(1, 0, 10, 0);
    }
    equipItem(ruinItemId, msg.sender, RUIN);
    equipItem(guardItemId, msg.sender, GUARD);
    equipItem(vigorItemId, msg.sender, VIGOR);
    equipItem(celerityItemId, msg.sender, CELERITY);
  }

  function subtractWithLimit(uint256 n1, uint256 n2) internal pure returns (uint256) {
    if (n2 > n1) {
      return 0;
    } else {
      return n1 - n2;
    }
  }

  function getEquippedItems(address owner) public view returns (uint256[4] memory gear) {
    return [equipped[0][owner], equipped[1][owner], equipped[2][owner], equipped[3][owner]];
  }

  function assertValidGear(address player) public view returns (bool) {
    require(stats[player].vigor > 0, "init");
    uint256[4] memory equippedItems = getEquippedItems(player);
    if (equippedItems[RUIN] != 0) {
      require(mineableGear.ownerOf(equipped[RUIN][player]) == player, "e0");
    }
    if (equippedItems[GUARD] != 0) {
      require(mineableGear.ownerOf(equipped[GUARD][player]) == player, "e1");
    }
    if (equippedItems[VIGOR] != 0) {
      require(mineableGear.ownerOf(equipped[VIGOR][player]) == player, "e2");
    }
    if (equippedItems[CELERITY] != 0) {
      require(mineableGear.ownerOf(equipped[CELERITY][player]) == player, "e3");
    }
    return true;
  }

  //21 bits is a turn
  function getDamageFromTurn(
    uint256 game,
    uint256 turn,
    Stats memory damageDealer,
    Stats memory damageTaker
  ) private pure returns (uint256) {
    uint256 turnShift = TURN_SHIFT * turn;
    uint256 damageTakerDodgeRoll = (game >> (turnShift)) & ROLL_MASK;

    damageTakerDodgeRoll = subtractWithLimit(damageTakerDodgeRoll, damageTaker.celerity << 1);

    uint256 missRoll = ((game >> (turnShift + MISS_SHIFT)) & ROLL_MASK) +
      (damageDealer.celerity << 1);

    if (missRoll < BASE_ROLL || damageTakerDodgeRoll < BASE_ROLL) {
      return 0;
    }

    uint256 critRoll = (game >> (turnShift + CRIT_SHIFT)) & ROLL_MASK;

    critRoll = subtractWithLimit(critRoll, damageTaker.celerity * 3);

    // if ruin is bigger than opponent, crit roll is reduced to reduce the chance of annihilation
    if (damageDealer.ruin > damageTaker.ruin) {
      critRoll = critRoll + ((damageDealer.ruin - damageTaker.ruin) * 5);
    }

    uint256 blockRoll = (game >> (turnShift + BLOCK_SHIFT)) & 0x3;
    uint256 blockAmount = damageTaker.guard >> blockRoll;

    uint256 damage = subtractWithLimit(damageDealer.ruin, 2) +
      ((game >> (turnShift + ATTACK_SHIFT)) & 0x3);

    // if miss roll is between base roll and 2x base roll, we do half damage
    if (missRoll < (BASE_ROLL << 1)) {
      damage = damage >> 1;
    }

    if (critRoll < BASE_ROLL) {
      damage = damage + damage;
    }

    //default to 1 damage if defense exceeds
    if (blockAmount > damage) {
      return 1;
    } else {
      return damage - blockAmount;
    }
  }

  function generateEnemy(
    uint256 seed,
    Stats memory challenger,
    uint256 affinity
  ) public view returns (Stats memory enemy) {
    // fiends get harder as more are minted
    uint256 fiendDifficulty = (ERC721Enumerable.totalSupply() / 256) + 1;

    // ruin is at least 5 to avoid intentional tie-breaking
    uint256 ruin = 5;
    if (challenger.ruin > 5) {
      ruin = challenger.ruin;
    }

    return
      Stats(
        uint64(ruin + (((seed >> 32) & 0xF) % fiendDifficulty)) + affinityToStatBuff[affinity * 4],
        uint64(challenger.guard + (((seed >> 36) & 0xF) % fiendDifficulty)) +
          affinityToStatBuff[affinity * 4 + 1],
        // add a little vigor to make it slightly harder
        uint64(challenger.vigor + (((seed >> 40) & 0xF) % fiendDifficulty)) +
          1 +
          affinityToStatBuff[affinity * 4 + 2],
        uint64(challenger.celerity + (((seed >> 44) & 0xF) % fiendDifficulty)) +
          affinityToStatBuff[affinity * 4 + 3]
      );
  }

  function getTieBreak(uint256 game, Stats memory c) internal pure returns (bool result) {
    // -11 for base stats of 1 ruin and 10 vigor
    // roll can add up to 64. Having a stat total of 32 gives a 50% to win. 64 is guaranteed
    if ((((game >> 250) & 0x3F) + (c.ruin + c.guard + c.vigor + c.celerity - 11)) > 64) {
      return true;
    } else {
      return false;
    }
  }

  //game returns winning address, or 0 if tie
  function executeGame(
    uint256 game,
    Stats memory challenger,
    Stats memory enemy
  ) public pure returns (bool result) {
    uint256 challengerHealth = challenger.vigor;
    uint256 enemyHealth = enemy.vigor;

    for (uint256 turn = 0; turn < 5; turn++) {
      //defender attacks first
      uint256 challengerDamageDealt = getDamageFromTurn(game, turn * 2, challenger, enemy);

      //opposer attacks next
      uint256 enemyDamageDealt = getDamageFromTurn(game, turn * 2 + 1, enemy, challenger);

      if (enemyDamageDealt >= challengerHealth && challengerDamageDealt >= enemyHealth) {
        return getTieBreak(game, challenger);
      }
      if (challengerDamageDealt >= enemyHealth) {
        return true;
      }
      if (enemyDamageDealt >= challengerHealth) {
        return false;
      }

      //proceed with damage if no win conditions are met
      enemyHealth = enemyHealth - challengerDamageDealt;
      challengerHealth = challengerHealth - enemyDamageDealt;
    }
    return getTieBreak(game, challenger);
  }

  function encodeNonce(address sender, uint96 nonce) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(uint160(sender), nonce)));
  }

  function encodeTokenData(uint256 traitData, Stats memory enemy) internal pure returns (uint256) {
    return
      traitData +
      (enemy.ruin << 32) +
      (enemy.guard << 40) +
      (enemy.vigor << 48) +
      (enemy.celerity << 56);
  }

  function getCharacteristicsData(uint256 tokenId) public view returns (uint256) {
    return encodeNonce(address(this), uint96(tokenIdToData[tokenId - 1] & TRAITS_MASK));
  }

  // 11-25 26-40 41-55 56-70 71-85 85+
  function getPowerLevel(Stats memory charStats) public pure returns (string memory) {
    uint256 total = charStats.ruin + charStats.guard + charStats.vigor + charStats.celerity;

    if (total <= 25) {
      return "Feeble";
    }
    if (total <= 40) {
      return "Sturdy";
    }
    if (total <= 55) {
      return "Formidable";
    }
    if (total <= 70) {
      return "Powerful";
    }
    if (total <= 85) {
      return "Triumphant";
    }
    return "Godlike";
  }

  function getStatsFromToken(uint256 tokenId) public view returns (Stats memory) {
    uint256 tokenData = tokenIdToData[tokenId - 1];
    return
      Stats(
        uint64((tokenData >> 32) & 0xFF),
        uint64((tokenData >> 40) & 0xFF),
        uint64((tokenData >> 48) & 0xFF),
        uint64((tokenData >> 56) & 0xFF)
      );
  }

  struct RenderTracker {
    uint256 armIndex;
    uint256 backIndex;
    uint256 bodyIndex;
    uint256 headIndex;
    uint256 legsIndex;
    uint256 runeIndex;
    bool hasBack;
    bool hasRune;
    uint256 size;
  }

  function renderData(
    uint256 tokenData,
    uint256[] memory palette,
    string memory backgroundColor
  ) public view returns (string memory svg) {
    RenderTracker memory tracker = RenderTracker(
      tokenData & TRAIT_MASK,
      (tokenData >> 4) & TRAIT_MASK,
      (tokenData >> 8) & TRAIT_MASK,
      (tokenData >> 12) & TRAIT_MASK,
      (tokenData >> 16) & TRAIT_MASK,
      (tokenData >> 20) & TRAIT_MASK,
      ((tokenData >> 24) & 0xF) < 2,
      ((tokenData >> 28) & 0xF) < 2,
      4
    );

    if (tracker.hasBack) {
      tracker.size += 1;
    }
    if (tracker.hasRune) {
      tracker.size += 1;
    }

    uint256[] memory layers = new uint256[](tracker.size);

    if (tracker.hasBack) {
      layers[0] = tracker.backIndex + 16;
      layers[1] = tracker.bodyIndex + 32;
      if (tracker.hasRune) {
        layers[2] = tracker.runeIndex + 80;
        layers[3] = tracker.headIndex + 48;
        layers[4] = tracker.legsIndex + 64;
        layers[5] = tracker.armIndex;
      } else {
        layers[2] = tracker.headIndex + 48;
        layers[3] = tracker.legsIndex + 64;
        layers[4] = tracker.armIndex;
      }
    } else {
      layers[0] = tracker.bodyIndex + 32;
      if (tracker.hasRune) {
        layers[1] = tracker.runeIndex + 80;
        layers[2] = tracker.headIndex + 48;
        layers[3] = tracker.legsIndex + 64;
        layers[4] = tracker.armIndex;
      } else {
        layers[1] = tracker.headIndex + 48;
        layers[2] = tracker.legsIndex + 64;
        layers[3] = tracker.armIndex;
      }
    }

    return
      onChainPixelArt.render(
        MFiendsAssets.composeLayers(layers),
        palette,
        21,
        21,
        string(abi.encodePacked('style="background-color: #', backgroundColor, '"')),
        3,
        3
      );
  }

  function renderStat(uint256 value, bytes memory name) internal view returns (bytes memory) {
    return
      abi.encodePacked(
        '{ "display_type": "number", "trait_type": "',
        name,
        '", "value": ',
        onChainPixelArt.toString(value),
        "}"
      );
  }

  function renderFiend(
    uint256 tokenTraits,
    uint256 paletteData,
    uint256 affinity
  ) public view returns (string memory svg) {
    uint256[] memory palette = new uint256[](3);
    uint256 paletteColor = getPalette(paletteData, affinity);
    // overfill palette just to make sure we don't OOB
    palette[0] = paletteColor;
    palette[1] = getPalette(encodeNonce(address(this), uint96(palette[0])), affinity);
    palette[2] = getPalette(encodeNonce(address(this), uint96(palette[1])), affinity);
    return renderData(tokenTraits, palette, onChainPixelArt.toHexString(affinityToColor[affinity]));
  }

  function render(uint256 tokenId) internal view returns (string memory svg) {
    uint256 hashedTraits = encodeNonce(
      address(this),
      uint96(tokenIdToData[tokenId - 1] & TRAITS_MASK)
    );
    return
      renderFiend(
        tokenIdToData[tokenId - 1] & TRAITS_MASK,
        hashedTraits,
        getAffinity(hashedTraits)
      );
  }

  function withdraw(uint256 amount) external onlyOwner {
    payable(Ownable.owner()).transfer(amount);
  }

  function mint(uint96 nonce, bool callForHelp) external payable {
    assertValidGear(msg.sender);
    uint256 result = encodeNonce(msg.sender, nonce);
    require(result < DIFFICULTY, "dif");
    uint256 tokenData = result & TRAITS_MASK;
    require(!traits[tokenData], "alr");

    if (callForHelp) {
      // mfiends can always be beat, but limited can be purchased
      require(tokenIdToData.length < 4096, "lim");
      require(msg.value >= 50000000000000000, "fee");
    }

    // game result comes from the hash of mineable gear address with nonce
    uint256 gameResult = encodeNonce(address(mineableGear), nonce);
    // use the hash result because we only use the first 32 bits for traits
    Stats memory enemy = generateEnemy(
      result,
      stats[msg.sender],
      getAffinity(encodeNonce(address(this), uint96(tokenData)))
    );

    bool win = executeGame(gameResult, stats[msg.sender], enemy);
    require(win || callForHelp, "lost");
    uint256 tokenId = tokenIdToData.length + 1;
    tokenIdToData.push(encodeTokenData(tokenData, enemy));
    traits[tokenData] = true;
    ERC721._safeMint(msg.sender, tokenId);
  }

  function getAttributes(uint256 tokenId) public view returns (string memory) {
    uint256 tokenData = tokenIdToData[tokenId - 1];
    Stats memory tokenStats = getStatsFromToken(tokenId);

    bytes memory attributes = abi.encodePacked(
      '"attributes": [{ "trait_type": "Affinity", "value": "',
      affinityToName[getAffinity(encodeNonce(address(this), uint96(tokenData & TRAITS_MASK)))],
      '" }, { "trait_type": "Power Level", "value": "',
      getPowerLevel(tokenStats),
      '" }'
    );

    bool hasBack = ((tokenData >> 24) & 0xF) < 2;
    bool hasRune = ((tokenData >> 28) & 0xF) < 2;

    string memory rareForm;
    if (hasBack || hasRune) {
      if (hasBack && hasRune) {
        rareForm = "Runed & Winged";
      } else if (hasBack) {
        rareForm = "Winged";
      } else if (hasRune) {
        rareForm = "Runed";
      }

      attributes = abi.encodePacked(
        attributes,
        ', { "trait_type": "Rare Form", "value": "',
        rareForm,
        '" }'
      );
    }

    attributes = abi.encodePacked(
      attributes,
      ", ",
      renderStat(tokenStats.ruin, "Ruin"),
      ", ",
      renderStat(tokenStats.guard, "Guard"),
      ", ",
      renderStat(tokenStats.vigor, "Vigor"),
      ", ",
      renderStat(tokenStats.celerity, "Celerity")
    );

    return string(abi.encodePacked(attributes, "]"));
  }

  function renderTokenURI(uint256 tokenId) public view returns (string memory) {
    return
      onChainPixelArt.uri(
        string(
          abi.encodePacked(
            '{"name": "mfiend #',
            onChainPixelArt.toString(tokenId),
            '", "description": "A fiend captured by proof-of-combat.", "image": "',
            onChainPixelArt.uriSvg(render(tokenId)),
            '", ',
            getAttributes(tokenId),
            " }"
          )
        )
      );
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(ERC721._exists(tokenId), "404");
    return renderTokenURI(tokenId);
  }
}