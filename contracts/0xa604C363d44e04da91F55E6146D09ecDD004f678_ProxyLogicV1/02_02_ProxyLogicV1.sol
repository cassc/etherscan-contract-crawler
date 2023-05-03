// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";

contract ProxyLogicV1 {

    address constant T = 0xCdF7028ceAB81fA0C6971208e83fa7872994beE5;

    function transfer(address token, address to, uint256 amount) external returns (bool){
        return IERC20(token).transfer(to, amount);
    }

    function approve(address token, address spender, uint256 amount) external returns (bool){
        return IERC20(token).approve(spender, amount);
    }

    function transferFrom(address token, address from, address to, uint256 amount) external returns (bool){
        return IERC20(token).transferFrom(from, to, amount);
    }

    function transferT(address to, uint256 amount) external returns (bool){
        return IERC20(T).transfer(to, amount);
    }

    function approveT(address spender, uint256 amount) external returns (bool){
        return IERC20(T).approve(spender, amount);
    }

    function transferTFrom(address from, address to, uint256 amount) external returns (bool){
        return IERC20(T).transferFrom(from, to, amount);
    }
}