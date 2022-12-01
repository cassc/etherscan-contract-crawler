// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../access/ACL.sol";
import "../access/Roles.sol";

contract MinimalWallet is ACL, Roles, ERC721Holder, ERC1155Holder {
    using SafeERC20 for IERC20;

    enum Protocol {
        ETH,
        ERC20,
        ERC721,
        ERC1155
    }

    struct TransferNote {
        Protocol protocol;
        address token;
        uint256[] ids;
        uint256[] amounts;
    }

    struct ApprovalNote {
        Protocol protocol;
        address token;
        address[] operators;
    }

    error WithdrawFailed();
    error InvalidArrayLength();

    ////////////////////////////////////////////////////
    // External functions //////////////////////////////
    ////////////////////////////////////////////////////

    // @notice Withdraw an array of assets
    // @dev Works for ETH, ERC20s, ERC721s, and ERC1155s
    // @param notes A tuple that contains the protocol id, token address, array of ids and amounts
    function withdraw(TransferNote[] memory notes) external isPermitted(OWNER_ROLE) {
        TransferNote memory note;
        Protocol protocol;
        uint256[] memory ids;
        uint256[] memory amounts;

        uint256 length = notes.length;
        for (uint256 i; i < length; ) {
            note = notes[i];
            protocol = note.protocol;
            if (protocol == Protocol.ETH) {
                amounts = note.amounts;
                if (amounts.length != 1) revert InvalidArrayLength();
                _withdrawETH(amounts[0]);
            } else if (protocol == Protocol.ERC20) {
                amounts = note.amounts;
                if (amounts.length != 1) revert InvalidArrayLength();
                _withdrawERC20(IERC20(note.token), amounts[0]);
            } else if (protocol == Protocol.ERC721) {
                ids = note.ids;
                _withdrawERC721s(IERC721(note.token), ids);
            } else if (protocol == Protocol.ERC1155) {
                ids = note.ids;
                amounts = note.amounts;
                _withdrawERC1155s(IERC1155(note.token), ids, amounts);
            }
            unchecked { ++i; }
        }
    }

    // @notice Withdraw ETH from this contract to the msg.sender
    // @param amount The amount of ETH to be withdrawn
    function withdrawETH(uint256 amount) external isPermitted(OWNER_ROLE) {
        _withdrawETH(amount);
    }

    // @notice Withdraw ERC20s
    // @param erc20s An array of erc20 addresses
    // @param amounts An array of amounts for each erc20
    function withdrawERC20s(
        IERC20[] memory erc20s,
        uint256[] memory amounts
    ) external isPermitted(OWNER_ROLE) {
        uint256 length = erc20s.length;
        if (amounts.length != length) revert InvalidArrayLength();
        for (uint256 i; i < length; ) {
            _withdrawERC20(erc20s[i], amounts[i]);
            unchecked { ++i; }
        }
    }

    // @notice Withdraw multiple ERC721 ids for a single ERC721 contract
    // @param erc721 The address of the ERC721 contract
    // @param ids An array of ids that are to be withdrawn
    function withdrawERC721s(
        IERC721 erc721,
        uint256[] memory ids
    ) external isPermitted(OWNER_ROLE) {
        _withdrawERC721s(erc721, ids);
    }

    // @notice Withdraw multiple ERC1155 ids for a single ERC1155 contract
    // @param erc1155 The address of the ERC155 contract
    // @param ids An array of ids that are to be withdrawn
    // @param amounts An array of amounts per id
    function withdrawERC1155s(
        IERC1155 erc1155,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external isPermitted(OWNER_ROLE) {
        _withdrawERC1155s(erc1155, ids, amounts);
    }

    // @notice Revoke approval on an array of assets and operators
    // @dev Works for ERC20s, ERC721s, and ERC1155s
    // @param notes A tuple that contains the protocol id, token address, and array of operators
    function revokeApprovals(ApprovalNote[] memory notes) external isPermitted(OWNER_ROLE) {
        ApprovalNote memory note;
        Protocol protocol;

        uint256 length = notes.length;
        for (uint256 i; i < length; ) {
            note = notes[i];
            protocol = note.protocol;
            if (protocol == Protocol.ERC20) {
                _revokeERC20Approvals(IERC20(note.token), note.operators);
            } else if (protocol == Protocol.ERC721) {
                _revokeERC721Approvals(IERC721(note.token), note.operators);
            } else if (protocol == Protocol.ERC1155) {
                _revokeERC1155Approvals(IERC1155(note.token), note.operators);
            }
            unchecked { ++i; }
        }
    }

    // @notice Revoke approval of an ERC20 for an array of operators
    // @param erc20 The address of the ERC20 token
    // @param operators The array of operators to have approval revoked
    function revokeERC20Approvals(
        IERC20 erc20,
        address[] memory operators
    ) external isPermitted(OWNER_ROLE) {
        _revokeERC20Approvals(erc20, operators);
    }

    // @notice Revoke approval of an ERC721 for an array of operators
    // @param erc721 The address of the ERC721 token
    // @param operators The array of operators to have approval revoked
    function revokeERC721Approvals(
        IERC721 erc721,
        address[] memory operators
    ) external isPermitted(OWNER_ROLE) {
        _revokeERC721Approvals(erc721, operators);
    }

    // @notice Revoke approval of an ERC1155 for an array of operators
    // @param erc1155 The address of the ERC1155 token
    // @param operators The array of operators to have approval revoked
    function revokeERC1155Approvals(
        IERC1155 erc1155,
        address[] memory operators
    ) external isPermitted(OWNER_ROLE) {
        _revokeERC1155Approvals(erc1155, operators);
    }

    ////////////////////////////////////////////////////
    // Internal functions //////////////////////////////
    ////////////////////////////////////////////////////

    function _withdrawETH(uint256 amount) internal {
        (bool success, ) = msg.sender.call{ value : amount }("");
        if (!success) revert WithdrawFailed();
    }

    function _withdrawERC20(
        IERC20 erc20,
        uint256 amount
    ) internal {
        erc20.safeTransfer(msg.sender, amount);
    }

    function _withdrawERC721s(
        IERC721 erc721,
        uint256[] memory ids
    ) internal {
        uint256 length = ids.length;
        for (uint256 i; i < length; ) {
            erc721.safeTransferFrom(address(this), msg.sender, ids[i]);
            unchecked { ++i; }
        }
    }

    function _withdrawERC1155s(
        IERC1155 erc1155,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        // safeBatchTransferFrom will validate the array lengths
        erc1155.safeBatchTransferFrom(address(this), msg.sender, ids, amounts, "");
    }

    function _revokeERC20Approvals(
        IERC20 erc20,
        address[] memory operators
    ) internal {
        uint256 length = operators.length;
        for (uint256 i; i < length; ) {
            erc20.safeApprove(operators[i], 0);
            unchecked { ++i; }
        }
    }

    function _revokeERC721Approvals(
        IERC721 erc721,
        address[] memory operators
    ) internal {
        uint256 length = operators.length;
        for (uint256 i; i < length; ) {
            erc721.setApprovalForAll(operators[i], false);
            unchecked { ++i; }
        }
    }

    function _revokeERC1155Approvals(
        IERC1155 erc1155,
        address[] memory operators
    ) internal {
        uint256 length = operators.length;
        for (uint256 i; i < length; ) {
            erc1155.setApprovalForAll(operators[i], false);
            unchecked { ++i; }
        }
    }

    ////////////////////////////////////////////////////
    // Fallback functions //////////////////////////////
    ////////////////////////////////////////////////////

    receive() external payable {}
}