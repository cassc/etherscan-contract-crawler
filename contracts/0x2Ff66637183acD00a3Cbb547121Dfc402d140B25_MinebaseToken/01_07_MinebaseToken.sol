// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * ╔╦╗╦╔╗╔╔═╗╔╗ ╔═╗╔═╗╔═╗  ╔╦╗╔═╗╦╔═╔═╗╔╗╔
 * ║║║║║║║║╣ ╠╩╗╠═╣╚═╗║╣    ║ ║ ║╠╩╗║╣ ║║║
 * ╩ ╩╩╝╚╝╚═╝╚═╝╩ ╩╚═╝╚═╝   ╩ ╚═╝╩ ╩╚═╝╝╚╝
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MinebaseToken is ERC20, ERC20Burnable, Ownable {
    uint256 private immutable _maxTokenSupply;

    constructor(
        address _contractOwner,
        address _tokenOwner,
        uint256 _preMintAmount,
        uint256 _maxAmount,
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC20(_tokenName, _tokenSymbol) {
        require(_maxAmount > 0, "ERC20MaxSupply: maxTokenSupply is 0");
        _maxTokenSupply = _maxAmount * 10**decimals();
        _mint(_tokenOwner, _preMintAmount * 10**decimals());
        _transferOwnership(_contractOwner);
    }

    function maxTokenSupply() public view virtual returns (uint256) {
        return _maxTokenSupply;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(ERC20.totalSupply() + amount <= maxTokenSupply(), "ERC20MaxSupply: maxTokenSupply exceeded");
        _mint(to, amount);
    }
}