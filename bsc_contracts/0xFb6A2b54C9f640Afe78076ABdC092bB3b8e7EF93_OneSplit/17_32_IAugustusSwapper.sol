// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IAugustusSwapper {
  function getTokenTransferProxy (  ) external view returns ( address );
}