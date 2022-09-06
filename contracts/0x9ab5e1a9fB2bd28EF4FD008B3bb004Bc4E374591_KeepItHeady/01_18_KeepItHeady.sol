// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Single.sol";

contract KeepItHeady is Single {
    constructor(
        address _zoraAsksV1_1,
        address _zoraTransferHelper,
        address _zoraModuleManager
    ) Single(_zoraAsksV1_1, _zoraTransferHelper, _zoraModuleManager) {
        mint();
    }

    /// @notice Exclusive sales mechanism for Keep it Heady using Zora V3 Module (Asks V1.1)
    function listForSale() public {
        _createAsk(tokenId);
    }
}