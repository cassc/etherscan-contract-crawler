// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarExecutable } from '../interfaces/IAxelarExecutable.sol';

interface IAxelarForecallable is IAxelarExecutable {
    error AlreadyForecalled();
    error TransferFailed();

    function forecall(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external;

    function forecallWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external;

    function getForecaller(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external returns (address forecaller);

    function getForecallerWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external returns (address forecaller);

    function amountPostFee(uint256 amount, bytes calldata payload) external returns (uint256);
}