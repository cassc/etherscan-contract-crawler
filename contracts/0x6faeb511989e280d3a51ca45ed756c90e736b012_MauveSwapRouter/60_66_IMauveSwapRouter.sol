// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@violetprotocol/mauve-periphery/contracts/interfaces/ISelfPermit.sol';

import './ISwapRouter.sol';
import './IApproveAndCall.sol';
import './IEATMulticallExtended.sol';

/// @title Router token swapping functionality
interface IMauveSwapRouter is ISwapRouter, IApproveAndCall, IEATMulticallExtended, ISelfPermit {

}