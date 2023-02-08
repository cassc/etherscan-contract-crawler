// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract PaprToken is ERC20 {
    error ControllerOnly();

    address immutable controller;

    modifier onlyController() {
        if (msg.sender != controller) {
            revert ControllerOnly();
        }
        _;
    }

    constructor(string memory name, string memory symbol)
        ERC20(string.concat("papr ", name), string.concat("papr", symbol), 18)
    {
        controller = msg.sender;
    }

    function mint(address to, uint256 amount) external onlyController {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) external onlyController {
        _burn(account, amount);
    }
}