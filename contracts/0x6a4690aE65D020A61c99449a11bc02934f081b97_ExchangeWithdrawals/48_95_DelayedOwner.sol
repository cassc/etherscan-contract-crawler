// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;

import "../../lib/Claimable.sol";
import "./DelayedTransaction.sol";


/// @title  DelayedOwner
/// @author Brecht Devos - <[email protected]>
contract DelayedOwner is DelayedTransaction, Claimable
{
    address public defaultContract;

    event FunctionDelayUpdate(
        bytes4  functionSelector,
        uint    delay
    );

    constructor(
        address _defaultContract,
        uint    _timeToLive
        )
        DelayedTransaction(_timeToLive)
    {
        require(_defaultContract != address(0), "INVALID_ADDRESS");

        defaultContract = _defaultContract;
    }

    receive()
        external
        // nonReentrant
        payable
    {
        // Don't do anything when receiving ETH
    }

    fallback()
        external
        nonReentrant
        payable
    {
        // Don't do anything if msg.sender isn't the owner
        if (msg.sender != owner) {
            return;
        }
        transactInternal(defaultContract, msg.value, msg.data);
    }

    function isAuthorizedForTransactions(address sender)
        internal
        override
        view
        returns (bool)
    {
        return sender == owner;
    }

    function setFunctionDelay(
        bytes4  functionSelector,
        uint    delay
        )
        internal
    {
        setFunctionDelay(defaultContract, functionSelector, delay);

        emit FunctionDelayUpdate(functionSelector, delay);
    }
}