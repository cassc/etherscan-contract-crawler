// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./SodiumManager.sol";
import "./interfaces/ISodiumWallet.sol";

contract SodiumERC721Manager is SodiumManager {
    function onERC721Received(
        address requester,
        address,
        uint256 tokenId,
        bytes memory data
    ) external nonReentrant returns (bytes4) {
        uint256 requestId = uint256(
            keccak256(abi.encode(tokenId, msg.sender, block.timestamp)) // Block timestamp included in ID hash to ensure subsequent same-collateral loans have distinct IDs
        );

        (uint256 loanLength, PoolRequest[] memory poolRequests) = abi.decode(data, (uint256, PoolRequest[]));

        address wallet = _executeLoanRequest(poolRequests, loanLength, requestId, tokenId, requester, msg.sender);
        IERC721(msg.sender).safeTransferFrom(address(this), wallet, tokenId);

        return this.onERC721Received.selector;
    }

    function _transferCollateral(
        address tokenAddress,
        uint256 tokenId,
        address from,
        address to
    ) internal override {
        ISodiumWallet(from).transferERC721(to, tokenAddress, tokenId);
    }
}