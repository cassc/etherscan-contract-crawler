// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "../access/Ownable.sol";
import "./interfaces/IPool.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract LPToken is ERC20Burnable, Ownable {

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address account, uint256 amount) external onlyOwner {
        require(amount != 0, "ERC20: zero mint amount");
        _mint(account, amount);
    }
}