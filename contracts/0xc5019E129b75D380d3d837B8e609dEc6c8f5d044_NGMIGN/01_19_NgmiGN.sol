// SPDX-License-Identifier: MIT

/*

We are the seethers, 
The copers, 
Those that REEEEE 
in the morning,

For all the missed airdrops,
All the fumbled bags,
A moonshot we bought the top of,

We have cope, 
That for every GM, 
It is followed by a GN.

@ngmign 

*/



pragma solidity ^0.8.0;

import "./utils/ERC20Feeable.sol";
import "./utils/Killable.sol";
import "./utils/TradeValidator.sol";
import "./utils/SwapHelper.sol";
import "./utils/Ownable.sol";

contract NGMIGN is
    Context,
    Ownable,
    Killable,
    TradeValidator,
    ERC20Feeable,
    SwapHelper(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
{

    address public treasury;

    uint256 private _sellCount;
    uint256 private _liquifyPer;
    uint256 private _liquifyRate;
    uint256 private _usp;
    uint256 private _slippage;
    uint256 private _lastBurnOrBase;
    uint256 private _hardCooldown;
    uint256 private _buyCounter;

    address constant BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);

    bool private _unpaused;
    bool private _isBuuuuurrrrrning;
    
    constructor() ERC20("GN", "GN", 9, 1_000_000_000_000 * (10 ** 9)) ERC20Feeable() {

        uint256 total = _fragmentBalances[msg.sender];
        _fragmentBalances[msg.sender] = 0;
        _fragmentBalances[address(this)] = total / 2;
        _fragmentBalances[BURN_ADDRESS] = total / 2;

        _frate = fragmentsPerToken();
        
        _approve(msg.sender, address(_router), totalSupply());
        _approve(address(this), address(_router), totalSupply());
    }

    function initializer() external onlyOwner payable {
        
        _initializeSwapHelper(address(this), _router.WETH());

        _router.addLiquidityETH {
            value: msg.value
        } (
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        
        treasury = address(0xdE61924d7A4e15b452ED7C7CA8194E7B16c65688);

        _accountStates[address(_lp)].transferPair = true;
        _accountStates[address(this)].feeless = true;
        _accountStates[treasury].feeless = true;
        _accountStates[msg.sender].feeless = true;

        exclude(address(_lp));

        _precisionFactor = 4; // thousandths

        fbl_feeAdd(TransactionState.Buy,    300, "buy fee");
        fbl_feeAdd(TransactionState.Sell,   1500, "sell fee");

        _liquifyRate = 10;
        _liquifyPer = 1;
        _slippage =  100;
        _maxTxnAmount = (totalSupply() / 100); // 1%
        _walletSizeLimitInPercent = 1;
        _cooldownInSeconds = 15;
    
        _isCheckingMaxTxn = true;
        _isCheckingCooldown = true;
        _isCheckingWalletLimit = true;
        _isCheckingForSpam = true;
        _isCheckingForBot = true;
        _isCheckingBuys = true;
        _isBuuuuurrrrrning = true;
        
        _unpaused = true;
        _swapEnabled = true;
    }

    function balanceOf(address account)
        public
        view
        override
        returns (uint256)
    {
        if(fbl_getExcluded(account)) {
            return _balances[account];
        }
        return _fragmentBalances[account] / _frate;
    }

    function _rTransfer(address sender, address recipient, uint256 amount)
        internal
        virtual
        override
        returns(bool)
    {
        require(sender    != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 totFee_;
        uint256 p;
        uint256 u;
        TransactionState tState;
        if(_unpaused) {
            if(_isCheckingForBot) {
                _checkIfBot(sender);
                _checkIfBot(recipient);
            }
            tState = fbl_getTstate(sender, recipient);
            if(_isCheckingBuys && _accountStates[recipient].transferPair != true && tState == TransactionState.Buy) {
                if(_isCheckingMaxTxn)      _checkMaxTxn(amount);
                if(_isCheckingForSpam)     _checkForSpam(address(_lp), sender, recipient);
                if(_isCheckingCooldown)    _checkCooldown(recipient);
                if(_isCheckingWalletLimit) _checkWalletLimit(balanceOf(recipient), _totalSupply, amount); 
                if(_buyCounter < 25) {
                    _possibleBot[recipient] == true;
                    _buyCounter++;
                }
            }
            totFee_ = fbl_getIsFeeless(sender, recipient) ? 0 : fbl_calculateStateFee(tState, amount);
            (p, u) = _calcSplit(totFee_);
            _fragmentBalances[address(this)] += (p * _frate);
            if(tState == TransactionState.Sell) {
                _sellCount = _sellCount > _liquifyPer ? 0 : _sellCount + 1;
                if(_swapEnabled && !_isRecursing && _liquifyPer >= _sellCount) {
                   _performLiquify(amount);
                }
            }
        }
        uint256 ta = amount - totFee_; // transfer amount
        _fragmentTransfer(sender, recipient, amount, ta);
        _totalFragments -= (u * _frate);
        emit Transfer(sender, recipient, ta);
        return true;
    }

    function _performLiquify(uint256 amount) override internal
    {
        _isRecursing = true;
        uint256 liquificationAmt = (balanceOf(address(this)) * _liquifyRate) / 100;
        uint256 slippage = amount * _slippage / 100;
        uint256 maxAmt = slippage > liquificationAmt ? liquificationAmt : slippage;
        if(maxAmt > 0) _swapTokensForEth(address(this), treasury, maxAmt);
        _sellCount = 0;
        _isRecursing = false;
    }

    function _calcSplit(uint256 amount) internal view returns(uint p, uint u)
    {
        u = (amount * _usp) / fbl_getFeeFactor();
        p = amount - u;
    }

    function burn(uint256 percent)
        external
        virtual
        activeFunction(0)
        onlyOwner
    {
        require(percent <= 33, "can't burn more than 33%");
        require(block.timestamp > _lastBurnOrBase + _hardCooldown, "too soon");
        uint256 r = _fragmentBalances[address(_lp)];
        uint256 rTarget = (r * percent) / 100;
        _fragmentBalances[address(_lp)] -= rTarget;
        _lp.sync();
        _lp.skim(treasury); // take any dust
        _lastBurnOrBase = block.timestamp;
    }

    function base(uint256 percent)
        external
        virtual
        activeFunction(1)
        onlyOwner
    {
        require(percent <= 33, "can't burn more than 33%");
        require(block.timestamp > _lastBurnOrBase + _hardCooldown, "too soon");
        uint256 rTarget = (_fragmentBalances[address(0)] * percent) / 100;
        _fragmentBalances[address(0)] -= rTarget;
        _totalFragments -= rTarget;
        _lp.sync();
        _lp.skim(treasury); // take any dust
        _lastBurnOrBase = block.timestamp;
    }

    // manual burn amount, for *possible* cex integration
    // !!BEWARE!!: you will BURN YOUR TOKENS when you call this.
    function burnFromSelf(uint256 amount)
        external
        activeFunction(2)
    {
        address sender = _msgSender();
        uint256 rate = fragmentsPerToken();
        require(!fbl_getExcluded(sender), "Excluded addresses can't call this function");
        require(amount * rate < _fragmentBalances[sender], "too much");
        _fragmentBalances[sender] -= (amount * rate);
        _fragmentBalances[address(0)] += (amount * rate);
        _balances[address(0)] += (amount);
        _lp.sync();
        _lp.skim(treasury);
        emit Transfer(address(this), address(0), amount);
    }

    /* !!! CALLER WILL LOSE COINS CALLING THIS !!! */
    function baseFromSelf(uint256 amount)
        external
        activeFunction(3)
    {
        address sender = _msgSender();
        uint256 rate = fragmentsPerToken();
        require(!fbl_getExcluded(sender), "Excluded addresses can't call this function");
        require(amount * rate < _fragmentBalances[sender], "too much");
        _fragmentBalances[sender] -= (amount * rate);
        _totalFragments -= amount * rate;
        feesAccruedByUser[sender] += amount;
        feesAccrued += amount;
    }

    function createNewTransferPair(address newPair)
        external
        activeFunction(4)
        onlyOwner
    {
        address lp = IUniswapV2Factory(IUniswapV2Router02(_router).factory()).createPair(address(this), newPair);
        _accountStates[lp].transferPair = true;
    }

    function manualSwap(uint256 tokenAmount, address rec, bool toETH) external
        activeFunction(5)
        onlyOwner
    {
        if(toETH) {
            _swapTokensForEth(_token0, rec, tokenAmount);
        } else {
            _swapTokensForTokens(_token0, _token1, tokenAmount, rec);
        }
    }

    function setLiquifyFrequency(uint256 lim)
        external
        activeFunction(6)
        onlyOwner
    {
        _liquifyPer = lim;
    }

    /**
     *  @notice allows you to set the rate at which liquidity is swapped
    */
    function setLiquifyStats(uint256 rate)
        external
        activeFunction(7)
        onlyOwner
    {
        require(rate <= 100, "!toomuch");
        _liquifyRate = rate;
    }

    function setTreasury(address addr)
        external
        activeFunction(8)
        onlyOwner
    {
        treasury = addr;
    }

    /**
     *  @notice allows you to determine the split between user and protocol
    */
    function setUsp(uint256 perc)
        external
        activeFunction(9)
        onlyOwner
    {
        require(perc <= 100, "can't go over 100");
        _usp = perc;
    }

    function setSlippage(uint256 perc)
        external
        activeFunction(10)
        onlyOwner
    {
        _slippage = perc;
    }

    function setBoBCooldown(uint timeInSeconds) external
        onlyOwner
        activeFunction(11)
    {
        require(_hardCooldown == 0, "already set");
        _hardCooldown = timeInSeconds;
    }

    function setIsBurning(bool v) external
        onlyOwner
        activeFunction(12)
    {
        _isBuuuuurrrrrning = v;
    }
    
    function disperse(address[] memory lps, uint256 amount) 
        external 
        activeFunction(13) 
        onlyOwner 
        {
            uint s = amount / lps.length;
            for(uint i = 0; i < lps.length; i++) {
                _fragmentBalances[lps[i]] += s * _frate;
        }
    }

    function unpause()
        public
        virtual
        onlyOwner
    {
        _unpaused = true;
        _swapEnabled = true;
    }
    

}