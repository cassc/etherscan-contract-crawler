// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title NoDecimalsERC20Alpha
/// @notice This contract is used to created NoDecimalsERC20Alpha that are burneable and with a fix supply
contract NoDecimalsERC20Alpha is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable {
    address public vaultAddress;
    address public lbpCreateProxyAddress;
    address public instantMintSwapProxyAddress;
    address public nftAddress; // ERC721 or ERC1155
    uint256 private immutable _defaultMintedAmount = 3 * (10**decimals());

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        string memory name,
        string memory symbol,
        address mintTo,
        uint256 initialAmount,
        address initialVaultAddress,
        address initialLbpCreateProxyAddress,
        address initialInstantMintSwapProxyAddress,
        address initialNftAddress
    ) public initializer {
        vaultAddress = initialVaultAddress;
        lbpCreateProxyAddress = initialLbpCreateProxyAddress;
        instantMintSwapProxyAddress = initialInstantMintSwapProxyAddress;
        nftAddress = initialNftAddress;
        __ERC20_init(name, symbol);
        __ERC20Burnable_init();
        _mint(mintTo, initialAmount + _defaultMintedAmount);
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function getMaxTransactionAmount() public view returns (uint256) {
        return totalSupply() - _defaultMintedAmount;
    }

    /**
     * @dev Allow transfer only between whitelisted addresses,
     * and also from and to the owner address.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        ERC20Upgradeable._beforeTokenTransfer(from, to, amount); // empty implementation, but for consistency sake
        require(
            (vaultAddress != address(0) && instantMintSwapProxyAddress != address(0) && nftAddress != address(0)),
            "Burn to mint: Vault, swap proxy, or nft contract address not set"
        );
        require(
            totalSupply() == 0 ||
                (to == lbpCreateProxyAddress) || // deposit into copper proxy
                (from == lbpCreateProxyAddress) || // withdraw from copper proxy or create lbp
                (from == vaultAddress) || // buy from vault (can only send to Vault through create proxy)
                (to == instantMintSwapProxyAddress) || // deposit into copper proxy
                (from == instantMintSwapProxyAddress) || // withdraw from copper proxy or create lbp
                (to == nftAddress) || // send to NFT for mint
                (from == nftAddress && to == address(0)), // burn to mint
            "Burn to mint: Specified transfer not supported within flow"
        );
        bool isLessThanMaximum = totalSupply() == 0 || totalSupply() - amount >= _defaultMintedAmount;
        require(
            isLessThanMaximum || from == lbpCreateProxyAddress || to == lbpCreateProxyAddress,
            "Burn to mint: Transfer tx amount must leave at least 3 tokens as dust"
        );
    }
}