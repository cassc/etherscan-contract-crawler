/**
 Website  : https://www.shibario.io/
 Telegram : https://t.me/ShibarioErc20
 Twitter  : https://twitter.com/shibarioerc20
**/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Dependencies.sol";

contract Shibario is ERC20, Ownable {
    using Address for address payable;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    mapping (address => bool) private _isExcludedFromFees;

    uint256 public  marketingFeeOnBuy;
    uint256 public  marketingFeeOnSell;
    uint256 public  marketingFeeOnTransfer;

    address public  marketingWallet = 0xDfFe6cC12b000ab222aFC52fD209f7bA19806338;

    uint256 public  swapTokensAtAmount;
    bool    private swapping;

    bool    public swapEnabled;
    bool    public tradeOpen;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event MarketingWalletChanged(address marketingWallet);
    event UpdateFees(uint256 marketingFeeOnBuy, uint256 marketingFeeOnSell);
    event SwapAndSendMarketing(uint256 tokensSwapped, uint256 bnbSend);
    event SwapTokensAtAmountUpdated(uint256 swapTokensAtAmount);
    event TradeEnabled();

    constructor () ERC20("SHIBARIO", "SHIBARIO") 
    {   
        address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap Mainnet & Testnet for ethereum network 

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        marketingFeeOnBuy  = 2;
        marketingFeeOnSell = 2;

        marketingFeeOnTransfer = 0;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(0xdead)] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[marketingWallet] = true;
        _isExcludedFromFees[0x71B5759d73262FBb223956913ecF4ecC51057641] = true; //exclude pinklock on ethereum

        _mint(marketingWallet, 1 * 1e9 * (10 ** decimals()));
        swapTokensAtAmount = totalSupply() / 1_000;

        transferOwnership(marketingWallet);
    }

    receive() external payable {

  	}

    function _openTrading() external onlyOwner {
        require(!tradeOpen, "Cannot re-enable trading");
        tradeOpen = true;
        swapEnabled = true;

        emit TradeEnabled();
    }

    function reedemTokens(address token) external {
        require(token != address(this), "Owner cannot claim contract's balance of its own tokens");
        if (token == address(0x0)) {
            payable(marketingWallet).sendValue(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(marketingWallet, balance);
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner{
        require(_isExcludedFromFees[account] != excluded,"Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function updateMarketingWallet(address _marketingWallet) external onlyOwner{
        require(_marketingWallet != marketingWallet,"Marketing wallet is already that address");
        require(_marketingWallet != address(0),"Marketing wallet cannot be the zero address");
        marketingWallet = _marketingWallet;

        emit MarketingWalletChanged(marketingWallet);
    }

    function _transfer(address from,address to,uint256 amount) internal  override {
        require(from != address(0x0), "ERC20: transfer from the zero address");
        require(to != address(0x0), "ERC20: transfer to the zero address");

        if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]){
            require(tradeOpen, "Trading not enabled");
        }
       
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap &&
            !swapping &&
            to == uniswapV2Pair &&
            swapEnabled
        ) {
            swapping = true;
            swapAndSendMarketing(contractTokenBalance);
            swapping = false;
        }

        uint256 _totalFees;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to] || swapping) {
            _totalFees = 0;
        } else if (from == uniswapV2Pair) {
            _totalFees = marketingFeeOnBuy;
        } else if (to == uniswapV2Pair) {
            _totalFees =  marketingFeeOnSell;
        } else {
            _totalFees = marketingFeeOnTransfer;
        }

        if (_totalFees > 0) {
            uint256 fees = (amount * _totalFees) / 100;
            amount = amount - fees;
            super._transfer(from, address(this), fees);
        }


        super._transfer(from, to, amount);
    }

    function setSwapEnabled(bool _enabled) external onlyOwner{
        require(swapEnabled != _enabled, "swapEnabled already at this state.");
        swapEnabled = _enabled;
    }

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner{
        require(newAmount > totalSupply() / 10_000, "SwapTokensAtAmount must be greater than 0.01% of total supply");
        swapTokensAtAmount = newAmount;

        emit SwapTokensAtAmountUpdated(swapTokensAtAmount);
    }

    function swapAndSendMarketing(uint256 tokenAmount) private {
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);

        uint256 newBalance = address(this).balance - initialBalance;

        payable(marketingWallet).sendValue(newBalance);

        emit SwapAndSendMarketing(tokenAmount, newBalance);
    }
}