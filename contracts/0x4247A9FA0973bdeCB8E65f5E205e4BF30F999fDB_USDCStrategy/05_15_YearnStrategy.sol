// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// Openzeppelin imports
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// Yearn imports
import "./VaultInterface.sol";

/// Local imports
import "./IStrategy.sol";

/**
 * @title Implementation of the Yearn Strategy.
 */
contract YearnStrategy is IStrategy {

    using SafeERC20 for IERC20;

    /// Public override member functions
    function decimals() public pure virtual override returns (uint256) {

        return 0;
    }

    function vaultAddress() public view virtual override returns (address) {

        return 0x0000000000000000000000000000000000000000;
    }

    function vaultTokenAddress() public view virtual override returns (address) {
        return 0x0000000000000000000000000000000000000000;
    }

    function farm(address erc20Token_, uint256 amount_) public override returns (uint256) {
        require(amount_ <= IERC20(erc20Token_).balanceOf(address(this)), "Insufficient balance");

        uint256 vaultTokenAmount = amount_;
        if (erc20Token_ != vaultTokenAddress()) {
            uint256 amountBefore = IERC20(vaultTokenAddress()).balanceOf(address(this));
            vaultTokenAmount = IERC20(vaultTokenAddress()).balanceOf(address(this)) - amountBefore;
        }

        IERC20(vaultTokenAddress()).safeApprove(vaultAddress(), vaultTokenAmount);

        VaultInterface(vaultAddress()).deposit(vaultTokenAmount);
        return vaultTokenAmount;
    }

    function estimateReward(address addr_) external view override returns (uint256) {
        return (VaultInterface(vaultAddress()).balanceOf(addr_) *
                VaultInterface(vaultAddress()).pricePerShare()) / (10**decimals());
    }

    function takeReward(address to_, uint256 amount_) public virtual override {

        VaultInterface(vaultAddress()).withdraw(amount_, to_);
    }

    function takeReward(address to_) public override {

        VaultInterface(vaultAddress()).withdraw(type(uint256).max, to_);
    }
}