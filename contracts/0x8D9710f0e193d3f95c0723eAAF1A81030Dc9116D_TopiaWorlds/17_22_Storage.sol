// SPDX-License-Identifier: MIT
//
// ...............   ...............   ...............  .....   ...............
// :==============.  ===============  :==============:  -====  .==============-
// :==============.  ===============  :==============:  -====  .==============-
// :==============.  ===============  :==============:  -====  .==============-
// :==============.  ===============  :==============:  -====  .==============-
// .::::-====-::::.  ===============  :====-:::::::::.  -====  .====-::::-====-
//      :====.       ===============  :====:            -====  .====:    .====-
//      :====.       ===============  :====:            -====  .====:    .====-
//
// Learn more at https://topia.gg or Twitter @topiagg
pragma solidity 0.8.18;

import "./INFTW.sol";

library Storage {
  bytes32 private constant STORAGE_SLOT = keccak256("gg.topia.worlds.NFT");

  struct Layout {
    INFTW nftw;
    string tokenBaseURI;
    string ipfsBaseURI;
    address updateApprover;
    mapping(uint256 => bool) usedUpdateNonces;
    mapping(uint256 => string) ipfsHashes;
  }

  function layout() internal pure returns (Layout storage _layout) {
    bytes32 slot = STORAGE_SLOT;

    assembly {
      _layout.slot := slot
    }
  }
}