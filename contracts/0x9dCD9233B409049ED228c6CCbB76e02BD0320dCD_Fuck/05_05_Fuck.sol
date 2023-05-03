/*
    $FUCK, A project by @sibeleth
        https://twitter.com/fuckcoineth
        https://fuckcoineth.xyz

    LIKE + RT FOR FUCK 👇
	    https://twitter.com/sibeleth/status/1652372258248163331
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract Fuck is ERC20 {
    constructor() ERC20("FUCK IT", "FUCK") {
        _mint(msg.sender, 69_000_000_000 ether);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function fuck() public pure {}
}