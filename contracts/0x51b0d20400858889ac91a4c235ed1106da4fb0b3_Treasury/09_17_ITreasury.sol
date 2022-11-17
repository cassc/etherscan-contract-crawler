// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// USX is an cross chain native stablecoin
interface ITreasury {
    function mint(address _stable, uint256 _amount) external;

    function redeem(address _stable, uint256 _amount) external;
}