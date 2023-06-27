// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

abstract contract IBuyBack {
    function canSellToken() external view virtual returns (address);

    function canSendToTreasury() public view virtual returns (bool);

    function canBurnTokens() external view virtual returns (bool);

    function canTopUpKeeper() external view virtual returns (bool);

    function sellTokens(address _token) external virtual;

    function burnTokens() external virtual;

    function sendToTreasury() external virtual;

    function topUpKeeper() external virtual;
}