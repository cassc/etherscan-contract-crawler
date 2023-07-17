// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract FreezableProvenance {
  string private _provenance;
  bool private _isProvenanceFreezed;

  event ProvenanceFreezed();
  event ProvenanceSet(string provenance);

  modifier whenNotProvenanceFreezed() {
    require(!_isProvenanceFreezed, "FreezableProvenance: provenance already freezed");
    _;
  }

  function provenance() public view returns (string memory) {
    return _provenance;
  }

  function _freezeProvenance() internal whenNotProvenanceFreezed {
    _isProvenanceFreezed = true;
    emit ProvenanceFreezed();
  }

  function _setProvenance(string memory provenance_, bool freezing) internal whenNotProvenanceFreezed {
    _provenance = provenance_;
    emit ProvenanceSet(provenance_);
    if (freezing) {
      _freezeProvenance();
    }
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}