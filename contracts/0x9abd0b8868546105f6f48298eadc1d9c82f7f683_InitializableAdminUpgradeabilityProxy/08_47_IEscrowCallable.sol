pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "../utils/Common.sol";

interface IEscrowCallable {
    function setLiquidityHaircut(uint128 haircut) external;
    function isValidCurrency(uint16 currency) external view returns (bool);
    function getBalances(address account) external view returns (int256[] memory);
    function convertBalancesToETH(int256[] calldata amounts) external view returns (int256[] memory);
    function portfolioSettleCash(address account, int256[] calldata settledCash) external;
    function unlockCurrentCash(uint16 currency, address cashMarket, int256 amount) external;

    function depositsOnBehalf(address account, Common.Deposit[] calldata deposits) external payable;
    function withdrawsOnBehalf(address account, Common.Withdraw[] calldata withdraws) external;

    function depositIntoMarket(
        address account,
        uint8 cashGroupId,
        uint128 value,
        uint128 fee
    ) external;
    function withdrawFromMarket(
        address account,
        uint8 cashGroupId,
        uint128 value,
        uint128 fee
    ) external;
}