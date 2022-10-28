// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IAddLiquidity.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @title Furio Token
 * @author Steve Harmeyer
 * @notice This is the ERC20 contract for $FUR.
 */

/// @custom:security-contact [email protected]
contract Token is BaseContract, ERC20Upgradeable {
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() public initializer {
        __BaseContract_init();
        __ERC20_init("Furio", "$FUR");
    }

    function setInit() external onlyOwner {
        _properties.tax = 1000;
        _properties.vaultTax = 6000;
        _properties.pumpAndDumpTax = 5000;
        _properties.pumpAndDumpRate = 2500;
        _properties.sellCooldown = 86400; // 24 Hour cooldown
        _inSwap = false;
        _lpRewardTax = 2000;
    }

    /**
     * Properties struct.
     */
    struct Properties {
        uint256 tax;
        uint256 vaultTax;
        uint256 pumpAndDumpTax;
        uint256 pumpAndDumpRate;
        uint256 sellCooldown;
        address lpAddress;
        address swapAddress;
        address poolAddress;
        address vaultAddress;
        address safeAddress;
    }
    Properties private _properties;

    /**
     * Mappings.
     */
    mapping(address => uint256) private _lastSale;

    uint256 _lpRewardTax;
    bool _inSwap;
    modifier _swapping() {
        _inSwap = true;
        _;
        _inSwap = false;
    }
    uint256 private _lastAddLiquidityTime;
    address _addLiquidityAddress; //addLiquidity Contract address
    address _lpStakingAddress; // LPStaking contract address

    /**
     * Event.
     */
    event Sell(address seller_, uint256 sellAmount_);
    event Tax(
        address indexed from_,
        uint256 transferAmount_,
        uint256 taxAmount_
    );
    event PumpAndDump(
        address indexed from_,
        uint256 transferAmount_,
        uint256 taxAmount_
    );

    /**
     * Should add Liquidity.
     * @return bool.
     */
    function _shouldAddLiquidity() internal view returns (bool) {
        return
            !_inSwap &&
            block.timestamp >= (_lastAddLiquidityTime + 2 days);
    }

    /**
     * Should swapback.
     * @return bool.
     */
    function _shouldSwapBack() internal view returns (bool) {
        return !_inSwap && msg.sender != _properties.lpAddress;
    }

    /**
     * Get prooperties.
     * @return Properties Contract properties.
     */
    function getProperties() external view returns (Properties memory) {
        return _properties;
    }

    /**
     * Get last sell.
     * @param address_ Address of seller.
     * @return uint256 Last sale timestamp.
     */
    function getLastSell(address address_) external view returns (uint256) {
        return _lastSale[address_];
    }

    /**
     * is on cooldown?
     * @param address_ Address of seller.
     * @return bool True if on cooldown.
     */
    function onCooldown(address address_) public view returns (bool) {
        return
            _lastSale[address_] >= block.timestamp - _properties.sellCooldown;
    }

    /**
     * Approve.
     * @param owner Address of owner.
     * @param spender Address of spender.
     * @param amount Amount to approve.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        return super._approve(owner, spender, amount);
    }

    /**
     * _transfer override for taxes.
     * @param from_ From address.
     * @param to_ To address.
     * @param amount_ Transfer amount.
     */
    function _transfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal override {
        if (_properties.lpAddress == address(0) ||
            _properties.safeAddress == address(0) ||
            _properties.swapAddress == address(0) ||
            _properties.vaultAddress == address(0) ||
            _addLiquidityAddress == address(0) ||
            _lpStakingAddress == address(0)
        ) {
            updateAddresses();
        }
        if (amount_ == 0) {
            // No tax on zero amount transactions.
            return super._transfer(from_, to_, amount_);
        }
        if (_inSwap) {
            // No tax on add liquidity and swapback.
            return super._transfer(from_, to_, amount_);
        }
        if (
            from_ == _properties.safeAddress || to_ == _properties.safeAddress
        ) {
            // No tax on safe transfers.
            return super._transfer(from_, to_, amount_);
        }
        if (from_ == _properties.poolAddress) {
            // No tax on transfers from pool.
            return super._transfer(from_, to_, amount_);
        }
        if (from_ == _properties.vaultAddress || to_ == _properties.vaultAddress) {
            // No tax on vault transfers.
            return super._transfer(from_, to_, amount_);
        }
        if (from_ == _properties.lpAddress && to_ == _properties.swapAddress) {
            // No tax on transfers from LP to swap.
            return super._transfer(from_, to_, amount_);
        }
        if (from_ == _properties.swapAddress && to_ == _properties.lpAddress) {
            // No tax on transfers from swap to LP.
            return super._transfer(from_, to_, amount_);
        }
        if (from_ == _lpStakingAddress || to_ == _lpStakingAddress) {
            // No tax on transfers on LP staking contract
            return super._transfer(from_, to_, amount_);
        }
        if (_shouldAddLiquidity()) {
            _addLiquidity();
        }

        uint256 _taxes_ = (amount_ * _properties.tax) / 10000;

        //** sell **//
        if (!_isExchange(from_) && _isExchange(to_)) {
            require(!onCooldown(from_), "Sell cooldown in effect");
            _lastSale[from_] = block.timestamp;
            _taxes_ += _pumpAndDumpTaxAmount(from_, amount_);
        }

        uint256 _vaultTax_ = (_taxes_ * _properties.vaultTax) / 10000;
        uint256 _lpRewardTax_ = (_taxes_ * _lpRewardTax) / 10000;
        super._transfer(from_, _addLiquidityAddress, _lpRewardTax_);
        super._transfer(from_, _properties.vaultAddress, _vaultTax_);

        //** buy **//
        if (_isExchange(from_) && !_isExchange(to_)) {
            super._transfer(
                from_,
                address(this),
                _taxes_ - _vaultTax_ - _lpRewardTax_
            );
            if (_shouldSwapBack()) {
                _swapBack();
            }

        }
        else{
            super._transfer(
                from_,
                _properties.safeAddress,
                _taxes_ - _vaultTax_ - _lpRewardTax_
            );
        }
        amount_ -= _taxes_;
        emit Tax(from_, amount_, _taxes_);
        super._transfer(from_, to_, amount_);
    }

    /**
     * auto add liquidity.
     */
    function _addLiquidity() internal _swapping {
        IAddLiquidity _AddLiquidity_ = IAddLiquidity(_addLiquidityAddress);
        _AddLiquidity_.addLiquidity();
        _lastAddLiquidityTime = block.timestamp;
    }

    function _swapBack() internal _swapping {
        IUniswapV2Router02 router = IUniswapV2Router02(
            addressBook.get("router")
        );
        require(address(router) != address(0), "Router not set");
        IERC20 USDC = IERC20(addressBook.get("payment"));
        require(address(USDC) != address(0), "Payment not set");

        _approve(address(this), address(router), balanceOf(address(this)));
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(USDC);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            balanceOf(address(this)),
            0,
            path,
            _properties.safeAddress,
            block.timestamp
        );
    }

    /**
     * Pump and dump tax amount.
     * @param from_ Sender.
     * @param amount_ Amount.
     * @return uint256 PnD tax amount.
     */
    function _pumpAndDumpTaxAmount(address from_, uint256 amount_)
        internal
        returns (uint256)
    {
        // Check vault.
        uint256 _taxAmount_;
        IVault _vaultContract_ = IVault(_properties.vaultAddress);
        if (!_vaultContract_.participantMaxed(from_)) {
            // Participant isn't maxed.
            if (
                amount_ >
                (_vaultContract_.participantBalance(from_) *
                    _properties.pumpAndDumpRate) /
                    10000
            ) {
                _taxAmount_ = (amount_ * _properties.pumpAndDumpTax) / 10000;
                emit PumpAndDump(from_, amount_, _taxAmount_);
            }
        }
        return _taxAmount_;
    }

    /**
     * Is exchange?
     * @param address_ Address to check.
     * @return bool True if swap or lp
     */
    function _isExchange(address address_) internal view returns (bool) {
        return
            address_ == _properties.swapAddress ||
            address_ == _properties.lpAddress;
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
     * Set vault tax.
     * @param vaultTax_ New vault tax rate.
     * @dev Sets the vault tax rate.
     */
    function setVaultTax(uint256 vaultTax_) external onlyOwner {
        require(vaultTax_ <= 10000, "Invalid amount");
        _properties.vaultTax = vaultTax_;
    }

    /**
     * Set pump and dump tax.
     * @param pumpAndDumpTax_ New vault tax rate.
     * @dev Sets the pump and dump tax rate.
     */
    function setPumpAndDumpTax(uint256 pumpAndDumpTax_) external onlyOwner {
        _properties.pumpAndDumpTax = pumpAndDumpTax_;
    }

    /**
     * Set pump and dump rate.
     * @param pumpAndDumpRate_ New vault Rate rate.
     * @dev Sets the pump and dump Rate rate.
     */
    function setPumpAndDumpRate(uint256 pumpAndDumpRate_) external onlyOwner {
        _properties.pumpAndDumpRate = pumpAndDumpRate_;
    }

    /**
     * Set sell cooldown period.
     * @param sellCooldown_ New cooldown rate.
     * @dev Sets the cooldown rate.
     */
    function setSellCooldown(uint256 sellCooldown_) external onlyOwner {
        _properties.sellCooldown = sellCooldown_;
    }

    /**
     * Update addresses.
     * @dev Updates stored addresses.
     */
    function updateAddresses() public {
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
        if (address_ == owner()) {
            return true;
        }
        if (address_ == addressBook.get("claim")) {
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