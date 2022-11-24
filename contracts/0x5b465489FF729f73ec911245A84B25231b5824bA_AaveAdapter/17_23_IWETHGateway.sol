// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IWETHGateway {
    function authorizeLendingPool(address lendingPool) external;

    function borrowETH(
        address lendingPool,
        uint256 amount,
        uint256 interesRateMode,
        uint16 referralCode
    ) external;

    function depositETH(
        address lendingPool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function emergencyEtherTransfer(address to, uint256 amount) external;

    function emergencyTokenTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    function getWETHAddress() external view returns (address);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function repayETH(
        address lendingPool,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external payable;

    function transferOwnership(address newOwner) external;

    function withdrawETH(
        address lendingPool,
        uint256 amount,
        address to
    ) external;
}