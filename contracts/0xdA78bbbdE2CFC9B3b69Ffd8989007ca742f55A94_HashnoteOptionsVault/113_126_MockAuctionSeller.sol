// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { IERC20 } from "../../lib/openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC1155 } from "../../lib/openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC1155Receiver } from "../../lib/openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import { IBatchAuction } from "../interfaces/IBatchAuction.sol";
import { IBatchAuctionSeller } from "../interfaces/IBatchAuctionSeller.sol";

contract MockAuctionSeller is IBatchAuctionSeller {
    address payable auctionAddress;
    address tokenAddress;
    address optionTokenAddress;

    event Novate(address recipient, uint256 amount, uint256[] options, uint256[] counterparty);

    event SettledAuction(uint256 auctionId, uint256 totalSold, int256 clearingPrice);

    constructor(address payable _auctionAddress, address payable _tokenAddress, address _optionTokenAddress) {
        auctionAddress = _auctionAddress;
        tokenAddress = _tokenAddress;
        optionTokenAddress = _optionTokenAddress;
    }

    function createAuction(
        address optionTokenAddr,
        uint256[] calldata optionTokens,
        address biddingToken,
        IBatchAuction.Collateral[] calldata collaterals,
        int96 minPrice,
        uint64 minBidSize,
        uint64 totalSize,
        uint256 endTime,
        address whitelist
    ) public {
        IBatchAuction(auctionAddress).createAuction(
            optionTokenAddr, optionTokens, biddingToken, collaterals, minPrice, minBidSize, totalSize, endTime, whitelist
        );
    }

    function settledAuction(uint256 auctionId, uint256 totalSold, int256 clearingPrice) external override {
        emit SettledAuction(auctionId, totalSold, clearingPrice);
    }

    function novate(address recipient, uint256 amount, uint256[] calldata options, uint256[] calldata counterparty)
        external
        override
    {
        IERC1155 optionToken = IERC1155(optionTokenAddress);
        // convert to batch!
        for (uint256 i; i < options.length;) {
            uint256 tokenId = options[i];

            if (optionToken.balanceOf(address(this), tokenId) >= amount) {
                optionToken.safeTransferFrom(address(this), recipient, tokenId, amount, bytes(""));
            }

            unchecked {
                ++i;
            }
        }

        emit Novate(recipient, amount, options, counterparty);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function approve(address addr, uint256 quantity) external {
        IERC20(tokenAddress).approve(addr, quantity);
    }

    receive() external payable { }
}