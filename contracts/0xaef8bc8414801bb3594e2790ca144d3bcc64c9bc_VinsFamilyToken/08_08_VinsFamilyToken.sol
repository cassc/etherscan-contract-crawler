// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC20.sol";
import "ERC20Burnable.sol";
import "Pausable.sol";
import "Ownable.sol";

contract VinsFamilyToken is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor(
    address tokenOwner,
    address marketing,
    uint256 rate

) ERC20("Vins Family Token", "$FAMILY") {
    _mint(tokenOwner, (69000000000 * 10 ** decimals()) * 17 / 100);
    _mint(marketing, (69000000000 * 10 ** decimals()) * 83 / 100);
    setBurnRate(rate);
}

function pause() public onlyOwner {
    _pause();
}

function unpause() public onlyOwner {
    _unpause();
}

function mint(address to, uint256 amount) public onlyOwner {
    require(totalSupply() + amount <= 69000000000 * 10 ** 18);
    _mint(to, amount);
}

function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    whenNotPaused
    override
{
    super._beforeTokenTransfer(from, to, amount);
}

function setBurnRate(uint256 _burnRate) public onlyOwner {
    ERC20.burnRate = _burnRate;
}

}