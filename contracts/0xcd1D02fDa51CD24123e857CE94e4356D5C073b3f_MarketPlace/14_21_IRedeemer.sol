// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IRedeemer {
    function authRedeem(
        address underlying,
        uint256 maturity,
        address from,
        address to,
        uint256 amount
    ) external returns (uint256);

    function approve(address p) external;

    function holdings(address u, uint256 m) external view returns (uint256);
}