// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DeMi is ERC20 {
    address public mintedAt;

    constructor(address minter) ERC20("DeMi", "$DEMI") {
        mintedAt = minter;
        _mint(minter, 50000000 * 10**decimals());
    }
}