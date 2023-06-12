// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract GHSI is ERC20, ERC20Burnable, Ownable {
    uint256 constant maxSupply = 100000000 * (10 ** 18); // 100,000,000 GHSI

    constructor() ERC20('GHSI', 'GHSI') {
        _mint(msg.sender, maxSupply);
    }
}