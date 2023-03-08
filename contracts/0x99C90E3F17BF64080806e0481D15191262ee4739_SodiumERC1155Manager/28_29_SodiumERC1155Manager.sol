// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./interfaces/ISodiumWallet.sol";
import "./SodiumManager.sol";

contract SodiumERC1155Manager is SodiumManager {
    uint256 public ERC1155Nonce;

    function onERC1155Received(
        address requester,
        address,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external nonReentrant returns (bytes4) {
        require(value == 1, "Sodium: amount is more than 1");

        uint256 requestId = uint256(keccak256(abi.encode(tokenId, msg.sender, block.timestamp, ERC1155Nonce)));
        ERC1155Nonce++;
        (uint256 loanLength, PoolRequest[] memory poolRequests) = abi.decode(data, (uint256, PoolRequest[]));

        address wallet = _executeLoanRequest(poolRequests, loanLength, requestId, tokenId, requester, msg.sender);
        IERC1155(msg.sender).safeTransferFrom(address(this), wallet, tokenId, 1, "");

        return this.onERC1155Received.selector;
    }

    function _transferCollateral(
        address tokenAddress,
        uint256 tokenId,
        address from,
        address to
    ) internal override {
        ISodiumWallet(from).transferERC1155(to, tokenAddress, tokenId);
    }
}