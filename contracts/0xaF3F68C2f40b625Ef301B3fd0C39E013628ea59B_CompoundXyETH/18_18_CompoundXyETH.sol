// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./CompoundXy.sol";

// solhint-disable no-empty-blocks
/// @title Deposit ETH/WETH in Compound and earn interest.
contract CompoundXyETH is CompoundXy {
    constructor(
        address _pool,
        address _swapper,
        address _comptroller,
        address _rewardToken,
        address _receiptToken,
        address _borrowCToken,
        string memory _name
    ) CompoundXy(_pool, _swapper, _comptroller, _rewardToken, _receiptToken, _borrowCToken, _name) {}

    /// @dev Unwrap ETH and supply in Compound
    function _mintX(uint256 _amount) internal override {
        if (_amount > 0) {
            TokenLike(WETH).withdraw(_amount);
            supplyCToken.mint{value: _amount}();
        }
    }

    /// @dev Withdraw ETH from Compound and Wrap those as WETH
    function _redeemX(uint256 _amount) internal override {
        super._redeemX(_amount);
        TokenLike(WETH).deposit{value: address(this).balance}();
    }
}