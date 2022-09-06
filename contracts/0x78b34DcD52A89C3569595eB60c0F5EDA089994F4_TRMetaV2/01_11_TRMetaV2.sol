// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './Base64.sol';
import './ENSNameResolver.sol';
import './TRScriptV2.sol';
import './TRRolls.sol';

abstract contract ERC721ATM {
  function ownerOf(uint256 tokenId) public view virtual returns (address);
}

interface ITRMetaV2 {
  function tokenURI(TRKeys.RuneCore memory core) external view returns (string memory);
  function tokenScript(TRKeys.RuneCore memory core) external view returns (string memory);
  function getElement(TRKeys.RuneCore memory core) external view returns (string memory);
  function getColorCount(TRKeys.RuneCore memory core) external view returns (uint256);
  function getColorByIndex(TRKeys.RuneCore memory core, uint256 index) external view returns (string memory);
  function getGrailId(TRKeys.RuneCore memory core) external view returns (uint256);
  function getMaxRelicLevel() external pure returns (uint8);
}

/// @notice The Reliquary Metadata v2
contract TRMetaV2 is Ownable, ITRMetaV2, ENSNameResolver {
  using Strings for uint256;

  address public constant THE_RELIQUARY = 0xd83B6F9A3E623ae4427298726aE32907B477b8CC;

  string public imageURL = 'https://vibes.art/reliquary/png/';
  string public imageSuffix = '.png';
  string public animationURL = 'https://vibes.art/reliquary/html/';
  string public animationSuffix = '.html';
  address public rollsContract;
  mapping(string => string) public descriptionsByElement;
  mapping(string => string) public descriptionsByEssence;
  mapping(uint256 => bool) public useGrayscaleBrush;

  error RollsAreImmutable();
  error NotYourRelic();

  constructor() Ownable() {}

  function tokenURI(TRKeys.RuneCore memory core)
    override
    external
    view
    returns (string memory)
  {
    TRRolls.RelicInfo memory info = ITRRolls(rollsContract).getRelicInfo(core);

    string memory json = string(abi.encodePacked(
      '{"name": "Relic 0x', TRUtils.toCapsHexString(core.runeCode),
      '", "description": "', tokenDescription(core, info),
      '", "image": "', tokenImage(core),
      '", "animation_url": "', tokenAnimation(core),
      '", "attributes": [{ "trait_type": "Element", "value": "', info.element
    ));

    json = string(abi.encodePacked(
      json,
      '" }, { "trait_type": "Type", "value": "', info.relicType,
      '" }, { "trait_type": "Essence", "value": "', info.essence,
      '" }, { "trait_type": "Palette", "value": "', info.palette,
      '" }, { "trait_type": "Style", "value": "', info.style
    ));

    json = string(abi.encodePacked(
      json,
      '" }, { "trait_type": "Speed", "value": "', info.speed,
      '" }, { "trait_type": "Glyph", "value": "', info.glyphType,
      '" }, { "trait_type": "Colors", "value": "', TRUtils.toString(info.colorCount),
      '" }, { "trait_type": "Level", "value": ', TRUtils.toString(core.level)
    ));

    json = string(abi.encodePacked(
      json,
      ' }, { "trait_type": "Mana", "value": ', TRUtils.toString(core.mana),
      ' }], "hidden": [{ "trait_type": "Runeflux", "value": ', TRUtils.toString(info.runeflux),
      ' }, { "trait_type": "Corruption", "value": ', TRUtils.toString(info.corruption),
      ' }, { "trait_type": "Grail", "value": ', TRUtils.toString(info.grailId),
      ' }]}'
    ));

    return string(abi.encodePacked(
      'data:application/json;base64,', Base64.encode(bytes(json))
    ));
  }

  function tokenScript(TRKeys.RuneCore memory core)
    override
    public
    view
    returns (string memory)
  {
    TRRolls.RelicInfo memory info = ITRRolls(rollsContract).getRelicInfo(core);
    string[] memory html = new string[](20);
    uint256[] memory glyph = core.glyph;

    if (info.grailId != TRKeys.GRAIL_ID_NONE) {
      glyph = info.grailGlyph;
    }

    html[0] = '<!doctype html><html><head></head><body><script>';
    html[1] = string(abi.encodePacked('var H="', core.runeHash, '";'));
    html[2] = string(abi.encodePacked('var N="', info.essence, '";'));
    html[3] = string(abi.encodePacked('var Y="', info.style, '";'));
    html[4] = string(abi.encodePacked('var E="', info.speed, '";'));
    html[5] = string(abi.encodePacked('var G="', info.gravity, '";'));
    html[6] = string(abi.encodePacked('var D="', info.display, '";'));
    html[7] = string(abi.encodePacked('var V=', TRUtils.toString(core.level), ';'));
    html[8] = string(abi.encodePacked('var F=', TRUtils.toString(info.runeflux), ';'));
    html[9] = string(abi.encodePacked('var C=', TRUtils.toString(info.corruption), ';'));

    if (useGrayscaleBrush[core.tokenId]) {
      html[10] = string(abi.encodePacked('var UG=true;'));
    } else {
      html[10] = string(abi.encodePacked('var UG=false;'));
    }

    string memory itemString;
    string memory partString;
    uint256 i;
    for (; i < TRKeys.RELIC_SIZE; i++) {
      if (i < glyph.length) {
        itemString = glyph[i].toString();
      } else {
        itemString = '0';
      }

      while (bytes(itemString).length < TRKeys.RELIC_SIZE) {
        itemString = string(abi.encodePacked('0', itemString));
      }

      if (i == 0) {
        itemString = string(abi.encodePacked('var L=["', itemString, '",'));
      } else if (i < TRKeys.RELIC_SIZE - 1) {
        itemString = string(abi.encodePacked('"', itemString, '",'));
      } else {
        itemString = string(abi.encodePacked('"', itemString, '"];'));
      }

      partString = string(abi.encodePacked(partString, itemString));
    }

    html[11] = partString;

    for (i = 0; i < 6; i++) {
      if (i < info.colorCount) {
        itemString = ITRRolls(rollsContract).getColorByIndex(core, i);
      } else {
        itemString = '';
      }

      if (i == 0) {
        partString = string(abi.encodePacked('var P=["', itemString, '",'));
      } else if (i < info.colorCount - 1) {
        partString = string(abi.encodePacked('"', itemString, '",'));
      } else if (i < info.colorCount) {
        partString = string(abi.encodePacked('"', itemString, '"];'));
      } else {
        partString = '';
      }

      html[12 + i] = partString;
    }

    html[18] = getScript();
    html[19] = '</script></body></html>';

    string memory output = string(abi.encodePacked(
      html[0], html[1], html[2], html[3], html[4], html[5], html[6], html[7], html[8]
    ));

    output = string(abi.encodePacked(
      output, html[9], html[10], html[11], html[12], html[13], html[14], html[15], html[16]
    ));

    return string(abi.encodePacked(
      output, html[17], html[18], html[19]
    ));
  }

  function tokenDescription(TRKeys.RuneCore memory core, TRRolls.RelicInfo memory info)
    public
    view
    returns (string memory)
  {
    string memory desc = string(abi.encodePacked(
      'Relic 0x', TRUtils.toCapsHexString(core.runeCode),
      '\\n\\n', info.essence, ' ', info.relicType, ' of ', info.element
    ));

    desc = string(abi.encodePacked(
      desc,
      '\\n\\nLevel: ', TRUtils.toString(core.level),
      '\\n\\nMana: ', TRUtils.toString(core.mana),
      '\\n\\nRuneflux: ', TRUtils.toString(info.runeflux),
      '\\n\\nCorruption: ', TRUtils.toString(info.corruption)
    ));

    if (core.credit != address(0)) {
      string memory ENSName = ENSNameResolver.getENSName(core.credit);
      if (bytes(ENSName).length > 0) {
        desc = string(abi.encodePacked(desc, '\\n\\nGlyph by: ', ENSName));
      } else {
        desc = string(abi.encodePacked(desc, '\\n\\nGlyph by: 0x', TRUtils.toAsciiString(core.credit)));
      }
    }

    string memory additionalInfo = ITRRolls(rollsContract).getDescription(core);
    if (bytes(additionalInfo).length > 0) {
      desc = string(abi.encodePacked(desc, '\\n\\n', additionalInfo));
    }

    if (bytes(descriptionsByElement[info.element]).length > 0) {
      desc = string(abi.encodePacked(desc, '\\n\\n', descriptionsByElement[info.element]));
    }

    if (bytes(descriptionsByEssence[info.essence]).length > 0) {
      desc = string(abi.encodePacked(desc, '\\n\\n', descriptionsByEssence[info.essence]));
    }

    return desc;
  }

  function tokenImage(TRKeys.RuneCore memory core) public view returns (string memory) {
    if (bytes(imageSuffix).length > 0) {
      return string(abi.encodePacked(imageURL, TRUtils.toString(core.tokenId), imageSuffix));
    } else {
      return string(abi.encodePacked(imageURL, TRUtils.toString(core.tokenId)));
    }
  }

  function tokenAnimation(TRKeys.RuneCore memory core) public view returns (string memory) {
    if (bytes(animationURL).length == 0) {
      return string(abi.encodePacked(
        'data:text/html;base64,', Base64.encode(bytes(tokenScript(core)))
      ));
    } else {
      if (bytes(animationSuffix).length > 0) {
        return string(abi.encodePacked(animationURL, TRUtils.toString(core.tokenId), animationSuffix));
      } else {
        return string(abi.encodePacked(animationURL, TRUtils.toString(core.tokenId)));
      }
    }
  }

  function getElement(TRKeys.RuneCore memory core) override public view returns (string memory) {
    return ITRRolls(rollsContract).getElement(core);
  }

  function getPalette(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getPalette(core);
  }

  function getEssence(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getEssence(core);
  }

  function getStyle(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getStyle(core);
  }

  function getSpeed(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getSpeed(core);
  }

  function getGravity(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getGravity(core);
  }

  function getDisplay(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getDisplay(core);
  }

  function getColorCount(TRKeys.RuneCore memory core) override public view returns (uint256) {
    return ITRRolls(rollsContract).getColorCount(core);
  }

  function getColorByIndex(TRKeys.RuneCore memory core, uint256 index)
    override
    public
    view
    returns (string memory)
  {
    return ITRRolls(rollsContract).getColorByIndex(core, index);
  }

  function getRelicType(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getRelicType(core);
  }

  function getRuneflux(TRKeys.RuneCore memory core) public view returns (uint256) {
    return ITRRolls(rollsContract).getRuneflux(core);
  }

  function getCorruption(TRKeys.RuneCore memory core) public view returns (uint256) {
    return ITRRolls(rollsContract).getCorruption(core);
  }

  function getGrailId(TRKeys.RuneCore memory core) override public view returns (uint256) {
    return ITRRolls(rollsContract).getGrailId(core);
  }

  function getMaxRelicLevel() override public pure returns (uint8) {
    return 2;
  }

  function getScript() public pure returns (string memory) {
    return TRScriptV2.getScript();
  }

  function setDescriptionForElement(string memory element, string memory desc) public onlyOwner {
    descriptionsByElement[element] = desc;
  }

  function setDescriptionForEssence(string memory essence, string memory desc) public onlyOwner {
    descriptionsByEssence[essence] = desc;
  }

  function setImageURL(string memory url) public onlyOwner {
    imageURL = url;
  }

  function setImageSuffix(string memory suffix) public onlyOwner {
    imageSuffix = suffix;
  }

  function setAnimationURL(string memory url) public onlyOwner {
    animationURL = url;
  }

  function setAnimationSuffix(string memory suffix) public onlyOwner {
    animationSuffix = suffix;
  }

  function setRollsContract(address rolls) public onlyOwner {
    if (rollsContract != address(0)) revert RollsAreImmutable();

    rollsContract = rolls;
  }

  function toggleGrayscaleBrush(uint256 tokenId) public {
    ERC721ATM theReliquary = ERC721ATM(THE_RELIQUARY);
    if (theReliquary.ownerOf(tokenId) != _msgSender()) revert NotYourRelic();

    useGrayscaleBrush[tokenId] = !useGrayscaleBrush[tokenId];
  }
}