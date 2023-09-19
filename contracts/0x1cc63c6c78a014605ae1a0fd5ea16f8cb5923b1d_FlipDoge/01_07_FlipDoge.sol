// SPDX-License-Identifier: MIT
/**
Website: https://flipdoge.com

Telegram: https://t.me/FlipDoge

Twitter: https://twitter.com/flipdogecoin
**/
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

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

contract FlipDoge is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public teamWallet;
    address public prizesWallet;
    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;
    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    uint256 public buyTotalFees;
    uint256 public buyPrizesFee;
    uint256 public buyLiquidityFee;
    uint256 public buyTeamFee;
    uint256 public sellTotalFees;
    uint256 public sellPrizesFee;
    uint256 public sellLiquidityFee;
    uint256 public sellTeamFee;
    uint256 public tokensForPrizes;
    uint256 public tokensForLiquidity;
    uint256 public tokensForTeam;
    address public constant deadAddress = address(0xdead);
    address public immutable uniswapV2Pair;
    bool private _swapping;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public isExcludedMaxTransactionAmount;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public preMigrationTransferrable;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(
        address indexed account,
        bool isExcluded
    );

    event SetAutomatedMarketMakerPair(
        address indexed pair,
        bool indexed value
    );

    event prizesWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event teamWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    modifier onlyTeam {
        require(
            msg.sender == teamWallet ||
            msg.sender == owner(),
            "sender is not from team"
        );
        _;
    }

    constructor() ERC20("FlipDoge", "FDOGE") {
        uint256 totalSupply = 1_000_000_000 * 1e18;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromMaxTransaction(address(_uniswapV2Router), true);

        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 _buyPrizesFee = 5;
        uint256 _buyLiquidityFee = 10;
        uint256 _buyTeamFee = 10;
        uint256 _sellPrizesFee = 5;
        uint256 _sellLiquidityFee = 10;
        uint256 _sellTeamFee = 10;

        maxTransactionAmount = 10_000_000 * 1e18;
        maxWallet = 20_000_000 * 1e18;
        swapTokensAtAmount = (totalSupply * 5) / 10000;

        buyPrizesFee = _buyPrizesFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyTeamFee = _buyTeamFee;
        buyTotalFees = buyPrizesFee + buyLiquidityFee + buyTeamFee;
        sellPrizesFee = _sellPrizesFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellTeamFee = _sellTeamFee;
        sellTotalFees = sellPrizesFee + sellLiquidityFee + sellTeamFee;

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function enableTrading() external onlyOwner {
        require(!tradingActive, "trading is already active");

        _addLiquidity(balanceOf(address(this)), address(this).balance);

        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        
        tradingActive = true;
        swapEnabled = true;
    }

    function removeLimits() external onlyTeam returns (bool) {
        limitsInEffect = false;

        return true;
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyTeam returns (bool) {
        require(newAmount >= (totalSupply() * 1) / 100000, "Swap amount cannot be lower than 0.001% total supply.");
        require(newAmount <= (totalSupply() * 5) / 1000, "Swap amount cannot be higher than 0.5% total supply.");

        swapTokensAtAmount = newAmount;

        return true;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyTeam {
        isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function excludeFromFees(address account, bool excluded) public onlyTeam {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyTeam {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updatePrizesWallet(address newWallet) external onlyTeam {
        prizesWallet = newWallet;
        emit prizesWalletUpdated(newWallet, prizesWallet);
    }

    function updateTeamWallet(address newWallet) external onlyTeam {
        teamWallet = newWallet;
        emit teamWalletUpdated(newWallet, teamWallet);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !_swapping
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] ||
                        _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                if (
                    automatedMarketMakerPairs[from] &&
                    !isExcludedMaxTransactionAmount[to]
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
                else if (
                    automatedMarketMakerPairs[to] &&
                    !isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTransactionAmount."
                    );
                }
                else if (!isExcludedMaxTransactionAmount[to]) {
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
            !_swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            _swapping = true;

            _swapBack();

            _swapping = false;
        }

        bool takeFee = !_swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForTeam += (fees * sellTeamFee) / sellTotalFees;
                tokensForPrizes += (fees * sellPrizesFee) / sellTotalFees;
            }
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForTeam += (fees * buyTeamFee) / buyTotalFees;
                tokensForPrizes += (fees * buyPrizesFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function _swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForPrizes + tokensForTeam;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens).sub(tokensForPrizes);

        uint256 initialETHBalance = address(this).balance;

        _swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForLiquidity = ethBalance.mul(20).div(100); // 20%

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }

        tokensForLiquidity = 0;
        tokensForPrizes = 0;
        tokensForTeam = 0;

        super._transfer(address(this), prizesWallet, balanceOf(address(this)));

        (success, ) = address(teamWallet).call{value: address(this).balance}("");
    }

    function withdrawStuckToken(address _token, address _to) external onlyTeam {
        require(_token != address(0), "_token address cannot be 0");

        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        
        IERC20(_token).transfer(_to, _contractBalance);
    }

    function withdrawStuckEth(address toAddr) external onlyTeam {
        (bool success, ) = toAddr.call{value: address(this).balance}("");

        require(success);
    }
}