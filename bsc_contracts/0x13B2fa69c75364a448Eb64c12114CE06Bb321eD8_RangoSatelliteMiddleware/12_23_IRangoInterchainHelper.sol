// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../libraries/LibSwapper.sol";
import "./IRango.sol";
import "./Interchain.sol";

/// @title An interface to facilitate function call in destination
/// @author George
interface IRangoInterchainHelper {
    function helplerHandleDestinationMessageWithTryCatch(
        address _token,
        uint _amount,
        Interchain.RangoInterChainMessage memory m
    ) external returns (address receivedToken, uint256 dstAmount, IRango.CrossChainOperationStatus status);
}