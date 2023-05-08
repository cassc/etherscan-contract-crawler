// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract leftcurve is ERC20, Ownable {
constructor() ERC20("Leftcurve", "LEFT") {
_mint(0xd451208E23111c8fdBf51764D79DD36A429b3694, 50000000000 * (10 ** uint256(decimals())));
}
}