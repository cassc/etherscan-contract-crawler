/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface ID3MM {
    function _CREATOR_() external view returns(address);
    function getFeeRate(address) external view returns(uint256);
    function allFlag() external view returns(uint256);
    function checkSafe() external view returns (bool);
    function checkBorrowSafe() external view returns (bool);
    function startLiquidation() external;
    function finishLiquidation() external;
    function isInLiquidation() external view returns (bool);
    function updateReserveByVault(address) external;
    function setNewAllFlag(uint256) external;

    function init(
        address creator,
        address maker,
        address vault,
        address oracle,
        address feeRateModel,
        address maintainer
    ) external;

    function sellToken(
        address to,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minReceiveAmount,
        bytes calldata data
    ) external returns (uint256);

    function buyToken(
        address to,
        address fromToken,
        address toToken,
        uint256 quoteAmount,
        uint256 maxPayAmount,
        bytes calldata data
    ) external returns (uint256);

    function lpDeposit(address lp, address token) external;
    function makerDeposit(address token) external;
    function getTokenReserve(address token) external view returns (uint256);
}