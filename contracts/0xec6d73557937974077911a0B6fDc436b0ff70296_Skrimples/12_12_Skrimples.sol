/****
        https://skrimples.ai
        https://t.me/Skrimples


        ███████╗██╗  ██╗██████╗ ██╗███╗   ███╗██████╗ ██╗     ███████╗███████╗
        ██╔════╝██║ ██╔╝██╔══██╗██║████╗ ████║██╔══██╗██║     ██╔════╝██╔════╝
        ███████╗█████╔╝ ██████╔╝██║██╔████╔██║██████╔╝██║     █████╗  ███████╗
        ╚════██║██╔═██╗ ██╔══██╗██║██║╚██╔╝██║██╔═══╝ ██║     ██╔══╝  ╚════██║
        ███████║██║  ██╗██║  ██║██║██║ ╚═╝ ██║██║     ███████╗███████╗███████║
        ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝╚═╝     ╚══════╝╚══════╝╚══════╝


        The scrappiest, stinkiest pup in all of Shibarium.

        by Bimpus & Snake
****/

//  SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0 < 0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


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

contract Skrimples is ERC20, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant BLACKLISTER_ROLE = keccak256("BLACKLISTER_ROLE");

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public marketingWallet;
    address public devWallet;
    address public bonePileWallet;
    address public liquidity;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    bool public blacklistEnabled = true;

    uint256 public buyTotalFees;
    uint256 public buyMarketingFee;
    uint256 public buyLiquidityFee;
    uint256 public buyDevFee;
    uint256 public buyBonePileFee;

    uint256 public sellTotalFees;
    uint256 public sellMarketingFee;
    uint256 public sellLiquidityFee;
    uint256 public sellDevFee;
    uint256 public sellBonePileFee;

    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;
    uint256 public tokensForDev;
    uint256 public tokensForBonePile;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public blacklists;

    // store addresses that are automatic market maker pairs. Transfers *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        _;
    }

    modifier onlyBlacklister() {
        require(hasRole(BLACKLISTER_ROLE, msg.sender), "Caller is not blacklister");
        _;
    }

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event LimitsRemoved();

    event BlacklistDisabled();

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event marketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event devWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event liquidityUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event bonePileWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    address admin = msg.sender;

    constructor(address blacklister) ERC20("Skrimples", "SKRIMP") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        // Grant the contract deployer the default admin role: will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        // Renouce blacklister role after blacklist is disabled
        _setupRole(BLACKLISTER_ROLE, blacklister);

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        // Initial tax of 97% to catch bots, once lowered cannot be raised higher than 5%
        uint256 _buyMarketingFee = 97;
        uint256 _buyLiquidityFee = 0;
        uint256 _buyDevFee = 0;
        uint256 _buyBonePileFee = 0;

        uint256 _sellMarketingFee = 2;
        uint256 _sellLiquidityFee = 0;
        uint256 _sellDevFee = 2;
        uint256 _sellBonePileFee = 1;

        uint256 totalSupply = 69000000000 * 1e18;

        // Limits imposed till the chart is stable
        maxTransactionAmount = (totalSupply * 1) / 100;
        maxWallet = (totalSupply * 1) / 100;
        swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05% swap wallet

        // Fees
        buyMarketingFee = _buyMarketingFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyDevFee = _buyDevFee;
        buyBonePileFee = _buyBonePileFee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyDevFee + buyBonePileFee;

        sellMarketingFee = _sellMarketingFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellDevFee = _sellDevFee;
        sellBonePileFee = _sellBonePileFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellDevFee + sellBonePileFee;

        marketingWallet = address(0x70ae2cC09b5BaEaeC0bFe6f9F13331872Ea8aEF8);
        devWallet = address(0x8d9C26ee524Ae225CA3d640f8A9d73C32b6632FB);
        bonePileWallet = address(0x03888625CCCbAfE87fC4e264B54616cEAD476258);
        liquidity = address(0x70ae2cC09b5BaEaeC0bFe6f9F13331872Ea8aEF8);

        // exclude from paying fees
        excludeFromFees(address(admin), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(marketingWallet, true);
        // exclude from max transaction amount
        excludeFromMaxTransaction(address(admin), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(marketingWallet, true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyBlacklister {
        blacklists[_address] = _isBlacklisting;
    }

    // Disable blacklist once token is stable, cannot be enabled again
    function disableBlacklist() external onlyBlacklister returns (bool) {
        blacklistEnabled = false;
        emit BlacklistDisabled();
        return true;
    }

    // once enabled, is forever enabled
    function enableTrading() external onlyAdmin {
        tradingActive = true;
        swapEnabled = true;
    }

    // remove limits after token is stable, cannot be enabled again
    function removeLimits() external onlyAdmin returns (bool) {
        limitsInEffect = false;
        emit LimitsRemoved();
        return true;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount)
        external onlyAdmin
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

    // MaxTxAmount and MaxWalletAmount, cannot set lower than 2% of totalSupply
    function updateMaximums(uint256 newNum) external onlyAdmin {
        require(
            newNum >= ((totalSupply() * 2) / 100) / 1e18,
            "Cannot set maximums lower than 2%"
        );
        maxWallet = newNum * (10**18);
        maxTransactionAmount = newNum * (10**18);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public onlyAdmin {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    // only use to disable buy/sell fees if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyAdmin {
        swapEnabled = enabled;
    }

    function updateFees(
        uint256 _marketingFeeBuy,
        uint256 _liquidityFeeBuy,
        uint256 _devFeeBuy,
        uint256 _bonePileFeeBuy,
        uint256 _marketingFeeSell,
        uint256 _liquidityFeeSell,
        uint256 _devFeeSell,
        uint256 _bonePileFeeSell
    ) external onlyAdmin {
        require(
            _marketingFeeBuy + _liquidityFeeBuy + _devFeeBuy + _bonePileFeeBuy <= 5,
            "buyTotalFees cannot exceed 5% of transaction"
        );
        require(
            _marketingFeeSell + _liquidityFeeSell + _devFeeSell + _bonePileFeeBuy <= 5,
            "sellTotalFees cannot exceed 5% of transaction"
        );
        buyMarketingFee = _marketingFeeBuy;
        buyLiquidityFee = _liquidityFeeBuy;
        buyDevFee = _devFeeBuy;
        buyBonePileFee = _bonePileFeeBuy;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyDevFee + buyBonePileFee;
        sellMarketingFee = _marketingFeeSell;
        sellLiquidityFee = _liquidityFeeSell;
        sellDevFee = _devFeeSell;
        sellBonePileFee = _bonePileFeeSell;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellDevFee + sellBonePileFee;
    }

    function excludeFromFees(address account, bool excluded) public onlyAdmin {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public onlyAdmin {
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

    function updateMarketingWallet(address newMarketingWallet)
        external onlyAdmin {
        emit marketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
    }

    function updateLiquidity(address newLiquidity)
        external onlyAdmin {
        emit liquidityUpdated(newLiquidity, liquidity);
        liquidity = newLiquidity;
    }

    function updateDevWallet(address newWallet) external onlyAdmin {
        emit devWalletUpdated(newWallet, devWallet);
        devWallet = newWallet;
    }

    function updateBonePileWallet(address newWallet) external onlyAdmin {
        emit bonePileWalletUpdated(newWallet, bonePileWallet);
        bonePileWallet = newWallet;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        if (blacklistEnabled) {
            require(!blacklists[to] && !blacklists[from], "Blacklisted");
        }
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
                from != address(admin) &&
                to != address(admin) &&
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

        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForDev += (fees * sellDevFee) / sellTotalFees;
                tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;
                tokensForBonePile += (fees * sellBonePileFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForDev += (fees * buyDevFee) / buyTotalFees;
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
                tokensForBonePile += (fees * buyBonePileFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidity,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForMarketing +
            tokensForDev +
            tokensForBonePile;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(
            totalTokensToSwap
        );
        uint256 ethForDev = ethBalance.mul(tokensForDev).div(totalTokensToSwap);

        uint256 ethForBonePile = ethBalance.mul(tokensForBonePile).div(totalTokensToSwap);

        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForDev - ethForBonePile;

        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForDev = 0;
        tokensForBonePile = 0;

        (success, ) = address(devWallet).call{value: ethForDev}("");

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }


        (success, ) = address(bonePileWallet).call{value: ethForBonePile}("");

        (success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");
    }
}