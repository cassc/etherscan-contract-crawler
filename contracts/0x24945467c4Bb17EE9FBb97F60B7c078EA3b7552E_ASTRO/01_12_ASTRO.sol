// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./token/ERC20/ERC20.sol";
import "./token/ERC20/extensions/ERC20Burnable.sol";
import "./security/Pausable.sol";
import "./access/Ownable.sol";
import "./token/ERC20/extensions/draft-ERC20Permit.sol";

contract ASTRO is ERC20, ERC20Burnable, Pausable, Ownable, ERC20Permit {
    constructor() ERC20("ASTRO", "ASTRO") ERC20Permit("ASTRO") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function withdraw() public onlyOwner{
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}