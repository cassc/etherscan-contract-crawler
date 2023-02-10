// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from './imports/IERC721.sol';
import {ILSSVMRouter} from './ILSSVMRouter.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';

contract RouterMulticall is ERC721Holder {
    struct MultiSwap {
        ILSSVMRouter.PairSwapSpecific[] swapList;
        ILSSVMRouter router;
        uint256 value;
    }
    struct MultiTrade {
        ILSSVMRouter.RobustPairNFTsFoTokenAndTokenforNFTsTrade params;
        ILSSVMRouter router;
        uint256 value;
    }

    function swapNFTsForToken(
        MultiSwap calldata firstMultiSwap,
        MultiSwap calldata secondMultiSwap,
        address tokenRecipient,
        uint256 deadline
    ) external returns (uint256 firstOutputValue, uint256 secondOutputValue) {
        uint256 numSwaps = firstMultiSwap.swapList.length;
        for (uint256 i; i < numSwaps; ) {
            ILSSVMRouter.PairSwapSpecific memory swapList = firstMultiSwap
                .swapList[i];
            IERC721 nft = swapList.pair.nft();
            uint256 numNfts = swapList.nftIds.length;
            for (uint256 j; j < numNfts; ) {
                nft.safeTransferFrom(
                    msg.sender,
                    address(this),
                    swapList.nftIds[j]
                );
                address router = address(firstMultiSwap.router);
                nft.setApprovalForAll(router, true);
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        uint256 numSwaps2 = secondMultiSwap.swapList.length;
        for (uint256 i; i < numSwaps2; ) {
            ILSSVMRouter.PairSwapSpecific memory swapList = secondMultiSwap
                .swapList[i];
            IERC721 nft = swapList.pair.nft();
            uint256 numNfts = swapList.nftIds.length;
            for (uint256 j; j < numNfts; ) {
                nft.safeTransferFrom(
                    msg.sender,
                    address(this),
                    swapList.nftIds[j]
                );
                address router = address(secondMultiSwap.router);
                nft.setApprovalForAll(router, true);
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        firstOutputValue = firstMultiSwap.router.swapNFTsForToken(
            firstMultiSwap.swapList,
            firstMultiSwap.value,
            tokenRecipient,
            deadline
        );
        secondOutputValue = secondMultiSwap.router.swapNFTsForToken(
            secondMultiSwap.swapList,
            secondMultiSwap.value,
            tokenRecipient,
            deadline
        );
    }

    function swapETHForSpecificNFTs(
        MultiSwap calldata firstMultiSwap,
        MultiSwap calldata secondMultiSwap,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    )
        external
        payable
        returns (uint256 firstRemainingValue, uint256 secondRemainingValue)
    {
        firstRemainingValue = firstMultiSwap.router.swapETHForSpecificNFTs{
            value: firstMultiSwap.value
        }(firstMultiSwap.swapList, ethRecipient, nftRecipient, deadline);
        secondRemainingValue = secondMultiSwap.router.swapETHForSpecificNFTs{
            value: firstMultiSwap.value
        }(secondMultiSwap.swapList, ethRecipient, nftRecipient, deadline);
    }

    function robustSwapETHForSpecificNFTsAndNFTsToToken(
        MultiTrade calldata firstTrade,
        MultiTrade calldata secondTrade
    )
        external
        payable
        returns (
            uint256 firstRemainingValue,
            uint256 secondRemainingValue,
            uint256 firstOutputAmount,
            uint256 secondOutputAmount
        )
    {
        uint256 numSwaps = firstTrade.params.nftToTokenTrades.length;
        for (uint256 i; i < numSwaps; ) {
            ILSSVMRouter.PairSwapSpecific memory swapList = firstTrade
                .params
                .nftToTokenTrades[i]
                .swapInfo;
            IERC721 nft = swapList.pair.nft();
            uint256 numNfts = swapList.nftIds.length;
            for (uint256 j; j < numNfts; ) {
                nft.safeTransferFrom(
                    msg.sender,
                    address(this),
                    swapList.nftIds[j]
                );
                address router = address(firstTrade.router);
                nft.setApprovalForAll(router, true);
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        uint256 numSwaps2 = secondTrade.params.nftToTokenTrades.length;
        for (uint256 i; i < numSwaps2; ) {
            ILSSVMRouter.PairSwapSpecific memory swapList = secondTrade
                .params
                .nftToTokenTrades[i]
                .swapInfo;
            IERC721 nft = swapList.pair.nft();
            uint256 numNfts = swapList.nftIds.length;
            for (uint256 j; j < numNfts; ) {
                nft.safeTransferFrom(
                    msg.sender,
                    address(this),
                    swapList.nftIds[j]
                );
                address router = address(secondTrade.router);
                nft.setApprovalForAll(router, true);
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        (firstRemainingValue, firstOutputAmount) = firstTrade
            .router
            .robustSwapETHForSpecificNFTsAndNFTsToToken{
            value: firstTrade.params.inputAmount
        }(firstTrade.params);
        (secondRemainingValue, secondOutputAmount) = secondTrade
            .router
            .robustSwapETHForSpecificNFTsAndNFTsToToken{
            value: secondTrade.params.inputAmount
        }(secondTrade.params);
    }

    receive() external payable {}
}