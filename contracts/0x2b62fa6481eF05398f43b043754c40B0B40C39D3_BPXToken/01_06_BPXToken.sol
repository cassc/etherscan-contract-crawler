// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract BPXToken is ERC20, ERC20Burnable {

    // 1.5 billion tokens
    uint256 public constant TOTAL_MINT = 1_500_000_000 * ( 10**18 );

    constructor(address _mintTo) ERC20("BitpitX", "BPX") {
        _mint(_mintTo, TOTAL_MINT);
    }
}