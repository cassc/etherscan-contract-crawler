// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;


/**
 * @title KeydonixOracleAbstract
 **/
abstract contract KeydonixOracleAbstract {

    uint public constant Q112 = 2 ** 112;

    struct ProofDataStruct {
        bytes block;
        bytes accountProofNodesRlp;
        bytes reserveAndTimestampProofNodesRlp;
        bytes priceAccumulatorProofNodesRlp;
    }

    function assetToUsd(
        address asset,
        uint amount,
        ProofDataStruct memory proofData
    ) public virtual view returns (uint);
}