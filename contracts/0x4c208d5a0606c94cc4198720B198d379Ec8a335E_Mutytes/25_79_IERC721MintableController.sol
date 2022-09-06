// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721TransferableController } from "../transferable/IERC721TransferableController.sol";

/**
 * @title Partial ERC721 interface required by controller functions
 */
interface IERC721MintableController is IERC721TransferableController {}