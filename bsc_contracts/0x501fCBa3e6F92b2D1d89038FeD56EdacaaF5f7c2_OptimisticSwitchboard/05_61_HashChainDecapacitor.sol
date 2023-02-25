// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/IDecapacitor.sol";
import "../libraries/RescueFundsLib.sol";
import "../utils/Ownable.sol";

contract HashChainDecapacitor is IDecapacitor, Ownable(msg.sender) {
    /// returns if the packed message is the part of a merkle tree or not
    /// @inheritdoc IDecapacitor
    function verifyMessageInclusion(
        bytes32 root_,
        bytes32 packedMessage_,
        bytes calldata proof_
    ) external pure override returns (bool) {
        bytes32[] memory chain = abi.decode(proof_, (bytes32[]));
        uint256 len = chain.length;
        bytes32 generatedRoot;
        bool isIncluded;
        for (uint256 i = 0; i < len; i++) {
            generatedRoot = keccak256(abi.encode(generatedRoot, chain[i]));
            if (chain[i] == packedMessage_) isIncluded = true;
        }

        return root_ == generatedRoot && isIncluded;
    }

    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) external onlyOwner {
        RescueFundsLib.rescueFunds(token_, userAddress_, amount_);
    }
}