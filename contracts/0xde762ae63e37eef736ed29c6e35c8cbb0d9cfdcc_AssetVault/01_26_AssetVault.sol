// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./CallWhitelistApprovals.sol";
import "../interfaces/ICallDelegator.sol";
import "../interfaces/IAssetVault.sol";
import "../external/interfaces/IPunks.sol";
import "./OwnableERC721.sol";

import { AV_WithdrawsDisabled, AV_WithdrawsEnabled, AV_AlreadyInitialized, AV_CallDisallowed, AV_NonWhitelistedCall, AV_NonWhitelistedApproval } from "../errors/Vault.sol";

/**
 * @title AssetVault
 * @author Non-Fungible Technologies, Inc.
 *
 * The Asset Vault is a vault for the storage of collateralized assets.
 * Designed for one-time use, like a piggy bank. Once withdrawals are enabled,
 * and the bank is broken, the vault can no longer be used or transferred.
 *
 * It starts in a deposit-only state. Funds cannot be withdrawn at this point. When
 * the owner calls "enableWithdraw()", the state is set to a withdrawEnabled state.
 * Withdraws cannot be disabled once enabled. This restriction protects integrations
 * and purchasers of AssetVaults from unexpected withdrawal and frontrunning attacks.
 * For example: someone buys an AV assuming it contains token X, but I withdraw token X
 * immediately before the sale concludes.
 *
 * @dev Asset Vaults support arbitrary external calls by either:
 *     - the current owner of the vault
 *     - someone who the current owner "delegates" through the ICallDelegator interface
 *
 * This is to enable airdrop claims by borrowers during loans and other forms of NFT utility.
 * In practice, LoanCore delegates to the borrower during the period of an open loan.
 * Arcade.xyz maintains an allowed and restricted list of calls to balance between utility and security.
 */
contract AssetVault is IAssetVault, OwnableERC721, Initializable, ERC1155Holder, ERC721Holder, ReentrancyGuard {
    using Address for address;
    using Address for address payable;
    using SafeERC20 for IERC20;

    // ============================================ STATE ==============================================

    /// @notice True if withdrawals are allowed out of this vault.
    /// @dev Note once set to true, it cannot be reverted back to false.
    bool public override withdrawEnabled;

    /// @notice Whitelist contract to determine if a given external call is allowed.
    ICallWhitelist public override whitelist;

    // ========================================== CONSTRUCTOR ===========================================

    /**
     * @dev Initializes values so initialize cannot be called on template.
     */
    constructor() {
        withdrawEnabled = true;
        OwnableERC721._setNFT(msg.sender);
    }

    // ========================================== INITIALIZER ===========================================

    /**
     * @notice Initializes the contract, used on clone deployments. In practice,
     *         always called by the VaultFactory contract.
     *
     * @param _whitelist            The contract maintaining the whitelist of allowed
     *                              arbitrary calls.
     */
    function initialize(address _whitelist) external override initializer {
        if (withdrawEnabled || ownershipToken != address(0)) revert AV_AlreadyInitialized(ownershipToken);
        // set ownership to inherit from the factory who deployed us
        // The factory should have a tokenId == uint256(address(this))
        // whose owner has ownership control over this contract
        OwnableERC721._setNFT(msg.sender);
        whitelist = ICallWhitelist(_whitelist);
    }

    // ========================================= VIEW FUNCTIONS =========================================

    /**
     * @inheritdoc OwnableERC721
     */
    function owner() public view override returns (address ownerAddress) {
        return OwnableERC721.owner();
    }

    // ===================================== WITHDRAWAL OPERATIONS ======================================

    /**
     * @notice Enables withdrawals on the vault. Irreversible. Caller must be the
     *         owner of the underlying ownership NFT.
     *
     * @dev Any integration should be aware that a withdraw-enabled vault cannot
     *      be transferred (will revert).
     *
     */
    function enableWithdraw() external override onlyOwner onlyWithdrawDisabled {
        withdrawEnabled = true;
        emit WithdrawEnabled(msg.sender);
    }

    /**
     * @notice Withdraw entire balance of a given ERC20 token from the vault.
     *         The vault must be in a "withdrawEnabled" state (non-transferrable),
     *         and the caller must be the owner.
     *
     * @param token                 The ERC20 token to withdraw.
     * @param to                    The recipient of the withdrawn funds.
     */
    function withdrawERC20(address token, address to) external override onlyOwner onlyWithdrawEnabled {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(to, balance);
        emit WithdrawERC20(msg.sender, token, to, balance);
    }

    /**
     * @notice Withdraw entire balance of a given ERC20 token from the vault.
     *         The vault must be in a "withdrawEnabled" state (non-transferrable),
     *         and the caller must be the owner. The specified token must
     *         exist and be owned by this contract.
     *
     * @param token                 The token to withdraw.
     * @param tokenId               The ID of the NFT to withdraw.
     * @param to                    The recipient of the withdrawn token.
     *
     */
    function withdrawERC721(
        address token,
        uint256 tokenId,
        address to
    ) external override onlyOwner onlyWithdrawEnabled {
        IERC721(token).safeTransferFrom(address(this), to, tokenId);
        emit WithdrawERC721(msg.sender, token, to, tokenId);
    }

    /**
     * @notice Withdraw entire balance of a given ERC1155 token from the vault.
     *         The vault must be in a "withdrawEnabled" state (non-transferrable),
     *         and the caller must be the owner.
     *
     * @param token                 The ERC1155 token to withdraw.
     * @param tokenId               The ID of the token to withdraw.
     * @param to                    The recipient of the withdrawn funds.
     */
    function withdrawERC1155(
        address token,
        uint256 tokenId,
        address to
    ) external override onlyOwner onlyWithdrawEnabled {
        uint256 balance = IERC1155(token).balanceOf(address(this), tokenId);
        IERC1155(token).safeTransferFrom(address(this), to, tokenId, balance, "");
        emit WithdrawERC1155(msg.sender, token, to, tokenId, balance);
    }

    /**
     * @notice Withdraw entire balance of ETH from the vault.
     *         The vault must be in a "withdrawEnabled" state (non-transferrable),
     *         and the caller must be the owner.
     *
     * @param to                    The recipient of the withdrawn funds.
     */
    function withdrawETH(address to) external override onlyOwner onlyWithdrawEnabled nonReentrant {
        // perform transfer
        uint256 balance = address(this).balance;
        payable(to).sendValue(balance);
        emit WithdrawETH(msg.sender, to, balance);
    }

    /**
     * @notice Withdraw cryptoPunk from the vault.
     *         The vault must be in a "withdrawEnabled" state (non-transferrable),
     *         and the caller must be the owner.
     *
     * @param punks                 The CryptoPunk contract address.
     * @param punkIndex             The index of the CryptoPunk to withdraw (i.e. token ID).
     * @param to                    The recipient of the withdrawn punk.
     */
    function withdrawPunk(
        address punks,
        uint256 punkIndex,
        address to
    ) external override onlyOwner onlyWithdrawEnabled {
        IPunks(punks).transferPunk(to, punkIndex);
        emit WithdrawPunk(msg.sender, punks, to, punkIndex);
    }

    // ====================================== UTILITY OPERATIONS ========================================

    /**
     * @notice Call a function on an external contract. Intended for claiming airdrops
     *         and other forms of NFT utility. All allowed calls are whitelist by the
     *         "whitelist" contract. The vault must have withdrawals disabled, and the caller
     *         must either be the owner, or the owner must have explicitly
     *         delegated this ability to the caller through ICallDelegator interface.
     *
     * @param to                    The contract address to call.
     * @param data                  The data to call the contract with.
     */
    function call(address to, bytes calldata data) external override onlyWithdrawDisabled nonReentrant {
        if (msg.sender != owner() && !ICallDelegator(owner()).canCallOn(msg.sender, address(this)))
            revert AV_CallDisallowed(msg.sender);

        if (!whitelist.isWhitelisted(to, bytes4(data[:4]))) revert AV_NonWhitelistedCall(to, bytes4(data[:4]));

        to.functionCall(data);

        emit Call(msg.sender, to, data);
    }

    /**
     * @notice Approve a token for spending by an external contract. Note that any token
     *         approved in the whitelist does not make good collateral, because the allowed
     *         spender may be able to withdraw it from the vault.
     *
     * @param token                 The token to approve.
     * @param spender               The approved spender.
     * @param amount                The amount to approve.
     */
    function callApprove(address token, address spender, uint256 amount) external override onlyWithdrawDisabled nonReentrant {
        if (msg.sender != owner() && !ICallDelegator(owner()).canCallOn(msg.sender, address(this)))
            revert AV_CallDisallowed(msg.sender);

        if (!CallWhitelistApprovals(address(whitelist)).isApproved(token, spender)) revert AV_NonWhitelistedApproval(token, spender);

        // Do approval
        IERC20(token).approve(spender, amount);

        emit Approve(msg.sender, token, spender, amount);
    }

    // ============================================ HELPERS =============================================

    /**
     * @dev For methods only callable with withdraws enabled (all withdrawal operations).
     */
    modifier onlyWithdrawEnabled() {
        if (!withdrawEnabled) revert AV_WithdrawsDisabled();
        _;
    }

    /**
     * @dev For methods only callable with withdraws disabled (call operations and enabling withdraws).
     */
    modifier onlyWithdrawDisabled() {
        if (withdrawEnabled) revert AV_WithdrawsEnabled();
        _;
    }

    /**
     * @dev Fallback "receive Ether" function. Contract can hold Ether
     *      which can be accessed using withdrawETH.
     */
    receive() external payable {}
}