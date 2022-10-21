// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {Recoverable} from "../../../util/Recoverable.sol";
import {ArbitraryCall} from "../../../util/ArbitraryCall.sol";
import {SendUtils} from "../../../util/SendUtils.sol";

interface SudoswapInterface {
    struct PairSwapSpecific {
        address pair;
        uint256[] nftIds;
    }

    struct RobustPairSwapSpecific {
        PairSwapSpecific swapInfo;
        uint256 maxCost;
    }

    function robustSwapETHForSpecificNFTs(
        RobustPairSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    )
        external
        payable
        returns (uint256);
}

contract GenieSudoswapMarket is Recoverable, ArbitraryCall {

    address public constant SUDOSWAP_ROUTER = 0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329;

    function robustSwapETHForSpecificNFTs(
        SudoswapInterface.RobustPairSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    )
        external
        payable
    {
        try SudoswapInterface(SUDOSWAP_ROUTER).robustSwapETHForSpecificNFTs{value: address(this).balance}(
            swapList,
            ethRecipient,
            nftRecipient,
            deadline
        ) {} catch {}
        SendUtils._returnAllEth();
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}