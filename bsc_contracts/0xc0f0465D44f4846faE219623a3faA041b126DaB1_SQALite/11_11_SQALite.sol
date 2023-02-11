// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC20Capped.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//200.000.000 $SLIT as per tokenomics
uint256 constant CAP = 200_000_000 * 1e18;

contract SQALite is ERC20Capped, Pausable, Ownable {
    using SafeERC20 for IERC20;
    
    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
        ERC20Capped(CAP)
    {}

    function mint(address to, uint256 amount) public onlyOwner whenNotPaused {
        _mint(to, amount);
    }

    function transfer(address to, uint256 amount)
        public
        override
        whenNotPaused
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        public
        virtual
        onlyOwner
        whenNotPaused
    {
        require(tokenAddress != address(0), "address can't be zero");
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override whenNotPaused returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function burn(uint256 amount) public whenNotPaused {
        _burn(msg.sender, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}