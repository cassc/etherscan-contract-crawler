// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../core/iface/ExchangeData.sol";

/// @title IBlockReceiver
/// @author Brecht Devos - <[email protected]>
abstract contract IBlockReceiver
{
    function beforeBlockSubmission(
        bytes              calldata txsData,
        bytes              calldata callbackData
        )
        external
        virtual;
}