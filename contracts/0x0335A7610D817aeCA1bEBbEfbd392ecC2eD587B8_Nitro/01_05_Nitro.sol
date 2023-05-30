// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Nitro is ERC20 {
    constructor(address distributor) ERC20("Nitro", "NITRO") {
        _mint(distributor, 10 ** (9 + 18));
    }
}