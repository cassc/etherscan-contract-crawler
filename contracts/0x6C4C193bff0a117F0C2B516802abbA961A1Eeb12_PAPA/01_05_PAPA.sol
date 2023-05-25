// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PAPA is ERC20 {

    string private _name = "Papa";
    string private constant _symbol = "PAPA";
    uint   private constant _numTokens = 1_000_000_000_000_000;

    constructor () ERC20(_name, _symbol) {
        _mint(msg.sender, _numTokens * (10 ** 18));
    }

    /**
     * @dev Destoys `amount` tokens from the caller.
     *
     * See `ERC20._burn`.
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}