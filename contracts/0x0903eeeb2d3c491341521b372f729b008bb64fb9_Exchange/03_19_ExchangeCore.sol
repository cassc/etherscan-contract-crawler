// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ExchangeAdmin.sol";
import "./lib/Validator.sol";
import "./lib/TransferManager.sol";
import "./lib/DataStruct.sol";

/// @title Core contract with major exchange logic
contract ExchangeCore is ExchangeAdmin, Validator, TransferManager {
    /// @notice The method responsible for exchanging assets
    /// @param sellOrder Order struct created by seller
    /// @param sellOrderSignature sellOrder signed by seller private key
    /// @param buyOrder Order struct created by buyer
    /// @param buyOrderSignature buyOrder signed by buyer private key
    /// @dev buyOrderSignature can be null in case of fixed order sell since the msg.sender will be present
    function matchOrders(
        DataStruct.Order memory sellOrder,
        bytes memory sellOrderSignature,
        DataStruct.Order memory buyOrder,
        bytes memory buyOrderSignature
    ) external payable whenNotPaused {
        validateFull(
            sellOrder,
            sellOrderSignature,
            buyOrder,
            buyOrderSignature
        );

        manageOrderTransfer(
            sellOrder.offeredAsset,
            sellOrder.expectedAsset,
            sellOrder.offerer,
            buyOrder.offerer,
            sellOrder.data
        );
    }
}