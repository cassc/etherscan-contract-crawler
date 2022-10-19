// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IFeeManagerDogs.sol";
import "./interfaces/IDogPound.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract DogsTokenV2 is ERC20("Animal Farm Dogs", "AFD"), Ownable {
    using SafeERC20 for IERC20;

    uint256 public TxBaseTax = 9000; // 90%
    uint256 public TxBurnRate = 333; // 3.33%
    uint256 public TxVaultRewardRate = 9666; // 96.66%

    uint256 public constant MAXIMUM_TX_BASE_TAX = 9001; // Max transfer tax rate: 90.01%.
    uint256 public constant ZERO_TAX_INT = 10001; // Special 0 tax int

    address public constant BUSD_ADDRESS = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    IERC20 public constant busdRewardCurrency = IERC20(BUSD_ADDRESS);

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    address public constant PANCAKESWAP_ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02 public pancakeswapRouter = IUniswapV2Router02(PANCAKESWAP_ROUTER_ADDRESS);

    address public dogsBusdSwapPair;
    address public dogsWbnbSwapPair;

    bool public swapAndLiquifyEnabled = false; // Automatic swap and liquify enabled
    bool private _inSwapAndLiquify;  // In swap and liquify

    IFeeManagerDogs public FeeManagerDogs;

    mapping(address => bool) public txTaxOperators;

    mapping(address => bool) public liquifyExemptFrom;
    mapping(address => bool) public liquifyExemptTo;

    mapping(address => uint256) public customTaxRateFrom;
    mapping(address => uint256) public customTaxRateTo;

    // Events
    event Burn(address indexed sender, uint256 amount);
    event SetSwapAndLiquifyEnabled(bool swapAndLiquifyEnabled);
    event TransferTaxChanged(uint256 txBaseTax);
    event TransferTaxDistributionChanged(uint256 baseBurnRate, uint256 vaultRewardRate);
    event UpdateCustomTaxRateFrom(address _account, uint256 _taxRate);
    event UpdateCustomTaxRateTo(address _account, uint256 _taxRate);
    event SetOperator(address operator);
    event SetFeeManagerDogs(address feeManagerDogs);
    event SetTxTaxOperator(address taxOperator, bool isOperator);

    // The operator can use admin functions
    address public _operator;

    // AB measures
    mapping(address => bool) private blacklistFrom;
    mapping(address => bool) private blacklistTo;
    mapping (address => bool) private _isExcludedFromLimiter;
    bool private blacklistFeatureAllowed = true;

    bool private transfersPaused = true;
    bool private transfersPausedFeatureAllowed = true;

    bool private sellingEnabled = false;
    bool private sellingToggleAllowed = true;

    bool private buySellLimiterEnabled = true;
    bool private buySellLimiterAllowed = true;
    uint256 private buySellLimitThreshold = 500e18;

    // AB events
    event LimiterUserUpdated(address account, bool isLimited);
    event BlacklistUpdated(address account, bool blacklisted);
    event TransferStatusUpdate(bool isPaused);
    event TransferPauseFeatureBurn();
    event SellingToggleFeatureBurn();
    event BuySellLimiterUpdate(bool isEnabled, uint256 amount);
    event SellingEnabledToggle(bool enabled);
    event LimiterFeatureBurn();
    event BlacklistingFeatureBurn();

    modifier onlyOperator() {
        require(_operator == msg.sender, "!operator");
        _;
    }

    modifier onlyTxTaxOperator() {
        require(txTaxOperators[msg.sender], "!txTaxOperator");
        _;
    }

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    modifier transferTaxFree {
        uint256 _TxBaseTaxPrevious = TxBaseTax;
        TxBaseTax = 0;
        _;
        TxBaseTax = _TxBaseTaxPrevious;

    }

    /**
     * @notice Constructs the Dogs Token contract.
     */
    constructor(address _addLiquidityHelper) {

        _operator = msg.sender;
        txTaxOperators[msg.sender] = true;

        // Create BUSD and WBNB pairs
        dogsBusdSwapPair = IUniswapV2Factory(pancakeswapRouter.factory()).createPair(address(this), BUSD_ADDRESS);
        dogsWbnbSwapPair = IUniswapV2Factory(pancakeswapRouter.factory()).createPair(address(this), pancakeswapRouter.WETH());

        // Exclude from AB limiter
        _isExcludedFromLimiter[msg.sender] = true;
        _isExcludedFromLimiter[_addLiquidityHelper] = true; // needs to be false for initial launch

        // Apply custom Taxes
        // Buying / Remove Liq directly on PCS incurs 6% tax.
        customTaxRateFrom[dogsBusdSwapPair] = 600;
        customTaxRateFrom[dogsWbnbSwapPair] = 600;

        // Adding liquidity via helper is tax free
        customTaxRateFrom[_addLiquidityHelper] = ZERO_TAX_INT;
        customTaxRateTo[_addLiquidityHelper] = ZERO_TAX_INT;

        // Operator is untaxed
        customTaxRateFrom[msg.sender] = ZERO_TAX_INT;

        // Sending to Burn address is tax free
        customTaxRateTo[BURN_ADDRESS] = ZERO_TAX_INT;

        // Exclude add liquidityHelper from triggering liquification
        liquifyExemptFrom[_addLiquidityHelper] = true;
        liquifyExemptTo[_addLiquidityHelper] = true;

        liquifyExemptFrom[dogsBusdSwapPair] = true;
        liquifyExemptTo[dogsBusdSwapPair] = true;

        liquifyExemptFrom[dogsWbnbSwapPair] = true;
        liquifyExemptTo[dogsWbnbSwapPair] = true;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    /// @dev overrides transfer function to meet tokenomics of Dogs Token
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {

        require(!isBlacklistedFrom(sender), "ERROR: Address Blacklisted!");
        require(!isBlacklistedTo(recipient), "ERROR: Address Blacklisted!");

        bool isExcluded = _isExcludedFromLimiter[sender] || _isExcludedFromLimiter[recipient];

        if (transfersPaused) {
            require(isExcluded, "ERROR: Transfer Paused!");
        }

        if (recipient == address(dogsBusdSwapPair) && !isExcluded) {
            require(sellingEnabled, "ERROR: Selling disabled!");
        }
        if (recipient == address(dogsWbnbSwapPair) && !isExcluded) {
            require(sellingEnabled, "ERROR: Selling disabled!");
        }

        //if any account belongs to _isExcludedFromLimiter account then don't do buy/sell limiting, used for initial liquidty adding
        if (buySellLimiterEnabled && !isExcluded) {
            if (recipient == address(dogsBusdSwapPair) || sender == address(dogsBusdSwapPair)) {
                require(amount <= buySellLimitThreshold, "ERROR: buy / sell exceeded!");
            }
            if (recipient == address(dogsWbnbSwapPair) || sender == address(dogsWbnbSwapPair)) {
                require(amount <= buySellLimitThreshold, "ERROR: buy / sell exceeded!");
            }
        }
        // End of AB measures

        if (swapAndLiquifyEnabled == true && _inSwapAndLiquify == false){
            if (!liquifyExemptFrom[sender] || !liquifyExemptTo[recipient]){
                swapAndLiquefy();
            }
        }

        uint256 taxToApply = TxBaseTax;
        if (customTaxRateFrom[sender] > 0 ){
            taxToApply = customTaxRateFrom[sender];
        }
        if (customTaxRateTo[recipient] > 0 ){
            taxToApply = customTaxRateTo[recipient];
        }

        if (taxToApply == ZERO_TAX_INT || taxToApply == 0) {
            super._transfer(sender, recipient, amount);
        } else {
            uint256 baseTax = amount * taxToApply / 10000;
            uint256 baseBurn = baseTax * TxBurnRate / 10000;
            uint256 vaultReward = baseTax * TxVaultRewardRate / 10000;
            uint256 sendAmount = amount - baseBurn - vaultReward;

            _burnTokens(sender, baseBurn);
            super._transfer(sender, address(FeeManagerDogs), vaultReward);
            super._transfer(sender, recipient, sendAmount);

        }
    }

    function swapAndLiquefy() private lockTheSwap transferTaxFree {
        FeeManagerDogs.liquefyDogs();
    }

    /**
     * @notice Destroys `amount` tokens from the sender, reducing the total supply.
	 */
    function burn(uint256 _amount) external {
        _burnTokens(msg.sender, _amount);
    }

    /**
     * @dev Destroys `amount` tokens from the sender, reducing the total supply.
	 */
    function _burnTokens(address sender, uint256 _amount) private {
        _burn(sender, _amount);
        emit Burn(sender, _amount);
    }

    /**
     * @dev Update the transfer base tax rate.
     * Can only be called by the current operator.
     */
    function updateTransferTaxRate(uint256 _txBaseTax) external onlyTxTaxOperator {
        require(_txBaseTax <= MAXIMUM_TX_BASE_TAX, "invalid tax");
        TxBaseTax = _txBaseTax;
        emit TransferTaxChanged(TxBaseTax);
    }

    function updateCustomTaxRateFrom(address _account, uint256 _taxRate) external onlyTxTaxOperator {
        require(_taxRate <= MAXIMUM_TX_BASE_TAX || _taxRate == ZERO_TAX_INT, "invalid tax");
        customTaxRateFrom[_account] = _taxRate;
        emit UpdateCustomTaxRateFrom(_account, _taxRate);
    }

    function updateCustomTaxRateTo(address _account, uint256 _taxRate) external onlyTxTaxOperator {
        require(_taxRate <= MAXIMUM_TX_BASE_TAX || _taxRate == ZERO_TAX_INT, "invalid tax");
        customTaxRateTo[_account] = _taxRate;
        emit UpdateCustomTaxRateTo(_account, _taxRate);
    }

    /**
     * @dev Update the transfer tax distribution ratio's.
     * Can only be called by the current operator.
     */
    function updateTaxDistribution(uint256 _txBurnRate, uint256 _txVaultRewardRate) external onlyOperator {
        require(_txBurnRate + _txVaultRewardRate <= 10000, "!valid");
        TxBurnRate = _txBurnRate;
        TxVaultRewardRate = _txVaultRewardRate;
        emit TransferTaxDistributionChanged(TxBurnRate, TxVaultRewardRate);
    }

    /**
     * @dev Returns the address of the current operator.
     */
    function operator() external view returns (address) {
        return _operator;
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function transferOperator(address newOperator) external onlyOperator {
        require(newOperator != address(0), "!!0");
        _operator = newOperator;

        emit SetOperator(_operator);
    }

    /**
     * @dev Update list of Transaction Tax Operators
     * Can only be called by the current operator.
     */
    function updateTxTaxOperator(address _txTaxOperator, bool _isTxTaxOperator) external onlyOperator {
        require(_txTaxOperator != address(0), "!!0");
        txTaxOperators[_txTaxOperator] = _isTxTaxOperator;

        emit SetTxTaxOperator(_txTaxOperator, _isTxTaxOperator);
    }


    /**
     * @dev Update Fee Manager Dogs, sets tax to 0, exclude from triggering liquification
     * Can only be called by the current operator.
     */
    function updateFeeManagerDogs(address _feeManagerDogs) public onlyOperator {
        FeeManagerDogs = IFeeManagerDogs(_feeManagerDogs);
        customTaxRateFrom[_feeManagerDogs] = ZERO_TAX_INT;
        liquifyExemptFrom[_feeManagerDogs] = true;
        emit SetFeeManagerDogs(_feeManagerDogs);
    }

    /**
     * @dev Update the swapAndLiquifyEnabled.
     * Can only be called by the current operator.
     */
    function updateSwapAndLiquifyEnabled(bool _enabled) external onlyOperator {
        swapAndLiquifyEnabled = _enabled;

        emit SetSwapAndLiquifyEnabled(swapAndLiquifyEnabled);
    }


    // AB measures
    function toggleExcludedFromLimiterUser(address account, bool isExcluded) external onlyOperator {
        require(buySellLimiterAllowed, 'feature destroyed');
        _isExcludedFromLimiter[account] = isExcluded;
        emit LimiterUserUpdated(account, isExcluded);
    }

    function toggleBuySellLimiter(bool isEnabled, uint256 amount) external onlyOperator {
        require(buySellLimiterAllowed, 'feature destroyed');
        buySellLimiterEnabled = isEnabled;
        buySellLimitThreshold = amount;
        emit BuySellLimiterUpdate(isEnabled, amount);
    }

    function burnLimiterFeature() external onlyOperator {
        buySellLimiterAllowed = false;
        emit LimiterFeatureBurn();
    }

    function isBlacklistedFrom(address account) public view returns (bool) {
        return blacklistFrom[account];
    }

    function isBlacklistedTo(address account) public view returns (bool) {
        return blacklistTo[account];
    }

    function toggleBlacklistUserFrom(address[] memory accounts, bool blacklisted) external onlyOperator {
        require(blacklistFeatureAllowed, "ERROR: Function burned!");
        for (uint256 i = 0; i < accounts.length; i++) {
            blacklistFrom[accounts[i]] = blacklisted;
            emit BlacklistUpdated(accounts[i], blacklisted);
        }
    }

    function toggleBlacklistUserTo(address[] memory accounts, bool blacklisted) external onlyOperator {
        require(blacklistFeatureAllowed, "ERROR: Function burned!");
        for (uint256 i = 0; i < accounts.length; i++) {
            blacklistTo[accounts[i]] = blacklisted;
            emit BlacklistUpdated(accounts[i], blacklisted);
        }
    }

    function burnBlacklistingFeature() external onlyOperator {
        blacklistFeatureAllowed = false;
        emit BlacklistingFeatureBurn();
    }

    function toggleSellingEnabled(bool enabled) external onlyOperator {
        require(sellingToggleAllowed, 'feature destroyed');
        sellingEnabled = enabled;
        emit SellingEnabledToggle(enabled);
    }

    function burnToggleSellFeature() external onlyOperator {
        sellingToggleAllowed = false;
        emit SellingToggleFeatureBurn();
    }

    function toggleTransfersPaused(bool isPaused) external onlyOperator {
        require(transfersPausedFeatureAllowed, 'feature destroyed');
        transfersPaused = isPaused;
        emit TransferStatusUpdate(isPaused);
    }

    function burnTogglePauseFeature() external onlyOperator {
        transfersPausedFeatureAllowed = false;
        emit TransferPauseFeatureBurn();
    }

}