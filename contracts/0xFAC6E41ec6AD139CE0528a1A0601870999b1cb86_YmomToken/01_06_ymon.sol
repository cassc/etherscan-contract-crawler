// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YmomToken is Ownable, ERC20 {
    bool public locked = true;
    uint256 public constant INITIAL_SUPPLY = 69000000000000 * 10**18;
    
    constructor() ERC20("Ymom", "YMOM") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function unlock() external onlyOwner {
        locked = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (locked) {
            require(from == owner() || to == owner(), "Trading not started");
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}