// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin-contracts/contracts/access/Ownable.sol";

import "../interfaces/IFeeManager.sol";

/**
 * @title FeeManager
 * @dev A fee manager contract designed to handle fees within the box
 */
contract FeeManager is IFeeManager, Ownable {
    uint256 public fee;
    uint256 public commissionBPS;

    /**
     * @dev Sets initial values for {fee} and {commissionBPS}.
     * @param _fee a flat fee, denominated in NATIVE, for transactions going through the box
     * @param _commissionBPS a bp fee, denominated in NATIVE, for transactions going through the box
     */
    constructor(uint256 _fee, uint256 _commissionBPS) {
        fee = _fee;
        commissionBPS = _commissionBPS;
    }

    /**
     * @dev allows owner to update the values for {fee} and {commissionBPS}.
     * @param _fee a flat fee, denominated in native, for transactions going through the box
     * @param _commissionBPS a bp fee, denominated in native, for transactions going through the box
     */
    function setFees(uint256 _fee, uint256 _commissionBPS) external onlyOwner {
        fee = _fee;
        commissionBPS = _commissionBPS;
    }

    /**
     * @dev calculates the bp fee on a transaction
     * @param amountIn The amount of native or erc20 being transferred.
     * @param tokenIn The address of the token being transferred, zero address for native currency.
     */
    function _calculateCommission(uint256 amountIn, address tokenIn) private view returns (uint256) {
        return commissionBPS == 0 || tokenIn != address(0) ? 0 : (amountIn * commissionBPS / 100_00);
    }

    /**
     * @dev calculates flat fee and bp fee for transaction, returns a tuple for both values
     * @param amountIn The amount of native or erc20 being transferred.
     * @param tokenIn The address of the token being transferred, zero address for native currency.
     */
    function calculateFees(uint256 amountIn, address tokenIn)
        external
        view
        returns (uint256 fees, uint256 commission)
    {
        return (fee, _calculateCommission(amountIn, tokenIn));
    }

    /**
     * @dev allows controller of feemanager to redeem fees
     */
    function redeemFees() external onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    receive() external payable {}
}