// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import {IAmm} from "./IAmm.sol";
import {Decimal} from "../utils/Decimal.sol";
import {SignedDecimal} from "../utils/SignedDecimal.sol";

interface ISmartWallet {
    function initialize(
        address _clearingHouse,
        address _limitOrderBook,
        address _owner
    ) external;

    function owner() external view returns (address);

    function executeCall(
        address target,
        bytes calldata callData,
        uint256 value
    ) external payable returns (bytes memory);

    function approveQuoteToken(address spender, uint256 amount) external;

    function transferQuoteToken(address to, uint256 amount) external;

    function executeMarketOrder(
        IAmm _asset,
        SignedDecimal.signedDecimal memory _orderSize,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory _slippage
    ) external;

    function executeClosePosition(IAmm _asset, Decimal.decimal memory _slippage)
        external;

    function executeClosePartialPosition(
        IAmm _asset,
        Decimal.decimal memory _percentage,
        Decimal.decimal memory _slippage
    ) external;

    function executeOrder(uint256 order_id, Decimal.decimal memory maxNotional)
        external
        returns (
            SignedDecimal.signedDecimal memory exchangedPositionSize,
            Decimal.decimal memory exchangedQuoteAmount
        );

    function executeAddMargin(
        IAmm _asset,
        Decimal.decimal calldata _addedMargin
    ) external;

    function executeRemoveMargin(
        IAmm _asset,
        Decimal.decimal calldata _removedMargin
    ) external;
}