// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "./ERC20.sol";

contract Boobs is ERC20 {
    using SafeMath for uint256;
    uint256 boobs = 0xB00BC;

    constructor (uint256 totalsupply_) public ERC20("BOOBS", "BOOBS") {
        _mint(_msgSender(), totalsupply_);
    }
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

}