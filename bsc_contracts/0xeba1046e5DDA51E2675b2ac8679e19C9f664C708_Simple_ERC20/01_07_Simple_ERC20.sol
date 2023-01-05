// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20Mintable.sol";
import "./ERC20Burnable.sol";

contract Simple_ERC20 is ERC20 {

    constructor (string memory t_name, string memory t_symbol, uint256 t_cap)
        ERC20(t_name, t_symbol)
        payable
    {
        _setupDecimals(18);
        _mint(msg.sender, t_cap);
    }
}