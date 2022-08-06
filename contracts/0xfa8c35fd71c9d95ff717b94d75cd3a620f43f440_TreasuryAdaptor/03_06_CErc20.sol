// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;
import "./Comptroller.sol";

interface CErc20 {
    /*** User Interface ***/
    function comptroller() external returns (ComptrollerInterface);

    function underlying() external returns (address);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function balanceOf(address owner) external view returns (uint256);
}