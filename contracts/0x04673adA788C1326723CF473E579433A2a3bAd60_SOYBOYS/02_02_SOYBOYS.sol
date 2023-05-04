// SOYBOYS by Spacebar (@mrspcbr) | https://t.me/soyboyseth | https://twitter.com/soyboyseth
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./ERC20.sol";
contract SOYBOYS is ERC20 {
    constructor() ERC20("SOYBOYS", "SOY") {_mint(msg.sender, 100000000000000 * 10 ** decimals());}
}