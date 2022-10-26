/**
 *Submitted for verification at Etherscan.io on 2022-10-25
*/

// Copyright (c) 2020-2022. All Rights Reserved
// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

/**
  * @title TrustlessMulicallRead
  * @notice Allows the caller to bundle many chain reads into a single call.
  */ 
contract TrustlessMulticallRead {
    struct ReadCall { 
        address target; 
        bytes callData; 
    }

    struct ReadResult { 
        bool success; 
        bytes returnData; 
    }

    /**
      * @notice Executes a read multicall.
      * @param calls The structured calls to make.
      * @return blockNumber The current block number used to allow the caller to determine
      *   the recency of the data returned.
      * @return results The return data from the calls, along with whether each call was successful or not.
      */ 
    function read(ReadCall[] calldata calls) external returns (
        uint256 blockNumber,
        ReadResult[] memory results
    ) {
        results = new ReadResult[](calls.length);

        for(uint256 i = 0; i < calls.length; i++) {
            (results[i].success, results[i].returnData) = calls[i].target.call(calls[i].callData);
        }

        return (block.number, results);
    }
}