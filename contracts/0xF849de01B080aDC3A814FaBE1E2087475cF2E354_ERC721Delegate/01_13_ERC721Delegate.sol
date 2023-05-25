// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import './MarketConsts.sol';
import './IDelegate.sol';

contract ERC721Delegate is IDelegate, AccessControl, IERC721Receiver {
    bytes32 public constant DELEGATION_CALLER = keccak256('DELEGATION_CALLER');

    struct Pair {
        IERC721 token;
        uint256 tokenId;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function decode(bytes calldata data) internal pure returns (Pair[] memory) {
        return abi.decode(data, (Pair[]));
    }

    function delegateType() external view returns (uint256) {
        // return uint256(Market.DelegationType.ERC721);
        return 1;
    }

    function executeSell(
        address seller,
        address buyer,
        bytes calldata data
    ) external onlyRole(DELEGATION_CALLER) returns (bool) {
        Pair[] memory pairs = decode(data);
        for (uint256 i = 0; i < pairs.length; i++) {
            Pair memory p = pairs[i];
            p.token.safeTransferFrom(seller, buyer, p.tokenId);
        }
        return true;
    }

    function executeBuy(
        address seller,
        address buyer,
        bytes calldata data
    ) external onlyRole(DELEGATION_CALLER) returns (bool) {
        Pair[] memory pairs = decode(data);
        for (uint256 i = 0; i < pairs.length; i++) {
            Pair memory p = pairs[i];
            p.token.safeTransferFrom(seller, buyer, p.tokenId);
        }
        return true;
    }

    function executeBid(
        address seller,
        address previousBidder,
        address, // bidder,
        bytes calldata data
    ) external onlyRole(DELEGATION_CALLER) returns (bool) {
        if (previousBidder == address(0)) {
            Pair[] memory pairs = decode(data);
            for (uint256 i = 0; i < pairs.length; i++) {
                Pair memory p = pairs[i];
                p.token.safeTransferFrom(seller, address(this), p.tokenId);
            }
        }
        return true;
    }

    function executeAuctionComplete(
        address, // seller,
        address buyer,
        bytes calldata data
    ) external onlyRole(DELEGATION_CALLER) returns (bool) {
        Pair[] memory pairs = decode(data);
        for (uint256 i = 0; i < pairs.length; i++) {
            Pair memory p = pairs[i];
            p.token.safeTransferFrom(address(this), buyer, p.tokenId);
        }
        return true;
    }

    function executeAuctionRefund(
        address seller,
        address, // lastBidder,
        bytes calldata data
    ) external onlyRole(DELEGATION_CALLER) returns (bool) {
        Pair[] memory pairs = decode(data);
        for (uint256 i = 0; i < pairs.length; i++) {
            Pair memory p = pairs[i];
            p.token.safeTransferFrom(address(this), seller, p.tokenId);
        }
        return true;
    }

    function transferBatch(Pair[] memory pairs, address to) public {
        for (uint256 i = 0; i < pairs.length; i++) {
            Pair memory p = pairs[i];
            p.token.safeTransferFrom(msg.sender, to, p.tokenId);
        }
    }
}