// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
pragma solidity ^0.8.0;

// Website: https://openai.com/
// https://twitter.com/WhaleChart/status/1657717456507469824?s=20

contract Worldcoin is ERC20 {
    constructor(uint256 _totalSupply) ERC20("Worldcoin", "WORLD") {
        _mint(msg.sender, _totalSupply);
    }
}