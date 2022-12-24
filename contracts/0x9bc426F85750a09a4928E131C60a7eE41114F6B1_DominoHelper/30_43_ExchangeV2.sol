// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./ExchangeV2Core.sol";
import "../domino/DominoTransferManager.sol";

contract ExchangeV2 is ExchangeV2Core, DominoTransferManager {
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
        __DominoTransferManager_init_unchained(newProtocolFee, newDefaultFeeReceiver, newRoyaltiesProvider);
        __OrderValidator_init_unchained();
    }

    function getProtocolFee() internal override view returns(uint) {
        return protocolFee;
    }
}