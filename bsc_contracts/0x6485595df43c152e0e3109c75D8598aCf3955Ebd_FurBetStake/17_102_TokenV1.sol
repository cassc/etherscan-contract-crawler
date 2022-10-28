// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IAddLiquidity.sol";
import "./interfaces/ITaxHandler.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

/**
 * @title Furio Token
 * @author Steve Harmeyer
 * @notice This is the ERC20 contract for $FUR.
 */

/// @custom:security-contact [email protected]
contract TokenV1 is BaseContract, ERC20Upgradeable {
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() public initializer {
        __BaseContract_init();
        __ERC20_init("Furio", "$FUR");
    }

    /**
     * Properties struct.
     */
    struct Properties {
        uint256 tax;
        uint256 vaultTax; // ...................................................DEPRECATED
        uint256 pumpAndDumpTax; // .............................................DEPRECATED
        uint256 pumpAndDumpRate; // ............................................DEPRECATED
        uint256 sellCooldown; // ...............................................DEPRECATED
        address lpAddress;
        address swapAddress;
        address poolAddress;
        address vaultAddress;
        address safeAddress;
    }
    Properties private _properties;

    mapping(address => uint256) private _lastSale; // ..........................DEPRECATED
    uint256 _lpRewardTax; // ...................................................DEPRECATED
    bool _inSwap; // ...........................................................DEPRECATED
    uint256 private _lastAddLiquidityTime; // ..................................DEPRECATED

    /**
     * External contracts.
     */
    address _addLiquidityAddress;
    address _lpStakingAddress;
    address private _lmsAddress;
    ITaxHandler private _taxHandler;

    /**
     * Addresses that can swap.
     */
    mapping(address => bool) private _canSwap;

    /**
     * Get prooperties.
     * @return Properties Contract properties.
     */
    function getProperties() external view returns (Properties memory) {
        return _properties;
    }

    /**
     * _transfer override.
     * @param from_ From address.
     * @param to_ To address.
     * @param amount_ Transfer amount.
     */
    function _transfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal override {
        if(from_ == _properties.lpAddress) require(_canSwap[to_], "FUR: No swaps from external contracts");
        if(to_ == _properties.lpAddress) require(_canSwap[from_], "FUR: No swaps from external contracts");
        uint256 _taxes_ = 0;
        if(!_taxHandler.isExempt(from_) && !_taxHandler.isExempt(to_)) {
            _taxes_ = amount_ * _properties.tax / 10000;
            super._transfer(from_, address(_taxHandler), _taxes_);
        }
        return super._transfer(from_, to_, amount_ - _taxes_);
    }

    /**
     * -------------------------------------------------------------------------
     * ADMIN FUNCTIONS.
     * -------------------------------------------------------------------------
     */
    function mint(address to_, uint256 quantity_) external {
        require(_canMint(msg.sender), "Unauthorized");
        super._mint(to_, quantity_);
    }

    /**
     * Set tax.
     * @param tax_ New tax rate.
     * @dev Sets the default tax rate.
     */
    function setTax(uint256 tax_) external onlyOwner {
        _properties.tax = tax_;
    }


    /**
     * Setup.
     * @dev Updates stored addresses.
     */
    function setup() public {
        IUniswapV2Factory _factory_ = IUniswapV2Factory(
            addressBook.get("factory")
        );
        _properties.lpAddress = _factory_.getPair(
            addressBook.get("payment"),
            address(this)
        );
        _properties.swapAddress = addressBook.get("swap");
        _properties.poolAddress = addressBook.get("pool");
        _properties.vaultAddress = addressBook.get("vault");
        _properties.safeAddress = addressBook.get("safe");
        _addLiquidityAddress = addressBook.get("addLiquidity");
        _lpStakingAddress = addressBook.get("lpStaking");
        _taxHandler = ITaxHandler(addressBook.get("taxHandler"));
        _lmsAddress = addressBook.get("liquidityManager");
        _canSwap[_properties.swapAddress] = true;
        _canSwap[_properties.poolAddress] = true;
        _canSwap[_addLiquidityAddress] = true;
        _canSwap[_lpStakingAddress] = true;
        _canSwap[_lmsAddress] = true;
        _canSwap[address(_taxHandler)] = true;
    }

    /**
     * -------------------------------------------------------------------------
     * HOOKS.
     * -------------------------------------------------------------------------
     */

    /**
     * @dev Add whenNotPaused modifier to token transfer hook.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {}

    /**
     * -------------------------------------------------------------------------
     * ACCESS.
     * -------------------------------------------------------------------------
     */

    /**
     * Can mint?
     * @param address_ Address of sender.
     * @return bool True if trusted.
     */
    function _canMint(address address_) internal view returns (bool) {
        if (address_ == addressBook.get("safe")) {
            return true;
        }
        if (address_ == addressBook.get("downline")) {
            return true;
        }
        if (address_ == addressBook.get("pool")) {
            return true;
        }
        if (address_ == addressBook.get("vault")) {
            return true;
        }
        return false;
    }
}