// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAaveToken {
    function redeem(uint256 amount) external;

    function underlyingAssetAddress() external view returns (address);
}

interface IAaveV1LendingPool {
    function deposit(
        IERC20 token,
        uint256 amount,
        uint16 refCode
    ) external payable;
}