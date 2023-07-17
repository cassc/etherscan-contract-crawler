// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import {LSSVMPair} from "../LSSVMPair.sol";
import {LSSVMRouter} from "../LSSVMRouter.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {ILSSVMPairFactoryLike} from "../ILSSVMPairFactoryLike.sol";
import {IPropertyChecker} from "../property-checking/IPropertyChecker.sol";

/**
 * @title LSSVMPairERC721
 * @author boredGenius, 0xmons, 0xCygaar
 * @notice An NFT/Token pair for an ERC721 NFT
 */
abstract contract LSSVMPairERC721 is LSSVMPair {
    error LSSVMPairERC721__PropertyCheckFailed();
    error LSSVMPairERC721__NeedPropertyChecking();

    /**
     * External state-changing functions
     */

    /**
     * @inheritdoc LSSVMPair
     */
    function swapTokenForSpecificNFTs(
        uint256[] calldata nftIds,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable virtual override returns (uint256) {
        // Store locally to remove extra calls
        factory().openLock();

        // Input validation
        {
            PoolType _poolType = poolType();
            if (_poolType == PoolType.TOKEN) revert LSSVMPair__WrongPoolType();
            if (nftIds.length == 0) revert LSSVMPair__ZeroSwapAmount();
        }

        // Call bonding curve for pricing information
        uint256 protocolFee;
        uint256 tradeFee;
        uint256 inputAmountExcludingRoyalty;
        (tradeFee, protocolFee, inputAmountExcludingRoyalty) =
            _calculateBuyInfoAndUpdatePoolParams(nftIds.length, bondingCurve(), factory());

        // Calculate royalties
        (address payable[] memory royaltyRecipients, uint256[] memory royaltyAmounts, uint256 royaltyTotal) =
            _calculateRoyalties(nftIds[0], inputAmountExcludingRoyalty - protocolFee - tradeFee);

        // Revert if the input amount is too large
        if (royaltyTotal + inputAmountExcludingRoyalty > maxExpectedTokenInput) {
            revert LSSVMPair__DemandedInputTooLarge();
        }

        _pullTokenInputs({
            inputAmountExcludingRoyalty: inputAmountExcludingRoyalty,
            royaltyAmounts: royaltyAmounts,
            royaltyRecipients: royaltyRecipients,
            royaltyTotal: royaltyTotal,
            tradeFeeAmount: 2 * tradeFee,
            isRouter: isRouter,
            routerCaller: routerCaller,
            protocolFee: protocolFee
        });

        {
            _sendSpecificNFTsToRecipient(IERC721(nft()), nftRecipient, nftIds);
        }

        _refundTokenToSender(royaltyTotal + inputAmountExcludingRoyalty);

        factory().closeLock();

        emit SwapNFTOutPair(royaltyTotal + inputAmountExcludingRoyalty, nftIds);

        return (royaltyTotal + inputAmountExcludingRoyalty);
    }

    /**
     * @inheritdoc LSSVMPair
     */
    function swapNFTsForToken(
        uint256[] calldata nftIds,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller
    ) external virtual override returns (uint256 outputAmount) {
        if (propertyChecker() != address(0)) revert LSSVMPairERC721__NeedPropertyChecking();

        return _swapNFTsForToken(nftIds, minExpectedTokenOutput, tokenRecipient, isRouter, routerCaller);
    }

    /**
     * @notice Sends a set of NFTs to the pair in exchange for token
     * @dev To compute the amount of token to that will be received, call bondingCurve.getSellInfo.
     * @param nftIds The list of IDs of the NFTs to sell to the pair
     * @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
     * amount is less than this value, the transaction will be reverted.
     * @param tokenRecipient The recipient of the token output
     * @param isRouter True if calling from LSSVMRouter, false otherwise. Not used for
     * ETH pairs.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pairs.
     * @param propertyCheckerParams Parameters to pass into the pair's underlying property checker
     * @return outputAmount The amount of token received
     */
    function swapNFTsForToken(
        uint256[] calldata nftIds,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller,
        bytes calldata propertyCheckerParams
    ) external virtual returns (uint256 outputAmount) {
        if (!IPropertyChecker(propertyChecker()).hasProperties(nftIds, propertyCheckerParams)) {
            revert LSSVMPairERC721__PropertyCheckFailed();
        }

        return _swapNFTsForToken(nftIds, minExpectedTokenOutput, tokenRecipient, isRouter, routerCaller);
    }

    /**
     * View functions
     */

    /**
     * @notice Returns the property checker address
     */
    function propertyChecker() public pure returns (address _propertyChecker) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _propertyChecker := shr(0x60, calldataload(add(sub(calldatasize(), paramsLength), 61)))
        }
    }

    /**
     * Internal functions
     */

    function _swapNFTsForToken(
        uint256[] calldata nftIds,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller
    ) internal virtual returns (uint256 outputAmount) {
        // Store locally to remove extra calls
        ILSSVMPairFactoryLike _factory = factory();

        _factory.openLock();

        // Input validation
        {
            PoolType _poolType = poolType();
            if (_poolType == PoolType.NFT) revert LSSVMPair__WrongPoolType();
            if (nftIds.length == 0) revert LSSVMPair__ZeroSwapAmount();
        }

        // Call bonding curve for pricing information
        uint256 protocolFee;
        (protocolFee, outputAmount) = _calculateSellInfoAndUpdatePoolParams(nftIds.length, bondingCurve(), _factory);

        // Compute royalties
        (address payable[] memory royaltyRecipients, uint256[] memory royaltyAmounts, uint256 royaltyTotal) =
            _calculateRoyalties(nftIds[0], outputAmount);

        // Deduct royalties from outputAmount
        unchecked {
            // Safe because we already require outputAmount >= royaltyTotal in calculateRoyalties()
            outputAmount -= royaltyTotal;
        }

        if (outputAmount < minExpectedTokenOutput) revert LSSVMPair__OutputTooSmall();

        _takeNFTsFromSender(IERC721(nft()), nftIds, _factory, isRouter, routerCaller);

        _sendTokenOutput(tokenRecipient, outputAmount);
        for (uint256 i; i < royaltyRecipients.length;) {
            _sendTokenOutput(royaltyRecipients[i], royaltyAmounts[i]);
            unchecked {
                ++i;
            }
        }

        _sendTokenOutput(payable(address(_factory)), protocolFee);

        _factory.closeLock();

        emit SwapNFTInPair(outputAmount, nftIds);
    }

    /**
     * @notice Sends specific NFTs to a recipient address
     * @dev Even though we specify the NFT address here, this internal function is only
     * used to send NFTs associated with this specific pool.
     * @param _nft The address of the NFT to send
     * @param nftRecipient The receiving address for the NFTs
     * @param nftIds The specific IDs of NFTs to send
     */
    function _sendSpecificNFTsToRecipient(IERC721 _nft, address nftRecipient, uint256[] calldata nftIds)
        internal
        virtual
    {
        // Send NFTs to recipient
        uint256 numNFTs = nftIds.length;
        for (uint256 i; i < numNFTs;) {
            _nft.transferFrom(address(this), nftRecipient, nftIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Takes NFTs from the caller and sends them into the pair's asset recipient
     * @dev This is used by the LSSVMPair's swapNFTForToken function.
     * @param _nft The NFT collection to take from
     * @param nftIds The specific NFT IDs to take
     * @param isRouter True if calling from LSSVMRouter, false otherwise. Not used for ETH pairs.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for ETH pairs.
     */
    function _takeNFTsFromSender(
        IERC721 _nft,
        uint256[] calldata nftIds,
        ILSSVMPairFactoryLike _factory,
        bool isRouter,
        address routerCaller
    ) internal virtual {
        {
            address _assetRecipient = getAssetRecipient();
            uint256 numNFTs = nftIds.length;

            if (isRouter) {
                // Verify if router is allowed
                LSSVMRouter router = LSSVMRouter(payable(msg.sender));
                (bool routerAllowed,) = _factory.routerStatus(router);
                if (!routerAllowed) revert LSSVMPair__NotRouter();

                // Call router to pull NFTs
                // If more than 1 NFT is being transfered, and there is no property checker, we can do a balance check
                // instead of an ownership check, as pools are indifferent between NFTs from the same collection
                if ((numNFTs > 1) && (propertyChecker() == address(0))) {
                    uint256 beforeBalance = _nft.balanceOf(_assetRecipient);
                    for (uint256 i; i < numNFTs;) {
                        router.pairTransferNFTFrom(_nft, routerCaller, _assetRecipient, nftIds[i]);

                        unchecked {
                            ++i;
                        }
                    }
                    if (_nft.balanceOf(_assetRecipient) - beforeBalance != numNFTs) {
                        revert LSSVMPair__NftNotTransferred();
                    }
                }
                // Otherwise we need to pull each asset 1 at a time and verify ownership
                else {
                    for (uint256 i; i < numNFTs;) {
                        router.pairTransferNFTFrom(_nft, routerCaller, _assetRecipient, nftIds[i]);
                        if (_nft.ownerOf(nftIds[i]) != _assetRecipient) revert LSSVMPair__NftNotTransferred();
                        unchecked {
                            ++i;
                        }
                    }
                }
            } else {
                // Pull NFTs directly from sender
                for (uint256 i; i < numNFTs;) {
                    _nft.transferFrom(msg.sender, _assetRecipient, nftIds[i]);
                    unchecked {
                        ++i;
                    }
                }
            }
        }
    }

    /**
     * Owner functions
     */

    /**
     * @notice Rescues a specified set of NFTs owned by the pair to the owner address. (onlyOwner modifier is in the implemented function)
     * @param a The NFT to transfer
     * @param nftIds The list of IDs of the NFTs to send to the owner
     */
    function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external virtual override onlyOwner {
        uint256 numNFTs = nftIds.length;
        for (uint256 i; i < numNFTs;) {
            a.safeTransferFrom(address(this), msg.sender, nftIds[i]);
            unchecked {
                ++i;
            }
        }

        if (a == IERC721(nft())) {
            emit NFTWithdrawal(nftIds);
        }
    }

    /**
     * @notice Rescues ERC1155 tokens from the pair to the owner. Only callable by the owner.
     * @param a The NFT to transfer
     * @param ids The NFT ids to transfer
     * @param amounts The amounts of each id to transfer
     */
    function withdrawERC1155(IERC1155 a, uint256[] calldata ids, uint256[] calldata amounts)
        external
        virtual
        override
        onlyOwner
    {
        a.safeBatchTransferFrom(address(this), msg.sender, ids, amounts, "");
    }
}