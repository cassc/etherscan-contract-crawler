// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "./ERC20.sol";

contract Boboa is ERC20 {
    using SafeMath for uint256;
    uint256 boobs = 0xB0B0A;

    constructor (uint256 totalsupply_) public ERC20("BOBOA", "BOBOA") {
        _mint(_msgSender(), totalsupply_);
    }
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

}