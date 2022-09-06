// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./MarketConsts.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IX2Y2Run {
    function run(Market.RunInput memory input) external payable;
}

library X2Y2Market {
    address public constant X2Y2EXCHANGE =
        0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3;

    struct Pair {
        IERC721 token;
        uint256 tokenId;
    }

    function run(Market.RunInput memory input) external {
        bytes memory _data = abi.encodeWithSelector(
            IX2Y2Run.run.selector,
            input
        );

        uint totalPrice;

        for (uint i = 0; i < input.details.length; i++) {
            totalPrice += input.details[i].price;
        }

        // for (uint i = 0; i < input.orders.length; i++) {
        //     for (uint j = 0; j < input.orders[i].items.length; j++) {
        //         totalPrice += input.orders[i].items[j].price;
        //     }
        // }

        (bool success, ) = X2Y2EXCHANGE.call{value: totalPrice}(_data);

        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        } else {
            //transfering NFTs

            bytes memory tokenInfo = input
                .orders[input.details[0].orderIdx]
                .items[input.details[0].itemIdx]
                .data;

            // uint[] memory detailsIndexes; //index orders
            // uint[] memory detailsItemIndexes; //index items
            // for (uint i = 0; i < input.details.length; i++) {
            //     detailsIndexes[i] = input.details[i].orderIdx;
            //     detailsItemIndexes[i] = input.details[i].itemIdx;
            // }
            // for (uint i = 0; i < detailsIndexes.length; i++) {
            //     bytes memory nftInfo = input
            //         .orders[detailsIndexes[i]]
            //         .items[detailsItemIndexes[i]]
            //         .data;
            Pair[] memory pairs = abi.decode(tokenInfo, (Pair[]));
            for (uint256 k = 0; k < pairs.length; k++) {
                Pair memory p = pairs[k];
                p.token.safeTransferFrom(address(this), msg.sender, p.tokenId);
            }

            // for (uint i = 0; i < input.orders.length; i++) {
            //     for (uint j = 0; j < input.orders[i].items.length; j++) {
            //         bytes memory tokenInfo = input.orders[i].items[j].data;

            //         Pair[] memory pairs = abi.decode(tokenInfo, (Pair[]));

            //         for (uint256 k = 0; k < pairs.length; k++) {
            //             Pair memory p = pairs[k];
            //             p.token.safeTransferFrom(
            //                 address(this),
            //                 msg.sender,
            //                 p.tokenId
            //             );
            //         }
            //     }
            // }
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}