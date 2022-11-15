//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEllipsisPool {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external;

    function add_liquidity(uint256[2] calldata amounts, uint256 minMintAmount) external;

    function add_liquidity(uint256[3] calldata amounts, uint256 minMintAmount) external;

    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 i,
        uint256 minAmount
    ) external;

    function balances(uint256 i) external view returns (uint256);

    function initial_A() external view returns (uint256);

    function future_A() external view returns (uint256);

    function initial_A_time() external view returns (uint256);

    function future_A_time() external view returns (uint256);

    function fee() external view returns (uint256);

    function admin_fee() external view returns (uint256);
}