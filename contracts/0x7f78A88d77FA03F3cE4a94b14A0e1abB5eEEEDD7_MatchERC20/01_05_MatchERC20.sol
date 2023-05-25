// contracts/MathchERC20.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MatchERC20 is ERC20 {

    uint256 private constant initSupply = 10000000000 * 10 ** 18;

    constructor(address to) ERC20("Matching game", "MATCH") {
        _mint(to, initSupply);
    }

    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

}