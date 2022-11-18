// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface INiftyLaunchComics {
  function burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory values
  ) external;
}