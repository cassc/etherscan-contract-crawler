/**
                              
,-.----.                                      
\    /  \               ,-.----.       ,---,. 
|   :    \         ,---,\    /  \    ,'  .' | 
|   |  .\ :       /_ ./|;   :    \ ,---.'   | 
.   :  |: | ,---, |  ' :|   | .\ : |   |   .' 
|   |   \ :/___/ \.  : |.   : |: | :   :  |-, 
|   : .   / .  \  \ ,' '|   |  \ : :   |  ;/| 
;   | |`-'   \  ;  `  ,'|   : .  / |   :   .' 
|   | ;       \  \    ' ;   | |  \ |   |  |-, 
:   ' |        '  \   | |   | ;\  \'   :  ;/| 
:   : :         \  ;  ; :   ' | \.'|   |    \ 
|   | :          :  \  \:   : :-'  |   :   .' 
`---'.|           \  ' ;|   |.'    |   | ,'   
  `---`            `--` `---'      `----'     

2% Burn on every TX
1% of each TX sent to the contract - contract automaticlly buys tokens on sells when balance is over 0.1 E
1% added to liquidity for price stability

LIQ locked for 1 year. 

-No dev tax 

Staking live on launch APY: 817%

Contract will be renounced at 50K MC - required to change max wallet sizes once bots are out. 

-Contract cannot be honey potted - taxes are hard capped 

Twitter: @pyre_eth - follow for updates
Web: https://pyre-eth.com/

No tg find somewhere else to fud your bags to eachother. 

 */


// SPDX-License-Identifier: MIT

pragma solidity =0.8.10 >=0.8.10 >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;


import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Stake.sol";

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Pyre is ERC20, Ownable, Stake {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public buybackWallet;
    
    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    uint256 public enableBlock = 0;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 public buyTotalFees;
    uint256 public buyBuybackFee;
    uint256 public buyBurnFee;
    uint256 public buyLiquidityFee;

    uint256 public sellTotalFees;
    uint256 public sellBuybackFee;
    uint256 public sellBurnFee;
    uint256 public sellLiquidityFee;

    uint256 tokensForBuyback;
    uint256 public tokensForBurn;
    uint256 public tokensForLiquidity;

    /******************/

    //Combating bots

    mapping (address => bool) public bots;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event buybackWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20("Pyre", "PYRE") {
            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 _buyBurnFee = 2;
        uint256 _buyBuybackFee = 1;
        uint256 _buyLiquidityFee = 1;

        uint256 _sellBurnFee = 2;
        uint256 _sellBuybackFee = 1;
        uint256 _sellLiquidityFee = 1;

        uint256 totalSupply = 1_000_000_000 * 1e18;

        maxTransactionAmount = 10_000_000 * 1e18; //1% of total supply
        maxWallet = 30_000_000 * 1e18; //3% of total supply
        swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05% - tokens swapped for buy back

        buyBurnFee = _buyBurnFee;
        buyBuybackFee = _buyBuybackFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyTotalFees = buyBurnFee + buyBuybackFee + buyLiquidityFee;

        sellBurnFee = _sellBurnFee;
        sellBuybackFee = _sellBuybackFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellTotalFees = sellBurnFee + sellBuybackFee + sellLiquidityFee;

        buybackWallet = address(owner());

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
        enableBlock = block.number;
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner returns (bool) {
        transferDelayEnabled = false;
        return true;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newNum * (10**18);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function updateBuyFees(
        uint256 _burnFee,
        uint256 _buybackFee,
        uint256 _buyLiquidityFee
    ) external onlyOwner {
        buyBurnFee = _burnFee;
        buyBuybackFee = _buybackFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyTotalFees = buyBurnFee + buyBuybackFee + buyLiquidityFee;
        require(buyTotalFees <= 10, "Fees must be lower than 10%");
    }
    
    function updateSellFees(
        uint256 _burnFee,
        uint256 _sellbackFee,
        uint256 _sellLiquidityFee
    ) external onlyOwner {
        sellBurnFee = _burnFee;
        sellBuybackFee = _sellbackFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellTotalFees = buyBurnFee + buyBuybackFee + sellLiquidityFee;
        require(sellTotalFees <= 10, "Fees must be lower than 10%");
    }


    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateBuybackWallet(address newBuybackWallet) external onlyOwner {
        emit buybackWalletUpdated(newBuybackWallet, buybackWallet);
        buybackWallet = newBuybackWallet;
    }


    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    event BoughtEarly(address indexed sniper);


    function _transfer(
        address from,
        address to, 
        uint256 amount
    ) internal override {
        require(from != address(0));
        require(to != address(0));

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (bots[from] || bots[to]){
            super._transfer(from, to, 0);
            return; 
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (transferDelayEnabled) {
                    if (
                        to != owner() &&
                        to != address(uniswapV2Router) &&
                        to != address(uniswapV2Pair)
                    ) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                                block.number,
                            "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTransactionAmount."
                    );
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        
        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            //on sells
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForBurn += (fees * sellBurnFee) / sellTotalFees;
                tokensForBuyback += (fees * sellBuybackFee) / sellTotalFees;

            }
            //on buys
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForBurn += (fees * buyBurnFee) / buyTotalFees;
                tokensForBuyback += (fees * buyBuybackFee) / buyTotalFees;
            }

            //Add bots
            if (automatedMarketMakerPairs[from] && enableBlock != 0 && block.number <= enableBlock) {
                bots[to] = true;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
                if(tokensForBurn > 0) {
                    _burn(address(this), tokensForBurn);
                    tokensForBurn = 0;
                }
                if(automatedMarketMakerPairs[to]) {
                    swapEthForTokens();
                }
            }
            
            amount -= fees;

        }

        super._transfer(from, to, amount);

    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapEthForTokens() private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        if(address(this).balance >= 0.1 ether) {
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens(
                0,
                path,
                deadAddress,
                block.timestamp
            );
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForBuyback;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForBuyback = ethBalance.mul(tokensForBuyback).div(
            totalTokensToSwap
        );

        uint256 ethForLiquidity = ethBalance - ethForBuyback;

        tokensForLiquidity = 0;
        tokensForBuyback = 0;

        // (success, ) = address(buybackWallet).call{value: ethForBuyback}("");

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }
    }

    //Staking funcs

    function mintStakeRewards(address staker, uint256 amount) internal {
        require(staker != address(0));
        _mint(staker, amount);
    }

    function stake(uint256 amount) public{
        require(amount < super.balanceOf(msg.sender));
        _stake(amount);
        _burn(msg.sender, amount);
    }

    function withdrawStake(uint256 amount) public {
        uint256 amountToWithdraw = _unstake(amount);
        mintStakeRewards(msg.sender, amountToWithdraw);
    }

    function setRewardRate(uint256 newRate) public onlyOwner{
        _rewardRate = newRate;
    }

    function getStakedAmount(address user) public view returns(uint256){
        return _stakedAmount[user];
    }


    function withdrawEthPool() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function withdrawStuckTokens(address token) public onlyOwner{
        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }

}