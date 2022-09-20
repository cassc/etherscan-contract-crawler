// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IResolver {
    function checker() external view returns (bool canExec, bytes memory execPayload);
}

import "./abstracts/BaseContract.sol";
import "./interfaces/ISwapV2.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

/// @custom:security-contact [email protected]
contract TaxHandler is BaseContract, IResolver
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
    }

    /**
     * Taxes.
     */
    mapping (address => bool) private _isExempt;
    uint256 public lpTax;
    uint256 public vaultTax;

    /**
     * Addresses.
     */
    address public addLiquidityAddress;
    address public lpStakingAddress;
    address public safeAddress;
    address public vaultAddress;

    /**
     * Tokens.
     */
    IERC20 public fur;
    IERC20 public usdc;

    /**
     * Exchanges.
     */
    ISwapV2 public swap;

    /**
     * Last distribution.
     */
    uint256 public distributionInterval;
    uint256 public lastDistribution;

    /**
     * Checker.
     */
    function checker() external view override returns (bool canExec, bytes memory execPayload)
    {
        if(lastDistribution + distributionInterval <= block.timestamp) return (false, bytes("Distribution is not due"));
        return(true, abi.encodeWithSelector(this.distribute.selector));
    }

    /**
     * Check if address is exempt.
     * @param address_ Address to check.
     * @return bool True if address is exempt.
     */
    function isExempt(address address_) external view returns (bool)
    {
        return _isExempt[address_];
    }

    /**
     * Add tax exemption.
     * @param address_ Address to be exempt.
     */
    function addTaxExemption(address address_) external onlyOwner
    {
        _isExempt[address_] = true;
    }

    /**
     * Distribute taxes.
     */
    function distribute() external
    {
        // Convert all FUR to USDC.
        uint256 _furBalance_ = fur.balanceOf(address(this));
        if(_furBalance_ > 0) {
            fur.approve(address(swap), _furBalance_);
            swap.sell(_furBalance_);
        }
        // Get USDC balance.
        uint256 _usdcBalance_ = usdc.balanceOf(address(this));
        // Calculate taxes.
        uint256 _vaultTax_ = _usdcBalance_ * vaultTax / 10000;
        uint256 _lpTax_ = _usdcBalance_ * lpTax / 10000;
        // Handle vault taxes.
        if(_vaultTax_ > 0) {
            // Swap USDC for FUR to cover vault taxes.
            usdc.approve(address(swap), _vaultTax_);
            swap.buy(address(usdc), _vaultTax_);
            // Transfer FUR to vault.
            fur.transfer(vaultAddress, fur.balanceOf(address(this)));
        }
        // Handle liquidity taxes.
        if(_lpTax_ > 0) {
            // Transfer USDC to AddLiquidity contract.
            usdc.transfer(addLiquidityAddress, _lpTax_);
        }
        // Transfer remaining USDC to safe
        usdc.transfer(safeAddress, usdc.balanceOf(address(this)));
        lastDistribution = block.timestamp;
    }

    /**
     * Setup.
     */
    function setup() external
    {
        // Addresses.
        addLiquidityAddress = addressBook.get("addLiquidity");
        lpStakingAddress = addressBook.get("lpStaking");
        safeAddress = addressBook.get("safe");
        vaultAddress = addressBook.get("vault");
        // Tokens.
        fur = IERC20(addressBook.get("token"));
        usdc = IERC20(addressBook.get("payment"));
        // Exchanges.
        swap = ISwapV2(addressBook.get("swap"));
        // Exemptions.
        _isExempt[address(this)] = true;
        _isExempt[address(swap)] = true;
        _isExempt[addLiquidityAddress] = true;
        _isExempt[lpStakingAddress] = true;
        _isExempt[safeAddress] = true;
        _isExempt[vaultAddress] = true;
        _isExempt[addressBook.get("downline")] = true;
        _isExempt[addressBook.get("pool")] = true;
        _isExempt[addressBook.get("router")] = true;
        // Taxes.
        lpTax = 2000;
        vaultTax = 6000;
        // Distributions.
        distributionInterval = 2 hours;
    }
}