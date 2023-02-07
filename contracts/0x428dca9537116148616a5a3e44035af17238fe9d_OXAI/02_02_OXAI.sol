// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "solmate/tokens/ERC20.sol";

contract OXAI is ERC20 {
    address public minter;

    error NotMinter();

    constructor() ERC20("OxAI", "OXAI", 18) {
        minter = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        if (msg.sender != minter) {
            revert NotMinter();
        }
        _mint(to, amount);
    }

    function transferMinter(address _newMinter) external {
        if (msg.sender != minter) {
            revert NotMinter();
        }
        minter = _newMinter;
    }
}