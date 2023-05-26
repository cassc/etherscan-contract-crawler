// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ICollectionPool} from "./ICollectionPool.sol";
import {CollectionPool} from "./CollectionPool.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {CurveErrorCodes} from "../bonding-curves/CurveErrorCodes.sol";
import {IPoolActivityMonitor} from "./IPoolActivityMonitor.sol";
import {PoolVariant, RoyaltyDue, EventType} from "./CollectionStructsAndEnums.sol";

/**
 * @title An NFT/Token pool where the token is an ERC20
 * @author Collection
 */
abstract contract CollectionPoolERC20 is CollectionPool {
    using SafeTransferLib for ERC20;

    error ReceivedETH();
    error UnallowedRouter(CollectionRouter router);
    error RouterDidNotSend(uint256 recipientBalanceDifference, uint256 expected);
    error InsufficientERC20Liquidity(uint256 liquidity, uint256 required);

    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 85;

    /**
     * @notice Returns the ERC20 token associated with the pool
     * @dev See CollectionPoolCloner for an explanation on how this works
     */
    function token() public pure returns (ERC20 _token) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _token := shr(0x60, calldataload(add(sub(calldatasize(), paramsLength), 65)))
        }
    }

    /// @inheritdoc ICollectionPool
    function liquidity() public view returns (uint256) {
        uint256 _balance = token().balanceOf(address(this));
        uint256 _accruedTradeFee = accruedTradeFee;
        if (_balance < _accruedTradeFee) revert InsufficientLiquidity(_balance, _accruedTradeFee);

        return _balance - _accruedTradeFee;
    }

    /// @inheritdoc CollectionPool
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool isRouter,
        address routerCaller,
        ICollectionPoolFactory _factory,
        uint256 protocolFee,
        RoyaltyDue[] memory royaltiesDue
    ) internal override {
        if (msg.value != 0) revert ReceivedETH();

        ERC20 _token = token();
        PoolVariant variant = poolVariant();

        uint256 totalRoyaltiesPaid;
        uint256 royaltiesSentToFactory;

        if (isRouter) {
            // Verify if router is allowed
            CollectionRouter router = CollectionRouter(payable(msg.sender));

            (bool routerAllowed,) = _factory.routerStatus(router);
            if (!routerAllowed) revert UnallowedRouter(router);

            // Pay royalties first to obtain total amount of royalties paid
            (totalRoyaltiesPaid, royaltiesSentToFactory) = _payRoyaltiesAndProtocolFee(
                _factory, royaltiesDue, protocolFee, routerCaller, isRouter, router, variant
            );

            // Cache state and then call router to transfer tokens from user
            address _assetRecipient = getAssetRecipient();
            uint256 amountToAssetRecipient = inputAmount - protocolFee - royaltiesSentToFactory;
            sendTokenWithRouter(router, _token, routerCaller, _assetRecipient, amountToAssetRecipient, variant);
        } else {
            // Pay royalties first to obtain total amount of royalties paid
            (, royaltiesSentToFactory) = _payRoyaltiesAndProtocolFee(
                _factory,
                royaltiesDue,
                protocolFee,
                msg.sender,
                isRouter,
                CollectionRouter(payable(address(0))),
                variant
            );

            // Transfer tokens directly
            _token.safeTransferFrom(msg.sender, getAssetRecipient(), inputAmount - protocolFee - royaltiesSentToFactory);
        }
    }

    /// @inheritdoc CollectionPool
    function _refundTokenToSender(uint256 inputAmount) internal override {
        // Do nothing since we transferred the exact input amount
    }

    /// @inheritdoc CollectionPool
    function _sendTokenOutputAndPayProtocolFees(
        ICollectionPoolFactory _factory,
        address payable tokenRecipient,
        uint256 outputAmount,
        RoyaltyDue[] memory royaltiesDue,
        uint256 protocolFee
    ) internal override {
        ERC20 _token = token();

        /// @dev Pay royalties
        _payRoyaltiesAndProtocolFee(
            _factory,
            royaltiesDue,
            protocolFee,
            address(this),
            false,
            CollectionRouter(payable(address(0))),
            poolVariant()
        );

        /// @dev Send tokens to caller
        if (outputAmount > 0) {
            uint256 funds = liquidity();
            if (funds < outputAmount) revert InsufficientERC20Liquidity(funds, outputAmount);
            _token.safeTransfer(tokenRecipient, outputAmount);
        }
    }

    /**
     * @notice Pay royalties to the factory, which should never revert. The factory
     * serves as a single contract to which royalty recipients can make a single
     * transaction to receive all royalties due as opposed to having to send
     * transactions to arbitrary numbers of pools
     *
     * @dev For NFTs whose royalty recipients resolve to this contract, no royalties
     * are sent for them. This is to prevent royalties from becoming trapped in
     * the factory as pools do not have a function to withdraw royalties
     *
     * @return totalRoyaltiesPaid The amount of royalties which were paid including
     * royalties whose resolved recipient is this contract itself
     * @return royaltiesSentToFactory `totalRoyaltiesPaid` less the amount whose
     * resolved recipient is this contract itself
     */
    function _payRoyaltiesAndProtocolFee(
        ICollectionPoolFactory _factory,
        RoyaltyDue[] memory royaltiesDue,
        uint256 protocolFee,
        address tokenSender,
        bool isRouter,
        CollectionRouter router,
        PoolVariant poolVariant
    ) internal returns (uint256 totalRoyaltiesPaid, uint256 royaltiesSentToFactory) {
        ERC20 _token = token();
        /// @dev Local scope to prevent stack too deep
        {
            uint256 length = royaltiesDue.length;
            for (uint256 i = 0; i < length;) {
                uint256 royaltyAmount = royaltiesDue[i].amount;
                totalRoyaltiesPaid += royaltyAmount;
                if (royaltyAmount > 0) {
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
        }

        uint256 amountToSend = royaltiesSentToFactory + protocolFee;

        if (isRouter) {
            sendTokenWithRouter(router, _token, tokenSender, address(_factory), amountToSend, poolVariant);
        } else {
            /// @dev If tokens are being sent from this pool, just use safeTransfer
            /// to avoid making an approve call
            if (tokenSender == address(this)) {
                _token.safeTransfer(address(_factory), amountToSend);
            } else {
                _token.safeTransferFrom(tokenSender, address(_factory), amountToSend);
            }
        }

        _factory.depositRoyaltiesNotification(_token, royaltiesDue, poolVariant);
    }

    /// @inheritdoc CollectionPool
    // @dev see CollectionPoolCloner for params length calculation
    function _immutableParamsLength() internal pure override returns (uint256) {
        return IMMUTABLE_PARAMS_LENGTH;
    }

    /**
     * @dev Deposit ERC20s into pool
     */
    function depositERC20(ERC20 a, uint256 amount) external {
        assertDepositsNotPaused();
        a.safeTransferFrom(msg.sender, address(this), amount);
        if (a == token()) {
            emit TokenDeposit(nft(), a, amount);
            notifyDeposit(EventType.DEPOSIT_TOKEN, amount);
        }
    }

    /**
     * @notice Withdraws all pool token owned by the pool to the owner address.
     * @dev Only callable by the owner.
     */
    function withdrawAllERC20() external {
        requireAuthorized();
        uint256 _accruedTradeFee = accruedTradeFee;
        accruedTradeFee = 0;

        ERC20 _token = token();
        uint256 amount = _token.balanceOf(address(this));
        _token.safeTransfer(owner(), amount);

        if (_accruedTradeFee >= amount) {
            _accruedTradeFee = amount;
            amount = 0;
        } else {
            amount -= _accruedTradeFee;
        }

        // emit event since it is the pool token
        IERC721 _nft = nft();
        emit TokenWithdrawal(_nft, _token, amount);
        emit AccruedTradeFeeWithdrawal(_nft, _token, _accruedTradeFee);
    }

    /// @inheritdoc ICollectionPool
    function withdrawERC20(ERC20 a, uint256 amount) external {
        requireAuthorized();
        if (a == token()) {
            uint256 funds = liquidity();
            if (funds < amount) revert InsufficientERC20Liquidity(funds, amount);

            // emit event since it is the pool token
            emit TokenWithdrawal(nft(), a, amount);
        }

        a.safeTransfer(owner(), amount);
    }

    /// @inheritdoc CollectionPool
    function withdrawAccruedTradeFee() external override onlyOwner {
        uint256 _accruedTradeFee = accruedTradeFee;
        if (_accruedTradeFee > 0) {
            accruedTradeFee = 0;

            ERC20 _token = token();
            _token.safeTransfer(msg.sender, _accruedTradeFee);

            // emit event since it is the pool token
            emit AccruedTradeFeeWithdrawal(nft(), _token, _accruedTradeFee);
        }
    }

    /**
     * @notice Helper function that uses a router to send tokens and check that
     * the tokens were actually transferred
     */
    function sendTokenWithRouter(
        CollectionRouter router,
        ERC20 _token,
        address from,
        address to,
        uint256 amount,
        PoolVariant variant
    ) internal {
        uint256 beforeBalance = _token.balanceOf(to);
        router.poolTransferERC20From(_token, from, to, amount, variant);
        uint256 balanceDifference = _token.balanceOf(to) - beforeBalance;
        if (balanceDifference != amount) {
            revert RouterDidNotSend(balanceDifference, amount);
        }
    }
}