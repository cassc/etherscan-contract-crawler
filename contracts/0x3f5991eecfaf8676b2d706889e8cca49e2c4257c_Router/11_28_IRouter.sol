// Copyright (C) 2022 Clutch Wallet. <https://www.clutchwallet.xyz>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import {
    AbsoluteTokenAmount,
    Input,
    SwapDescription,
    AccountSignature,
    ProtocolFeeSignature,
    Fee
} from "../shared/Structs.sol";

import { ITokensHandler } from "./ITokensHandler.sol";
import { ISignatureVerifier } from "./ISignatureVerifier.sol";

interface IRouter is ITokensHandler, ISignatureVerifier {
    /**
     * @notice Emits swap info
     * @param inputToken Input token address
     * @param absoluteInputAmount Max amount of input token to be taken from the account address
     * @param inputBalanceChange Actual amount of input token taken from the account address
     * @param outputToken Output token address
     * @param absoluteOutputAmount Min amount of output token to be returned to the account address
     * @param returnedAmount Actual amount of tokens returned to the account address
     * @param protocolFeeAmount Protocol fee amount
     * @param marketplaceFeeAmount Marketplace fee amount
     * @param swapDescription Swap parameters
     * @param sender Address that called the Router contract
     */
    event Executed(
        address indexed inputToken,
        uint256 absoluteInputAmount,
        uint256 inputBalanceChange,
        address indexed outputToken,
        uint256 absoluteOutputAmount,
        uint256 returnedAmount,
        uint256 protocolFeeAmount,
        uint256 marketplaceFeeAmount,
        SwapDescription swapDescription,
        address sender
    );

    /**
     * @notice Main function executing the swaps
     * @param input Token and amount (relative or absolute) to be taken from the account address,
     *     also, permit type and call data may provided if required
     * @dev `address(0)` may be used as input token address,
     *     in this case no tokens will be taken from the user
     * @param absoluteOutput Token and absolute amount requirement
     *     to be returned to the account address
     * @dev `address(0)` may be used as output token address,
     *     in this case no tokens will be returned to the user, no fees are applied
     * @param swapDescription Swap description with the following elements:
     *     - Whether the inputs or outputs are fixed
     *     - Protocol fee share and beneficiary address
     *     - Marketplace fee share and beneficiary address
     *     - Address of the account executing the swap
     *     - Address of the Caller contract to be called
     *     - Calldata for the call to the Caller contract
     * @param accountSignature Signature for the relayed transaction
     *     (checks that account address is the one who actually did a signature)
     * @param protocolFeeSignature Signature for the discounted protocol fee
     *     (checks that current protocol fee signer is the one who actually did a signature),
     *     this signature may be reused multiple times until the deadline
     * @return inputBalanceChange Actual amount of input tokens spent
     * @return actualOutputAmount Actual amount of output tokens returned to the user
     * @return protocolFeeAmount Actual amount of output tokens charged as protocol fee
     * @return marketplaceFeeAmount Actual amount of output tokens charged as marketplace fee
     */
    function execute(
        Input calldata input,
        AbsoluteTokenAmount calldata absoluteOutput,
        SwapDescription calldata swapDescription,
        AccountSignature calldata accountSignature,
        ProtocolFeeSignature calldata protocolFeeSignature
    ) external payable
        returns (
            uint256 inputBalanceChange,
            uint256 actualOutputAmount,
            uint256 protocolFeeAmount,
            uint256 marketplaceFeeAmount
        );

    /**
     * @notice Function for the account signature cancellation
     * @param input Token and amount (relative or absolute) to be taken from the account address,
     *     also, permit type and call data may provided if required
     * @dev `address(0)` may be used as input token address,
     *     in this case no tokens will be taken from the user
     * @param absoluteOutput Token and absolute amount requirement
     *     to be returned to the account address
     * @dev `address(0)` may be used as output token address,
     *     in this case no tokens will be returned to the user, no fees are applied
     * @param swapDescription Swap description with the following elements:
     *     - Whether the inputs or outputs are fixed
     *     - Protocol fee share and beneficiary address
     *     - Marketplace fee share and beneficiary address
     *     - Address of the account executing the swap
     *     - Address of the Caller contract to be called
     *     - Calldata for the call to the Caller contract
     * @param accountSignature Signature for the relayed transaction
     *     (checks that account address is the one who actually did a signature)
     */
    function cancelAccountSignature(
        Input calldata input,
        AbsoluteTokenAmount calldata absoluteOutput,
        SwapDescription calldata swapDescription,
        AccountSignature calldata accountSignature
    ) external;
}