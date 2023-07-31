// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {LSSVMPair} from "./LSSVMPair.sol";
import {ILSSVMPairFactoryLike} from "./ILSSVMPairFactoryLike.sol";

/**
 * @title An NFT/Token pair where the token is ETH
 * @author boredGenius, 0xmons, 0xCygaar
 */
abstract contract LSSVMPairETH is LSSVMPair {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    error LSSVMPairETH__InsufficientInput();

    /**
     * @inheritdoc LSSVMPair
     */
    function _pullTokenInputs(
        uint256 inputAmountExcludingRoyalty,
        uint256[] memory royaltyAmounts,
        address payable[] memory royaltyRecipients,
        uint256 royaltyTotal,
        uint256 tradeFeeAmount,
        bool, /*isRouter*/
        address, /*routerCaller*/
        uint256 protocolFee
    ) internal override {
        // Require that the input amount is sufficient to pay for the sale amount, royalties, and fees
        if (msg.value < (royaltyTotal + inputAmountExcludingRoyalty)) revert LSSVMPairETH__InsufficientInput();

        // Transfer inputAmountExcludingRoyalty ETH to assetRecipient if it has been set
        address payable _assetRecipient = getAssetRecipient();

        // Attempt to transfer trade fees only if TRADE pool and they exist
        if (poolType() == PoolType.TRADE && tradeFeeAmount != 0) {
            address payable _feeRecipient = getFeeRecipient();

            // Only send and deduct tradeFeeAmount if the fee recipient is not the asset recipient (i.e. the pool)
            if (_feeRecipient != _assetRecipient) {
                inputAmountExcludingRoyalty -= tradeFeeAmount;
                _feeRecipient.safeTransferETH(tradeFeeAmount);
            }
            // In the else case, we would want to ensure that inputAmountExcludingRoyalty >= tradeFeeAmount / 2
            // to avoid underpaying the trade fee, but it is always true because the max royalty
            // is 25%, the max protocol fee is 10%, and the max trade fee is 50%, meaning they can
            // never add up to more than 100%.
        }

        if (_assetRecipient != address(this)) {
            _assetRecipient.safeTransferETH(inputAmountExcludingRoyalty - protocolFee);
        }

        // Transfer royalties
        for (uint256 i; i < royaltyRecipients.length;) {
            royaltyRecipients[i].safeTransferETH(royaltyAmounts[i]);
            unchecked {
                ++i;
            }
        }

        // Take protocol fee
        if (protocolFee != 0) {
            payable(address(factory())).safeTransferETH(protocolFee);
        }
    }

    /**
     * @inheritdoc LSSVMPair
     */
    function _refundTokenToSender(uint256 inputAmount) internal override {
        // Give excess ETH back to caller
        if (msg.value > inputAmount) {
            payable(msg.sender).safeTransferETH(msg.value - inputAmount);
        }
    }

    /**
     * @inheritdoc LSSVMPair
     */
    function _sendTokenOutput(address payable tokenRecipient, uint256 outputAmount) internal override {
        // Send ETH to caller
        if (outputAmount != 0) {
            tokenRecipient.safeTransferETH(outputAmount);
        }
    }

    /**
     * @notice Withdraws all token owned by the pair to the owner address.
     * @dev Only callable by the owner.
     */
    function withdrawAllETH() external onlyOwner {
        withdrawETH(address(this).balance);
    }

    /**
     * @notice Withdraws a specified amount of token owned by the pair to the owner address.
     * @dev Only callable by the owner.
     * @param amount The amount of token to send to the owner. If the pair's balance is less than
     * this value, the transaction will be reverted.
     */
    function withdrawETH(uint256 amount) public onlyOwner {
        payable(msg.sender).safeTransferETH(amount);

        // emit event since ETH is the pair token
        emit TokenWithdrawal(amount);
    }

    /**
     * @inheritdoc LSSVMPair
     */
    function withdrawERC20(ERC20 a, uint256 amount) external override onlyOwner {
        a.safeTransfer(msg.sender, amount);
    }

    /**
     * @dev All ETH transfers into the pair are accepted. This is the main method
     * for the owner to top up the pair's token reserves.
     */
    receive() external payable {
        emit TokenDeposit(msg.value);
    }

    /**
     * @dev All ETH transfers into the pair are accepted. This is the main method
     * for the owner to top up the pair's token reserves.
     */
    fallback() external payable {
        // Only allow calls without function selector
        require(msg.data.length == _immutableParamsLength());
        emit TokenDeposit(msg.value);
    }

    function _preCallCheck(address) internal pure override {}
}