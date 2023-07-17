// SPDX-License-Identifier: CAL
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PGen is ERC20 {
    constructor(address distributor_) ERC20("Polygen", "PGEN") { _mint(distributor_, 10 ** (9 + 18)); }
}