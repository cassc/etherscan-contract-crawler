// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ICurveTC1Router {
    function exchange_with_best_rate(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) external returns (uint256);

    function exchange(
        address pool,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) payable external returns (uint256);

    function exchange_multiple(
        address[9] calldata _route,
        uint256[3][4] calldata _swap_params,
        uint256 _amount,
        uint256 _expected,
        address[4] calldata _pools,
        address _receiver
    ) external payable returns (uint256);

    function is_killed() external view returns (bool);

    function registry() external view returns (address);
}