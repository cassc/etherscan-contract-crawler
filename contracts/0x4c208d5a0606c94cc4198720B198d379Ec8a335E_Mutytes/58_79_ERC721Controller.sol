// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721Controller } from "./IERC721Controller.sol";
import { ERC721BaseController } from "./base/ERC721BaseController.sol";
import { ERC721ApprovableController } from "./approvable/ERC721ApprovableController.sol";
import { ERC721TransferableController } from "./transferable/ERC721TransferableController.sol";

abstract contract ERC721Controller is
    IERC721Controller,
    ERC721BaseController,
    ERC721ApprovableController,
    ERC721TransferableController
{}