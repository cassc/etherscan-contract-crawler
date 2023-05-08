// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@chocolate-factory/contracts/token/ERC721/presets/MultiStageBase.sol";

contract Chibitos is MultiStageBase {
  function initialize (Args memory args) public initializer {
    __Base_init(args);
  }
}