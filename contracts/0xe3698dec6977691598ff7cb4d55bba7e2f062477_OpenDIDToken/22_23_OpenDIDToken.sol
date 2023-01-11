// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OpenDIDToken is ERC20, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        uint256 total
    ) ERC20(name, symbol) {
        _mint(msg.sender, total * 10**decimals());
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}