// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "../../interfaces/modules/beforeTransfer/I721BeforeTransfersModule.sol";

contract OpenSeaCreatorFeeFilter721 is DefaultOperatorFilterer, I721BeforeTransfersModule {
    /// @notice Restricts NFT sales from marketplaces that do not enforce creator fees via OpenSea operator filter registry
    /// @dev see https://github.com/ProjectOpenSea/operator-filter-registry
    /// @param sender original tx sender
    /// @param from holder fo token being transferred
    function beforeTokenTransfers(
        address sender,
        address from,
        address, /*to*/
        uint256, /*startTokenId*/
        uint256 /*quantity*/
    ) external view {
        // https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/OperatorFilterer.sol#L37
        // logic from OS modifier
        if (from != sender) {
            _checkFilterOperator(sender);
        }
    }
}