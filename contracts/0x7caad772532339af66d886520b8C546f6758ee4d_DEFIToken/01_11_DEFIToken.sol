// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract DEFIToken is ERC20, ERC20Permit {
    constructor(address holder)
        ERC20("Decentralized Finance Token", "DEFI")
        ERC20Permit("Decentralized Finance Token")
    {
        _mint(holder, 100_000_000 * 10**18);
    }
}