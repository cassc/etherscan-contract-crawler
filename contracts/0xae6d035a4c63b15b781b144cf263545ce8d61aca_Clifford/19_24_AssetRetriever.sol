// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./TraitBase.sol";

contract AssetRetriever {

  TraitBase[] internal traitBases;

  constructor(TraitBase[] memory _traitBases) {
    traitBases = _traitBases;
  }

  function getAsset(uint assetID) public view returns (string memory) {
    if (assetID == 0) {
      return "";
    }

    return traitBases[assetID / 1000 - 1].getAssetFromTrait(assetID);
  }
}