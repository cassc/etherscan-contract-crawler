// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface IExchange {
    function get_best_rate(address from, address to, uint256 amount) external view returns (address, uint);

    function get_exchange_amount(address pool, address from, address to, uint256 amount) external view returns (uint);

    function exchange(
        address pool,
        address from,
        address to,
        uint256 amount,
        uint256 expected,
        address receiver
    ) external payable returns (uint256);

    function exchange_with_best_rate(
        address from,
        address to,
        uint256 amount,
        uint256 expected,
        address receiver
    ) external payable returns (uint256);
}