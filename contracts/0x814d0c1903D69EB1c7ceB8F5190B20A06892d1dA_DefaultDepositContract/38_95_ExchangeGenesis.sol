// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../../lib/MathUint.sol";
import "../../iface/ExchangeData.sol";
import "../../iface/IAgentRegistry.sol";
import "../../iface/IBlockVerifier.sol";
import "../../iface/ILoopringV3.sol";
import "./ExchangeTokens.sol";


/// @title ExchangeGenesis.
/// @author Daniel Wang  - <[email protected]>
/// @author Brecht Devos - <[email protected]>
library ExchangeGenesis
{
    using ExchangeTokens    for ExchangeData.State;

    event ExchangeGenesisBlockInitialized(
        address loopringAddr,
        bytes32 genesisMerkleRoot,
        bytes32 genesisMerkleAssetRoot,
        bytes32 domainSeparator
    );

    function initializeGenesisBlock(
        ExchangeData.State storage S,
        address _loopringAddr,
        bytes32 _genesisMerkleRoot,
        bytes32 _genesisMerkleAssetRoot,
        bytes32 _domainSeparator
        )
        public
    {
        require(address(0) != _loopringAddr, "INVALID_LOOPRING_ADDRESS");
        require(_genesisMerkleRoot != 0, "INVALID_GENESIS_MERKLE_ROOT");
        require(_genesisMerkleAssetRoot != 0, "INVALID_GENESIS_MERKLE_ASSET_ROOT");

        S.maxAgeDepositUntilWithdrawable = ExchangeData.MAX_AGE_DEPOSIT_UNTIL_WITHDRAWABLE_UPPERBOUND;
        S.DOMAIN_SEPARATOR = _domainSeparator;

        ILoopringV3 loopring = ILoopringV3(_loopringAddr);
        S.loopring = loopring;

        S.blockVerifier = IBlockVerifier(loopring.blockVerifierAddress());

        S.merkleRoot = _genesisMerkleRoot;
        S.merkleAssetRoot = _genesisMerkleAssetRoot;
        S.blocks[0] = ExchangeData.BlockInfo(uint32(block.timestamp), bytes28(0));
        S.numBlocks = 1;

        // Get the protocol fees for this exchange
        S.protocolFeeData.syncedAt = uint32(0);

        S.protocolFeeData.protocolFeeBips = S.loopring.protocolFeeBips();
        S.protocolFeeData.previousProtocolFeeBips = S.protocolFeeData.protocolFeeBips;

        S.protocolFeeData.nextProtocolFeeBips = S.protocolFeeData.protocolFeeBips;
        S.protocolFeeData.executeTimeOfNextProtocolFeeBips = uint32(0);

        // Call these after the main state has been set up
        S.registerToken(address(0), true);
        S.registerToken(loopring.lrcAddress(), true);

        emit ExchangeGenesisBlockInitialized(_loopringAddr, _genesisMerkleRoot, _genesisMerkleAssetRoot, _domainSeparator);
    }
}