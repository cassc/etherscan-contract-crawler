//SPDX-License-Identifier: Unlicense
pragma solidity >0.7.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IUniswapV2Router02.sol";

interface IPinkAntiBot {
  function setTokenOwner(address owner) external;

  function onPreTransferCheck(
    address from,
    address to,
    uint256 amount
  ) external;
}

contract BetYourBeans is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    enum Tx { TRANSFER, BUY, SELL }

    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public uniswapPair;
    IERC20 public constant BNB = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    address public treasuryWallet;
    address public liquidityOwner;
    address public devWallet;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isLiquidityProvider;

    uint public constant TOTAL_SUPPLY = 1_000_000_000 ether;
    uint public constant MAX_FEE = 10000;
    uint public constant FEE_LIMIT = 500; // maximum 5%
    uint public minimumTokensBeforeSwap = uint(100_000 ether);
    uint public maxTradeLimit = TOTAL_SUPPLY;

    bool inSwapAndLiquify;
    bool swapAndLiquifyEnabled = true;

    bool public tradingEnabled = false;
    uint public liquidityFee = 300;
    uint public treasuryFee = 400;
    uint public devFee = 500;
    uint public totalFee = liquidityFee.add(treasuryFee).add(devFee);

    event UpdatedTax(uint liquidityFee, uint treasuryFee, uint devFee);
    event UpdatedSwapAmount(uint amount);
    event UpdatedWhiteList(address indexed account, bool flag);
    event UpdatedTreasuryWallet(address indexed wallet);
    event UpdatedLiquidityLocker(address indexed wallet);
    event UpdatedDevWallet(address indexed wallet);
    event UpdatedMaxTradeLimit(uint amount);
    event UpdatedRouter(address indexed router);

    constructor () ERC20('Bet Your Beans', 'BYB') {
        _mint(msg.sender, TOTAL_SUPPLY);

        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isLiquidityProvider[msg.sender] = true;

        treasuryWallet = msg.sender;
        liquidityOwner = msg.sender;
        devWallet = msg.sender;

        if (block.chainid == 97) { // BSC Testnet
            uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        }

        uniswapPair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
    }

    function _transfer(address _from, address _to, uint _amount) internal override {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_amount > 0, "Transfer amount must be greater than zero");

        // In case that remove liquidity
        if ((_from == uniswapPair && _to == address(uniswapV2Router)) || _from == address(uniswapV2Router)) {
            super._transfer(_from, _to, _amount);
            return;
        }

        Tx tradeMode = _isTrading(_from, _to);
        if (tradeMode != Tx.TRANSFER && _amount > maxTradeLimit) {
            require (false, "exceeded trading amount");
        }

        if (tradingEnabled == false &&
            ((tradeMode == Tx.BUY && !_isLiquidityProvider[_to]) ||
            (tradeMode == Tx.SELL && !_isLiquidityProvider[_from]))
        ) {
            require (false, "!available trading");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        if (
            contractTokenBalance >= minimumTokensBeforeSwap && 
            _from != uniswapPair && 
            tradingEnabled && 
            swapAndLiquifyEnabled && 
            // tradeMode == Tx.TRANSFER && // Run at only normal transfer (when not buy or sell)
            !inSwapAndLiquify
        ) {
            inSwapAndLiquify = true;
            
            uint amountToSwap = contractTokenBalance - contractTokenBalance.mul(liquidityFee).div(totalFee).div(2);
            _swapTokensForBNB(amountToSwap);

            uint amountBNBForLiquidity = address(this).balance.mul(liquidityFee.div(2)).div(totalFee.sub(liquidityFee.div(2)));
            _addLiquidity(balanceOf(address(this)), amountBNBForLiquidity);

            uint _totalFee = treasuryFee.add(devFee);
            uint _amountBNB = address(this).balance;
            if (treasuryFee > 0) {
                (bool ret, ) = payable(treasuryWallet).call{
                    value: _amountBNB.mul(treasuryFee).div(_totalFee),
                    gas: 30000
                }("");
                require (ret, "Treasury wallet can't receive the fee");
            }

            if (devFee > 0) {
                (bool ret, ) = payable(devWallet).call{
                    value: _amountBNB.mul(devFee).div(_totalFee),
                    gas: 30000
                }("");
                require (ret, "Dev wallet can't receive the fee");
            }
            
            inSwapAndLiquify = false;
        }

        uint fee = tradeMode == Tx.TRANSFER ? 0 : _amount.mul(totalFee).div(MAX_FEE);

        if(_isExcludedFromFee[_from] || _isExcludedFromFee[_to] || fee == 0) {
            super._transfer(_from, _to, _amount);
            return;
        }

        if (fee > 0) super._transfer(_from, address(this), fee);
        super._transfer(_from, _to, _amount.sub(fee));
    }

    function _swapAndLiquify(uint256 contractTokenBalance) internal {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        _swapTokensForBNB(half);

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity
        _addLiquidity(half, newBalance);
    }

    function _swapTokensForBNB(uint256 tokenAmount) internal {
        if (tokenAmount == 0) return;

        // Generate the uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp.add(180)
        );
    }
    
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            liquidityOwner,
            block.timestamp
        );
    }

    function getTokensInStuck() external onlyOwner {
        if (balanceOf(address(this)) > 0) {
            super._transfer(address(this), msg.sender, balanceOf(address(this)));
        }

        if (address(this).balance > 0) {
            payable(msg.sender).call{value: address(this).balance, gas: 3000}("");
        }
    }

    function _isTrading(address _sender, address _recipient)
        internal view
        returns (Tx)
    {
        if (balanceOf(uniswapPair) == 0) return Tx.TRANSFER; // There is no liquidity yet

        if (_sender == uniswapPair && _recipient != address(uniswapV2Router)) return Tx.BUY; // Buy Case

        if (_recipient == uniswapPair) return Tx.SELL; // Sell Case

        return Tx.TRANSFER;
    }

    function setMinimumTokensBeforeSwap(uint256 _minimumTokensBeforeSwap) external onlyOwner {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;

        emit UpdatedSwapAmount(_minimumTokensBeforeSwap);
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;

        emit UpdatedWhiteList(account, true);
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;

        emit UpdatedWhiteList(account, false);
    }

    function setLiquidityProvider(address _wallet, bool _flag) external onlyOwner{
        _isLiquidityProvider[_wallet] = _flag;
    }

    function setTradingEnabled(bool _flag) external onlyOwner {
        tradingEnabled = _flag;
    }

    function setTreasuryWallet(address _wallet) external onlyOwner {
        treasuryWallet = _wallet;

        emit UpdatedTreasuryWallet(_wallet);
    }

    function setLiquidityOwner(address _wallet) external onlyOwner {
        liquidityOwner = _wallet;

        emit UpdatedLiquidityLocker(_wallet);
    }

    function setDevWallet(address _wallet) external onlyOwner {
        devWallet = _wallet;

        emit UpdatedDevWallet(_wallet);
    }

    function setTax(uint _liquidityFee, uint _treasuryFee, uint _devFee) external onlyOwner {
        require (_liquidityFee <= FEE_LIMIT, "!available sell tax");
        require (_treasuryFee <= FEE_LIMIT, "!available sell tax");
        require (_devFee <= FEE_LIMIT, "!available sell tax");
        
        liquidityFee = _liquidityFee;
        treasuryFee = _treasuryFee;
        devFee = _devFee;
        totalFee = liquidityFee.add(treasuryFee).add(devFee);

        emit UpdatedTax(liquidityFee, treasuryFee, devFee);
    }

    function setMaxTradeLimit(uint _limit) external onlyOwner {
        require(_limit > 0, "invalid limit");
        maxTradeLimit = _limit;

        emit UpdatedMaxTradeLimit(_limit);
    }

    function setUniswapRouter(address _router) external onlyOwner {
        require (_router != address(uniswapV2Router), 'already settled');
        uniswapV2Router = IUniswapV2Router02(_router);

        address pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());
        if (pair != address(0)) return;

        uniswapPair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());

        emit UpdatedRouter(_router);
    }

    function setSwapAndLiquify(bool _flag) external onlyOwner {
        swapAndLiquifyEnabled = _flag;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
}