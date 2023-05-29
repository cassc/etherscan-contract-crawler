// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import 'src/interfaces/IERC20.sol';

interface INotional {
    function getUnderlyingToken() external view returns (IERC20, int256);

    function getMaturity() external view returns (uint40);

    function deposit(uint256, address) external returns (uint256);

    function maxRedeem(address) external returns (uint256);

    function redeem(
        uint256,
        address,
        address
    ) external returns (uint256);
}