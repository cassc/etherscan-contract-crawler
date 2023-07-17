// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract PreNoox is ERC20, ERC20Burnable, Ownable {

    mapping(address => bool) private _whitelist;

    constructor() ERC20("preNOOX", "PRENOOX") {}

    function mint(address to, uint256 amount) public onlyOwner {
        require(isWhitelisted(to), "mint: address not whitelisted");
        _mint(to, amount);
    }

    function addWhitelist(address _address) public onlyOwner {
        _whitelist[_address] = true;
    }

    function removeWhitelist(address _address) public onlyOwner {
        _whitelist[_address] = false;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return _whitelist[_address];
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
        require(
            (isWhitelisted(from)) || (from == address(0) && isWhitelisted(to)), 
            "transfer: not allowed"
        );
    }
}