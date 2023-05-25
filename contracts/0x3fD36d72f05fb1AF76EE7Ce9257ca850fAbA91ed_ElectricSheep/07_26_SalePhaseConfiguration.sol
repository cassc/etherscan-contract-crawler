// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract SalePhaseConfiguration is Ownable {
    error BuilderMintNotActive();
    error PublicSaleNotActive();
    error AllowlistNotActive();
    error SaleAlreadyStarted();

    event BuilderMintStarted(uint256 price, uint256 amount);
    event BuilderMintStopped();
    event AllowlistStarted(uint256 price, uint256 amount);
    event AllowlistStopped();
    event PublicSaleStarted(uint256 price, uint256 amount);
    event PublicSaleStopped();

    bool public builderMintActive;
    bool public allowlistActive;
    bool public publicSaleActive;

    uint256 public builderMintPrice;
    uint256 public builderMintMaxPerAddress;
    uint256 public builderMintMaxAmount;

    uint256 public allowlistPrice;
    uint256 public allowlistMaxMintPerAddress;
    uint256 public allowlistMaxAmount;

    uint256 public publicSalePrice;
    uint256 public publicSaleMaxMintPerAddress;
    uint256 public publicSaleMaxAmount;

    /**
     * @notice Allowlist mint is started
     */
    modifier whenAllowlistActive() {
        if (!allowlistActive) {
            revert AllowlistNotActive();
        }
        _;
    }

    /**
     * @notice Public sale mint is started
     */
    modifier whenPublicSaleActive() {
        if (!publicSaleActive) {
            revert PublicSaleNotActive();
        }
        _;
    }

    /**
     * @notice Builder mint is started
     */
    modifier whenBuilderMintActive() {
        if (!builderMintActive) {
            revert BuilderMintNotActive();
        }
        _;
    }

    /**
     * @notice Start builder mint
     * @param price mint price
     * @param maxMintPerAddress maximal amount for every address can mint
     * @param maxAmount maximal amount for whole public sale
     */
    function startBuilderMint(
        uint256 price,
        uint256 maxMintPerAddress,
        uint256 maxAmount
    ) external onlyOwner {
        if (builderMintActive) {
            revert SaleAlreadyStarted();
        }

        builderMintPrice = price;
        builderMintMaxPerAddress = maxMintPerAddress;
        builderMintMaxAmount = maxAmount;
        builderMintActive = true;

        emit BuilderMintStarted(price, maxAmount);
    }

    /**
     * @notice Stop builder mint
     */
    function stopBuilderMint() external onlyOwner {
        builderMintActive = false;
        emit BuilderMintStopped();
    }

    /**
     * @notice Start allowlist mint
     * @param price mint price
     * @param maxMintPerAddress maximal amount for every address can mint
     * @param maxAmount maximal amount for whole allowlist
     */
    function startAllowlist(
        uint256 price,
        uint256 maxMintPerAddress,
        uint256 maxAmount
    ) external onlyOwner {
        if (allowlistActive) {
            revert SaleAlreadyStarted();
        }

        allowlistPrice = price;
        allowlistMaxMintPerAddress = maxMintPerAddress;
        allowlistMaxAmount = maxAmount;
        allowlistActive = true;

        emit AllowlistStarted(price, maxAmount);
    }

    /**
     * @notice Stop allowlist mint
     */
    function stopAllowlist() external onlyOwner {
        allowlistActive = false;
        emit AllowlistStopped();
    }

    /**
     * @notice Start public sale mint
     * @param price mint price
     * @param maxMintPerAddress maximal amount for every address can mint
     * @param maxAmount maximal amount for whole public sale
     */
    function startPublicSale(
        uint256 price,
        uint256 maxMintPerAddress,
        uint256 maxAmount
    ) external onlyOwner {
        if (publicSaleActive) {
            revert SaleAlreadyStarted();
        }

        publicSalePrice = price;
        publicSaleMaxMintPerAddress = maxMintPerAddress;
        publicSaleMaxAmount = maxAmount;
        publicSaleActive = true;

        emit PublicSaleStarted(price, maxAmount);
    }

    /**
     * @notice Stop public sale mint
     */
    function stopPublicSale() external onlyOwner {
        publicSaleActive = false;
        emit PublicSaleStopped();
    }
}