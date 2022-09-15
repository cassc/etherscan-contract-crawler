// SPDX-License-Identifier: MIT
/**************************************************

    The CURSE dao

    Where magic gives you power, a new era begins.

    - https://www.thecursedao.com/
    - https://twitter.com/TheCurseDao
    - https://t.me/thecursedao

**************************************************/

pragma solidity 0.8.7;

import "./Interfaces/uniswap/IUniswapV2Factory.sol";
import "./Interfaces/uniswap/IUniswapV2Pair.sol";
import "./Interfaces/uniswap/IUniswapV2Router02.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./Interfaces/CERC20.sol";

contract Curse is CERC20 {
    using Address for address;

    struct IFeeCollection {
        uint256 tokensForLiquidity;
        uint256 tokensForMarketing;
        uint256 tokensForGrandMaster;
    }

    struct ILiquiditySettings {        
        uint256 swapTokensAtAmount;
        bool enabled;
        bool swapping;
    }

    struct IFeeSettings {
        uint64 marketingFee; // With the precision of 0.1%
        uint64 liquidityFee; // With the precision of 0.1%
        uint64 grandMasterFee; // With the precision of 0.1%
        uint64 percentageDiscountPerLvl; // With the precision of 0.1%
    }
    
    struct ITradeSettings {
        uint256 startBlock;
        uint256 deadblocks;
        bool enabled;
    }

    struct ITransactionSettings {
        uint256 maxTxLimit;
        uint256 maxWalletLimit;
        bool enabled;
    }

    // ACL constants
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // Fee constants
    uint256 public constant FEE_DENOMINATOR = 10000; // Allow fees set in the range of 0.01%
    uint256 public constant FEE_OVERDRIVE_BLOCK_LIMIT = 22; // Max block height until fees can be set higher
    uint8 public constant FEE_BUY = 0;
    uint8 public constant FEE_SELL = 1;

    // Liquidity settings
    uint256 public constant SWAP_AT_DENOMINATOR = 10000; // Allow settings set in the range of 0.01%
    uint256 public constant TX_DENOMINATOR = 1000; // Allow settings set in the range of 0.1%

    uint256 public maxTxLimit;
    uint256 public maxWalletLimit;
    bool public limitsEnabled;

    address private immutable _uniswapRouter;    
    address public uniswapPair;
    address private _feeWallet;
    address public grandMasterBeneficiary;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _feeExempt;
    mapping(address => bool) private _maxTxExempt;
    mapping(address => bool) private _maxWalletExempt;
    mapping(address => bool) private _bots;
    mapping(address => bool) private _pairs;

    IFeeSettings[2] private _fees;

    ILiquiditySettings private _liquiditySettings;
    ITransactionSettings private _txSettings;
    IFeeCollection private _feeCollection;
    ITradeSettings private _tradeSettings;

    constructor(address casterData) CERC20(casterData, "The Curse", "CURSE") {
        // Total supply 100,000
        uint256 totalSupply = 100_000 * 1e18;

        address _owner = _msgSender();

        // ACL configs
        _grantRole(ADMIN_ROLE, _owner);
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(OPERATOR_ROLE, _owner);

        // Set default fee wallet and grandMaster
        _feeWallet = address(_owner);
        grandMasterBeneficiary = _feeWallet;

        // Default exempts
        _maxWalletExempt[address(_feeWallet)] = true;
        _maxWalletExempt[address(this)] = true;
        _maxWalletExempt[address(0xdead)] = true;

        _maxTxExempt[address(_feeWallet)] = true;
        _maxTxExempt[address(this)] = true;
        _maxTxExempt[address(0xdead)] = true;

        _feeExempt[address(_feeWallet)] = true;
        _feeExempt[address(this)] = true;
        _feeExempt[address(0xdead)] = true;

        // Default tx limits
        limitsEnabled = true;
        maxTxLimit = (totalSupply * 20) / TX_DENOMINATOR;
        maxWalletLimit = (totalSupply * 30) / TX_DENOMINATOR;

        // Default fee settings
        _fees[FEE_BUY].marketingFee = 300; // 3.0%
        _fees[FEE_BUY].liquidityFee = 200; // 2.0%
        _fees[FEE_BUY].grandMasterFee = 100; // 1.0%
        _fees[FEE_BUY].percentageDiscountPerLvl = 100; // Lvl1: 1.0% | Lvl2: 2.0% | Lvl3: 3.0%

        _fees[FEE_SELL].marketingFee = 300; // 3.0%
        _fees[FEE_SELL].liquidityFee = 200; // 2.0%
        _fees[FEE_SELL].grandMasterFee = 100; // 1.0%
        _fees[FEE_SELL].percentageDiscountPerLvl = 100; // Lvl1: 1.0% | Lvl2: 2.0% | Lvl3: 3.0%

        // Default liquidty settings
        _liquiditySettings.enabled = true;
        _liquiditySettings.swapTokensAtAmount = (totalSupply * 15) / SWAP_AT_DENOMINATOR;

        // Default trade settings
        _tradeSettings.startBlock = 0;
        _tradeSettings.enabled = false;
        _tradeSettings.deadblocks = 2;

        _uniswapRouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
               
        _mint(_owner, totalSupply);
    }

    modifier lockSwap() {
        _liquiditySettings.swapping = true;
        _;
        _liquiditySettings.swapping = false;
    }

    /**
     * Internal and private functions
     */

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        IUniswapV2Router02 router = IUniswapV2Router02(_uniswapRouter);
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _feeWallet,
            block.timestamp
        );
    }

    function _swapForEth(uint256 tokenAmount) private {
        IUniswapV2Router02 router = IUniswapV2Router02(_uniswapRouter);
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _autoSwapBack() private lockSwap {
        uint256 tokenBalance = balanceOf(address(this)) - _feeCollection.tokensForGrandMaster;
        //uint256 tokenBalance = _feeCollection.tokensForLiquidity + _feeCollection.tokensForMarketing;
        uint256 tokens = _feeCollection.tokensForLiquidity + _feeCollection.tokensForMarketing;  

        if ( tokenBalance == 0 || tokens == 0) return ;
        // Enforce limit
        tokenBalance = tokenBalance > _liquiditySettings.swapTokensAtAmount? _liquiditySettings.swapTokensAtAmount : tokenBalance;

        uint256 tokensForLiquidity = (tokenBalance * _feeCollection.tokensForLiquidity) / tokens / 2;
        uint256 amountToEth = tokenBalance - tokensForLiquidity;

        uint256 initialEthBalance = address(this).balance;
        
        _swapForEth(amountToEth);

        uint256 ethBalance = address(this).balance - initialEthBalance;

        // Distribute ETH fees
        uint256 ethForMarketing = (ethBalance * _feeCollection.tokensForMarketing) / tokens;
        uint256 ethForLiquidity = ethBalance - ethForMarketing;

        _feeCollection.tokensForLiquidity = 0;
        _feeCollection.tokensForMarketing = 0;

        payable(_feeWallet).transfer(ethForMarketing);

        if (tokensForLiquidity > 0 && ethForLiquidity > 0) _addLiquidity(tokensForLiquidity, ethForLiquidity);
    }
    
    function _autoSwap(address from, address to) private {
        uint256 tokens = _feeCollection.tokensForLiquidity +
            _feeCollection.tokensForMarketing;

        if(tokens >= _liquiditySettings.swapTokensAtAmount &&
           !_liquiditySettings.swapping &&
           !_pairs[from] &&
           !_feeExempt[from] &&
           !_feeExempt[to] &&
           _liquiditySettings.enabled)
        {
            _autoSwapBack();
        }
    }
    
    function _isLaunched(address from, address to) private view {
        require(
            _feeExempt[from] || _feeExempt[to] || _tradeSettings.enabled,
            "CURSE: not launched yet"
        );
    }


    function _collectFee(uint256 amount, uint8 selector, uint8 level) private returns (uint256) {
        uint256 totalFeeWithoutDiscount = _fees[selector].marketingFee + 
                _fees[selector].liquidityFee + 
                _fees[selector].grandMasterFee;
        uint256 totalFee = totalFeeWithoutDiscount - ( uint256(level) * _fees[selector].percentageDiscountPerLvl );
                
        uint256 fees = (amount * totalFee) / FEE_DENOMINATOR;

        _feeCollection.tokensForLiquidity += (fees * _fees[selector].liquidityFee) / totalFeeWithoutDiscount;
        _feeCollection.tokensForMarketing += (fees * _fees[selector].marketingFee) / totalFeeWithoutDiscount;
        _feeCollection.tokensForGrandMaster += (fees * _fees[selector].grandMasterFee) / totalFeeWithoutDiscount;

        return fees;
    }

    function _ensureLimits(address from, address to, uint256 amount, bool isBuy) private view {
        if (
            from != _feeWallet &&
            to != _feeWallet &&
            !_maxTxExempt[from] &&
            !_maxTxExempt[to] &&
            !_maxTxExempt[tx.origin] &&
            !_maxWalletExempt[from] &&
            !_maxWalletExempt[to] &&
            !_maxWalletExempt[tx.origin] &&
            limitsEnabled &&
            from != address(this) &&
            to != address(this)
        ) 
        {
            require(amount <= maxTxLimit, "CURSE: tx over limit");
            if (isBuy) {
                require(
                    (amount + balanceOf(to)) <= maxWalletLimit,
                    "CURSE: wallet over limit"
                );
            }
        }
        
    }

    function _isTakeFee(address from, address to) private view returns (bool) {
        bool takeFee = !_liquiditySettings.swapping;
        if (_feeExempt[from] || _feeExempt[to]) {
            takeFee = false;
        }
        return takeFee;
    }

    /**
     * @dev Helper function to return the uniswap pair of the contract. 
     * must be implemented by the child
     *
     * Returns:
     * - `address` of the uniswap pair
     */
    function _getUniswapPair() internal override view returns (address) {
        return uniswapPair;
    }

    /**
     * @dev Helper function to transfer the collected tokens from a previous grandmaster to the new one. Will be called by `illusion` 
     * and the child contract has the responsibility to implement it.
     *
     * Returns:
     * - `caster` the new grandmaster
     */
    function _transferGrandMaster(address caster) internal override {
        uint256 amount = _feeCollection.tokensForGrandMaster;
        // Reset the fee collection
        _feeCollection.tokensForGrandMaster = 0;
        
        if (amount > 0) 
            _transfer(address(this), grandMasterBeneficiary, amount);
        
        // Set the new grandMaster
        grandMasterBeneficiary = caster;
    }
    
    /**
     * Standard trade functions
     */

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "CURSE: transfer from the zero address");
        require(to != address(0), "CURSE: transfer to the zero address");       
        require(!_bots[from], "CURSE: bot detected");

        // Check if launched
        _isLaunched(from, to);

        // Perform the autoswap if possible
        _autoSwap(from, to);

        bool isBuy = _pairs[from];
        bool isSell = _pairs[to];

        // Ensure the limits if applicable
        _ensureLimits(from, to, amount, isBuy);
            
        uint256 fees = 0;
        if (_isTakeFee(from, to)) {
            if (isBuy) {
                if ((block.number < _tradeSettings.startBlock + _tradeSettings.deadblocks)) {
                    _bots[to] = true;
                }
                fees = _collectFee(amount, FEE_BUY, CASTER.getLevel(to));

            } else if (isSell) {
                require(!isFrozen(from), "CURSE: you are frozen");
                require(!isStolen(from), "CURSE: you are a thief");

                fees = _collectFee(amount, FEE_SELL, CASTER.getLevel(from));                
            } else { 
                // This is a wallet < - > wallet transfer. The frozen curse could be broken here, but hey ... you cannot be smarter than TheKeeper
                require(!isFrozen(from), "CURSE: you are frozen");
                require(!isStolen(from), "CURSE: you are a thief");
            }

            if (fees > 0) {

                super._transfer(from, address(this), fees);
            }
            amount = amount - fees;
        }

        super._transfer(from, to, amount);
    }

    receive() external payable {}


    /**
     * Config/Management section
     */
    function setSpellBook(address spellBook) external onlyRole(ADMIN_ROLE) {
        _grantRole(SPELLBOOK_ROLE, spellBook);
        setEnableExempt(spellBook, true, true, true);
    }

    function promoteAdmin(address newAdmin) public onlyRole(ADMIN_ROLE) {
        _grantRole(ADMIN_ROLE, newAdmin);
    }

    function updateFeeWallet(address wallet) public onlyRole(ADMIN_ROLE) {
        _feeExempt[wallet] = true;
        _maxTxExempt[wallet] = true;
        _maxWalletExempt[wallet] = true;

        _feeWallet = wallet;
    }

    function promoteOperator(address operator) public onlyRole(OPERATOR_ROLE) {
        _grantRole(OPERATOR_ROLE, operator);
    }

    function setEnablePair(address pair, bool value) external onlyRole(OPERATOR_ROLE) {
        _pairs[pair] = value;
    }

    function updateTxLimit(uint256 percentage, uint256 divisor) external onlyRole(OPERATOR_ROLE)
    {
        maxTxLimit = (totalSupply() * percentage) / divisor;
        require(maxTxLimit >= (totalSupply() * 1000) / 100000, "CURSE: too low"); // Max TX must be more than 1,000
    }

    function updateMaxWallet(uint256 percentage, uint256 divisor) external onlyRole(OPERATOR_ROLE)
    {
        maxWalletLimit = (totalSupply() * percentage) / divisor;
        require(maxWalletLimit >= (totalSupply() * 1000) / 100000, "CURSE: too low"); // Max TX must be more than 1,000
    }

    function updateSwapTokensAt(uint256 percentage, uint256 divisor) external onlyRole(OPERATOR_ROLE)
    {
        _liquiditySettings.swapTokensAtAmount =
            (totalSupply() * percentage) /
            divisor;
    }

    function setEnableExempt(address addr, bool fee, bool maxTx, bool maxWallet) public onlyRole(OPERATOR_ROLE) {
        _feeExempt[addr] = fee;
        _maxTxExempt[addr] = maxTx;
        _maxWalletExempt[addr] = maxWallet;
    }

    function updateBuyFee(uint64 marketing, uint64 liquidity, uint64 grandMaster, uint64 discountPerLvl) external onlyRole(OPERATOR_ROLE)
    {
        uint64 sum = marketing + liquidity + grandMaster;
        
        if (block.number > (_tradeSettings.startBlock + FEE_OVERDRIVE_BLOCK_LIMIT) && _tradeSettings.enabled) {
            require(sum <= 1100, "CURSE: Fee too high"); // Max fee is 11%
        }
        
        require((discountPerLvl * 3) <= sum, "CURSE: discount must less than fees");

        _fees[FEE_BUY].marketingFee = marketing; 
        _fees[FEE_BUY].liquidityFee = liquidity; 
        _fees[FEE_BUY].grandMasterFee = grandMaster;
        _fees[FEE_BUY].percentageDiscountPerLvl = discountPerLvl;
    }

    function updateSellFee(uint64 marketing, uint64 liquidity, uint64 grandMaster, uint64 discountPerLvl) external onlyRole(OPERATOR_ROLE)
    {
        uint64 sum = marketing + liquidity + grandMaster;
        
        if (block.number > (_tradeSettings.startBlock + FEE_OVERDRIVE_BLOCK_LIMIT) && _tradeSettings.enabled) {
            require(sum <= 1100, "CURSE: Fee too high"); // Max fee is 11%
        }
        
        require((discountPerLvl * 3) <= sum, "CURSE: discount must less than fees");

        _fees[FEE_SELL].marketingFee = marketing; 
        _fees[FEE_SELL].liquidityFee = liquidity; 
        _fees[FEE_SELL].grandMasterFee = grandMaster;
        _fees[FEE_SELL].percentageDiscountPerLvl = discountPerLvl;
    }
    
    function removeLimits() external onlyRole(OPERATOR_ROLE) {
        limitsEnabled = false;
    }

    function sendEth() external onlyRole(OPERATOR_ROLE) {
        payable(_feeWallet).transfer(address(this).balance);
    }

    function swap() external onlyRole(OPERATOR_ROLE) {
        _autoSwapBack();
    }

    function removeBot(address bot) external onlyRole(OPERATOR_ROLE) {
        _bots[bot] = false;
    }

    function enableTrading(uint256 deadblock) external onlyRole(OPERATOR_ROLE) {
        require(!_tradeSettings.enabled, "CURSE: already enabled");
        _tradeSettings.enabled = true;
        _tradeSettings.startBlock = block.number;
        _tradeSettings.deadblocks = deadblock;
    }


    function releaseTheCurse() external onlyRole(OPERATOR_ROLE) {
        IUniswapV2Router02 router = IUniswapV2Router02(_uniswapRouter);
        address pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        // Store the pair
        _pairs[pair] = true;
        // Shorthand for uniswap pair
        uniswapPair = pair;
    }

}