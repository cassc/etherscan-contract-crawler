// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
import "./ERC20.sol";

contract Beam is ERC20 {
    using SafeMath for uint256;
    uint256 salt = 0xBEA11;

    constructor (uint256 totalsupply_) public ERC20("BEAM", "BEAM") {
        _mint(_msgSender(), totalsupply_);
    }
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

}