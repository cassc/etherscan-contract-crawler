// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { FCNProduct } from "./FCNProduct.sol";
import { FCNVaultMetadata, VaultStatus } from "./Structs.sol";

contract FCNVault is IERC4626, ERC20, Ownable {
    using SafeERC20 for ERC20;

    address public asset;
    FCNProduct public fcnProduct;

    /**
     * @notice Creates a new FCNVault that is owned by the FCNProduct
     * @param _asset is the address of the underlying asset
     * @param _tokenName is the name of the token
     * @param _tokenSymbol is the name of the token symbol
     */
    constructor(address _asset, string memory _tokenName, string memory _tokenSymbol) ERC20(_tokenName, _tokenSymbol) {
        asset = _asset;
        fcnProduct = FCNProduct(owner());
    }

    /**
     * @notice Returns underlying amount associated for the vault
     */
    function totalAssets() public view returns (uint256) {
        (, , , , , uint256 underlyingAmount, , , , , , , , , , ) = fcnProduct.vaults(address(this));
        return underlyingAmount;
    }

    /**
     * @notice Converts units of shares to assets
     * @param shares is the number of vault tokens
     */
    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) return 0;
        return (shares * totalAssets()) / _totalSupply;
    }

    /**
     * @notice Converts units assets to shares
     * @param assets is the amount of underlying assets
     */
    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        uint256 _totalAssets = totalAssets();
        if (_totalAssets == 0 || _totalSupply == 0) return assets;
        return (assets * _totalSupply) / _totalAssets;
    }

    /**
     * @notice Maximum sum of deposits that a vault can accept
     */
    function maxDeposit(address) external pure returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @notice Preview the amount of shares for a given deposit
     * @param assets is the amount of underlying assets
     */
    function previewDeposit(uint256 assets) external view returns (uint256) {
        return convertToShares(assets);
    }

    /**
     * Product can deposit into the vault
     * @param assets is the number of underlying assets to be deposited
     * @param receiver is the address of the original depositor
     */
    function deposit(uint256 assets, address receiver) public onlyOwner returns (uint256) {
        uint256 shares = convertToShares(assets);

        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);

        return shares;
    }

    /**
     * @notice Product can deposit into the vault
     * @param assets is the number of underlying assets to be deposited
     */
    function deposit(uint256 assets) external onlyOwner returns (uint256) {
        return deposit(assets, msg.sender);
    }

    /**
     * @notice Maximum amount of shares (vault tokens) that can be minted
     */
    function maxMint(address) external pure returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @notice Preview the amount of assets to return for an amount of shares
     * @param shares is the number of vault tokens
     */
    function previewMint(uint256 shares) external view returns (uint256) {
        uint256 assets = convertToAssets(shares);
        if (assets == 0 && totalAssets() == 0) return shares;
        return assets;
    }

    /**
     * @notice Mint a given amount of shares & deduct the correct amount of assets to do so
     * @param shares is the number of shares (vault tokens)
     * @param receiver is the address of the receiver
     */
    function mint(uint256 shares, address receiver) public onlyOwner returns (uint256) {
        uint256 assets = convertToAssets(shares);

        if (totalAssets() == 0) assets = shares;

        ERC20(asset).safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);

        return assets;
    }

    /**
     * Mint a given amount of shares (vault tokens)
     * @param shares is the number of shares
     */
    function mint(uint256 shares) external onlyOwner returns (uint256) {
        return mint(shares, msg.sender);
    }

    /**
     * @notice Maximum amount that can be withdrawn
     */
    function maxWithdraw(address) external pure returns (uint256) {
        return type(uint256).max;
    }

    /**
     * Preview the amount of shares that would be withdrawn to return assets
     * @param assets is the number of assets
     */
    function previewWithdraw(uint256 assets) external view returns (uint256) {
        uint256 shares = convertToShares(assets);
        if (totalSupply() == 0) return 0;
        return shares;
    }

    /**
     * Withdraw for a given amount of assets and burn shares
     * @param assets is the amount of assets
     * @param receiver is the receiver of the assets
     * @param owner is the owner of the shares to be withdrawn
     */
    function withdraw(uint256 assets, address receiver, address owner) public onlyOwner returns (uint256) {
        uint256 shares = convertToShares(assets);

        if (owner != msg.sender) {
            _spendAllowance(owner, msg.sender, shares);
        }
        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return shares;
    }

    /**
     * Withdraw a given amount of assets and burn shares
     * @param assets is the amount of assets to withdraw
     * @param receiver is the address of the receiver of the assets
     */
    function withdraw(uint256 assets, address receiver) external onlyOwner returns (uint256) {
        return withdraw(assets, receiver, msg.sender);
    }

    /**
     * Withdraw a given amount of assets and burn shares
     * the owner of the shares and receiver of assets is the same address
     * @param assets is the number of underlying assets to be withdrawn
     */
    function withdraw(uint256 assets) external onlyOwner returns (uint256) {
        return withdraw(assets, msg.sender, msg.sender);
    }

    /**
     * Maximum amount that can be redeemed
     */
    function maxRedeem(address) external pure returns (uint256) {
        return type(uint256).max;
    }

    /**
     * Preview amount of assets that can be redeemed
     * @param shares is the amount of shares to be redeemed
     */
    function previewRedeem(uint256 shares) external view returns (uint256) {
        return convertToAssets(shares);
    }

    /**
     * Redeem a given amount of shares in return for assets
     * @param shares is the amount of shares (vault tokens) to be redeemed
     * @param receiver is the address to receive assets
     * @param owner is the owner of the shares
     */
    function redeem(uint256 shares, address receiver, address owner) public onlyOwner returns (uint256) {
        uint256 assets = convertToAssets(shares);

        if (owner != msg.sender) {
            _spendAllowance(owner, msg.sender, shares);
        }
        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return assets;
    }

    /**
     * Redeem a given amount of shares in return for assets
     * Shares are burned from the caller
     * @param shares is the amount of shares (vault tokens) to be redeemed
     * @param receiver is the address to receive assets
     */
    function redeem(uint256 shares, address receiver) external onlyOwner returns (uint256) {
        return redeem(shares, receiver, msg.sender);
    }

    /**
     * Redeem a given amount of shares in return for assets
     * Shares are burned from the caller & assets sent to the caller
     * @param shares is the amount of shares (vault tokens) to be redeemed
     */
    function redeem(uint256 shares) external onlyOwner returns (uint256) {
        return redeem(shares, msg.sender, msg.sender);
    }
}