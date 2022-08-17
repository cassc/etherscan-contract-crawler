// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../Earn.sol";
import "../Vesper.sol";

/// @notice This strategy will deposit collateral in a Vesper Grow Pool and converts the yield to another Drip Token
// solhint-disable no-empty-blocks
contract VesperEarn is Vesper, Earn {
    constructor(
        address pool_,
        address swapper_,
        address receiptToken_,
        address dripToken_,
        address vsp_,
        string memory name_
    ) Vesper(pool_, swapper_, receiptToken_, vsp_, name_) Earn(dripToken_) {}

    function _approveToken(uint256 amount_) internal virtual override(Strategy, Vesper) {
        super._approveToken(amount_);
    }

    function _rebalance()
        internal
        override(Strategy, Vesper)
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        )
    {
        (_profit, , _payback) = _generateReport();
        _handleProfit(_profit);
        _profit = 0;
        IVesperPool(pool).reportEarning(_profit, _loss, _payback);
        _deposit();
    }
}