// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router01 {
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

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

contract PRISU is
    ERC20,
    Ownable // CONTRACT NAME FOR YOUR CUSTOM CONTRACT
{
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;
    bool public swapping = false;
    bool public tradingEnabled = false;

    uint256 public sellAmount = 0;
    uint256 public buyAmount = 0;

    uint256 private totalSellFees;
    uint256 private totalBuyFees;

    address payable public bridgeFund;
    address payable public devWallet;

    uint256 public maxWallet;
    bool public maxWalletEnabled = true;
    uint256 public swapTokensAtAmount;
    uint256 public sellMarketingFees;
    uint256 public sellBridgeFundFees;
    uint256 public buyMarketingFees;
    uint256 public buyBridgeFundFees;
    uint256 public buyDevFee;
    uint256 public sellDevFee;
    uint256 public liquidityFee = 0;

    bool public swapAndLiquifyEnabled = true;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) private canTransferBeforeTradingIsEnabled;

    bool public limitsInEffect = false;
    uint256 private gasPriceLimit = 7 * 1 gwei; // MAX GWEI
    mapping(address => uint256) private _holderLastTransferBlock; // FOR 1TX PER BLOCK
    mapping(address => uint256) private _holderLastTransferTimestamp; // FOR COOLDOWN
    uint256 public launchblock; // FOR DEADBLOCKS
    uint256 public launchtimestamp; // FOR LAUNCH TIMESTAMP
    uint256 public cooldowntimer = 0; // DEFAULT COOLDOWN TIMER

    event EnableSwapAndLiquify(bool enabled);
    event SetPreSaleWallet(address wallet);
    event updateMarketingWallet(address wallet);
    event updateDevWallet(address wallet);
    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event TradingEnabled();

    event UpdateFees(
        uint256 sellMarketingFees,
        uint256 sellBridgeFundFees,
        uint256 buyMarketingFees,
        uint256 buyBridgeFundFees,
        uint256 buyDevFee,
        uint256 sellDevFee
    );

    event Airdrop(address holder, uint256 amount);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SendDividends(uint256 opAmount, bool success);

    constructor() ERC20("Princessu INU", "PRISU") {
        bridgeFund = payable(0xF5F0753F9Fd3a94dE9d5F8FfE61dDb5291f1db17);
        devWallet = payable(0x0000000000000000000000000000000000000000);
        address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

        //INITIAL FEE VALUES HERE
        buyBridgeFundFees = 4;
        sellBridgeFundFees = 4;

        // TOTAL BUY AND TOTAL SELL FEE CALCS
        totalBuyFees = buyBridgeFundFees;
        totalSellFees = sellBridgeFundFees;

        uniswapV2Router = IUniswapV2Router02(router);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );

        _setAutomatedMarketMakerPair(uniswapV2Pair, true);

        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[msg.sender] = true;
        _isExcludedFromFees[bridgeFund] = true;

        uint256 _totalSupply = (10_000_000_000) * (10**18); // TOTAL SUPPLY IS SET HERE
        _mint(owner(), _totalSupply); // only time internal mint function is ever called is to create supply
        maxWallet = _totalSupply / 50; // 2%
        swapTokensAtAmount = _totalSupply / 100; // 1%;
        // maxWallet = _totalSupply;
        // swapTokensAtAmount = _totalSupply;
        canTransferBeforeTradingIsEnabled[owner()] = true;
        canTransferBeforeTradingIsEnabled[address(this)] = true;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    receive() external payable {}

    function enableTrading() external onlyOwner {
        require(!tradingEnabled);
        tradingEnabled = true;
        launchblock = block.number;
        launchtimestamp = block.timestamp;
        emit TradingEnabled();
    }

    function setCanTransferBefore(address wallet, bool enable)
        external
        onlyOwner
    {
        canTransferBeforeTradingIsEnabled[wallet] = enable;
    }

    function setLimitsInEffect(bool value) external onlyOwner {
        limitsInEffect = value;
    }

    function setMaxWalletEnabled(bool value) external onlyOwner {
        maxWalletEnabled = value;
    }

    function setcooldowntimer(uint256 value) external onlyOwner {
        require(value <= 300, "cooldown timer cannot exceed 5 minutes");
        cooldowntimer = value;
    }

    // TAKES ALL BNB FROM THE CONTRACT ADDRESS AND SENDS IT TO OWNERS WALLET

    function setSwapTriggerAmount(uint256 amount) public onlyOwner {
        swapTokensAtAmount = amount * (10**18);
    }

    function enableSwapAndLiquify(bool enabled) public onlyOwner {
        require(swapAndLiquifyEnabled != enabled);
        swapAndLiquifyEnabled = enabled;
        emit EnableSwapAndLiquify(enabled);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    // THIS IS THE ONE YOU USE TO TRASNFER OWNER IF U EVER DO
    function transferAdmin(address newOwner) public onlyOwner {
        _isExcludedFromFees[newOwner] = true;
        canTransferBeforeTradingIsEnabled[newOwner] = true;
        transferOwnership(newOwner);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "IERC20: transfer from the zero address");
        require(to != address(0), "IERC20: transfer to the zero address");
        uint256 fee = 0;
        if (!canTransferBeforeTradingIsEnabled[from]) {
            require(tradingEnabled, "Trading has not yet been enabled");
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        } else if ( !swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to] ) {
            bool isSelling = automatedMarketMakerPairs[to];
            if (isSelling) {
                fee = sellBridgeFundFees;
                if (limitsInEffect) {
                    require(
                        block.timestamp >=
                            _holderLastTransferTimestamp[tx.origin] +
                                cooldowntimer,
                        "cooldown period active"
                    );
                    _holderLastTransferTimestamp[tx.origin] = block.timestamp;
                }
            } else {
                fee = buyBridgeFundFees;
                if (limitsInEffect) {
                    require(
                        block.number > launchblock + 2,
                        "you shall not pass"
                    );
                    require(
                        tx.gasprice <= gasPriceLimit,
                        "Gas price exceeds limit."
                    );
                    require(
                        _holderLastTransferBlock[tx.origin] != block.number,
                        "Too many TX in block"
                    );
                    require(
                        block.timestamp >=
                            _holderLastTransferTimestamp[tx.origin] +
                                cooldowntimer,
                        "cooldown period active"
                    );
                    _holderLastTransferBlock[tx.origin] = block.number;
                    _holderLastTransferTimestamp[tx.origin] = block.timestamp;
                }

                if (maxWalletEnabled) {
                    uint256 contractBalanceRecipient = balanceOf(to);
                    require(
                        contractBalanceRecipient + amount <= maxWallet,
                        "Exceeds maximum wallet token amount."
                    );
                }
            }
            uint256 totalFees = fee;
            uint256 fees = amount.mul(totalFees).div(100);
            amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
            // swapAndSendDividends();
        }

        super._transfer(from, to, amount);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
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
            owner(),
            block.timestamp
        );
    }

    function forceSwapAndSendDividends() public {
        require(bridgeFund == msg.sender);
        swapAndSendDividends();
    }

    // TAX PAYOUT CODE
    function swapAndSendDividends() private {
        uint256 token = balanceOf(address(this));
        if(token == 0) return;
        swapTokensForEth(token);
        payable(bridgeFund).transfer(address(this).balance);
    }
}