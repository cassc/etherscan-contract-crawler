// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IAoToken is IERC721 {
  function mintBatch(
    uint256 _phase,
    uint256[] memory _tokenIds,
    address[] memory _receivers
  ) external;

  function mint(
    uint256 _phase,
    uint256 _tokenId,
    address _receiver
  ) external;

  function exists(uint256 _tokenId) external view returns (bool);
}