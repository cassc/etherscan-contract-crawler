// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
// Credit to Ellipsis
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICurve is IERC20 {
    function coins(uint256 i) external view returns (address);

    function get_virtual_price() external view returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);

    function fee() external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external view returns (uint256);
}