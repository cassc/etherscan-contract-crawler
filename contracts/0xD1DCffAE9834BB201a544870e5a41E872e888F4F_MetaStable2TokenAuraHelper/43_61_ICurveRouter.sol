// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface ICurveRouter {
    function exchange(
        uint256 _amount,
        address[6] calldata _route,
        uint256[8] calldata _indices,
        uint256 _min_received
    ) external payable;

    function get_exchange_routing(
        address _initial,
        address _target,
        uint256 _amount
    ) external view returns (
        address[6] memory route,
        uint256[8] memory indexes,
        uint256 expectedOutputAmount
    );

    function can_route(address _initial, address _target) external view returns (bool);
}