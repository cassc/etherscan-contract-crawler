// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/IAssetVault.sol";
import "../interfaces/ICallDelegator.sol";
import "../external/interfaces/IPunks.sol";
import "../external/interfaces/ISuperRareV1.sol";

import "./CallWhitelistDelegation.sol";
import "./CallWhitelistApprovals.sol";
import "./OwnableERC721.sol";

import {
    AV_WithdrawsDisabled,
    AV_WithdrawsEnabled,
    AV_AlreadyInitialized,
    AV_MissingAuthorization,
    AV_NonWhitelistedCall,
    AV_NonWhitelistedApproval,
    AV_TooManyItems,
    AV_LengthMismatch,
    AV_ZeroAddress,
    AV_NonWhitelistedDelegation
} from "../errors/Vault.sol";

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
 *
 * Implementation warning: AssetVault is an OwnableERC721, which means that ownership of this contract
 * is tracked by a separate ERC721 contract defined by calling `_setNFT()`. In the current implementation,
 * the deployer is the VaultFactory, an ERC721 contract whose token ownership corresponds to vault ownership.
 * If this contract is modified or extended, or the deployer of a given AssetVault is not an ERC721 contract,
 * ownership will not work as intended.
 */
contract AssetVault is
    IAssetVault,
    OwnableERC721,
    Initializable,
    ERC1155HolderUpgradeable,
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable
{
    using AddressUpgradeable for address;
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // ============================================ STATE ==============================================

    /// @notice True if withdrawals are allowed out of this vault.
    /// @dev Note once set to true, it cannot be reverted back to false.
    bool public override withdrawEnabled;

    /// @notice Whitelist contract to determine if a given external call is allowed.
    address public override whitelist;

    /// @notice The maximum number of items that can be withdrawn from a vault at once.
    uint256 public constant MAX_WITHDRAW_ITEMS = 25;

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
        whitelist = _whitelist;

        __ReentrancyGuard_init();
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
        if (to == address(0)) revert AV_ZeroAddress("to");

        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20Upgradeable(token).safeTransfer(to, balance);
        emit WithdrawERC20(msg.sender, token, to, balance);
    }

    /**
     * @notice Withdraw a specific ERC721 token from the vault. The vault must
     *         be in a "withdrawEnabled" state (non-transferrable), and the caller
     *         must be the owner. The specified token must exist and be owned by
     *         this contract.
     *
     * @param token                 The token to withdraw.
     * @param tokenId               The ID of the NFT to withdraw.
     * @param to                    The recipient of the withdrawn token.
     */
    function withdrawERC721(
        address token,
        uint256 tokenId,
        address to
    ) external override onlyOwner onlyWithdrawEnabled {
        _withdrawERC721(token, tokenId, to);
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
        _withdrawERC1155(token, tokenId, to);
    }

    /**
     * @notice Batch withdraw assets from the vault. The vault must be in a
     *         "withdrawEnabled" state (non-transferrable), and the caller must
     *         be the owner.
     *
     * @dev This function is used to withdraw multiple ERC721 and ERC1155 tokens
     *      from the vault. The caller must specify the token type (ERC721 or
     *      ERC1155) and the token ID for each token to withdraw. The caller
     *      must also specify the recipient of the withdrawal. Refer to the
     *      MAX_WITHDRAW_ITEMS state constant for the maximum number of vault
     *      items that can be withdrawn per function call.
     *
     * @param tokens                An array of tokens address to withdraw.
     * @param tokenIds              An array of tokenIds to withdraw.
     * @param tokenTypes            An arrary of token types to withdraw.
     * @param to                    The recipient of the withdrawn tokens.
     */
    // solhint-disable-next-line code-complexity
    function withdrawBatch(
        address[] calldata tokens,
        uint256[] calldata tokenIds,
        TokenType[] calldata tokenTypes,
        address to
    ) external override onlyOwner onlyWithdrawEnabled {
        uint256 tokensLength = tokens.length;
        if (tokensLength > MAX_WITHDRAW_ITEMS) revert AV_TooManyItems(tokensLength);
        if (tokensLength != tokenIds.length) revert AV_LengthMismatch("tokenId");
        if (tokensLength != tokenTypes.length) revert AV_LengthMismatch("tokenType");

        for (uint256 i = 0; i < tokensLength;) {
            if (tokens[i] == address(0)) revert AV_ZeroAddress("token");

            if (tokenTypes[i] == TokenType.ERC721) {
                _withdrawERC721(tokens[i], tokenIds[i], to);
            } else {
                _withdrawERC1155(tokens[i], tokenIds[i], to);
            }

            // Can never overflow because length is bounded by MAX_WITHDRAW_ITEMS
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Withdraw entire balance of ETH from the vault.
     *         The vault must be in a "withdrawEnabled" state (non-transferrable),
     *         and the caller must be the owner.
     *
     * @param to                    The recipient of the withdrawn funds.
     */
    function withdrawETH(address to) external override onlyOwner onlyWithdrawEnabled nonReentrant {
        if (to == address(0)) revert AV_ZeroAddress("to");

        // perform transfer
        uint256 balance = address(this).balance;
        // sendValue() internally uses call() which passes along all of
        // the remaining gas, potentially introducing an attack vector
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
        if (to == address(0)) revert AV_ZeroAddress("to");

        IPunks(punks).transferPunk(to, punkIndex);
        emit WithdrawPunk(msg.sender, punks, to, punkIndex);
    }

    /**
     * @notice Withdraw SuperRare V1 from the vault.
     *         Vault must have withdraw enabled.
     *         Caller must be owner.
     *
     * @param superRareV1           SuperRare V1 contract address
     * @param tokenId               tokenId to withdraw
     * @param to                    recipient of the token
     */
    function withdrawSuperRareV1(
        address superRareV1,
        uint256 tokenId,
        address to
    ) external override onlyOwner onlyWithdrawEnabled {
        if (to == address(0)) revert AV_ZeroAddress("to");

        ISuperRareV1(superRareV1).transfer(to, tokenId);
        emit WithdrawSuperRareV1(msg.sender, superRareV1, to, tokenId);
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
    function call(
        address to,
        bytes calldata data
    ) external override onlyAllowedCallers onlyWithdrawDisabled nonReentrant {
        if (!ICallWhitelist(whitelist).isWhitelisted(to, bytes4(data[:4]))) {
            revert AV_NonWhitelistedCall(to, bytes4(data[:4]));
        }

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
    function callApprove(
        address token,
        address spender,
        uint256 amount
    ) external override onlyAllowedCallers onlyWithdrawDisabled nonReentrant {
        if (!CallWhitelistApprovals(whitelist).isApproved(token, spender)) {
            revert AV_NonWhitelistedApproval(token, spender);
        }

        // Do approval
        IERC20Upgradeable(token).safeApprove(spender, amount);

        emit Approve(msg.sender, token, spender, amount);
    }

    /**
     * @notice Increase token allowance for spending by an external contract. Note that any
     *         token approved in the whitelist does not make good collateral, because the
     *         allowed spender may be able to withdraw it from the vault.
     *
     * @param token                 The token to approve.
     * @param spender               The approved spender.
     * @param amount                The amount to increase allowance by.
     */
    function callIncreaseAllowance(
        address token,
        address spender,
        uint256 amount
    ) external override onlyAllowedCallers onlyWithdrawDisabled nonReentrant {
        if (!CallWhitelistApprovals(whitelist).isApproved(token, spender)) {
            revert AV_NonWhitelistedApproval(token, spender);
        }

        // increase spender allowance
        IERC20Upgradeable(token).safeIncreaseAllowance(spender, amount);

        emit IncreaseAllowance(msg.sender, token, spender, amount);
    }

    /**
     * @notice Decrease token allowance for spending by an external contract. Note that any
     *         token approved in the whitelist does not make good collateral, because the
     *         allowed spender may be able to withdraw it from the vault.
     *
     * @param token                 The token to approve.
     * @param spender               The approved spender.
     * @param amount                The amount to decrease allowance by.
     */
    function callDecreaseAllowance(
        address token,
        address spender,
        uint256 amount
    ) external override onlyAllowedCallers onlyWithdrawDisabled nonReentrant {
        if (!CallWhitelistApprovals(whitelist).isApproved(token, spender)) {
            revert AV_NonWhitelistedApproval(token, spender);
        }

        // decrease spender allowance
        IERC20Upgradeable(token).safeDecreaseAllowance(spender, amount);

        emit DecreaseAllowance(msg.sender, token, spender, amount);
    }

    /**
     * @notice Delegate a token held by the vault to an external contract. This token must
     *         be whitelisted for delegation by the CallWhitelistDelegation contract. This
     *         will grant delegation powers for all tokens within this contract held by the vault.
     *
     * @param token                 The token to delegate.
     * @param target                The address to delegate to (the hot wallet).
     * @param enable                Whether to enable or disable delegation.
     */
    function callDelegateForContract(
        address token,
        address target,
        bool enable
    ) external override onlyAllowedCallers onlyWithdrawDisabled nonReentrant {
        if (!CallWhitelistDelegation(whitelist).isDelegationApproved(token)) {
            revert AV_NonWhitelistedDelegation(token);
        }

        // Do delegation
        CallWhitelistDelegation(whitelist).registry().delegateForContract(target, token, enable);

        emit DelegateContract(msg.sender, token, target, enable);
    }

    /**
     * @notice Delegate a specific tokenId held by the vault to an external contract. This token must
     *         be whitelisted for delegation by the CallWhitelistDelegation contract. This
     *         will grant delegation powers for only the specified tokenId within the token.
     *
     * @param token                 The token to delegate.
     * @param target                The address to delegate to (the hot wallet).
     * @param tokenId               The token ID to delegate.
     * @param enable                Whether to enable or disable delegation.
     */
    function callDelegateForToken(
        address token,
        address target,
        uint256 tokenId,
        bool enable
    ) external override onlyAllowedCallers onlyWithdrawDisabled nonReentrant {
        if (!CallWhitelistDelegation(whitelist).isDelegationApproved(token)) {
            revert AV_NonWhitelistedDelegation(token);
        }

        // Do delegation
        CallWhitelistDelegation(whitelist).registry().delegateForToken(target, token, tokenId, enable);

        emit DelegateToken(msg.sender, token, target, tokenId, enable);
    }

    /**
     * @notice Revoke all delegations the vault has granted to an external contract. For individual
     *         revocations per-contract and perToken, use callDelegateForContract and callDelegateForToken
     *         with enabled set to false.
     */
     function callRevokeAllDelegates() external override onlyAllowedCallers onlyWithdrawDisabled nonReentrant {
        CallWhitelistDelegation(whitelist).registry().revokeAllDelegates();

        emit DelegateRevoke(msg.sender);
     }

    // ============================================ HELPERS =============================================

    /**
     * @dev Private function to withdraw a ERC721 token from the vault.
     *
     * @param token                 The token to withdraw.
     * @param tokenId               The ID of the NFT to withdraw.
     * @param to                    The recipient of the withdrawn token.
     */
    function _withdrawERC721(
        address token,
        uint256 tokenId,
        address to
    ) private {
        if (to == address(0)) revert AV_ZeroAddress("to");

        IERC721Upgradeable(token).safeTransferFrom(address(this), to, tokenId);

        emit WithdrawERC721(msg.sender, token, to, tokenId);
    }

    /**
     * @dev Private function to withdraw ERC1155 tokens from the vault.
     *
     * @param token                 The token to withdraw.
     * @param tokenId               The ID of the token to withdraw.
     * @param to                    The recipient of the withdrawn funds.
     */
    function _withdrawERC1155(
        address token,
        uint256 tokenId,
        address to
    ) private {
        if (to == address(0)) revert AV_ZeroAddress("to");

        uint256 balance = IERC1155(token).balanceOf(address(this), tokenId);
        IERC1155Upgradeable(token).safeTransferFrom(address(this), to, tokenId, balance, "");

        emit WithdrawERC1155(msg.sender, token, to, tokenId, balance);
    }

    /**
     * @dev For any utility function, check whether the caller is the owner or has been
     *      approved via the ICallDelegator interface by the owner.
     */
    modifier onlyAllowedCallers() {
        if (msg.sender != owner() && !ICallDelegator(owner()).canCallOn(msg.sender, address(this))) {
            revert AV_MissingAuthorization(msg.sender);
        }

        _;
    }

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