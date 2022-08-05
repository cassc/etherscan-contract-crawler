// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import {IERC1155NTErrors} from "../interfaces/IERC1155NTErrors.sol";

/// @title Dopamine non-transferable ERC-1155 contract
/// @notice This is a minimal ERC-1155 implementation that does not support
///  transfers outside of minting, throwing in all such cases.
contract ERC1155NT is IERC1155, IERC1155NTErrors {

    /// @notice Gets for an address the number of NFTs owned of a specific type.
    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    /// @notice EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC1155_INTERFACE_ID = 0xd9b67a26;
    bytes4 private constant _ERC1155_METADATA_INTERFACE_ID = 0x0e89341c;

    /// @notice Transfers an NFT from a source to a destination address.
    ///  WARNING: This will always throw as transfers are unsupported.
    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual {
        revert TokenNonTransferable();
    }

    /// @notice Transfers multiple NFTs from a source to a destination address.
    ///  WARNING: This will always throw as transfers are unsupported.
    function safeBatchTransferFrom(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual {
        revert TokenNonTransferable();
    }

    /// @notice Retrieves balances of multiple account / NFT type pairs.
    /// @param owners List of NFT owner addresses.
    /// @param ids List of ids of NFT types.
    /// @return balances List of balances corresponding to the owner / id pairs.
    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        if (owners.length != ids.length) {
            revert ArityMismatch();
        }

        balances = new uint256[](owners.length);
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /// @notice Checks if an operator is an authorized operator for an owner.
    ///  WARNING: This will always return false as operators are unsupported.
    function isApprovedForAll(address, address)
        external
        view
        virtual
        returns (bool)
    {
        return false;
    }

    /// @notice Sets the operator for the sender address.
    ///  WARNING: This will always throw as operators are unsupported.
    function setApprovalForAll(address, bool) public virtual {
        revert TokenNonTransferable();
    }

    /// @notice Checks if interface of identifier `id` is supported.
    /// @param id The ERC-165 interface identifier.
    /// @return True if interface id `id` is supported, False otherwise.
    function supportsInterface(bytes4 id) public pure virtual returns (bool) {
        return
            id == _ERC165_INTERFACE_ID ||
            id == _ERC1155_INTERFACE_ID ||
            id == _ERC1155_METADATA_INTERFACE_ID;
    }

    /// @notice Mints NFT of type `id` to address `to`.
    /// @param to Address receiving the minted NFT.
    /// @param id The id of the NFT type being minted.
    function _mint(address to, uint256 id) internal virtual {
        if (balanceOf[to][id] == 1) {
            revert TokenAlreadyMinted();
        }
        balanceOf[to][id] = 1;
        emit TransferSingle(msg.sender, address(0), to, id, 1);

        if (
            to.code.length != 0 &&
            IERC1155Receiver(to).onERC1155Received(
                msg.sender,
                address(0),
                id,
                1,
                ""
            ) !=
            IERC1155Receiver.onERC1155Received.selector
        ) {
            revert SafeTransferUnsupported();
        } else if (to == address(0)) {
            revert ReceiverInvalid();
        }
    }
}