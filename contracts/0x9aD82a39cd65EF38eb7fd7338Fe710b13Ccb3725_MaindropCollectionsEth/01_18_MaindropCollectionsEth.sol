// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import './ERC1155CustomMint.sol';

contract MaindropCollectionsEth is ERC1155CustomMint {
  constructor(address whitelistContract)
    public
    ERC1155CustomMint(whitelistContract, 'Maindrop Collections', 'MC', 100 ether, 10)
  {}
}