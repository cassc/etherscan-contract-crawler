// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./BlackHole.sol";

interface IBlackHoles is IERC721 {
  function blackHoleForTokenId(uint256 _tokenId) external view returns (BlackHole memory);

  function merge(uint256[] memory tokens) external;

  function massForTokenId(uint256 _tokenId) external view returns (uint256);

  function burn(uint256 _tokenId) external;

  function totalMinted() external view returns (uint256);

  function MAX_SUPPLY_OF_INTERSTELLAR() external view returns (uint256);

  function MAX_LEVEL() external view returns (uint256);

  function nameForBlackHoleLevel(uint256 _level) external view returns (string memory);
}