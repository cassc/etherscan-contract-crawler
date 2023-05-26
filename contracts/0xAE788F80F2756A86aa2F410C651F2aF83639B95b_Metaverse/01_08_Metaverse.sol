// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Metaverse is ERC20Burnable, Ownable, ERC20Capped {

    uint256 public constant CAP_AMOUNT = 2000000000 * 10 ** 18;
    constructor() ERC20("Metaverse", "MV") ERC20Capped(CAP_AMOUNT){}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }
}