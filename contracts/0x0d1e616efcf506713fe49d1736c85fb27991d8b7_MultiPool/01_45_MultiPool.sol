// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {LSSVMPair} from "../LSSVMPair.sol";
import {LSSVMPairFactory} from "../LSSVMPairFactory.sol";

contract MultiPool {
    LSSVMPairFactory immutable factory;

    constructor(LSSVMPairFactory _factory) {
        factory = _factory;
    }

    function createBulk1155Pools(
        LSSVMPairFactory.CreateERC1155ERC20PairParams[]
            calldata pairCreationArgs,
        // We expect token amounts to be 0 in the above params, and instead use the value submitted here for consistency
        uint256[] calldata tokenAmounts,
        bool isETH
    ) external payable returns (address[] memory) {
        address[] memory pairs = new address[](pairCreationArgs.length);

        // Set approval (assuming only for 1 address at a time)
        pairCreationArgs[0].nft.setApprovalForAll(address(factory), true);

        if (!isETH) {
            // Create all pools
            for (uint256 i; i < pairCreationArgs.length; ) {
                LSSVMPairFactory.CreateERC1155ERC20PairParams
                    memory params = pairCreationArgs[i];

                // Deposit assets from caller into pools
                params.nft.safeTransferFrom(
                    msg.sender,
                    address(this),
                    params.nftId,
                    params.initialNFTBalance,
                    ""
                );

                LSSVMPair pair = factory.createPairERC1155ERC20(params);

                // Transfer ownership to caller
                pair.transferOwnership(msg.sender, "");

                // Transfer tokens to pair
                if (tokenAmounts[i] > 0) {
                    params.token.transferFrom(
                        msg.sender,
                        address(pair),
                        tokenAmounts[i]
                    );
                }

                pairs[i] = address(pair);
                unchecked {
                    ++i;
                }
            }
        } else {
            for (uint256 i; i < pairCreationArgs.length; ) {
                LSSVMPairFactory.CreateERC1155ERC20PairParams
                    memory params = pairCreationArgs[i];

                // Deposit assets from caller into pools
                params.nft.safeTransferFrom(
                    msg.sender,
                    address(this),
                    params.nftId,
                    params.initialNFTBalance,
                    ""
                );

                // Create pairs with eth
                LSSVMPair pair = factory.createPairERC1155ETH{
                    value: tokenAmounts[i]
                }(
                    params.nft,
                    params.bondingCurve,
                    params.assetRecipient,
                    params.poolType,
                    params.delta,
                    params.fee,
                    params.spotPrice,
                    params.nftId,
                    params.initialNFTBalance
                );

                // Transfer ownership to caller
                pair.transferOwnership(msg.sender, "");

                pairs[i] = address(pair);
                unchecked {
                    ++i;
                }
            }
        }

        // Set approval (assuming only for 1 address at a time)
        pairCreationArgs[0].nft.setApprovalForAll(address(factory), false);

        return pairs;
    }

    function onERC1155Received(address , address from, uint256 , uint256 amount, bytes memory data)
        public
        returns (bytes4)
    {
        return this.onERC1155Received.selector;
    }
}