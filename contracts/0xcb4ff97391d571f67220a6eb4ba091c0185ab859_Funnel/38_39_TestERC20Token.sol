// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { ERC20Permit } from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract TestERC20Token is ERC20Permit {
    constructor(
        string memory name,
        string memory symbol,
        address initialHolder,
        uint256 initialAmount
    ) ERC20(name, symbol) ERC20Permit(name) {
        _mint(initialHolder, initialAmount);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }

    function version() public pure returns (string memory) {
        return "1";
    }
}