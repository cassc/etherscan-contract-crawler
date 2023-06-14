// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {LSSVMPair} from "./LSSVMPair.sol";
import {LSSVMRouter} from "./LSSVMRouter.sol";
import {ILSSVMPairFactoryLike} from "./ILSSVMPairFactoryLike.sol";

/**
 * @title An NFT/Token pair where the token is an ERC20
 * @author boredGenius, 0xmons, 0xCygaar
 */
abstract contract LSSVMPairERC20 is LSSVMPair {
    using SafeTransferLib for ERC20;

    error LSSVMPairERC20__RoyaltyNotPaid();
    error LSSVMPairERC20__MsgValueNotZero();
    error LSSVMPairERC20__AssetRecipientNotPaid();

    /**
     * @notice Returns the ERC20 token associated with the pair
     * @dev See LSSVMPairCloner for an explanation on how this works
     * @dev The last 20 bytes of the immutable data contain the ERC20 token address
     */
    function token() public pure returns (ERC20 _token) {
        assembly {
            _token := shr(0x60, calldataload(sub(calldatasize(), 20)))
        }
    }

    /**
     * @inheritdoc LSSVMPair
     */
    function _pullTokenInputs(
        uint256 inputAmountExcludingRoyalty,
        uint256[] memory royaltyAmounts,
        address payable[] memory royaltyRecipients,
        uint256, /* royaltyTotal */
        uint256 tradeFeeAmount,
        bool isRouter,
        address routerCaller,
        uint256 protocolFee
    ) internal override {
        address _assetRecipient = getAssetRecipient();

        // Transfer tokens
        if (isRouter) {
            // Verify if router is allowed
            // Locally scoped to avoid stack too deep
            {
                (bool routerAllowed,) = factory().routerStatus(LSSVMRouter(payable(msg.sender)));
                if (!routerAllowed) revert LSSVMPair__NotRouter();
            }

            // Cache state and then call router to transfer tokens from user
            uint256 beforeBalance = token().balanceOf(_assetRecipient);
            LSSVMRouter(payable(msg.sender)).pairTransferERC20From(
                token(), routerCaller, _assetRecipient, inputAmountExcludingRoyalty - protocolFee
            );

            // Verify token transfer (protect pair against malicious router)
            ERC20 token_ = token();
            if (token_.balanceOf(_assetRecipient) - beforeBalance != (inputAmountExcludingRoyalty - protocolFee)) {
                revert LSSVMPairERC20__AssetRecipientNotPaid();
            }

            // Transfer royalties (if they exist)
            for (uint256 i; i < royaltyRecipients.length;) {
                beforeBalance = token_.balanceOf(royaltyRecipients[i]);
                LSSVMRouter(payable(msg.sender)).pairTransferERC20From(
                    token_, routerCaller, royaltyRecipients[i], royaltyAmounts[i]
                );
                if (token_.balanceOf(royaltyRecipients[i]) - beforeBalance != royaltyAmounts[i]) {
                    revert LSSVMPairERC20__RoyaltyNotPaid();
                }
                unchecked {
                    ++i;
                }
            }

            // Take protocol fee (if it exists)
            if (protocolFee != 0) {
                LSSVMRouter(payable(msg.sender)).pairTransferERC20From(
                    token_, routerCaller, address(factory()), protocolFee
                );
            }
        } else {
            // Transfer tokens directly (sans the protocol fee)
            ERC20 token_ = token();
            token_.safeTransferFrom(msg.sender, _assetRecipient, inputAmountExcludingRoyalty - protocolFee);

            // Transfer royalties (if they exists)
            for (uint256 i; i < royaltyRecipients.length;) {
                token_.safeTransferFrom(msg.sender, royaltyRecipients[i], royaltyAmounts[i]);
                unchecked {
                    ++i;
                }
            }

            // Take protocol fee (if it exists)
            if (protocolFee != 0) {
                token_.safeTransferFrom(msg.sender, address(factory()), protocolFee);
            }
        }
        // Send trade fee if it exists, is TRADE pool, and fee recipient != pool address
        // @dev: (note that tokens are sent from the pool and not the caller)
        if (poolType() == PoolType.TRADE && tradeFeeAmount != 0) {
            address payable _feeRecipient = getFeeRecipient();
            if (_feeRecipient != _assetRecipient) {
                token().safeTransfer(_feeRecipient, tradeFeeAmount);
            }
        }
    }

    /**
     * @inheritdoc LSSVMPair
     */
    function _refundTokenToSender(uint256 inputAmount) internal override {
        // Do nothing since we transferred the exact input amount
    }

    /**
     * @inheritdoc LSSVMPair
     */
    function _sendTokenOutput(address payable tokenRecipient, uint256 outputAmount) internal override {
        // Send tokens to caller
        if (outputAmount != 0) {
            token().safeTransfer(tokenRecipient, outputAmount);
        }
    }

    /**
     * @inheritdoc LSSVMPair
     */
    function withdrawERC20(ERC20 a, uint256 amount) external override onlyOwner {
        a.safeTransfer(msg.sender, amount);

        if (a == token()) {
            // emit event since it is the pair token
            emit TokenWithdrawal(amount);
        }
    }

    function _preCallCheck(address target) internal pure override {
        if (target == address(token())) revert LSSVMPair__TargetNotAllowed();
    }
}