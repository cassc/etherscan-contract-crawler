// SPDX-License-Identifier: MIT
/**
/// Data Ammo - A Cryptocurrency Payment Solution /// 

Website: https://www.dataammo.io/
Twitter: https://www.twitter.com//DataAmmoIO

*/
pragma solidity ^0.8.10;

import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

abstract contract Project {

    string constant _name = "Data Ammo";
    string constant _symbol = "DAMMO";
    uint8 constant _decimals = 18;

    uint256 constant _totalSupply = 1 * 1e9 * 1e18;
}

/**
*   MainContract
*/
contract DataAmmoToken is Project, Context, ERC20, Ownable {

    constructor() ERC20(_name, _symbol) {
        _mint(_msgSender(), _totalSupply);
    }

    function burn(uint256 value) external {
        _burn(_msgSender(), value);
    }
}