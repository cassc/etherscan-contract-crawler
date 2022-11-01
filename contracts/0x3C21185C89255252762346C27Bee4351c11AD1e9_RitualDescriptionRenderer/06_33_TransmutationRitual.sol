// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import '../interfaces/IDataStorage.sol';
import '../interfaces/ISpellCompute.sol';
import '../Merge.sol';
import '../MergeMana.sol';
import '../storage/AdminEditableStorage.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@abf-monorepo/protocol/contracts/renderers/LayerCompositeRenderer.sol';
import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';

contract TransmutationRitual is Ownable {
  using Strings for uint256;

  Merge public merge;
  MergeMana public mergeMana;
  ISpellCompute public spellCompute;
  IDataStorage public spellLabelsStorage;
  AdminEditableStorage public spellStorage;

  mapping(bytes32 => bytes32) public simulatedSpell;

  bool public emergencyShutdown = false;

  struct DeployTransmutationRitualConfig {
    address merge;
    address spellCompute;
    address spellLabelsStorage;
    address mergeMana;
    address spellStorage;
  }

  constructor(DeployTransmutationRitualConfig memory config) {
    merge = Merge(config.merge);
    mergeMana = MergeMana(config.mergeMana);
    spellLabelsStorage = IDataStorage(config.spellLabelsStorage);
    spellCompute = ISpellCompute(config.spellCompute);
    spellStorage = AdminEditableStorage(config.spellStorage);
  }

  function getComputedSeed(uint256 tokenId, bytes32 spell)
    public
    view
    returns (bytes5)
  {
    return spellCompute.compute(tokenId, spell);
  }

  function getManaCost(bytes32 spell) public view returns (uint256) {
    return spellCompute.manaCost(spell);
  }

  function getSpell(uint256 tokenId) public view returns (bytes32) {
    bytes32 simulatedKey = keccak256(abi.encodePacked(tokenId, block.number));
    if (uint256(simulatedSpell[simulatedKey]) != 0) {
      return simulatedSpell[simulatedKey];
    }
    return bytes32(spellStorage.indexToData(tokenId));
  }

  function getSpellInWords(bytes32 spell)
    public
    view
    returns (string[] memory spellWords)
  {
    bytes memory spellArr = abi.encodePacked(spell);
    spellWords = new string[](32);
    for (uint256 i = 0; i < 32; ++i) {
      spellWords[i] = string(
        spellLabelsStorage.indexToData(uint256(uint8(spellArr[i]) / 4))
      );
    }
  }

  function performRitual(uint256 tokenId, bytes32 spell) public {
    require(
      merge.ownerOf(tokenId) == msg.sender,
      'TransmutationRitual: Only owner can perform ritual'
    );
    // pay for spell
    uint256 manaCost = getManaCost(spell);
    mergeMana.consumeMana(tokenId, manaCost);
    // write spell
    spellStorage.editData(tokenId, abi.encodePacked(spell));
  }

  function simulateRitual(uint256 tokenId, bytes32 spell) public {
    bytes32 simulatedKey = keccak256(abi.encodePacked(tokenId, block.number));
    simulatedSpell[simulatedKey] = spell;
  }

  function setSpellCompute(address _spellCompute) public onlyOwner {
    spellCompute = ISpellCompute(_spellCompute);
  }

  function setSpellLabelsStorage(address _spellLabelsStorage) public onlyOwner {
    spellLabelsStorage = IDataStorage(_spellLabelsStorage);
  }

  function setSpellStorage(address _spellStorage) public onlyOwner {
    spellStorage = AdminEditableStorage(_spellStorage);
  }
}