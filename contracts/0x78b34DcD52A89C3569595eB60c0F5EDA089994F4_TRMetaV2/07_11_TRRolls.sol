// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import './TRColors.sol';

interface ITRRolls {

  struct RelicInfo {
    string element;
    string palette;
    string essence;
    uint256 colorCount;
    string style;
    string speed;
    string gravity;
    string display;
    string relicType;
    string glyphType;
    uint256 runeflux;
    uint256 corruption;
    uint256 grailId;
    uint256[] grailGlyph;
  }

  function getRelicInfo(TRKeys.RuneCore memory core) external view returns (RelicInfo memory);
  function getElement(TRKeys.RuneCore memory core) external view returns (string memory);
  function getPalette(TRKeys.RuneCore memory core) external view returns (string memory);
  function getEssence(TRKeys.RuneCore memory core) external view returns (string memory);
  function getStyle(TRKeys.RuneCore memory core) external view returns (string memory);
  function getSpeed(TRKeys.RuneCore memory core) external view returns (string memory);
  function getGravity(TRKeys.RuneCore memory core) external view returns (string memory);
  function getDisplay(TRKeys.RuneCore memory core) external view returns (string memory);
  function getColorCount(TRKeys.RuneCore memory core) external view returns (uint256);
  function getColorByIndex(TRKeys.RuneCore memory core, uint256 index) external view returns (string memory);
  function getRelicType(TRKeys.RuneCore memory core) external view returns (string memory);
  function getGlyphType(TRKeys.RuneCore memory core) external view returns (string memory);
  function getRuneflux(TRKeys.RuneCore memory core) external view returns (uint256);
  function getCorruption(TRKeys.RuneCore memory core) external view returns (uint256);
  function getDescription(TRKeys.RuneCore memory core) external view returns (string memory);
  function getGrailId(TRKeys.RuneCore memory core) external pure returns (uint256);

}

/// @notice The Reliquary Rarity Distribution
contract TRRolls is Ownable, ITRRolls {

  mapping(uint256 => address) public grailContracts;

  error GrailsAreImmutable();

  constructor() Ownable() {}

  function getRelicInfo(TRKeys.RuneCore memory core)
    override
    public
    view
    returns (RelicInfo memory)
  {
    RelicInfo memory info;
    info.element = getElement(core);
    info.palette = getPalette(core);
    info.essence = getEssence(core);
    info.colorCount = getColorCount(core);
    info.style = getStyle(core);
    info.speed = getSpeed(core);
    info.gravity = getGravity(core);
    info.display = getDisplay(core);
    info.relicType = getRelicType(core);
    info.glyphType = getGlyphType(core);
    info.runeflux = getRuneflux(core);
    info.corruption = getCorruption(core);
    info.grailId = getGrailId(core);

    if (info.grailId != TRKeys.GRAIL_ID_NONE) {
      info.grailGlyph = Grail(grailContracts[info.grailId]).getGlyph();
    }

    return info;
  }

  function getElement(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getElement();
    }

    if (bytes(core.transmutation).length > 0) {
      return core.transmutation;
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_ELEMENT);
    if (roll <= uint256(125)) {
      return TRKeys.ELEM_NATURE;
    } else if (roll <= uint256(250)) {
      return TRKeys.ELEM_LIGHT;
    } else if (roll <= uint256(375)) {
      return TRKeys.ELEM_WATER;
    } else if (roll <= uint256(500)) {
      return TRKeys.ELEM_EARTH;
    } else if (roll <= uint256(625)) {
      return TRKeys.ELEM_WIND;
    } else if (roll <= uint256(750)) {
      return TRKeys.ELEM_ARCANE;
    } else if (roll <= uint256(875)) {
      return TRKeys.ELEM_SHADOW;
    } else {
      return TRKeys.ELEM_FIRE;
    }
  }

  function getPalette(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getPalette();
    }

    if (core.colors.length > 0) {
      return TRKeys.ANY_PAL_CUSTOM;
    }

    string memory element = getElement(core);
    uint256 roll = roll1000(core, TRKeys.ROLL_PALETTE);
    if (TRUtils.compare(element, TRKeys.ELEM_NATURE)) {
      return getNaturePalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_LIGHT)) {
      return getLightPalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_WATER)) {
      return getWaterPalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_EARTH)) {
      return getEarthPalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_WIND)) {
      return getWindPalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_ARCANE)) {
      return getArcanePalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_SHADOW)) {
      return getShadowPalette(roll);
    } else {
      return getFirePalette(roll);
    }
  }

  function getNaturePalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.NAT_PAL_JUNGLE;
    } else if (roll <= 900) {
      return TRKeys.NAT_PAL_CAMOUFLAGE;
    } else {
      return TRKeys.NAT_PAL_BIOLUMINESCENCE;
    }
  }

  function getLightPalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.LIG_PAL_PASTEL;
    } else if (roll <= 900) {
      return TRKeys.LIG_PAL_INFRARED;
    } else {
      return TRKeys.LIG_PAL_ULTRAVIOLET;
    }
  }

  function getWaterPalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.WAT_PAL_FROZEN;
    } else if (roll <= 900) {
      return TRKeys.WAT_PAL_DAWN;
    } else {
      return TRKeys.WAT_PAL_OPALESCENT;
    }
  }

  function getEarthPalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.EAR_PAL_COAL;
    } else if (roll <= 900) {
      return TRKeys.EAR_PAL_SILVER;
    } else {
      return TRKeys.EAR_PAL_GOLD;
    }
  }

  function getWindPalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.WIN_PAL_BERRY;
    } else if (roll <= 900) {
      return TRKeys.WIN_PAL_THUNDER;
    } else {
      return TRKeys.WIN_PAL_AERO;
    }
  }

  function getArcanePalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.ARC_PAL_FROSTFIRE;
    } else if (roll <= 900) {
      return TRKeys.ARC_PAL_COSMIC;
    } else {
      return TRKeys.ARC_PAL_COLORLESS;
    }
  }

  function getShadowPalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.SHA_PAL_DARKNESS;
    } else if (roll <= 900) {
      return TRKeys.SHA_PAL_VOID;
    } else {
      return TRKeys.SHA_PAL_UNDEAD;
    }
  }

  function getFirePalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.FIR_PAL_HEAT;
    } else if (roll <= 900) {
      return TRKeys.FIR_PAL_EMBER;
    } else {
      return TRKeys.FIR_PAL_CORRUPTED;
    }
  }

  function getEssence(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getEssence();
    }

    string memory element = getElement(core);
    string memory relicType = getRelicType(core);
    if (TRUtils.compare(element, TRKeys.ELEM_NATURE)) {
      return getNatureEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_LIGHT)) {
      return getLightEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_WATER)) {
      return getWaterEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_EARTH)) {
      return getEarthEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_WIND)) {
      return getWindEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_ARCANE)) {
      return getArcaneEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_SHADOW)) {
      return getShadowEssence(relicType);
    } else {
      return getFireEssence(relicType);
    }
  }

  function getNatureEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.NAT_ESS_FOREST;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.NAT_ESS_SWAMP;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.NAT_ESS_WILDBLOOD;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.NAT_ESS_LIFE;
    } else {
      return TRKeys.NAT_ESS_SOUL;
    }
  }

  function getLightEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.LIG_ESS_HEAVENLY;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.LIG_ESS_FAE;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.LIG_ESS_PRISMATIC;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.LIG_ESS_RADIANT;
    } else {
      return TRKeys.LIG_ESS_PHOTONIC;
    }
  }

  function getWaterEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.WAT_ESS_TIDAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.WAT_ESS_ARCTIC;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.WAT_ESS_STORM;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.WAT_ESS_ILLUVIAL;
    } else {
      return TRKeys.WAT_ESS_UNDINE;
    }
  }

  function getEarthEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.EAR_ESS_MINERAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.EAR_ESS_CRAGGY;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.EAR_ESS_DWARVEN;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.EAR_ESS_GNOMIC;
    } else {
      return TRKeys.EAR_ESS_CRYSTAL;
    }
  }

  function getWindEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.WIN_ESS_SYLPHIC;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.WIN_ESS_VISCERAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.WIN_ESS_FROSTED;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.WIN_ESS_ELECTRIC;
    } else {
      return TRKeys.WIN_ESS_MAGNETIC;
    }
  }

  function getArcaneEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.ARC_ESS_MAGIC;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.ARC_ESS_ASTRAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.ARC_ESS_FORBIDDEN;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.ARC_ESS_RUNIC;
    } else {
      return TRKeys.ARC_ESS_UNKNOWN;
    }
  }

  function getShadowEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.SHA_ESS_NIGHT;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.SHA_ESS_FORGOTTEN;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.SHA_ESS_ABYSSAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.SHA_ESS_EVIL;
    } else {
      return TRKeys.SHA_ESS_LOST;
    }
  }

  function getFireEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.FIR_ESS_INFERNAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.FIR_ESS_MOLTEN;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.FIR_ESS_ASHEN;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.FIR_ESS_DRACONIC;
    } else {
      return TRKeys.FIR_ESS_CELESTIAL;
    }
  }

  function getStyle(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getStyle();
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_STYLE);
    if (roll <= 760) {
      return TRKeys.STYLE_SMOOTH;
    } else if (roll <= 940) {
      return TRKeys.STYLE_SILK;
    } else if (roll <= 980) {
      return TRKeys.STYLE_PAJAMAS;
    } else {
      return TRKeys.STYLE_SKETCH;
    }
  }

  function getSpeed(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getSpeed();
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_SPEED);
    if (roll <= 70) {
      return TRKeys.SPEED_ZEN;
    } else if (roll <= 260) {
      return TRKeys.SPEED_TRANQUIL;
    } else if (roll <= 760) {
      return TRKeys.SPEED_NORMAL;
    } else if (roll <= 890) {
      return TRKeys.SPEED_FAST;
    } else if (roll <= 960) {
      return TRKeys.SPEED_SWIFT;
    } else {
      return TRKeys.SPEED_HYPER;
    }
  }

  function getGravity(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getGravity();
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_GRAVITY);
    if (roll <= 50) {
      return TRKeys.GRAV_LUNAR;
    } else if (roll <= 150) {
      return TRKeys.GRAV_ATMOSPHERIC;
    } else if (roll <= 340) {
      return TRKeys.GRAV_LOW;
    } else if (roll <= 730) {
      return TRKeys.GRAV_NORMAL;
    } else if (roll <= 920) {
      return TRKeys.GRAV_HIGH;
    } else if (roll <= 970) {
      return TRKeys.GRAV_MASSIVE;
    } else if (roll <= 995) {
      return TRKeys.GRAV_STELLAR;
    } else {
      return TRKeys.GRAV_GALACTIC;
    }
  }

  function getDisplay(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getDisplay();
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_DISPLAY);
    if (roll <= 250) {
      return TRKeys.DISPLAY_NORMAL;
    } else if (roll <= 500) {
      return TRKeys.DISPLAY_MIRRORED;
    } else if (roll <= 750) {
      return TRKeys.DISPLAY_UPSIDEDOWN;
    } else {
      return TRKeys.DISPLAY_MIRROREDUPSIDEDOWN;
    }
  }

  function getColorCount(TRKeys.RuneCore memory core) override public view returns (uint256) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getColorCount();
    }

    string memory style = getStyle(core);
    if (TRUtils.compare(style, TRKeys.STYLE_SILK)) {
      return 5;
    } else if (TRUtils.compare(style, TRKeys.STYLE_PAJAMAS)) {
      return 5;
    } else if (TRUtils.compare(style, TRKeys.STYLE_SKETCH)) {
      return 4;
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_COLORCOUNT);
    if (roll <= 400) {
      return 2;
    } else if (roll <= 750) {
      return 3;
    } else {
      return 4;
    }
  }

  function getColorByIndex(TRKeys.RuneCore memory core, uint256 index)
    override
    public
    view
    returns (string memory)
  {
    // if the requested index exceeds the color count, return empty string
    if (index >= getColorCount(core)) {
      return '';
    }

    // if we've imagined new colors, use them instead
    if (core.colors.length > index) {
      return TRUtils.getColorCode(core.colors[index]);
    }

    // fetch the color palette
    uint256[] memory colorInts;
    uint256 colorIntCount;
    (colorInts, colorIntCount) = TRColors.get(getPalette(core));

    // shuffle the color palette
    uint256 i;
    uint256 temp;
    uint256 count = colorIntCount;
    while (count > 0) {
      string memory rollKey = string(abi.encodePacked(
        TRKeys.ROLL_SHUFFLE,
        TRUtils.toString(count)
      ));

      i = roll1000(core, rollKey) % count;

      temp = colorInts[--count];
      colorInts[count] = colorInts[i];
      colorInts[i] = temp;
    }

    // slightly adjust the RGB channels of the color to make it unique
    temp = getWobbledColor(core, index, colorInts[index % colorIntCount]);

    // return a hex code (without the #)
    return TRUtils.getColorCode(temp);
  }

  function getWobbledColor(TRKeys.RuneCore memory core, uint256 index, uint256 color)
    public
    pure
    returns (uint256)
  {
    uint256 r = (color >> uint256(16)) & uint256(255);
    uint256 g = (color >> uint256(8)) & uint256(255);
    uint256 b = color & uint256(255);

    string memory k = TRUtils.toString(index);
    uint256 dr = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_RED, k))) % 8;
    uint256 dg = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_GREEN, k))) % 8;
    uint256 db = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_BLUE, k))) % 8;
    uint256 rSign = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_REDSIGN, k))) % 2;
    uint256 gSign = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_GREENSIGN, k))) % 2;
    uint256 bSign = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_BLUESIGN, k))) % 2;

    if (rSign == 0) {
      if (r > dr) {
        r -= dr;
      } else {
        r = 0;
      }
    } else {
      if (r + dr <= 255) {
        r += dr;
      } else {
        r = 255;
      }
    }

    if (gSign == 0) {
      if (g > dg) {
        g -= dg;
      } else {
        g = 0;
      }
    } else {
      if (g + dg <= 255) {
        g += dg;
      } else {
        g = 255;
      }
    }

    if (bSign == 0) {
      if (b > db) {
        b -= db;
      } else {
        b = 0;
      }
    } else {
      if (b + db <= 255) {
        b += db;
      } else {
        b = 255;
      }
    }

    return uint256((r << uint256(16)) | (g << uint256(8)) | b);
  }

  function getRelicType(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getRelicType();
    }

    if (core.isDivinityQuestLoot) {
      return TRKeys.RELIC_TYPE_CURIO;
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_RELICTYPE);
    if (roll <= 360) {
      return TRKeys.RELIC_TYPE_TRINKET;
    } else if (roll <= 620) {
      return TRKeys.RELIC_TYPE_TALISMAN;
    } else if (roll <= 820) {
      return TRKeys.RELIC_TYPE_AMULET;
    } else if (roll <= 960) {
      return TRKeys.RELIC_TYPE_FOCUS;
    } else {
      return TRKeys.RELIC_TYPE_CURIO;
    }
  }

  function getGlyphType(TRKeys.RuneCore memory core) override public pure returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return TRKeys.GLYPH_TYPE_GRAIL;
    }

    if (core.glyph.length > 0) {
      return TRKeys.GLYPH_TYPE_CUSTOM;
    }

    return TRKeys.GLYPH_TYPE_NONE;
  }

  function getRuneflux(TRKeys.RuneCore memory core) override public view returns (uint256) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getRuneflux();
    }

    if (core.isDivinityQuestLoot) {
      return 700 + rollMax(core, TRKeys.ROLL_RUNEFLUX) % 300;
    }

    return roll1000(core, TRKeys.ROLL_RUNEFLUX) - 1;
  }

  function getCorruption(TRKeys.RuneCore memory core) override public view returns (uint256) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getCorruption();
    }

    if (core.isDivinityQuestLoot) {
      return 700 + rollMax(core, TRKeys.ROLL_CORRUPTION) % 300;
    }

    return roll1000(core, TRKeys.ROLL_CORRUPTION) - 1;
  }

  function getDescription(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getDescription();
    }

    return '';
  }

  function getGrailId(TRKeys.RuneCore memory core) override public pure returns (uint256) {
    uint256 grailId = TRKeys.GRAIL_ID_NONE;

    if (bytes(core.hiddenLeyLines).length > 0) {
      uint256 rollDist = TRUtils.random(core.hiddenLeyLines) ^ TRUtils.random(TRKeys.ROLL_GRAILS);
      uint256 digits = 1 + rollDist % TRKeys.GRAIL_DISTRIBUTION;
      for (uint256 i; i < TRKeys.GRAIL_COUNT; i++) {
        if (core.tokenId == digits + TRKeys.GRAIL_DISTRIBUTION * i) {
          uint256 rollShuf = TRUtils.random(core.hiddenLeyLines) ^ TRUtils.random(TRKeys.ROLL_ELEMENT);
          uint256 offset = rollShuf % TRKeys.GRAIL_COUNT;
          grailId = 1 + (i + offset) % TRKeys.GRAIL_COUNT;
          break;
        }
      }
    }

    return grailId;
  }

  function rollMax(TRKeys.RuneCore memory core, string memory key) internal pure returns (uint256) {
    string memory tokenKey = string(abi.encodePacked(key, TRUtils.toString(7 * core.tokenId)));
    return TRUtils.random(core.runeHash) ^ TRUtils.random(tokenKey);
  }

  function roll1000(TRKeys.RuneCore memory core, string memory key) internal pure returns (uint256) {
    return 1 + rollMax(core, key) % 1000;
  }

  function rollColor(TRKeys.RuneCore memory core, uint256 index) internal pure returns (uint256) {
    string memory k = TRUtils.toString(index);
    return rollMax(core, string(abi.encodePacked(TRKeys.ROLL_RANDOMCOLOR, k))) % 16777216;
  }

  function setGrailContract(uint256 grailId, address grailContract) public onlyOwner {
    if (grailContracts[grailId] != address(0)) revert GrailsAreImmutable();

    grailContracts[grailId] = grailContract;
  }

}



abstract contract Grail {
  function getElement() external pure virtual returns (string memory);
  function getPalette() external pure virtual returns (string memory);
  function getEssence() external pure virtual returns (string memory);
  function getStyle() external pure virtual returns (string memory);
  function getSpeed() external pure virtual returns (string memory);
  function getGravity() external pure virtual returns (string memory);
  function getDisplay() external pure virtual returns (string memory);
  function getColorCount() external pure virtual returns (uint256);
  function getRelicType() external pure virtual returns (string memory);
  function getRuneflux() external pure virtual returns (uint256);
  function getCorruption() external pure virtual returns (uint256);
  function getGlyph() external pure virtual returns (uint256[] memory);
  function getDescription() external pure virtual returns (string memory);
}