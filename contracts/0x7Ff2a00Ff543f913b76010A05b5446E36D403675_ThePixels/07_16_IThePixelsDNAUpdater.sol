// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

interface IThePixelsDNAUpdater {
  function canUpdateDNAExtension(
    address _owner,
    uint256 _tokenId,
    uint256 _dna,
    uint256 _dnaExtension
  ) external view returns (bool);

  function getUpdatedDNAExtension(
    address _owner,
    uint256 _tokenId,
    uint256 _dna,
    uint256 _dnaExtension
  ) external returns (uint256);
}