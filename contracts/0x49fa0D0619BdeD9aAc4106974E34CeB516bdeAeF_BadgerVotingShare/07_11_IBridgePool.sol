// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBridgePool {
    function liquidReserves() external view returns (uint256);
    function utilizedReserves() external view returns (uint256);
    function undistributedLpFees() external view returns (uint256);
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    function addLiquidity(uint256 l1TokenAmount) external;

}