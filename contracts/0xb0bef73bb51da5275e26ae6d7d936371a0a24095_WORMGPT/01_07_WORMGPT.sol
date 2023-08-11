// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "ERC20.sol";
import "Pausable.sol";
import "Ownable.sol";

contract WORMGPT is ERC20, Pausable, Ownable {
    uint256 private constant INITIAL_SUPPLY = 1000000000;

    constructor() ERC20("WormGPT", "WORMGPT") {
        _mint(msg.sender, INITIAL_SUPPLY * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}