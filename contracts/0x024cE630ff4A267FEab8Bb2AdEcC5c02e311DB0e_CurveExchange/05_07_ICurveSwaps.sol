// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICurveSwaps {
    /* solhint-disable */
    function get_best_rate(address _from, address _to, uint256 _amount) external view returns (address, uint256);

    function get_exchange_amount(
        address _pool,
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint256);

    function exchange(
        address _pool,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) external payable returns (uint256);

    /**
     @notice This function queries the exchange rate for every pool where a swap between _to and _from is possible.
     For pairs that can be swapped in many pools this will result in very significant gas costs!
     */
    function exchange_with_best_rate(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) external payable returns (uint256);

    function get_exchange_multiple_amount(
        address[9] calldata _route,
        uint256[3][4] calldata _swap_params,
        uint256 _amount
    ) external view returns (uint256);

    function exchange_multiple(
        address[9] calldata _route,
        uint256[3][4] calldata _swap_params,
        uint256 _amount,
        uint256 _expected,
        address[4] calldata _pools,
        address _receiver
    ) external returns (uint256);
}