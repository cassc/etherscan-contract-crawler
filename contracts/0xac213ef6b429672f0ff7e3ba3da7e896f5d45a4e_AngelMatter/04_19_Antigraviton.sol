// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.20;

import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";

contract Antigraviton is ERC20 {
    address immutable angel;

    constructor() ERC20("Antigraviton", "&#966;", 18) {
        angel = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == angel);
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(msg.sender == angel);
        _burn(from, amount);
    }
}