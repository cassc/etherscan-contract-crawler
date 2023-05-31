// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface CToken {
    function accrueInterest() external returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function mint() external payable; // For ETH

    function mint(uint256 mintAmount) external returns (uint256); // For ERC20

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function transfer(address user, uint256 amount) external returns (bool);

    function transferFrom(
        address owner,
        address user,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);
}

interface Comptroller {
    function claimComp(address holder, address[] memory) external;

    function compAccrued(address holder) external view returns (uint256);
}