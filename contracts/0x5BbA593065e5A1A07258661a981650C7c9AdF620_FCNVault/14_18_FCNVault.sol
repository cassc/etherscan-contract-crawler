// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { FCNProduct } from "./FCNProduct.sol";
import { FCNVaultMetadata, VaultStatus } from "./Structs.sol";

contract FCNVault is ERC20, Ownable {
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

    function decimals() public view virtual override returns (uint8) {
        return 6;
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
     * Product can deposit into the vault
     * @param assets is the number of underlying assets to be deposited
     * @param receiver is the address of the original depositor
     */
    function deposit(uint256 assets, address receiver) public onlyOwner returns (uint256) {
        uint256 shares = convertToShares(assets);

        _mint(receiver, shares);

        return shares;
    }

    /**
     * Redeem a given amount of shares in return for assets
     * Shares are burned from the caller
     * @param shares is the amount of shares (vault tokens) to be redeemed
     */
    function redeem(uint256 shares) external onlyOwner returns (uint256) {
        uint256 assets = convertToAssets(shares);

        _burn(msg.sender, shares);

        return assets;
    }
}