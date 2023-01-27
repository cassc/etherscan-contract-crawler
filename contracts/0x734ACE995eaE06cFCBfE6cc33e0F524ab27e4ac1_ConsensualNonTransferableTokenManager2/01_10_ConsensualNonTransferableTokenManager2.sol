// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../utils/Ownable.sol";
import "./InterfaceSupportEditionsTokenManager.sol";
import "./interfaces/IPostTransfer.sol";
import "./interfaces/IPostBurn.sol";
import "./interfaces/ITokenManagerEditions.sol";

/**
 * @author [email protected]
 * @notice A basic token manager that prevents transfers unless 
        recipient is nft contract owner, and allows burns. Second version
 */
contract ConsensualNonTransferableTokenManager2 is
    ITokenManagerEditions,
    IPostTransfer,
    IPostBurn,
    InterfaceSupportEditionsTokenManager
{
    /**
     * @notice See {ITokenManager-canUpdateMetadata}
     */
    function canUpdateMetadata(
        address sender,
        uint256, /* id */
        bytes calldata /* newTokenImageUri */
    ) external view override returns (bool) {
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @notice See {ITokenManagerEditions-canUpdateEditionsMetadata}
     */
    function canUpdateEditionsMetadata(
        address editionsAddress,
        address sender,
        uint256, /* editionId */
        bytes calldata, /* newTokenImageUri */
        FieldUpdated /* fieldUpdated */
    ) external view override returns (bool) {
        return Ownable(editionsAddress).owner() == sender;
    }

    /**
     * @notice See {ITokenManager-canSwap}
     */
    function canSwap(
        address sender,
        uint256, /* id */
        address /* newTokenManager */
    ) external view override returns (bool) {
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @notice See {ITokenManager-canRemoveItself}
     */
    function canRemoveItself(
        address sender,
        uint256 /* id */
    ) external view override returns (bool) {
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @notice See {IPostTransfer-postSafeTransferFrom}
     */
    function postSafeTransferFrom(
        address, /* operator */
        address, /* from */
        address to,
        uint256, /* id */
        bytes memory /* data */
    ) external view override {
        if (to != Ownable(msg.sender).owner()) {
            revert("Transfers disallowed");
        }
    }

    /**
     * @notice See {IPostTransfer-postTransferFrom}
     */
    function postTransferFrom(
        address, /* operator */
        address, /* from */
        address to,
        uint256 /* id */
    ) external view override {
        if (to != Ownable(msg.sender).owner()) {
            revert("Transfers disallowed");
        }
    }

    /* solhint-disable no-empty-blocks */
    /**
     * @notice See {IPostBurn-postBurn}
     */
    function postBurn(
        address, /* operator */
        address, /* sender */
        uint256 /* id */
    ) external pure override {}

    /* solhint-enable no-empty-blocks */

    /**
     * @notice See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(InterfaceSupportEditionsTokenManager)
        returns (bool)
    {
        return
            interfaceId == type(IPostTransfer).interfaceId ||
            interfaceId == type(IPostBurn).interfaceId ||
            InterfaceSupportEditionsTokenManager.supportsInterface(interfaceId);
    }
}