// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ICollectionPool} from "./ICollectionPool.sol";
import {CollectionPool} from "./CollectionPool.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {IPoolActivityMonitor} from "./IPoolActivityMonitor.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {RoyaltyDue, EventType} from "./CollectionStructsAndEnums.sol";

/**
 * @title An NFT/Token pool where the token is ETH
 * @author Collection
 */
abstract contract CollectionPoolETH is CollectionPool {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 65;

    /// @inheritdoc ICollectionPool
    function liquidity() public view returns (uint256) {
        uint256 _balance = address(this).balance;
        uint256 _accruedTradeFee = accruedTradeFee;
        if (_balance < _accruedTradeFee) revert InsufficientLiquidity(_balance, _accruedTradeFee);

        return _balance - _accruedTradeFee;
    }

    /// @inheritdoc CollectionPool
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool, /*isRouter*/
        address, /*routerCaller*/
        ICollectionPoolFactory _factory,
        uint256 protocolFee,
        RoyaltyDue[] memory royaltiesDue
    ) internal override {
        require(msg.value >= inputAmount, "Sent too little ETH");

        // Pay royalties first to obtain total amount of royalties paid
        (uint256 totalRoyaltiesPaid,) = _payRoyaltiesAndProtocolFee(_factory, royaltiesDue, protocolFee);

        // Transfer inputAmount ETH to assetRecipient if it's been set
        address payable _assetRecipient = getAssetRecipient();
        if (_assetRecipient != address(this)) {
            _assetRecipient.safeTransferETH(inputAmount - protocolFee - totalRoyaltiesPaid);
        }
    }

    /// @inheritdoc CollectionPool
    function _refundTokenToSender(uint256 inputAmount) internal override {
        // Give excess ETH back to caller
        if (msg.value > inputAmount) {
            payable(msg.sender).safeTransferETH(msg.value - inputAmount);
        }
    }

    /**
     * @notice Pay royalties to the factory, which should never revert. The factory
     * serves as a single contract to which royalty recipients can make a single
     * transaction to receive all royalties due as opposed to having to send
     * transactions to arbitrary numbers of pools
     *
     * In addition, pay protocol fees in the same transfer since both go to factory
     *
     * @return totalRoyaltiesPaid The amount of royalties which were paid including
     * royalties whose resolved recipient is this contract itself
     * @return royaltiesSentToFactory `totalRoyaltiesPaid` less the amount whose
     * resolved recipient is this contract itself
     */
    function _payRoyaltiesAndProtocolFee(
        ICollectionPoolFactory _factory,
        RoyaltyDue[] memory royaltiesDue,
        uint256 protocolFee
    ) internal returns (uint256 totalRoyaltiesPaid, uint256 royaltiesSentToFactory) {
        /// @dev For ETH pools, calculate how much to send in total since factory
        /// can't call safeTransferFrom.
        uint256 length = royaltiesDue.length;
        for (uint256 i = 0; i < length;) {
            uint256 royaltyAmount = royaltiesDue[i].amount;
            if (royaltyAmount > 0) {
                totalRoyaltiesPaid += royaltyAmount;
                address finalRecipient = getRoyaltyRecipient(payable(royaltiesDue[i].recipient));
                if (finalRecipient != address(this)) {
                    royaltiesSentToFactory += royaltyAmount;
                    royaltiesDue[i].recipient = finalRecipient;
                }
            }

            unchecked {
                ++i;
            }
        }

        _factory.depositRoyaltiesNotification{value: royaltiesSentToFactory + protocolFee}(
            ERC20(address(0)), royaltiesDue, poolVariant()
        );
    }

    /// @inheritdoc CollectionPool
    function _sendTokenOutputAndPayProtocolFees(
        ICollectionPoolFactory _factory,
        address payable tokenRecipient,
        uint256 outputAmount,
        RoyaltyDue[] memory royaltiesDue,
        uint256 protocolFee
    ) internal override {
        /// @dev Pay royalties and protocol fee
        _payRoyaltiesAndProtocolFee(_factory, royaltiesDue, protocolFee);

        /// @dev Send ETH to caller
        if (outputAmount > 0) {
            require(liquidity() >= outputAmount, "Too little ETH");
            tokenRecipient.safeTransferETH(outputAmount);
        }
    }

    /// @inheritdoc CollectionPool
    // @dev see CollectionPoolCloner for params length calculation
    function _immutableParamsLength() internal pure override returns (uint256) {
        return IMMUTABLE_PARAMS_LENGTH;
    }

    /**
     * @notice Withdraws all token owned by the pool to the owner address.
     * @dev Only callable by the owner.
     */
    function withdrawAllETH() external {
        requireAuthorized();
        uint256 _accruedTradeFee = accruedTradeFee;
        accruedTradeFee = 0;

        uint256 amount = address(this).balance;
        payable(owner()).safeTransferETH(amount);

        if (_accruedTradeFee >= amount) {
            _accruedTradeFee = amount;
            amount = 0;
        } else {
            amount -= _accruedTradeFee;
        }

        // emit event since ETH is the pool token
        IERC721 _nft = nft();
        emit TokenWithdrawal(_nft, ERC20(address(0)), amount);
        emit AccruedTradeFeeWithdrawal(_nft, ERC20(address(0)), _accruedTradeFee);
    }

    /**
     * @notice Withdraws a specified amount of token owned by the pool to the owner address.
     * @dev Only callable by the owner.
     * @param amount The amount of token to send to the owner. If the pool's balance is less than
     * this value, the transaction will be reverted.
     */
    function withdrawETH(uint256 amount) external {
        requireAuthorized();
        require(liquidity() >= amount, "Too little ETH");

        payable(owner()).safeTransferETH(amount);

        // emit event since ETH is the pool token
        emit TokenWithdrawal(nft(), ERC20(address(0)), amount);
    }

    /// @inheritdoc ICollectionPool
    function withdrawERC20(ERC20 a, uint256 amount) external {
        requireAuthorized();
        a.safeTransfer(owner(), amount);
    }

    /// @inheritdoc CollectionPool
    function withdrawAccruedTradeFee() external override onlyOwner {
        uint256 _accruedTradeFee = accruedTradeFee;
        if (_accruedTradeFee > 0) {
            accruedTradeFee = 0;

            payable(owner()).safeTransferETH(_accruedTradeFee);

            // emit event since ETH is the pool token
            emit AccruedTradeFeeWithdrawal(nft(), ERC20(address(0)), _accruedTradeFee);
        }
    }

    /**
     * @dev All ETH transfers into the pool are accepted. This is the main method
     * for the owner to top up the pool's token reserves.
     */
    receive() external payable {
        assertDepositsNotPaused();
        emit TokenDeposit(nft(), ERC20(address(0)), msg.value);
        notifyDeposit(EventType.DEPOSIT_TOKEN, msg.value);
    }

    /**
     * @dev All ETH transfers into the pool are accepted. This is the main method
     * for the owner to top up the pool's token reserves.
     */
    fallback() external payable {
        assertDepositsNotPaused();
        // Only allow calls without function selector
        require(msg.data.length == _immutableParamsLength());
        emit TokenDeposit(nft(), ERC20(address(0)), msg.value);
        notifyDeposit(EventType.DEPOSIT_TOKEN, msg.value);
    }
}