//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/Utils.sol";
import "../upgrade/FsAdmin.sol";

/// @title TokenVault implementation.
/// @notice TokenVault is the only contract in the Futureswap system that stores ERC20 tokens, including both collateral
/// and liquidity. Each exchange has its own instance of TokenVault, which provides isolation of the funds between
/// different exchanges and adds an additional layer of protection in case one exchange gets compromised.
/// Users are not meant to interact with this contract directly. For each exchange, only the TokenRouter and the
/// corresponding implementation of IAmm (for example, SpotMarketAmm) are authorized to withdraw funds. If new versions
/// of these contracts become available, then they can be approved and the old ones disapproved.
///
/// @dev We decided to make TokenVault non-upgradable. The implementation is very simple and in case of an emergency
/// recovery of funds, the VotingExecutor (which should be the owner of TokenVault) can approve arbitrary addresses
/// to withdraw funds.
contract TokenVault is Ownable, FsAdmin, GitCommitHash {
    using SafeERC20 for IERC20;

    /// @notice Mapping to track addresses that are approved to move funds from this vault.
    mapping(address => bool) public isApproved;

    /// @notice When the TokenVault is frozen, no transfer of funds in or out of the contract can happen.
    bool isFrozen;

    /// @notice Requires caller to be an approved address.
    modifier onlyApprovedAddress() {
        require(isApproved[msg.sender], "Not an approved address");
        _;
    }

    /// @notice Emitted when approvals for `userAddress` changes. Reports the value before the change in
    /// `previousApproval` and the value after the change in `currentApproval`.
    event VaultApprovalChanged(
        address indexed userAddress,
        bool previousApproval,
        bool currentApproval
    );

    /// @notice Emitted when `amount` tokens are transfered from the TokenVault to the `recipient`.
    event VaultTokensTransferred(address recipient, address token, uint256 amount);

    /// @notice Emitted when the vault is frozen/unfrozen.
    event VaultFreezeStateChanged(bool previousFreezeState, bool freezeState);

    constructor(address _admin) {
        initializeFsAdmin(_admin);
    }

    /// @notice Changes the approval status of an address. If an address is approved, it's allowed to move funds from
    /// the vault. Can only be called by the VotingExecutor.
    ///
    /// @param userAddress The address to change approvals for. Can't be the zero address.
    /// @param approved Whether to approve or disapprove the address.
    function setAddressApproval(address userAddress, bool approved) external onlyOwner {
        // This does allow an arbitrary address to be approved to withdraw funds from the vault but this risk
        // is mitigated as only the owner can call this function. As long as the owner is the VotingExecutor,
        // which is controlled by governance, no single individual would be able to approve a malicious address.
        // slither-disable-next-line missing-zero-check
        userAddress = FsUtils.nonNull(userAddress);
        bool previousApproval = isApproved[userAddress];

        if (previousApproval == approved) {
            return;
        }

        isApproved[userAddress] = approved;
        emit VaultApprovalChanged(userAddress, previousApproval, approved);
    }

    /// @notice Transfers the given amount of token from the vault to a given address.
    /// This can only be called by an approved address.
    ///
    /// @param recipient The address to transfer tokens to.
    /// @param token Which token to transfer.
    /// @param amount The amount to transfer, represented in the token's underlying decimals.
    function transfer(
        address recipient,
        address token,
        uint256 amount
    ) external onlyApprovedAddress {
        require(!isFrozen, "Vault is frozen");

        emit VaultTokensTransferred(recipient, token, amount);
        // There's no risk of a malicious token being passed here, leading to reentrancy attack
        // because:
        // (1) Only approved addresses can call this method to move tokens from the vault.
        // (2) Only tokens associated with the exchange would ever be moved.
        // OpenZeppelin safeTransfer doesn't return a value and will revert if any issue occurs.
        IERC20(token).safeTransfer(recipient, amount);
    }

    /// @notice For security we allow admin/voting to freeze/unfreeze the vault this allows an admin
    /// to freeze funds, but not move them.
    function setIsFrozen(bool _isFrozen) external {
        if (isFrozen == _isFrozen) {
            return;
        }

        require(msg.sender == owner() || msg.sender == admin, "Only owner or admin");
        emit VaultFreezeStateChanged(isFrozen, _isFrozen);
        isFrozen = _isFrozen;
    }
}