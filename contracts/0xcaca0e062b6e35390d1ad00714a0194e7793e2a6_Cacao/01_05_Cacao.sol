// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "./ERC20.sol";

contract Cacao is ERC20 {
    using SafeMath for uint256;
  
    constructor (uint256 totalsupply_) public ERC20("CACAO", "CACAO") {
        _mint(_msgSender(), totalsupply_);
    }
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

}