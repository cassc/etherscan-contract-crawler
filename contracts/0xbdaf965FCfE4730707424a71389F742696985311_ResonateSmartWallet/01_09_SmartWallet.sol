// SPDX-License-Identifier: GNU-GPL v3.0 or later

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IERC4626.sol";
import "./interfaces/ISmartWallet.sol";

pragma solidity ^0.8.0;

/// @author RobAnon
/** @title Resonate Smart Wallet. */
contract ResonateSmartWallet is ISmartWallet, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    /// Address for msg.sender
    address public immutable override MASTER;
    /// Resonate address
    address public immutable override RESONATE;
    /// IERC20 Interface ID
    bytes4 public constant IERC20_INTERFACE = type(IERC20).interfaceId;

    uint private constant PRECISION = 1 ether;


    
    constructor(address _resonate) {
        MASTER = msg.sender;
        RESONATE = _resonate;
    }

    /**
     * @dev Throws if called by any account other than master or resonate.
     */
    modifier onlyMaster() {
        require(msg.sender == MASTER || msg.sender == RESONATE, 'E016');
        _;
    }

    /**
     * @notice Function used by Purchaser to claim any remaining interest/residual interest at end of life-cycle
     * @param vaultAdapter the ERC-4626 vault to redeem shares from 
     * @param receiver the address that will receive the redeemed assets
     * @param amountUnderlying the amount of underlying tokens to claim interest on. May be zero
     * @param totalShares the total number of shares the principal is worth. May be zero
     * @param residual the residual amount of shares left by already-withdrawn principal
     * @return interest the amount of interest this function claimed
     * @return sharesRedeemed the numebr of shares that were redeemed by this function
     */
    function reclaimInterestAndResidual(
        address vaultAdapter,
        address receiver,
        uint amountUnderlying, 
        uint totalShares,
        uint residual
    ) external override onlyMaster nonReentrant returns (uint interest, uint sharesRedeemed) {
        uint shareSum = totalShares + residual;
        IERC4626 vault = IERC4626(vaultAdapter);

        uint underlyingShares = vault.previewWithdraw(amountUnderlying);
        
        if(underlyingShares < shareSum) {
            sharesRedeemed = shareSum - underlyingShares;
            interest = vault.redeem(sharesRedeemed, receiver, address(this));
        }
    }

    /**
     * @notice Reclaims the principal at the end of the FNFT's life-cycle
     * @param vaultAdapter the ERC-4626 vault to reclaim principal from
     * @param receiver the address where the reclaimed principal will be sent
     * @param amountUnderlying the total amount of tokens this principal is supposed to represent
     * @param totalShares the total shares that were previously mapped to this position
     * @param leaveResidual will be true if the interest-FNFT still exists, otherwise, accumulated interest is 
     *                      provided to the receiver as a bonus
     * @return residualShares the amount of shares that were left as a residual for the interest-FNFT if it still exists
     */
    function reclaimPrincipal(
        address vaultAdapter,
        address receiver,
        uint amountUnderlying, 
        uint totalShares,
        bool leaveResidual
    ) external onlyMaster nonReentrant returns (uint residualShares) {
        IERC4626 vault = IERC4626(vaultAdapter);
        if(leaveResidual) {
            // Handle edge-case where fees have eaten the residual
            uint sharesWithdrawn;
            if(vault.previewWithdraw(amountUnderlying) <= totalShares) {
                sharesWithdrawn = vault.withdraw(amountUnderlying, receiver, address(this));
            } else {
                // NB: Edge-case handling for principal that is worth less than its nominal value
                // Only can occur when vaults charge high fees on withdrawals
                sharesWithdrawn = totalShares;
                vault.redeem(sharesWithdrawn, receiver, address(this));
            }
            residualShares = totalShares - sharesWithdrawn;
        } else {
            // Claim everything we can
            vault.redeem(totalShares, receiver, address(this));
        }
    }

    /**
     * @notice Redeem the amount of passed-in shares and send their corresponding assets to receiver
     * @param vaultAdapter the ERC-4626 to call redeem on
     * @param receiver the address to send the received assets to
     * @param totalShares the total number of shares to redeem
     * @return amountUnderlying the amount of assets sent to receiver as a result of calling redeem
     */
    function redeemShares(
        address vaultAdapter,
        address receiver,
        uint totalShares
    ) external override onlyMaster nonReentrant returns (uint amountUnderlying) {
        IERC4626 vault = IERC4626(vaultAdapter);
        amountUnderlying = vault.redeem(totalShares, receiver, address(this));
    }

    /**
     * @notice Allows for arbitrary calls to be made via the assets stored in this contract
     * @param token the base token for this wallet's corresponding ERC-4626, typically a governance token or flashloan-topic
     * @param vault the traditional vault, if any, that the ERC-4626 plugs into as an adapter
     * @param vaultAdapter the ERC-4626 vault whose tokens are stored in this contract
     * @param targets the contract(s) to target for the list of calls
     * @param values The Ether values to transfer (typically zero)
     * @param calldatas Encoded calldata for each function
     * @dev Calldata must be properly encoded and function selectors must be on the whitelist for this method to function. Functions cannot transfer tokens out
     */
    function proxyCall(address token, address vault, address vaultAdapter, address[] memory targets, uint256[] memory values, bytes[] memory calldatas) external override onlyMaster nonReentrant {
        uint preBalVaultToken = IERC20(vaultAdapter).balanceOf(address(this));
        uint preBalToken = IERC20(token).balanceOf(address(this));
        uint preVaultBalToken = IERC20(token).balanceOf(vault);
        uint prePreviewRedeem = IERC4626(vaultAdapter).previewRedeem(PRECISION);
        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, ) = targets[i].call{value: values[i]}(calldatas[i]);
            require(success, "ER022");
        }
        require(IERC20(vaultAdapter).balanceOf(address(this)) >= preBalVaultToken, "ER019");
        require(IERC20(token).balanceOf(address(this)) >= preBalToken, "ER019");
        require(IERC20(token).balanceOf(vault) >= preVaultBalToken, "ER019");
        require(IERC4626(vaultAdapter).previewRedeem(PRECISION) >= prePreviewRedeem, 'ER019');
    }

    /**
     * @notice Triggers the withdrawal or deposit of vault-bound assets for purposes of metagovernance to/from this contract
     * @param vaultAdapter the ERC-4626 vault whose tokens are stored in this contract and which will be targeted with this call
     * @param amount The amount of tokens to withdraw/deposit to/from the ISmartWallet depository
     * @param isWithdrawal Whether these tokens are being removed for use in a vote (true) or being put back after a vote has been effected (false)
     * @dev This can only move tokens in and out of their associated vaults into and out of their associated depositories. It cannot transfer them elsewhere
     * @dev Requires correct MEV flashbots config to function as intended – withdrawal, vote, and deposit should occur within a single transaction
     */
    function withdrawOrDeposit(address vaultAdapter, uint amount, bool isWithdrawal) external override onlyMaster nonReentrant {
        IERC4626 vault = IERC4626(vaultAdapter);
        if (isWithdrawal) {
            vault.redeem(amount, address(this), address(this));
        } else {
            IERC20 token = IERC20(vault.asset());
            if(token.allowance(address(this), vaultAdapter) < amount) {
                token.safeApprove(vaultAdapter, amount);
            }
            vault.deposit(amount, address(this));
        }
    }

}