// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**

    ___             __ __ _            
   /   | ________  / //_/(_)___  ____ _
  / /| |/ ___/ _ \/ ,<  / / __ \/ __ `/
 / ___ / /__/  __/ /| |/ / / / / /_/ / 
/_/  |_\___/\___/_/ |_/_/_/ /_/\__, /  
                              /____/   
website: https://aceking.gg
twitter: https://twitter.com/officialaceking
telegram: https://t.me/AceKingPortal
medium: https://medium.com/@acekingofficial

*/

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IWETH {
    function balanceOf(address account) external view returns (uint256);
    function approve(address guy, uint wad) external returns (bool);
}

contract AceKing is ERC20, Ownable {

    // events
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool excluded);
    event ExcludeFromMaxTransaction(address indexed account, bool excluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

    // errors
    error ErrMintDisabled();
    error ErrERC20FromZero();
    error ErrERC20ToZero();
    error ErrTradingNotActive();
    error ErrBuyTransferExceedsMaxTransactionAmount();
    error ErrBuyExceedsMaxWallet();
    error ErrSellTransferExceedsMaxTransactionAmount();
    error ErrMaxWallet();
    error ErrMigrateDisabled();
    error ErrTotalSupplyExceeded();
    error ErrFeeTooHigh();
    error ErrSwapAmountTooLow();
    error ErrSwapAmountTooHigh();
    error ErrPairCannotBeRemoved();

    // constants
    uint256 public constant maxSupply = 1 * 1e9 ether;
    address constant devWallet = 0x407cc56d2Db7E3D89aC179e905013EFA0467C9a4;
    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable uniswapV2Pair;
    address private constant burnAddress = address(0xdead);

    // states
    bool public tradingEnabled = false;
    bool public swapEnabled = false;
    bool public limitsEnabled = true;

    uint256 public maxTransactionAmount;
    uint256 public maxWallet;
    uint256 public swapTokensAtAmount;

    uint256 public buyLiquidityFee;
    uint256 public buyDevFee;

    uint256 public sellLiquidityFee;
    uint256 public sellDevFee;

    uint256 public tokensForLiquidity;
    uint256 public tokensForDev;

    bool private isSwapping;

    // - exclude from fees and max transaction amount
    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isExcludedMaxTransactionAmount;

    // - store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    //   could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    // constructor
    constructor() ERC20("AceKing", unicode"ACEK") {
    
        // create uniswap pair
        address _uniswapPair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapPair;

        // initialize states
        maxTransactionAmount = 2 * 1e7 ether;       // 2% from total supply maxTransactionAmountTxn
        maxWallet = 2 * 1e7 ether;                  // 2% from total supply maxWallet
        swapTokensAtAmount = maxSupply / 1000;      // 0.1% swap wallet

        buyLiquidityFee = 2;
        buyDevFee = 2;

        sellLiquidityFee = 4;
        sellDevFee = 4;

        // exclude from paying fees or having max transaction amount
        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);
        excludeFromFees(burnAddress, true);

        excludeFromMaxTransaction(address(uniswapV2Router), true);
        excludeFromMaxTransaction(address(_uniswapPair), true);
        excludeFromMaxTransaction(msg.sender, true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(burnAddress, true);

        // set amm pair
        _setAutomatedMarketMakerPair(address(_uniswapPair), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, maxSupply);
    }

    // receive
    receive() external payable {}

    // transfer
    function _transfer(address from, address to, uint256 amount) internal override {
        if (from == address(0)) { revert ErrERC20FromZero(); }
        if (to == address(0)) { revert ErrERC20ToZero(); }

        // zero amount
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool isBuying = automatedMarketMakerPairs[from] && !isExcludedMaxTransactionAmount[to];
        bool isSelling = automatedMarketMakerPairs[to] && !isExcludedMaxTransactionAmount[from];

        bool isOwner = from == owner() || to == owner();
        bool isBurning = to == burnAddress;

        // check limits
        if (limitsEnabled && !isSwapping && !isOwner && !isBurning) {
            if (!tradingEnabled) {
                if (!isExcludedFromFees[from] && !isExcludedFromFees[to]) { revert ErrTradingNotActive(); }
            }

            if (isBuying) {
                if (amount > maxTransactionAmount) { revert ErrBuyTransferExceedsMaxTransactionAmount(); }
                if (amount + balanceOf(to) > maxWallet) { revert ErrBuyExceedsMaxWallet(); }
            } 
            
            else if (isSelling) {
                if (amount > maxTransactionAmount) { revert ErrSellTransferExceedsMaxTransactionAmount(); }
            }

            else if (!isExcludedMaxTransactionAmount[to]) {
                if (amount + balanceOf(to) > maxWallet) { revert ErrMaxWallet(); }
            }
        }

        // swap
        if (swapEnabled && balanceOf(address(this)) >= swapTokensAtAmount && !isSwapping && !automatedMarketMakerPairs[from] && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            isSwapping = true;
            _swap();
            isSwapping = false;
        }

        // fees
        uint256 fees = 0;
        if (!isSwapping && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {

            // only take fees on buys/sells, never on wallet transfers
            uint256 sellTotalFees = sellLiquidityFee + sellDevFee;
            uint256 buyTotalFees = buyLiquidityFee + buyDevFee;

            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount * sellTotalFees / 100;
                tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                tokensForDev += fees * sellDevFee / sellTotalFees;                
                super._transfer(from, address(this), fees);
            }

            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount * buyTotalFees / 100;
                tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForDev += fees * buyDevFee / buyTotalFees;
                super._transfer(from, address(this), fees);
            }
        }

        super._transfer(from, to, amount - fees);
    }

    // owners only
    function excludeFromMaxTransaction(address addr, bool excluded) public onlyOwner {
        isExcludedMaxTransactionAmount[addr] = excluded;
        emit ExcludeFromMaxTransaction(addr, excluded);
    }

    function excludeFromFees(address addr, bool excluded) public onlyOwner {
        isExcludedFromFees[addr] = excluded;
        emit ExcludeFromFees(addr, excluded);
    }

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
        swapEnabled = true;
    }

    function pauseTrading() external onlyOwner {
        tradingEnabled = false;
        swapEnabled = false;
    }

    function removeLimits() external onlyOwner {
        limitsEnabled = false;
    }

    function setFees(uint256 _buyLiquidityFee, uint256 _buyDevFee, uint256 _sellLiquidityFee, uint256 _sellDevFee) external onlyOwner {
        if (buyLiquidityFee + buyDevFee > 10) { revert ErrFeeTooHigh(); }
        if (sellLiquidityFee + sellDevFee > 10) { revert ErrFeeTooHigh(); }

        buyLiquidityFee = _buyLiquidityFee;
        buyDevFee = _buyDevFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellDevFee = _sellDevFee;
    }

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        uint256 _totalSupply = totalSupply();
        if (newAmount < _totalSupply / 100000) { revert ErrSwapAmountTooLow(); }
        if (newAmount > _totalSupply * 5 / 1000) { revert ErrSwapAmountTooHigh(); }
        swapTokensAtAmount = newAmount;
    }

    function setSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function setMaxTransactionAmount(uint256 max) external onlyOwner {
        maxTransactionAmount = max;
    }

    function setMaxWallet(uint256 max) external onlyOwner {
        maxWallet = max;
    }

    // private
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            devWallet,
            block.timestamp
        );
    }

    function _swap() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForDev;

        // nothing to swap
        if (contractBalance == 0 || totalTokensToSwap == 0) { return; }

        // swap amount
        uint256 swapAmount = contractBalance;
        if (swapAmount > swapTokensAtAmount * 20) {
            swapAmount = swapTokensAtAmount * 20;
        }

        // split liquidity tokens - 0.5 keep as is, 0.5 swap to ETH
        uint256 totalLiquidityTokens = swapAmount * tokensForLiquidity / totalTokensToSwap;
        uint256 liquidityTokens = totalLiquidityTokens / 2;

        uint256 devTokens = swapAmount - totalLiquidityTokens;
        uint256 liquidityETHTokens = totalLiquidityTokens - liquidityTokens;

        uint256 initialETHBalance = address(this).balance;
        _swapTokensForEth(devTokens + liquidityETHTokens);
        uint256 gainedETH = address(this).balance - initialETHBalance;

        uint256 ethForLiquidity = gainedETH * liquidityETHTokens / (liquidityETHTokens + devTokens);

        // reset states
        tokensForLiquidity = 0;
        tokensForDev = 0;

        // add liquidity
        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                devTokens + liquidityETHTokens,
                gainedETH,
                liquidityTokens
            );
        }

        // dev transfer
        payable(address(devWallet)).transfer(address(this).balance);
    }
}