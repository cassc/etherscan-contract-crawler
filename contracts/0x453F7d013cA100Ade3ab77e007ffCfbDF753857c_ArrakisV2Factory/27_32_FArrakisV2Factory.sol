// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

function _getTokenOrder(address tokenA_, address tokenB_)
    pure
    returns (address token0, address token1)
{
    require(tokenA_ != tokenB_, "same token");
    (token0, token1) = tokenA_ < tokenB_
        ? (tokenA_, tokenB_)
        : (tokenB_, tokenA_);
    require(token0 != address(0), "no address zero");
}

function _append(
    string memory a_,
    string memory b_,
    string memory c_,
    string memory d_
) pure returns (string memory) {
    return string(abi.encodePacked(a_, b_, c_, d_));
}