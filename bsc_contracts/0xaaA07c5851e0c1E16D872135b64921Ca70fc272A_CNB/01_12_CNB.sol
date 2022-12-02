//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import './IPancakeV2Router02.sol';
import './IPancakeV2Factory.sol';
import './IPancakeV2Pair.sol';
import './Governance.sol';
import './MarketingSwapper.sol';

interface IAntisnipe {
    function assureCanTransfer(
        address sender,
        address from,
        address to,
        uint256 amount
    ) external;
}

contract CNB is IERC20, Ownable, Governance {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    uint256 private _tTotal = 42_000_000_000 * 10**18;
    uint256 private _initTotal = 42_000_000_000 * 10**18;
    uint256 private _tFeeTotal;

    string private _name = 'CANABOYZ';
    string private _symbol = 'CNB';
    uint8 private _decimals = 18;

    // Base Fees
    uint256 public _liquidityFee = 4;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _burnFee = 2;
    uint256 private _previousBurnFee = _burnFee;

    uint256 public _marketingFee = 4;
    uint256 private _previousMarketingFee = _marketingFee;

    // Sell Fees
    uint256 public _sellLiquidityFee = 4;
    uint256 public _sellBurnFee = 4;
    uint256 public _sellMarketingFee = 12;

    // Anti whale
    uint256 public constant MAX_HOLDING_PERCENTS_DIVISOR = 1000;
    uint256 public _maxHoldingPercents = 5;
    bool public antiWhaleEnabled;
    bool public _marketingSwap = true;

    // Anti manager
    address public antiManager;

    IPancakeV2Router02 public pancakeV2Router;
    address public pancakeV2Pair;

    uint256 private numTokensSellToAddToLiquidity = 1000000 * 10**18;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event MarketingCommission(address marketingWallet, uint256 amount);

    MarketingSwapper public swapper;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(IPancakeV2Router02 _pancakeV2Router, address _antiManager) {
        antiManager = _antiManager;

        // Create a pancake pair for this new token
        pancakeV2Pair = IPancakeV2Factory(_pancakeV2Router.factory()).createPair(
            address(this),
            _pancakeV2Router.WETH()
        );

        // set the rest of the contract variables
        pancakeV2Router = _pancakeV2Router;
        _tOwned[msg.sender] = _tTotal;
        //exclude owner, anti manager and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_antiManager] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    IAntisnipe public antisnipe;
    bool public antisnipeDisable;

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (from == address(0) || to == address(0)) return;
        if (!antisnipeDisable && address(antisnipe) != address(0))
            antisnipe.assureCanTransfer(msg.sender, from, to, amount);
    }

    function setAntisnipeDisable() external onlyOwner {
        require(!antisnipeDisable);
        antisnipeDisable = true;
    }

    function setAntisnipeAddress(address addr) external onlyOwner {
        antisnipe = IAntisnipe(addr);
    }

    function setMarketingSwap(bool _state) public onlyOwner {
        _marketingSwap = _state;
    }

    function setSwapper(address payable _swapper) public onlyOwner {
        swapper = MarketingSwapper(_swapper);
        _isExcludedFromFee[_swapper] = true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                'BEP20: transfer amount exceeds allowance'
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                'BEP20: decreased allowance below zero'
            )
        );
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    //to receive BNB from pancakeV2Router when swapping
    receive() external payable {}

    function _getValues(uint256 tAmount) private view returns (uint256, uint256) {
        (uint256 tTransferAmount, uint256 tLiquidity) = _getTValues(tAmount);
        return (tTransferAmount, tLiquidity);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tLiquidity);
        return (tTransferAmount, tLiquidity);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(10**2);
    }

    function activateSellFee() private {
        _previousLiquidityFee = _liquidityFee;
        _previousBurnFee = _burnFee;
        _previousMarketingFee = _marketingFee;

        _liquidityFee = _sellLiquidityFee;
        _marketingFee = _sellMarketingFee;
        _burnFee = _sellBurnFee;
    }

    function removeAllFee() private {
        if (_liquidityFee == 0 && _marketingFee == 0 && _burnFee == 0) return;

        _previousLiquidityFee = _liquidityFee;
        _previousBurnFee = _burnFee;
        _previousMarketingFee = _marketingFee;

        _liquidityFee = 0;
        _marketingFee = 0;
        _burnFee = 0;
    }

    function restoreAllFee() private {
        _liquidityFee = _previousLiquidityFee;
        _burnFee = _previousBurnFee;
        _marketingFee = _previousMarketingFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), 'BEP20: transfer from the zero address');
        require(amount > 0, 'Transfer amount must be greater than zero');
        _beforeTokenTransfer(from, to, amount);

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancake pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            (from != pancakeV2Pair &&
            from != address(swapper) &&
            to != address(swapper)) &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount);

        if (from != address(swapper) && to != address(swapper)) {
            if (antiWhaleEnabled) {
                uint256 maxAllowed = (_initTotal * _maxHoldingPercents) / MAX_HOLDING_PERCENTS_DIVISOR;
                if (to == pancakeV2Pair) {
                    require(
                        amount <= maxAllowed,
                        'Transacted amount exceed the max allowed value'
                    );
                } else {
                    require(
                        balanceOf(to) <= maxAllowed,
                        'Wallet balance exceeds the max limit'
                    );
                }
            }
        }
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half);
        // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to pancake
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function functionSwapForMarketing() private {
        swapper.checkSwapAction();
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeV2Router.WETH();

        _approve(address(this), address(pancakeV2Router), tokenAmount);

        // make the swap
        pancakeV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function mint(address _to, uint256 _amount) public onlyGovernance {
        _tOwned[_to] = _tOwned[_to].add(_amount);
        _tTotal = _tTotal + _amount;
    }

    function burn(address _from, uint256 _amount) public onlyGovernance {
        _transferStandard(_from, address(0), _amount);
        _tTotal = _tTotal - _amount;
    }

    function burnOnTransfer(address _from, uint256 _amount) private {
        _transferStandard(_from, address(0), _amount);
        _tTotal = _tTotal - _amount;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeV2Router), tokenAmount);

        // add the liquidity
        pancakeV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            removeAllFee();
        } else if (recipient != pancakeV2Pair && sender != pancakeV2Pair) {
            removeAllFee();
        }

        //Calculate burn amount and marketing amount
        uint256 burnAmt = amount.mul(_burnFee).div(100);
        uint256 marketingAmt = amount.mul(_marketingFee).div(100);

        if (
            address(swapper) != recipient &&
            address(swapper) != sender &&
            address(pancakeV2Pair) != sender
            && _marketingSwap
        ) {
            functionSwapForMarketing();
        }

        _transferStandard(sender, recipient, (amount.sub(burnAmt).sub(marketingAmt)));

        if (address(swapper) != recipient && address(swapper) != sender) {
            //Temporarily remove fees to transfer to burn address and marketing wallet
            _liquidityFee = 0;

            if (burnAmt > 0) {
                burnOnTransfer(sender, burnAmt);
            }
            if (marketingAmt > 0) {
                _transferStandard(sender, address(swapper), marketingAmt);
            }

            //Restore tax and liquidity fees
            _liquidityFee = _previousLiquidityFee;
        }

        if (
            _isExcludedFromFee[sender] ||
            _isExcludedFromFee[recipient] ||
            (recipient != pancakeV2Pair && sender != pancakeV2Pair)
        ) {
            restoreAllFee();
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (uint256 tTransferAmount, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _takeLiquidity(tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        require(liquidityFee <= 10, 'Liquidity fee cannot be more than 10%');
        _liquidityFee = liquidityFee;
    }

    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner {
        require(marketingFee <= 10, 'Marketing fee cannot be more than 10%');
        _marketingFee = marketingFee;
    }

    function setBurnFeePercent(uint256 burnFee) external onlyOwner {
        require(burnFee <= 10, 'Burn fee cannot be more than 10%');
        _burnFee = burnFee;
    }

    function setSellBurnFeePercent(uint256 sellBurnFee) external onlyOwner {
        require(sellBurnFee <= 10, 'Sell burn fee cannot be more than 10%');
        _sellBurnFee = sellBurnFee;
    }

    function setSellMarketingFeePercent(uint256 sellMarketingFee) external onlyOwner {
        require(sellMarketingFee <= 10, 'Sell marketing fee cannot be more than 10%');
        _sellMarketingFee = sellMarketingFee;
    }

    function setSellLiquidityFeePercent(uint256 sellLiquidityFee) external onlyOwner {
        require(sellLiquidityFee <= 10, 'Sell liquidity fee cannot be more than 10%');
        _sellLiquidityFee = sellLiquidityFee;
    }

    function setMaxHoldingPercents(uint256 maxHoldingPercents) external onlyOwner {
        require(maxHoldingPercents >= 1, 'Max holding percents cannot be less than 0.1%');
        require(maxHoldingPercents <= 30, 'Max holding percents cannot be more than 3%');
        _maxHoldingPercents = maxHoldingPercents;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setAntiWhale(bool enabled) external {
        require(
            msg.sender == owner() || msg.sender == antiManager,
            'Only admin or anti manager allowed'
        );
        antiWhaleEnabled = enabled;
    }
}