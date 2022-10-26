// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./OTCallable.sol";

contract OpenTown is ERC20("$OPENTOWN", "$OT"), OTCallable {
    uint256 public constant MAX_SUPPLY = 1000000000 ether;

    function mint(address to, uint256 amount) external onlyOTCaller {
        require(amount > 0, "Invalid amount");
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");

        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOTCaller {
        _burn(from, amount);
    }
}