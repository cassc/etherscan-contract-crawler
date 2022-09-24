// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface ICurveExchange {
    function get_exchange_amount(
        address _pool,
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint256);
}