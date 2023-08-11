// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import { ISimpleVaultTransferLlamaEthLP } from './ISimpleVaultTransferLlamaEthLP.sol';
import { SimpleVaultInternal } from './SimpleVaultInternal.sol';

contract SimpleVaultTransferLlamaEthLP is
    SimpleVaultInternal,
    ISimpleVaultTransferLlamaEthLP
{
    constructor(
        address feeRecipient,
        address dawnOfInsrt
    ) SimpleVaultInternal(feeRecipient, dawnOfInsrt) {}

    /**
     * @inheritdoc ISimpleVaultTransferLlamaEthLP
     */
    function transfer_llamaEthLP(uint256 amount) external onlyProtocolOwner {
        _transferLlamaEthLP(amount);
    }
}