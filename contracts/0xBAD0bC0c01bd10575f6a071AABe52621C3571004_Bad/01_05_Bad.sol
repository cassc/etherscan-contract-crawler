// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "./ERC20.sol";

contract Bad is ERC20 {
    using SafeMath for uint256;
    uint256 bad = 0xBAD;

    constructor (uint256 totalsupply_) public ERC20("BAD", "BAD") {
        _mint(_msgSender(), totalsupply_);
    }
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

}