/**
 *Submitted for verification at Etherscan.io on 2023-05-15
*/

// File: IERC20.sol

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// File: treausury.sol

pragma solidity ^0.8.0;
//* SPDX-License-Identifier: Unlicensed


contract KekistanTreasury {
    IERC20 public token;

    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
    }
    
    function deposit(uint256 amount) public {
        require(amount > 0, "Amount must be > 0");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }

    function withdraw(address to, uint256 amount) public {
        require(token.transfer(to, amount), "Transfer failed");
    }
}