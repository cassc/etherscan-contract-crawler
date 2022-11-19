// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./VaultOwnershipChecker.sol";
import "../interfaces/IVaultDepositRouter.sol";
import "../interfaces/IVaultInventoryReporter.sol";
import "../interfaces/IVaultFactory.sol";
import "../external/interfaces/IPunks.sol";

/**
 * @title VaultInventoryReporter
 * @author Non-Fungible Technologies, Inc.
 *
 * The VaultInventoryReporter contract is a helper contract that
 * works with Arcade asset vaults and the vault inventory reporter.
 * By depositing to asset vaults by calling the functions in this contract,
 * inventory registration will be automatically updated.
 */
contract VaultDepositRouter is IVaultDepositRouter, VaultOwnershipChecker {
    using SafeERC20 for IERC20;

    // ============================================ STATE ==============================================

    // ============= Global Immutable State ==============

    address public immutable factory;
    IVaultInventoryReporter public immutable reporter;

    // ========================================= CONSTRUCTOR ===========================================

    constructor(address _factory, address _reporter) {
        if (_factory == address(0)) revert VDR_ZeroAddress();
        if (_reporter == address(0)) revert VDR_ZeroAddress();

        factory = _factory;
        reporter = IVaultInventoryReporter(_reporter);
    }

    // ====================================== DEPOSIT OPERATIONS ========================================

    /**
     * @notice Deposit an ERC20 token to the vault, registering its inventory on the reporter
     *         simultaneously.
     *
     * @param vault                         The vault to deposit to.
     * @param token                         The token to deposit.
     * @param amount                        The amount of tokens to deposit.
     */
    function depositERC20(
        address vault,
        address token,
        uint256 amount
    ) external override validate(vault, msg.sender) {
        IERC20(token).safeTransferFrom(msg.sender, vault, amount);

        IVaultInventoryReporter.Item[] memory items = new IVaultInventoryReporter.Item[](1);

        items[0] = IVaultInventoryReporter.Item({
            itemType: IVaultInventoryReporter.ItemType.ERC_20,
            tokenAddress: token,
            tokenId: 0,
            tokenAmount: amount
        });

        reporter.add(vault, items);

        // No events because both token and reporter will emit
    }

    /**
     * @notice Deposit multiple ERC20 tokens to the vault, registering inventory on the reporter
     *         simultaneously.
     *
     * @param vault                          The vault to deposit to.
     * @param tokens                         The tokens to deposit.
     * @param amounts                        The amount of tokens to deposit, for each token.
     */
    function depositERC20Batch(
        address vault,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external override validate(vault, msg.sender) {
        uint256 numItems = tokens.length;
        if (numItems != amounts.length) revert VDR_BatchLengthMismatch();

        IVaultInventoryReporter.Item[] memory items = new IVaultInventoryReporter.Item[](numItems);

        for (uint256 i = 0; i < numItems; i++) {
            address token = tokens[i];
            uint256 amount = amounts[i];

            IERC20(token).safeTransferFrom(msg.sender, vault, amount);

            items[i] = IVaultInventoryReporter.Item({
                itemType: IVaultInventoryReporter.ItemType.ERC_20,
                tokenAddress: token,
                tokenId: 0,
                tokenAmount: amount
            });
        }

        reporter.add(vault, items);

        // No events because both token and reporter will emit
    }

    /**
     * @notice Deposit an ERC721 token to the vault, registering its inventory on the reporter
     *         simultaneously.
     *
     * @param vault                         The vault to deposit to.
     * @param token                         The token to deposit.
     * @param id                            The ID of the token to deposit.
     */
    function depositERC721(
        address vault,
        address token,
        uint256 id
    ) external override validate(vault, msg.sender) {
        IVaultInventoryReporter.Item[] memory items = new IVaultInventoryReporter.Item[](1);

        items[0] = _depositERC721(vault, token, id);

        reporter.add(vault, items);

        // No events because both token and reporter will emit
    }

    /**
     * @notice Deposit ERC721 tokens to the vault, registering inventory on the reporter
     *         simultaneously.
     *
     * @param vault                         The vault to deposit to.
     * @param tokens                        The token to deposit.
     * @param ids                           The ID of the token to deposit, for each token.
     */
    function depositERC721Batch(
        address vault,
        address[] calldata tokens,
        uint256[] calldata ids
    ) external override validate(vault, msg.sender) {
        uint256 numItems = tokens.length;
        if (numItems != ids.length) revert VDR_BatchLengthMismatch();

        IVaultInventoryReporter.Item[] memory items = new IVaultInventoryReporter.Item[](numItems);

        for (uint256 i = 0; i < numItems; i++) {
            items[i] = _depositERC721(vault, tokens[i], ids[i]);
        }

        reporter.add(vault, items);

        // No events because both token and reporter will emit
    }

    /**
     * @notice Deposit an ERC1155 token to the vault, registering its inventory on the reporter
     *         simultaneously.
     *
     * @param vault                         The vault to deposit to.
     * @param token                         The token to deposit.
     * @param id                            The ID of the token to deposit.
     * @param amount                        The amount of tokens to deposit.
     */
    function depositERC1155(
        address vault,
        address token,
        uint256 id,
        uint256 amount
    ) external override validate(vault, msg.sender) {
        IVaultInventoryReporter.Item[] memory items = new IVaultInventoryReporter.Item[](1);
        items[0] = _depositERC1155(vault, token, id, amount);

        reporter.add(vault, items);

        // No events because both token and reporter will emit
    }

    /**
     * @notice Deposit ERC1155 tokens to the vault, registering its inventory on the reporter
     *         simultaneously.
     *
     * @param vault                         The vault to deposit to.
     * @param tokens                        The token to deposit.
     * @param ids                           The ID of the tokens to deposit.
     * @param amounts                       The amount of tokens to deposit, for each token.
     */
    function depositERC1155Batch(
        address vault,
        address[] calldata tokens,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external override validate(vault, msg.sender) {
        uint256 numItems = tokens.length;
        if (numItems != ids.length) revert VDR_BatchLengthMismatch();
        if (numItems != amounts.length) revert VDR_BatchLengthMismatch();
        if (ids.length != amounts.length) revert VDR_BatchLengthMismatch();

        IVaultInventoryReporter.Item[] memory items = new IVaultInventoryReporter.Item[](numItems);

        for (uint256 i = 0; i < numItems; i++) {
            items[i] = _depositERC1155(vault, tokens[i], ids[i], amounts[i]);
        }

        reporter.add(vault, items);

        // No events because both token and reporter will emit
    }

    /**
     * @notice Deposit a CryptoPunk to the vault, registering its inventory on the reporter
     *         simultaneously.
     *
     * @param vault                         The vault to deposit to.
     * @param token                         The token to deposit.
     * @param id                            The ID of the token to deposit.
     */
    function depositPunk(
        address vault,
        address token,
        uint256 id
    ) external override validate(vault, msg.sender) {
        IPunks(token).buyPunk(id);
        IPunks(token).transferPunk(vault, id);

        IVaultInventoryReporter.Item[] memory items = new IVaultInventoryReporter.Item[](1);

        items[0] = IVaultInventoryReporter.Item({
            itemType: IVaultInventoryReporter.ItemType.PUNKS,
            tokenAddress: token,
            tokenId: id,
            tokenAmount: 0
        });

        reporter.add(vault, items);

        // No events because both token and reporter will emit
    }

    /**
     * @notice Deposit CryptoPunks to the vault, registering inventory on the reporter
     *         simultaneously.
     *
     * @param vault                         The vault to deposit to.
     * @param tokens                        The token to deposit.
     * @param ids                           The ID of the tokens to deposit.
     */
    function depositPunkBatch(
        address vault,
        address[] calldata tokens,
        uint256[] calldata ids
    ) external override validate(vault, msg.sender) {
        uint256 numItems = tokens.length;
        if (numItems != ids.length) revert VDR_BatchLengthMismatch();

        IVaultInventoryReporter.Item[] memory items = new IVaultInventoryReporter.Item[](numItems);

        for (uint256 i = 0; i < numItems; i++) {
            address token = tokens[i];
            uint256 id = ids[i];

            IPunks(token).buyPunk(id);
            IPunks(token).transferPunk(vault, id);

            items[i] = IVaultInventoryReporter.Item({
                itemType: IVaultInventoryReporter.ItemType.PUNKS,
                tokenAddress: token,
                tokenId: id,
                tokenAmount: 0
            });
        }

        reporter.add(vault, items);

        // No events because both token and reporter will emit
    }

    // ============================================ HELPERS =============================================

    /**
     * @dev Collect an ERC1155 from the caller, and return the Item struct.
     *
     * @param vault                         The vault to deposit to.
     * @param token                         The token to deposit.
     * @param id                            The ID of the token to deposit.
     * @param amount                        The amount of tokens to deposit.
     *
     * @return item                         The Item struct for the asset collected.
     */
    function _depositERC1155(
        address vault,
        address token,
        uint256 id,
        uint256 amount
    ) internal returns (IVaultInventoryReporter.Item memory) {
        IERC1155(token).safeTransferFrom(msg.sender, vault, id, amount, "");

        return IVaultInventoryReporter.Item({
            itemType: IVaultInventoryReporter.ItemType.ERC_1155,
            tokenAddress: token,
            tokenId: id,
            tokenAmount: amount
        });
    }

    /**
     * @dev Collect an ERC721 from the caller, and return the Item struct.
     *
     * @param vault                         The vault to deposit to.
     * @param token                         The token to deposit.
     * @param id                            The ID of the token to deposit.
     *
     * @return item                         The Item struct for the asset collected.
     */
    function _depositERC721(
        address vault,
        address token,
        uint256 id
    ) internal returns (IVaultInventoryReporter.Item memory) {
        IERC721(token).safeTransferFrom(msg.sender, vault, id);

        return IVaultInventoryReporter.Item({
            itemType: IVaultInventoryReporter.ItemType.ERC_721,
            tokenAddress: token,
            tokenId: id,
            tokenAmount: 0
        });
    }

    /**
     * @dev Validates that the caller is allowed to deposit to the specified vault (owner or approved),
     *      and that the specified vault exists. Reverts on failed validation.
     *
     * @param vault                         The vault that will be deposited to.
     * @param caller                        The caller who wishes to deposit.
     */
    modifier validate(address vault, address caller) {
        _checkApproval(factory, vault, caller);

        _;
    }
}