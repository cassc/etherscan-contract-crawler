// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ExchangeV2Core.sol";
import "../transfer-manager/GhostMarketTransferManager.sol";

contract ExchangeV2 is ExchangeV2Core, GhostMarketTransferManager {
    function __ExchangeV2_init(
        address _transferProxy,
        address _erc20TransferProxy,
        uint newProtocolFee,
        address newDefaultFeeReceiver,
        IRoyaltiesProvider newRoyaltiesProvider
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __TransferExecutor_init_unchained(_transferProxy, _erc20TransferProxy);
        __GhostMarketTransferManager_init_unchained(newProtocolFee, newDefaultFeeReceiver, newRoyaltiesProvider);
        __OrderValidator_init_unchained();
    }
}