// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./CompoundStrategy.sol";
import "../../interfaces/token/IToken.sol";

// solhint-disable no-empty-blocks
/// @title Deposit ETH/WETH in Compound and earn interest.
contract CompoundStrategyETH is CompoundStrategy {
    constructor(
        address _pool,
        address _swapManager,
        address _comptroller,
        address _rewardToken,
        address _receiptToken,
        string memory _name
    ) CompoundStrategy(_pool, _swapManager, _comptroller, _rewardToken, _receiptToken, _name) {}

    /// @dev Only receive ETH from either cToken or WETH
    receive() external payable {
        require(msg.sender == address(cToken) || msg.sender == WETH, "not-allowed-to-send-ether");
    }

    /**
     * @dev This hook get called after collateral is redeemed from Compound
     * Vesper deals in WETH as collateral so convert ETH to WETH
     */
    function _afterRedeem() internal override {
        TokenLike(WETH).deposit{value: address(this).balance}();
    }

    /**
     * @dev During reinvest we have WETH as collateral but Compound accepts ETH.
     * Withdraw ETH from WETH before calling mint in Compound.
     */
    function _reinvest() internal override {
        uint256 _collateralBalance = collateralToken.balanceOf(address(this));
        if (_collateralBalance != 0) {
            TokenLike(WETH).withdraw(_collateralBalance);
            cToken.mint{value: _collateralBalance}();
        }
    }
}