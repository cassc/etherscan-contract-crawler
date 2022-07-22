// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721BaseController } from "./base/IERC721BaseController.sol";
import { IERC721ApprovableController } from "./approvable/IERC721ApprovableController.sol";
import { IERC721TransferableController } from "./transferable/IERC721TransferableController.sol";

/**
 * @title Partial ERC721 interface required by controller functions
 */
interface IERC721Controller is
    IERC721TransferableController,
    IERC721ApprovableController,
    IERC721BaseController
{}