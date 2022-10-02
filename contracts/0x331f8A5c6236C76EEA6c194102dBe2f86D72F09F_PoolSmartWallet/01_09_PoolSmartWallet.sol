pragma solidity ^0.8.0;
// SPDX-License-Identifier: GNU-GPL v3.0 or later

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IERC4626.sol";
import "./interfaces/IPoolWallet.sol";

/// @author RobAnon
/** @title Pool Smart Wallet. */
contract PoolSmartWallet is IPoolWallet, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    /// Address for msg.sender
    address public immutable override MASTER;
    /// Resonate address
    address public immutable override RESONATE;

    /// IERC20 Interface ID
    bytes4 public constant IERC20_INTERFACE = type(IERC20).interfaceId;

    /**
     * @notice constructor for PoolSmartWallet
     * @param _resonate the address of resonate
     */
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
     * @notice Transfers tokens to recipient after taking dev fee
     * @param value value to be withdrawn
     * @param fee fee to be taken
     * @param token token to be transferred
     * @param recipient recipient the tokens will be transferred to
     * @param devWallet address of dev wallet
     * @dev given fee > 0, actual value transferred will always be less than passed value.
     */ 
    function withdraw(
        uint value, 
        uint fee, 
        address token, 
        address recipient, 
        address devWallet
    ) external override onlyMaster nonReentrant {
        IERC20(token).safeTransfer(recipient, value - fee);
        if(fee > 0 && devWallet != address(0)) {
            IERC20(token).safeTransfer(devWallet, fee);
        }
    }

    /**
     * @notice Deposits tokens into vault and directs shares to smartWallet
     * @param amountTokens amount of tokens to deposit
     * @param vaultAddress address of vault to deposit to
     * @param smartWallet address of smartWallet to direct shares to
     * @return shares number of adapter shares minted from deposit
     * @dev Allows for deposit of tokens from this contract to ERC-4626 vault, used by non-farming consumer positions.
     */ 
    function depositAndTransfer(
        uint amountTokens, 
        address vaultAddress, 
        address smartWallet
    ) external override onlyMaster nonReentrant returns (uint shares) {
        IERC4626 vault = IERC4626(vaultAddress);
        _checkApproval(amountTokens, vault.asset(), vaultAddress);
        shares = vault.deposit(amountTokens, smartWallet);
    }
    /**
     * @notice Redeems shares from vault and directs assets to receiver
     * @param shares amount of shares to redeem
     * @param receiver address to direct redeemed assets to
     * @param vault address of vault to redeem from
     * @return tokens number of tokens from redemption
     */
    function withdrawFromVault(
        uint shares, 
        address receiver, 
        address vault
    ) external override onlyMaster nonReentrant returns (uint tokens) {
        tokens = IERC4626(vault).redeem(shares, receiver, address(this));
    }

    /**
     * @notice Route interest accumulated in consumer queue to the dev wallet, then transfer adapter shares to fnft
     * @param amountUnderlying principal amount
     * @param totalShares total shares
     * @param fnftWallet address of fnft wallet
     * @param devWallet address of dev wallet
     * @param vaultAdapter address of vaultAdapter
     * @return shares amount of shares transferred
     * @return interest amount of interest captured
     */
    function activateExistingConsumerPosition(
        uint amountUnderlying, 
        uint totalShares, 
        address fnftWallet,
        address devWallet,
        address vaultAdapter
    ) external override onlyMaster nonReentrant returns (uint shares, uint interest) {
        IERC4626 vault = IERC4626(vaultAdapter);
        uint totalValueOfShares = vault.previewRedeem(totalShares);
        if(totalValueOfShares > amountUnderlying) {
            interest = totalValueOfShares - amountUnderlying;
        }

        // Where devs take profits         
        // Withdraw is acceptable here since it is proceeded by previewRedeem
        shares = interest > 0 ? totalShares - vault.withdraw(interest, devWallet, address(this)) : totalShares;
        IERC20(vaultAdapter).safeTransfer(fnftWallet, shares);
    }

    /**
     * @notice Withdraw purchaser queue position and send upfront payment to consumer
     * @param amountUnderlying amount underlying
     * @param totalShares total shares to redeem
     * @param fee fee to transfer to dev wallet
     * @param consumer address of consumer
     * @param devWallet address of devWallet
     * @param vaultAdapter address of vault adapter
     * @return interest amount of interest received
     * @dev Amount underlying is inclusive of fee
     * 
     */
    function activateExistingProducerPosition(
        uint amountUnderlying, 
        uint totalShares, 
        uint fee,
        address consumer,
        address devWallet,
        address vaultAdapter
    ) external override onlyMaster nonReentrant returns (uint interest) {
        IERC4626 vault = IERC4626(vaultAdapter);
        IERC20 asset = IERC20(vault.asset());

        // Edge-case handling for withdrawal fees
        uint assets = vault.redeem(totalShares, address(this), address(this));
        if(assets > amountUnderlying) {
            interest = assets - amountUnderlying;
        } else {
            // Recalculate fee to avoid over-charging percentagewise
            fee = assets * fee / amountUnderlying;
            amountUnderlying = assets;
        }
        
        asset.safeTransfer(consumer, amountUnderlying - fee);
        asset.safeTransfer(devWallet, interest + fee);
    }

    function _checkApproval(uint amountUnderlying, address token, address vaultAdapter) private {
        if(IERC20(token).allowance(address(this), vaultAdapter) < amountUnderlying) {
            IERC20(token).safeApprove(vaultAdapter, 0);
            IERC20(token).safeApprove(vaultAdapter, type(uint).max);
        }
    }

}