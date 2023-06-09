// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract FlashZToken is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    uint8 private immutable dec;

    constructor(string memory _tokenName, string memory _tokenSymbol, uint8 _decimals)
        ERC20(_tokenName, _tokenSymbol)
        ERC20Permit(_tokenName)
    {
        dec = _decimals;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burnOwner(address _from, uint256 amount) public onlyOwner {
        _burn(_from, amount);
    }

    function decimals() public view override returns (uint8) {
        return dec;
    }
}