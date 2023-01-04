// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDropManagementForERC721A {
  enum Status {
    NONE,
    UPCOMING,
    LIVE,
    ENDED,
    CANCELED,
    FINISHED
  }

  function currentStatus() external view returns (Status);
}