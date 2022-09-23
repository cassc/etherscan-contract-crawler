// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;
import "./Pausable.sol";

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract iSmarten is ERC20 , Pausable, ERC20Burnable{
    constructor(address TO_) ERC20("iSmarten", "iSmarten") {
        _mint(TO_, 900000000000 * 10 ** decimals());
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

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}