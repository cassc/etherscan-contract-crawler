// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@chocolate-factory/contracts/token/ERC721/presets/MultiStageBase.sol";

contract IcarusPass is MultiStageBase {
  function initialize (Args memory args) public initializer {
    __Base_init(args);
  }

  function _startTokenId()
        internal
        pure
        override(ERC721AUpgradeable)
        returns (uint256)
    {
        return 1;
    }
}