// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./StakeManager.sol";

contract PoolStakeManager is StakeManager {
    modifier _maxTokensMintedCheck(uint256 maxTokensMinted) override {
        _;
        require(
            token.balanceOf(address(this)) - tvl >= maxTokensMinted - expectedTokensIssued,
            "PoolStakeManager: Balance too low for the distributable amount"
        );
    }

    function _withdrawMethod(address recipient, uint256 amount) internal virtual override {
        require(token.transfer(recipient, amount), "PoolStakeManager: Cannot make transfer");
    }

    function _exitWithdraw(uint256 withdrawn, uint256 totalAmount) internal override {
        totalAmount;
        require(token.transfer(msg.sender, withdrawn), "PoolStakeManager: Cannot make transfer");
    }

    function withdrawLiquidity(uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            maxTokensIssued - amount >= expectedTokensIssued,
            "PoolStakeManager: Cannot withdraw more than necessary for staking"
        );
        require(token.transfer(msg.sender, amount), "PoolStakeManager: Cannot make transfer");
        maxTokensIssued -= amount;
    }

    uint256[50] private gap;
}