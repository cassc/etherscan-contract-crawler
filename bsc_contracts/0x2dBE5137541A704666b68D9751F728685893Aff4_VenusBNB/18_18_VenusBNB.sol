// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Venus.sol";
import "vesper-pools/contracts/interfaces/token/IToken.sol";

// solhint-disable no-empty-blocks
/// @title Deposit BNB/WBNB in Venus and earn interest.
contract VenusBNB is Venus {
    address internal constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    constructor(
        address pool_,
        address swapper_,
        address comptroller_,
        address rewardToken_,
        address receiptToken_,
        string memory name_
    ) Venus(pool_, swapper_, comptroller_, rewardToken_, receiptToken_, name_) {}

    /// @dev Only receive BNB from either Venus Token or WBNB
    receive() external payable {
        require(msg.sender == address(cToken) || msg.sender == WBNB, "not-allowed-to-send-ether");
    }

    /**
     * @dev This hook get called after collateral is redeemed from Venus
     * Vesper deals in WBNB as collateral so convert BNB to WBNB
     */
    function _afterRedeem() internal override {
        TokenLike(WBNB).deposit{value: address(this).balance}();
    }

    /**
     * @dev During reinvest we have WBNB as collateral but Venus accepts BNB.
     * Withdraw BNB from WBNB before calling mint in Venus.
     */
    function _deposit(uint256 _amount) internal override {
        if (_amount > 0) {
            TokenLike(WBNB).withdraw(_amount);
            cToken.mint{value: _amount}();
        }
    }
}