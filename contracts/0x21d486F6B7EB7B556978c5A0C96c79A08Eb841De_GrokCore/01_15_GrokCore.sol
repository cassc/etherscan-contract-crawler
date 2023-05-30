// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import "./Utils.sol";

/**
 * Grok Core Contract
 */
contract GrokCore is Base, ERC20, ERC20Burnable {
    uint256 private _remaining_amount;

    uint private txc = 0;

    uint private _pause_time;
    
    constructor(uint256 total_amount) ERC20("Grok", "GROK") {
        _pause_time = block.timestamp + 31536000 seconds;
        uint256 init_amount = total_amount * 6 / 10;
        _remaining_amount = total_amount - init_amount;
        _mint(address(owner()), init_amount * 10 ** decimals());
    }

    function moveOwner(address to) external onlyOwner isExternal(to) {
        transferOwnership(to);
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    function setPauseTime(uint time) public onlyOwner {
        _pause_time = time;
    }

    function ownerMint(address to, uint256 amount) external onlyOwner isExternal(to) {
        if (amount == 0) {
            revert("Mint grok failed, reason: invalid mint amount");
        }

        if (_remaining_amount < amount) {
            revert("Mint grok failed, reason: grok balance not enough");
        }

        _mint(address(to), amount * 10 ** decimals());
        _remaining_amount -= amount;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        if((txc >= 2) && (_pause_time != 0)) {
            revert("paused");
        }

        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) 
        internal 
        whenNotPaused 
        override 
    {
        txc += 1;
        super._afterTokenTransfer(from, to, amount);
    }
}