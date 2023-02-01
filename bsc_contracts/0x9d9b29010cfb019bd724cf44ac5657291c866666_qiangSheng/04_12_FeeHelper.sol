// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract FeeHelper is Ownable {
    using SafeMath for uint256;

    constructor(){}

    function transferToken(address token_, address to_, uint256 amount_) public onlyOwner {
        IERC20(token_).transfer(to_, amount_);
    }
}