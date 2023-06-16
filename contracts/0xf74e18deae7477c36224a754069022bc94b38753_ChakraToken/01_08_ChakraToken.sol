// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract ChakraToken is ERC20Capped, ERC20Burnable {
    using SafeMath for uint;

    constructor(uint totalSupply, address assetManager, string memory name, string memory symbol) ERC20(name, symbol) ERC20Capped(totalSupply) {
        _mint(assetManager, totalSupply);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _mint(
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Capped) {
        super._mint(to, amount);
    }
}