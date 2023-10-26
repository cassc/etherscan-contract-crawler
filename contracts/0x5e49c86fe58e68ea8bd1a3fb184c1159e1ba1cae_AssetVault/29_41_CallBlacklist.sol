// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

//solhint-disable max-line-length

/**
 * @title CallBlacklist
 * @author Non-Fungible Technologies, Inc.
 *
 * Library contract maintaining an immutable blacklist for any CallWhitelist contract
 * (or CallWhitelistApprovals). These functions can never be called through the vault's
 * `call` functionality. Note that CallWhitelistApprovals still allows approvals to take
 * place based on certain spenders set in `setApproval`.
 */
abstract contract CallBlacklist {
    // ============================================ STATE ==============================================

    // ============= Global Immutable State ==============

    /**
     * @dev Global blacklist for transfer functions.
     */
    bytes4 private constant ERC20_TRANSFER = IERC20.transfer.selector;
    bytes4 private constant ERC20_ERC721_APPROVE = IERC20.approve.selector;
    bytes4 private constant ERC20_ERC721_TRANSFER_FROM = IERC20.transferFrom.selector;
    bytes4 private constant ERC20_INCREASE_ALLOWANCE = bytes4(keccak256("increaseAllowance(address,uint256)"));
    bytes4 private constant ERC20_BURN = bytes4(keccak256("burn(address,uint256)"));
    bytes4 private constant ERC20_BURN_FROM = bytes4(keccak256("burnFrom(address,uint256)"));

    bytes4 private constant ERC721_SAFE_TRANSFER_FROM = bytes4(keccak256("safeTransferFrom(address,address,uint256)"));
    bytes4 private constant ERC721_SAFE_TRANSFER_FROM_DATA = bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));
    bytes4 private constant ERC721_ERC1155_SET_APPROVAL = IERC721.setApprovalForAll.selector;
    bytes4 private constant ERC721_BURN = bytes4(keccak256("burn(uint256)"));

    bytes4 private constant ERC1155_SAFE_TRANSFER_FROM = IERC1155.safeTransferFrom.selector;
    bytes4 private constant ERC1155_SAFE_BATCH_TRANSFER_FROM = IERC1155.safeBatchTransferFrom.selector;
    bytes4 private constant ERC1155_BURN = bytes4(keccak256("burn(address,uint256,uint256)"));
    bytes4 private constant ERC1155_BURN_BATCH = bytes4(keccak256("burn(address,uint256[],uint256[])"));

    bytes4 private constant PUNKS_TRANSFER = bytes4(keccak256("transferPunk(address,uint256)"));
    bytes4 private constant PUNKS_OFFER = bytes4(keccak256("offerPunkForSale(uint256,uint256)"));
    bytes4 private constant PUNKS_OFFER_TO_ADDRESS = bytes4(keccak256("offerPunkForSaleToAddress(uint256,uint256,address)"));
    bytes4 private constant PUNKS_BUY = bytes4(keccak256("buyPunk(uint256)"));

    bytes4 private constant SUPERRARE_SET_SALE_PRICE = bytes4(keccak256("setSalePrice(uint256,uint256)"));
    bytes4 private constant SUPERRARE_ACCEPT_BID = bytes4(keccak256("acceptBid(uint256)"));
    // SuperRare transfer already blacklisted - same elector as IERC20.transfer
    // SuperRare approve already blacklisted - same elector as IERC20.approve

    // ================= Blacklist State ==================

    /**
     * @notice Returns true if the given function selector is on the global blacklist.
     *         Blacklisted function selectors cannot be called on any contract.
     *
     * @param selector              The function selector to check.
     *
     * @return isBlacklisted        True if blacklisted, else false.
     */
    function isBlacklisted(bytes4 selector) public pure returns (bool) {
        return
            selector == ERC20_TRANSFER ||
            selector == ERC20_ERC721_APPROVE ||
            selector == ERC20_ERC721_TRANSFER_FROM ||
            selector == ERC20_INCREASE_ALLOWANCE ||
            selector == ERC20_BURN ||
            selector == ERC20_BURN_FROM ||
            selector == ERC721_SAFE_TRANSFER_FROM ||
            selector == ERC721_SAFE_TRANSFER_FROM_DATA ||
            selector == ERC721_ERC1155_SET_APPROVAL ||
            selector == ERC721_BURN ||
            selector == ERC1155_SAFE_TRANSFER_FROM ||
            selector == ERC1155_SAFE_BATCH_TRANSFER_FROM ||
            selector == ERC1155_BURN ||
            selector == ERC1155_BURN_BATCH ||
            selector == PUNKS_TRANSFER ||
            selector == PUNKS_OFFER ||
            selector == PUNKS_OFFER_TO_ADDRESS ||
            selector == PUNKS_BUY ||
            selector == SUPERRARE_SET_SALE_PRICE ||
            selector == SUPERRARE_ACCEPT_BID;
    }
}