// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
// Invalid operation. tokenId is banned.
// @param addr sent address of collection.
// @param tokenId sent tokenId belongs to the collection.
error TokenIsBanned(address collection, uint256 tokenId);
// Invalid operation. tokenId is not banned.
// @param addr sent address of collection.
// @param tokenId sent tokenId belongs to the collection.
error TokenIsNotBanned(address collection, uint256 tokenId);
// Invalid operation. Transfers on collection are not enabled.
// @param collection sent address of collection.
error TransferIsNotEnabled(address collection);
// Invalid operation. Transfers on collection are enabled.
// @param collection sent address of collection.
error TransferIsEnabled(address collection);
// Invalid operation. tranferControllers is empty.
error TransferControllerIsEmpty();
// Invalid operation. Not valid controller.
// @param controller sent address of IGMTransferController.
error NotValidTransferController(address controller);