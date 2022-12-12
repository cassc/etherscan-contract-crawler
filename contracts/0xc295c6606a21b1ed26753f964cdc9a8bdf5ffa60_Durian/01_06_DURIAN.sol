// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Durian is ERC20 {
    using SafeMath for uint256;
    uint TAX_FEE = 1;
    address public owner;
    mapping(address => bool) public exclidedFromTax;

    constructor() ERC20("DURIAN", "DURC") {
    _mint(msg.sender, 1000000000 * 10 ** decimals());
    owner = msg.sender;
    exclidedFromTax[msg.sender] = false;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if(exclidedFromTax[msg.sender]  == true) {
            _transfer(_msgSender(), recipient, amount);
        } else {
            uint adminAmount = amount.mul(TAX_FEE) / 100;
            _transfer(_msgSender(), owner, adminAmount);
            _transfer(_msgSender(), recipient, amount.sub(adminAmount));
        }
        return true;
    }
}