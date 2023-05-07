// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PepechainCEXTreasury is Ownable {
    using SafeMath for uint256;

    IERC20 public token;
   
    constructor(IERC20 _token) {
        token = _token;
    }

    function release(uint256 _amount) public onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        require(amount >= _amount, "invalid _amount");
        token.transfer(owner(), _amount);
    }
}