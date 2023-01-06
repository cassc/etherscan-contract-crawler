// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
// INTERFACES
import "./interfaces/ILiquidityManager.sol";
import "./interfaces/ILPStakingV1.sol";
import "./interfaces/ITaxHandler.sol";
import "./interfaces/IVault.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

error SWAP__onSellCooldown();
error SWAP__exceedsMaxSale();
error SWAP__transferFailed();

/// @custom:security-contact [email protected]
contract SwapV2 is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
        tax = 1000;
        pumpAndDumpMultiplier = 6; // Tax at 6x the normal rate (e.g. 60% instead of 10%)
        pumpAndDumpRate = 2500; // 25%
        cooldownPeriod = 1 days;
    }

    /**
     * Contracts.
     */
    IUniswapV2Factory public factory;
    IERC20 public fur;
    ILiquidityManager public liquidityManager;
    IUniswapV2Pair public pair;
    IUniswapV2Router02 public router;
    ITaxHandler public taxHandler;
    IERC20 public usdc;
    IVault public vault;

    /**
     * Taxes.
     */
    uint256 public tax;
    uint256 public pumpAndDumpMultiplier;
    uint256 public pumpAndDumpRate;

    /**
     * Cooldown.
     */
    uint256 public cooldownPeriod;
    mapping(address => bool) private _isExemptFromCooldown;
    mapping(address => uint256) public lastSell;

    /**
     * Liquidity manager.
     */
    bool public liquidityManagerEnabled;

    /**
     * Limits.
     */
    uint256 public maxSale;

    /**
     * Contract setup.
     */
    function setup() external
    {
        factory = IUniswapV2Factory(addressBook.get("factory"));
        fur = IERC20(addressBook.get("token"));
        liquidityManager = ILiquidityManager(addressBook.get("liquidityManager"));
        router = IUniswapV2Router02(addressBook.get("router"));
        taxHandler = ITaxHandler(addressBook.get("taxHandler"));
        usdc = IERC20(addressBook.get("payment"));
        vault = IVault(addressBook.get("vault"));
        pair = IUniswapV2Pair(factory.getPair(address(fur), address(usdc)));
        _isExemptFromCooldown[address(this)] = true;
        _isExemptFromCooldown[address(liquidityManager)] = true;
        _isExemptFromCooldown[address(taxHandler)] = true;
        _isExemptFromCooldown[addressBook.get("addLiquidity")] = true;
        _isExemptFromCooldown[addressBook.get("furmax")] = true;
        _isExemptFromCooldown[0x77F50D741997DbBBb112C58dec50315E2De8Da58] = true;
        _isExemptFromCooldown[addressBook.get("safe")] = true;
        _isExemptFromCooldown[owner()] = true;
        maxSale = 100e18;
    }

    /**
     * Buy FUR.
     * @param payment_ Address of payment token.
     * @param amount_ Amount of tokens to spend.
     */
    function buy(address payment_, uint256 amount_) external whenNotPaused
    {
        // Buy FUR.
        uint256 _received_ = _buy(msg.sender, payment_, amount_);
        // Transfer received FUR to sender.
        if(!fur.transfer(msg.sender, _received_)) revert SWAP__transferFailed();
    }

    /**
     * Deposit buy.
     * @param payment_ Address of payment token.
     * @param amount_ Amount of payment.
     */
    function depositBuy(address payment_, uint256 amount_) external whenNotPaused
    {
        // Buy FUR.
        uint256 _received_ = _buy(msg.sender, payment_, amount_);
        // Deposit into vault.
        vault.depositFor(msg.sender, _received_, address(0));
    }

    /**
     * Deposit buy with referrer.
     * @param payment_ Address of payment token.
     * @param amount_ Amount of payment.
     * @param referrer_ Address of referrer.
     */
    function depositBuy(address payment_, uint256 amount_, address referrer_) external whenNotPaused
    {
        // Buy FUR.
        uint256 _received_ = _buy(msg.sender, payment_, amount_);
        // Deposit into vault.
        vault.depositFor(msg.sender, _received_, referrer_);
    }

    /**
     * Internal buy FUR.
     * @param buyer_ Buyer address.
     * @param payment_ Address of payment token.
     * @param amount_ Amount of tokens to spend.
     * @return uint256 Amount of FUR received.
     */
    function _buy(address buyer_, address payment_, uint256 amount_) internal returns (uint256)
    {
        // Convert payment to USDC.
        uint256 _usdcAmount_ = _buyUsdc(payment_, amount_, buyer_);
        // Get sender exempt status.
        bool _isExempt_ = taxHandler.isExempt(buyer_);
        // Calculate USDC taxes.
        uint256 _tax_ = 0;
        if(!_isExempt_) _tax_ = _usdcAmount_ * tax / 10000;
        // Get FUR balance.
        uint256 _startingFurBalance_ = fur.balanceOf(address(this));
        // Swap USDC for FUR.
        _swap(address(usdc), address(fur), _usdcAmount_ - _tax_);
        uint256 _furSwapped_ = fur.balanceOf(address(this)) - _startingFurBalance_;
        // Transfer taxes to tax handler.
        if(_tax_ > 0) usdc.transfer(address(taxHandler), _tax_);
        // Transfer extra FUR to vault contract.
        if(_startingFurBalance_ > 0) fur.transfer(address(vault), _startingFurBalance_);
        // Return amount.
        return _furSwapped_;
    }

    /**
     * Internal buy USDC.
     * @param payment_ Address of payment token.
     * @param amount_ Amount of tokens to spend.
     * @param buyer_ Address of buyer.
     * @return uint256 Amount of USDC purchased.
     */
    function _buyUsdc(address payment_, uint256 amount_, address buyer_) internal returns (uint256)
    {
        // Instanciate payment token.
        IERC20 _payment_ = IERC20(payment_);
        // Get payment balance.
        uint256 _startingPaymentBalance_ = _payment_.balanceOf(address(this));
        // Transfer payment tokens to this address.
        if(!_payment_.transferFrom(buyer_, address(this), amount_)) revert SWAP__transferFailed();
        uint256 _balance_ = _payment_.balanceOf(address(this)) - _startingPaymentBalance_;
        // If payment is already USDC, return.
        if(payment_ == address(usdc)) {
            return _balance_;
        }
        // Swap payment for USDC.
        uint256 _startingUsdcBalance_ = usdc.balanceOf(address(this));
        _swap(address(_payment_), address(usdc), _balance_);
        uint256 _usdcSwapped_ = usdc.balanceOf(address(this)) - _startingUsdcBalance_;
        // Return tokens received.
        return _usdcSwapped_;
    }

    /**
     * Swap.
     * @param in_ Address of input token.
     * @param out_ Address of output token.
     * @param amount_ Amount of input tokens to swap.
     */
    function _swap(address in_, address out_, uint256 amount_) internal
    {
        if(liquidityManagerEnabled) {
            _swapThroughLiquidityManager(in_, out_, amount_);
        }
        else {
            _swapThroughUniswap(in_, out_, amount_);
        }
    }

    /**
     * Swap through uniswap.
     * @param in_ Input token address.
     * @param out_ Output token address.
     * @param amount_ Amount of input token.
     */
    function _swapThroughUniswap(address in_, address out_, uint256 amount_) internal
    {
        address[] memory _path_ = new address[](2);
        _path_[0] = in_;
        _path_[1] = out_;
        IERC20(in_).approve(address(router), amount_);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount_,
            0,
            _path_,
            address(this),
            block.timestamp + 3600
        );
    }

    /**
     * Swap through LMS.
     * @param in_ Input token address.
     * @param out_ Output token address.
     * @param amount_ Amount of input token.
     */
    function _swapThroughLiquidityManager(address in_, address out_, uint256 amount_) internal
    {
        if(in_ != address(fur) && out_ != address(fur)) {
            return _swapThroughUniswap(in_, out_, amount_);
        }
        IERC20(in_).approve(address(liquidityManager), amount_);
        //uint256 _output_;
        if(in_ == address(fur)) {
            liquidityManager.swapTokenForUsdc(address(this), amount_, 1);
        }
        else {
            //_output_ = buyOutput(address(usdc), amount_);
            liquidityManager.swapUsdcForToken(address(this), amount_, 1);
        }
    }

    /**
     * On cooldown.
     * @param participant_ Address of participant.
     * @return bool True if on cooldown.
     */
    function onCooldown(address participant_) public view returns (bool)
    {
        return !_isExemptFromCooldown[participant_] && lastSell[participant_] + cooldownPeriod > block.timestamp;
    }

    /**
     * Sell FUR.
     * @param amount_ Amount of FUR to sell.
     */
    function sell(uint256 amount_) external whenNotPaused
    {
        // Check cooldown.
        if(!_isExemptFromCooldown[msg.sender]) {
            if(block.timestamp < lastSell[msg.sender] + cooldownPeriod) revert SWAP__onSellCooldown();
            if(amount_ > maxSale) revert SWAP__exceedsMaxSale();
        }
        // Update last sell timestamp.
        lastSell[msg.sender] = block.timestamp;
        // Get starting FUR balance.
        uint256 _startingFurBalance_ = fur.balanceOf(address(this));
        // Transfer FUR to this contract.
        if(!fur.transferFrom(msg.sender, address(this), amount_)) revert SWAP__transferFailed();
        // Get FUR received.
        uint256 _furReceived_ = fur.balanceOf(address(this)) - _startingFurBalance_;
        // Get starting USDC balance.
        uint256 _startingUsdcBalance_ = usdc.balanceOf(address(this));
        // Swap FUR for USDC.
        _swap(address(fur), address(usdc), _furReceived_);
        uint256 _usdcSwapped_ = usdc.balanceOf(address(this)) - _startingUsdcBalance_;
        // Handle taxes.
        uint256 _taxAmount_ = calculateTax(msg.sender, _usdcSwapped_);
        _usdcSwapped_ -= _taxAmount_;
        if(_taxAmount_ > 0) usdc.transfer(address(taxHandler), _taxAmount_);
        // Handle furpool.
        uint256 _furpoolAmount_ = calculateFurpool(msg.sender, _usdcSwapped_);
        _usdcSwapped_ -= _furpoolAmount_;
        if(_furpoolAmount_ > 0) {
            address _furpool_ = 0x77F50D741997DbBBb112C58dec50315E2De8Da58;
            usdc.approve(_furpool_, _furpoolAmount_);
            ILPStakingV1(_furpool_).stakeFor(address(usdc), _furpoolAmount_, 1, msg.sender);
        }
        // Transfer received USDC to sender.
        if(!usdc.transfer(msg.sender, _usdcSwapped_)) revert SWAP__transferFailed();
    }

    /**
     * Calculate tax.
     * @param participant_ Participant address.
     * @param amount_ Amount of USDC to calculate tax for.
     * @return uint256 Tax amount.
     */
    function calculateTax(address participant_, uint256 amount_) public view returns (uint256)
    {
        if(taxHandler.isExempt(participant_)) {
            return 0;
        }
        return amount_ * tax / 10000;
    }

    /**
     * Calculate Furpool.
     * @param participant_ Participant address.
     * @param amount_ Amount of USDC to calculate furpool for.
     * @return uint256 Furpool amount.
     */
    function calculateFurpool(address participant_, uint256 amount_) public view returns (uint256)
    {
        if(taxHandler.isExempt(participant_)) {
            return 0;
        }
        return amount_ * 25 / 100;
    }

    /**
     * Enable LMS
     */
    function enableLiquidityManager() external onlyOwner
    {
        liquidityManager.enableLiquidityManager(true);
        liquidityManagerEnabled = true;
    }

    /**
     * Disable LMS
     */
    function disableLiquidtyManager() external onlyOwner
    {
        liquidityManager.enableLiquidityManager(false);
        liquidityManagerEnabled = false;
    }

    /**
     * Get token buy output.
     * @param payment_ Address of payment token.
     * @param amount_ Amount spent.
     * @return uint256 Amount of tokens received.
     */
    function buyOutput(address payment_, uint256 amount_) public view returns (uint256) {
        if(!taxHandler.isExempt(msg.sender)) {
            amount_ -= amount_ * tax / 10000;
        }
        return _getOutput(payment_, address(fur), amount_);
    }

    /**
     * Get token sell output.
     * @param amount_ Amount sold.
     * @return uint256 Amount of tokens received.
     */
    function sellOutput(uint256 amount_) external view returns (uint256) {
        return _getOutput(address(fur), address(usdc), amount_);
    }

    /**
     * Get token sell input.
     * @param amount_ Amount received.
     * @return uint256 Amount of tokens spent.
     */
    function sellInput(uint256 amount_) external view returns (uint256) {
        return _getInput(address(fur), address(usdc), amount_);
    }

    /**
     * Get output.
     * @param in_ In token.
     * @param out_ Out token.
     * @param amount_ Amount in.
     * @return uint256 Estimated tokens received.
     */
    function _getOutput(
        address in_,
        address out_,
        uint256 amount_
    ) internal view returns (uint256) {
        address[] memory _path_ = new address[](2);
        _path_[0] = in_;
        _path_[1] = out_;
        uint256[] memory _outputs_ = router.getAmountsOut(amount_, _path_);
        return _outputs_[1];
    }

    /**
     * Get input.
     * @param in_ In token.
     * @param out_ Out token.
     * @param amount_ Amount out.
     * @return uint256 Estimated tokens spent.
     */
    function _getInput(
        address in_,
        address out_,
        uint256 amount_
    ) internal view returns (uint256) {
        address[] memory _path_ = new address[](2);
        _path_[0] = in_;
        _path_[1] = out_;
        uint256[] memory _inputs_ = router.getAmountsIn(amount_, _path_);
        return _inputs_[0];
    }

    /**
     * Exempt from cooldown.
     * @param participant_ Address of participant.
     * @param value_ True to exempt, false to unexempt.
     */
    function exemptFromCooldown(address participant_, bool value_) external onlyOwner
    {
        _isExemptFromCooldown[participant_] = value_;
    }

    /**
     * Sweep dust.
     */
    function sweepDust() external onlyOwner
    {
        uint256 _furBalance_ = fur.balanceOf(address(this));
        if(_furBalance_ > 0) {
            fur.transfer(address(vault), _furBalance_);
        }
        uint256 _usdcBalance_ = usdc.balanceOf(address(this));
        if(_usdcBalance_ > 0) {
            usdc.transfer(address(taxHandler), _usdcBalance_);
        }
    }
}