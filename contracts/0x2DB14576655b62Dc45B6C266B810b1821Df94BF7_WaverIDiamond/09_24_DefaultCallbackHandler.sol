// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

import "../interfaces/ERC1155TokenReceiver.sol";
import "../interfaces/ERC721TokenReceiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {VoteProposalLib} from "../libraries/VotingStatusLib.sol";

/// @title Default Callback Handler - returns true for known token callbacks
/// @author Richard Meissner - <[email protected]>
contract DefaultCallbackHandler is ERC1155TokenReceiver, ERC721TokenReceiver, IERC165 {

function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external view override returns (bytes4) {
        VoteProposalLib.enforceMarried();
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external view override returns (bytes4) {
        VoteProposalLib.enforceMarried();
        return 0xbc197c81;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external view override returns (bytes4) {
        VoteProposalLib.enforceMarried();
        return 0x150b7a02;
    }
    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == type(ERC1155TokenReceiver).interfaceId ||
            interfaceId == type(ERC721TokenReceiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}