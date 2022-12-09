// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

error NewOwnerNotModuleAdmin(address newOwner);
error RequestExpired(uint256 startStamp, uint256 endStamp, uint256 nowStamp);
error CallerIsNotOwnerOrApproved(address sender, uint256 tokenId);
error AccessControl();
error AlreadyMinted(bytes32 uid);
error MintChoicesMinted();