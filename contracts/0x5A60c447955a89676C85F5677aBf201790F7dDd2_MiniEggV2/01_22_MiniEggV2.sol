//
//  _____  _     _____   _     ___  _ ____  _____  _____ ____  _  ____  _     ____    _      _  _      _  _____ _____ _____ ____  _
// /__ __\/ \ /|/  __/  / \__/|\  \/// ___\/__ __\/  __//  __\/ \/  _ \/ \ /\/ ___\  / \__/|/ \/ \  /|/ \/  __//  __//  __// ___\/ \
//   / \  | |_|||  \    | |\/|| \  / |    \  / \  |  \  |  \/|| || / \|| | |||    \  | |\/||| || |\ ||| ||  \  | |  _| |  _|    \| |
//   | |  | | |||  /_   | |  || / /  \___ |  | |  |  /_ |    /| || \_/|| \_/|\___ |  | |  ||| || | \||| ||  /_ | |_//| |_//\___ |\_/
//   \_/  \_/ \|\____\  \_/  \|/_/   \____/  \_/  \____\\_/\_\\_/\____/\____/\____/  \_/  \|\_/\_/  \|\_/\____\\____\\____\\____/(_)
//
// The Mysterious MiniEggs! for aFan
//
// New Web 3.0 SNS for Creators!
// Website: https://afan.ai
//
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import '@ainft-team/ainft-contracts/contracts/ainft/AINFTBaseV1.sol';

contract MiniEggV2 is AINFTBaseV1 {
  uint8 public constant MAX_MINT_BATCH = 100;

  constructor(string memory baseURI_, uint256 maxTokenId_)
    AINFTBaseV1(
      'The Mysterious MiniEggs! for aFan',
      'ME4F',
      baseURI_,
      maxTokenId_
    )
  {
    nextTokenId = 1;
  }

  function batchMint(address[] memory addresses_, uint8[] memory quantities_)
    public
    onlyRole(MINTER_ROLE)
  {
    require(
      addresses_.length == quantities_.length,
      'MiniEggV2: Array lengths mismatch'
    );
    require(
      addresses_.length <= MAX_MINT_BATCH,
      'MiniEggV2: Too many requests'
    );

    for (uint8 i = 0; i < addresses_.length; i++) {
      mint(addresses_[i], quantities_[i]);
    }
  }
}