// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./VTokenInterface.sol";

interface VBep20Interface is IERC20 {
    /*** User Interface ***/

    function mint(uint256 mintAmount) external returns (uint256);

    function mintBehalf(address receiver, uint256 mintAmount)
        external
        returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        VTokenInterface vTokenCollateral
    ) external returns (uint256);

    /***  View Functions ***/
    function isVToken() external view returns (bool);

    function underlying() external view returns (address);

    function exchangeRateStored() external view returns (uint256);

    function comptroller() external view returns (address);

    /*** Admin Functions ***/

    function _addReserves(uint256 addAmount) external returns (uint256);
}