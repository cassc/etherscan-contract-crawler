// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "../Orderer.sol";

contract TestOrderer is Orderer {
    function calculateInternalSwapShares(
        address sellAccount,
        address buyAccount,
        SwapDetails memory _details,
        uint _sellOrderShares,
        uint _buyOrderShares
    ) external returns (uint248 _sellShares, uint248 _buyShares) {
        return _calculateInternalSwapShares(sellAccount, buyAccount, _details, _sellOrderShares, _buyOrderShares);
    }
}