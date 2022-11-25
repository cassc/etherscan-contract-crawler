// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "IWitnetRequestBoardEvents.sol";
import "IWitnetRequestBoardReporter.sol";
import "IWitnetRequestBoardRequestor.sol";
import "IWitnetRequestBoardView.sol";
import "IWitnetRequestParser.sol";

/// @title Witnet Request Board functionality base contract.
/// @author The Witnet Foundation.
abstract contract WitnetRequestBoard is
    IWitnetRequestBoardEvents,
    IWitnetRequestBoardReporter,
    IWitnetRequestBoardRequestor,
    IWitnetRequestBoardView,
    IWitnetRequestParser
{
    receive() external payable {
        revert("WitnetRequestBoard: no transfers accepted");
    }
}