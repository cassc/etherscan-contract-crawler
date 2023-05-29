// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface IMarketPlace {
    function setSwivel(address) external returns (bool);

    function setAdmin(address) external returns (bool);

    function createMarket(
        uint8,
        uint256,
        address,
        string memory,
        string memory
    ) external returns (bool);

    function matureMarket(
        uint8,
        address,
        uint256
    ) external returns (bool);

    function authRedeem(
        uint8,
        address,
        uint256,
        address,
        address,
        uint256
    ) external returns (uint256);

    function exchangeRate(uint8, address) external returns (uint256);

    function rates(
        uint8,
        address,
        uint256
    ) external returns (uint256, uint256);

    function transferVaultNotional(
        uint8,
        address,
        uint256,
        address,
        uint256
    ) external returns (bool);

    // adds notional and mints zctokens
    function mintZcTokenAddingNotional(
        uint8,
        address,
        uint256,
        address,
        uint256
    ) external returns (bool);

    // removes notional and burns zctokens
    function burnZcTokenRemovingNotional(
        uint8,
        address,
        uint256,
        address,
        uint256
    ) external returns (bool);

    // returns the amount of underlying principal to send
    function redeemZcToken(
        uint8,
        address,
        uint256,
        address,
        uint256
    ) external returns (uint256);

    // returns the amount of underlying interest to send
    function redeemVaultInterest(
        uint8,
        address,
        uint256,
        address
    ) external returns (uint256);

    // returns the cToken address for a given market
    function cTokenAddress(
        uint8,
        address,
        uint256
    ) external returns (address);

    // EVFZE FF EZFVE call this which would then burn zctoken and remove notional
    function custodialExit(
        uint8,
        address,
        uint256,
        address,
        address,
        uint256
    ) external returns (bool);

    // IVFZI && IZFVI call this which would then mint zctoken and add notional
    function custodialInitiate(
        uint8,
        address,
        uint256,
        address,
        address,
        uint256
    ) external returns (bool);

    // IZFZE && EZFZI call this, tranferring zctoken from one party to another
    function p2pZcTokenExchange(
        uint8,
        address,
        uint256,
        address,
        address,
        uint256
    ) external returns (bool);

    // IVFVE && EVFVI call this, removing notional from one party and adding to the other
    function p2pVaultExchange(
        uint8,
        address,
        uint256,
        address,
        address,
        uint256
    ) external returns (bool);

    // IVFZI && IVFVE call this which then transfers notional from msg.sender (taker) to swivel
    function transferVaultNotionalFee(
        uint8,
        address,
        uint256,
        address,
        uint256
    ) external returns (bool);
}