// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../lib_constants/TraitDefs.sol";

library Gene {
  function getGene(uint8 traitDef, uint256 dna) internal pure returns (uint16) {
    // type(uint16).max
    // right shift traitDef * 16, then bitwise & with the max 16 bit number
    return uint16((dna >> (traitDef * 16)) & uint256(type(uint16).max));
  }

  function getSpeciesGene(uint256 dna) internal pure returns (uint16) {
    return getGene(TraitDefs.SPECIES, dna);
  }

  // returns what dna would look like with gene passed in
  function setSpecies(uint16 gene, uint256 dna)
    internal
    pure
    returns (uint256)
  {
    uint256 snippedDNA = (dna >> 16) << 16; //zero out the gene

    // then bitwise & with uint256(gene);
    return snippedDNA | uint256(gene);
  }
}