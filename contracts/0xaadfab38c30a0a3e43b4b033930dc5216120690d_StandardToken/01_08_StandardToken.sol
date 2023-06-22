// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

interface IUniswapV2Caller {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external;
}
interface IFee {
    function payFee(
        uint256 _tokenType
    ) external payable;
}
contract StandardToken is ERC20, Ownable {
    using SafeERC20 for IERC20;
    uint256 private constant MAX = ~uint256(0);
    IUniswapV2Caller public constant uniswapV2Caller =
        IUniswapV2Caller(0x1CcFE8c40eF259566433716002E379dFfFbf5a3e);
    IFee public constant feeContract = IFee(0xfd6439AEfF9d2389856B7486b9e74a6DacaDcDCe);
    uint8 private _decimals;
    ///////////////////////////////////////////////////////////////////////////
    address public baseTokenForPair;
    bool private inSwapAndLiquify;
    uint16 public sellLiquidityFee;
    uint16 public buyLiquidityFee;

    uint16 public sellMarketingFee;
    uint16 public buyMarketingFee;

    address public marketingWallet;
    bool public isMarketingFeeBaseToken;

    uint256 public minAmountToTakeFee;
    uint256 public maxWallet;
    uint256 public maxTransactionAmount;

    IUniswapV2Router02 public mainRouter;
    address public mainPair;

    mapping(address => bool) public isExcludedFromMaxTransactionAmount;
    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public automatedMarketMakerPairs;

    uint256 private _liquidityFeeTokens;
    uint256 private _marketingFeeTokens;
    event UpdateLiquidityFee(
        uint16 newSellLiquidityFee,
        uint16 newBuyLiquidityFee,
        uint16 oldSellLiquidityFee,
        uint16 oldBuyLiquidityFee
    );
    event UpdateMarketingFee(
        uint16 newSellMarketingFee,
        uint16 newBuyMarketingFee,
        uint16 oldSellMarketingFee,
        uint16 oldBuyMarketingFee
    );
    event UpdateMarketingWallet(
        address indexed newMarketingWallet,
        bool newIsMarketingFeeBaseToken,
        address indexed oldMarketingWallet,
        bool oldIsMarketingFeeBaseToken
    );
    event ExcludedFromMaxTransactionAmount(address indexed account, bool isExcluded);
    event UpdateMinAmountToTakeFee(uint256 newMinAmountToTakeFee, uint256 oldMinAmountToTakeFee);
    event SetAutomatedMarketMakerPair(address indexed pair, bool value);
    event ExcludedFromFee(address indexed account, bool isEx);
    event SwapAndLiquify(
        uint256 tokensForLiquidity,
        uint256 baseTokenForLiquidity
    );
    event MarketingFeeTaken(
        uint256 marketingFeeTokens,
        uint256 marketingFeeBaseTokenSwapped
    );
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldRouter);
    event UpdateMaxWallet(uint256 newMaxWallet, uint256 oldMaxWallet);
    event UpdateMaxTransactionAmount(uint256 newMaxTransactionAmount, uint256 oldMaxTransactionAmount);
    ///////////////////////////////////////////////////////////////////////////////
 

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[3] memory _accounts,
        bool _isMarketingFeeBaseToken,
        uint16[4] memory _fees
    ) payable ERC20(_name, _symbol) {
        feeContract.payFee{value: msg.value}(1);   
        _decimals = __decimals;
        _mint(msg.sender, _totalSupply );
        baseTokenForPair=_accounts[2];
        require(_accounts[0]!=address(0), "marketing wallet can not be 0");
        require(_accounts[1]!=address(0), "Router address can not be 0");
        require(_fees[0]+(_fees[2])<=200, "sell fee <= 20%");
        require(_fees[1]+(_fees[3])<=200, "buy fee <= 20%");

        marketingWallet=_accounts[0];
        isMarketingFeeBaseToken=_isMarketingFeeBaseToken;
        emit UpdateMarketingWallet(
            marketingWallet,
            isMarketingFeeBaseToken,
            address(0),
            false
        );
        mainRouter=IUniswapV2Router02(_accounts[1]);
        if(baseTokenForPair != mainRouter.WETH()){            
            IERC20(baseTokenForPair).approve(address(mainRouter), MAX);            
        }
        _approve(address(this), address(uniswapV2Caller), MAX);
        _approve(address(this), address(mainRouter), MAX);
        
        
        emit UpdateUniswapV2Router(address(mainRouter), address(0));
        mainPair = IUniswapV2Factory(mainRouter.factory()).createPair(
            address(this),
            baseTokenForPair
        );
        require(_maxTransactionAmount>=_totalSupply / 10000, "maxTransactionAmount >= total supply / 10000");
        require(_maxWallet>=_totalSupply / 10000, "maxWallet >= total supply / 10000");
        maxWallet=_maxWallet;
        emit UpdateMaxWallet(maxWallet, 0);
        maxTransactionAmount=_maxTransactionAmount;
        emit UpdateMaxTransactionAmount(maxTransactionAmount, 0);
        
        sellLiquidityFee=_fees[0];
        buyLiquidityFee=_fees[1];
        emit UpdateLiquidityFee(sellLiquidityFee, buyLiquidityFee, 0, 0);        
        sellMarketingFee=_fees[2];
        buyMarketingFee=_fees[3];
        emit UpdateMarketingFee(
            sellMarketingFee,
            buyMarketingFee,
            0,
            0
        );
        minAmountToTakeFee=_totalSupply/10000;
        emit UpdateMinAmountToTakeFee(minAmountToTakeFee, 0);
        isExcludedFromFee[address(this)]=true;
        isExcludedFromFee[marketingWallet]=true;
        isExcludedFromFee[_msgSender()]=true;
        isExcludedFromFee[address(0xdead)] = true;
        isExcludedFromMaxTransactionAmount[address(0xdead)]=true;
        isExcludedFromMaxTransactionAmount[address(this)]=true;
        isExcludedFromMaxTransactionAmount[marketingWallet]=true;
        isExcludedFromMaxTransactionAmount[_msgSender()]=true;
        _setAutomatedMarketMakerPair(mainPair, true);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function updateUniswapV2Pair(address _baseTokenForPair) external onlyOwner {
        baseTokenForPair = _baseTokenForPair;
        mainPair = IUniswapV2Factory(mainRouter.factory()).createPair(
            address(this),
            baseTokenForPair
        );
        if(baseTokenForPair != mainRouter.WETH()){
            IERC20(baseTokenForPair).approve(address(mainRouter), MAX);            
        }
        _setAutomatedMarketMakerPair(mainPair, true);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(mainRouter),
            "The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(mainRouter));
        mainRouter = IUniswapV2Router02(newAddress);
        _approve(address(this), address(mainRouter), MAX);
        if(baseTokenForPair != mainRouter.WETH()){
            IERC20(baseTokenForPair).approve(address(mainRouter), MAX);            
        }        
        address _mainPair = IUniswapV2Factory(mainRouter.factory()).createPair(
            address(this),
            baseTokenForPair
        );
        mainPair = _mainPair;
        _setAutomatedMarketMakerPair(mainPair, true);
    }

    /////////////////////////////////////////////////////////////////////////////////
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function updateLiquidityFee(
        uint16 _sellLiquidityFee,
        uint16 _buyLiquidityFee
    ) external onlyOwner {
        require(
            _sellLiquidityFee + (sellMarketingFee) <= 200,
            "sell fee <= 20%"
        );
        require(_buyLiquidityFee + (buyMarketingFee) <= 200, "buy fee <= 20%");
        emit UpdateLiquidityFee(
            _sellLiquidityFee,
            _buyLiquidityFee,
            sellLiquidityFee,
            buyLiquidityFee
        );
        sellLiquidityFee = _sellLiquidityFee;
        buyLiquidityFee = _buyLiquidityFee;           
    }

    function updateMaxWallet(uint256 _maxWallet) external onlyOwner {
        require(_maxWallet>=totalSupply() / 10000, "maxWallet >= total supply / 10000");
        emit UpdateMaxWallet(_maxWallet, maxWallet);
        maxWallet = _maxWallet;
    }

    function updateMaxTransactionAmount(uint256 _maxTransactionAmount)
        external
        onlyOwner
    {
        require(_maxTransactionAmount>=totalSupply() / 10000, "maxTransactionAmount >= total supply / 10000");
        emit UpdateMaxTransactionAmount(_maxTransactionAmount, maxTransactionAmount);
        maxTransactionAmount = _maxTransactionAmount;
    }

    function updateMarketingFee(
        uint16 _sellMarketingFee,
        uint16 _buyMarketingFee
    ) external onlyOwner {
        require(
            _sellMarketingFee + (sellLiquidityFee) <= 200,
            "sell fee <= 20%"
        );
        require(_buyMarketingFee + (buyLiquidityFee) <= 200, "buy fee <= 20%");
        emit UpdateMarketingFee(
            _sellMarketingFee,
            _buyMarketingFee,
            sellMarketingFee,
            buyMarketingFee
        );
        sellMarketingFee = _sellMarketingFee;
        buyMarketingFee = _buyMarketingFee;  
    }

    function updateMarketingWallet(
        address _marketingWallet,
        bool _isMarketingFeeBaseToken
    ) external onlyOwner {
        require(_marketingWallet != address(0), "marketing wallet can't be 0");
        emit UpdateMarketingWallet(_marketingWallet, _isMarketingFeeBaseToken,
            marketingWallet, isMarketingFeeBaseToken);
        marketingWallet = _marketingWallet;
        isMarketingFeeBaseToken = _isMarketingFeeBaseToken;
        isExcludedFromFee[_marketingWallet] = true;
        isExcludedFromMaxTransactionAmount[_marketingWallet] = true;
    }

    function updateMinAmountToTakeFee(uint256 _minAmountToTakeFee)
        external
        onlyOwner
    {
        require(_minAmountToTakeFee > 0, "minAmountToTakeFee > 0");
        emit UpdateMinAmountToTakeFee(_minAmountToTakeFee, minAmountToTakeFee);
        minAmountToTakeFee = _minAmountToTakeFee;     
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
        isExcludedFromMaxTransactionAmount[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function excludeFromFee(address account, bool isEx) external onlyOwner {
        require(isExcludedFromFee[account] != isEx, "already");
        isExcludedFromFee[account] = isEx;
        emit ExcludedFromFee(account, isEx);
    }

    function excludeFromMaxTransactionAmount(address account, bool isEx)
        external
        onlyOwner
    {
        require(isExcludedFromMaxTransactionAmount[account]!=isEx, "already");
        isExcludedFromMaxTransactionAmount[account] = isEx;
        emit ExcludedFromMaxTransactionAmount(account, isEx);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >=
            minAmountToTakeFee;

        // Take Fee
        if (
            !inSwapAndLiquify &&
            balanceOf(mainPair) > 0 &&
            overMinimumTokenBalance &&
            automatedMarketMakerPairs[to]
        ) {
            takeFee();
        }

        uint256 _liquidityFee;
        uint256 _marketingFee;
        // If any account belongs to isExcludedFromFee account then remove the fee

        if (
            !inSwapAndLiquify &&
            !isExcludedFromFee[from] &&
            !isExcludedFromFee[to]
        ) {
            // Buy
            if (automatedMarketMakerPairs[from]) {
                _liquidityFee = (amount * (buyLiquidityFee)) / (1000);
                _marketingFee = (amount * (buyMarketingFee)) / (1000);
            }
            // Sell
            else if (automatedMarketMakerPairs[to]) {
                _liquidityFee = (amount * (sellLiquidityFee)) / (1000);
                _marketingFee = (amount * (sellMarketingFee)) / (1000);
            }
            uint256 _feeTotal = _liquidityFee + (_marketingFee);
            if (_feeTotal > 0) super._transfer(from, address(this), _feeTotal);
            amount = amount - (_liquidityFee) - (_marketingFee);
            _liquidityFeeTokens = _liquidityFeeTokens + (_liquidityFee);
            _marketingFeeTokens = _marketingFeeTokens + (_marketingFee);
        }
        super._transfer(from, to, amount);
        if (!inSwapAndLiquify) {
            if (!isExcludedFromMaxTransactionAmount[from]) {
                require(
                    amount < maxTransactionAmount,
                    "ERC20: exceeds transfer limit"
                );
            }
            if (!isExcludedFromMaxTransactionAmount[to]) {
                require(
                    balanceOf(to) < maxWallet,
                    "ERC20: exceeds max wallet limit"
                );
            }
        }
    }

    function takeFee() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensTaken = _liquidityFeeTokens + _marketingFeeTokens;
        if (totalTokensTaken == 0 || contractBalance < totalTokensTaken) {
            return;
        }

        // Halve the amount of liquidity tokens
        uint256 tokensForLiquidity = _liquidityFeeTokens / 2;
        uint256 initialBaseTokenBalance = baseTokenForPair==mainRouter.WETH() ? address(this).balance
            : IERC20(baseTokenForPair).balanceOf(address(this));
        uint256 baseTokenForLiquidity;
        if (isMarketingFeeBaseToken) {
            uint256 tokensForSwap=tokensForLiquidity+_marketingFeeTokens;
            if(tokensForSwap>0)
                swapTokensForBaseToken(tokensForSwap);
            uint256 baseTokenBalance = baseTokenForPair==mainRouter.WETH() ? address(this).balance - initialBaseTokenBalance
                : IERC20(baseTokenForPair).balanceOf(address(this)) - initialBaseTokenBalance;
            uint256 baseTokenForMarketing = (baseTokenBalance *
                _marketingFeeTokens) / tokensForSwap;
            baseTokenForLiquidity = baseTokenBalance - baseTokenForMarketing;
            if(baseTokenForMarketing>0){
                if(baseTokenForPair==mainRouter.WETH()){                
                    (bool success, )=address(marketingWallet).call{value: baseTokenForMarketing}("");
                    if(success){
                        emit MarketingFeeTaken(0, baseTokenForMarketing);
                    }
                }else{
                    IERC20(baseTokenForPair).safeTransfer(
                        marketingWallet,
                        baseTokenForMarketing
                    );
                    emit MarketingFeeTaken(0, baseTokenForMarketing);
                }                
            }            
        } else {
            if(tokensForLiquidity>0)
                swapTokensForBaseToken(tokensForLiquidity);
            baseTokenForLiquidity = baseTokenForPair==mainRouter.WETH() ? address(this).balance - initialBaseTokenBalance
                : IERC20(baseTokenForPair).balanceOf(address(this)) - initialBaseTokenBalance;
            if(_marketingFeeTokens>0){
                _transfer(address(this), marketingWallet, _marketingFeeTokens);
                emit MarketingFeeTaken(_marketingFeeTokens, 0);                
            }            
        }

        if (tokensForLiquidity > 0 && baseTokenForLiquidity > 0) {
            addLiquidity(tokensForLiquidity, baseTokenForLiquidity);
            emit SwapAndLiquify(tokensForLiquidity, baseTokenForLiquidity);
        }
        _marketingFeeTokens = 0;
        _liquidityFeeTokens = 0;    
        if(owner()!=address(0))
            _transfer(address(this), owner(), balanceOf(address(this)));  
    }

    function swapTokensForBaseToken(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = baseTokenForPair;        
        if (path[1] == mainRouter.WETH()){
            mainRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of BaseToken
                path,
                address(this),
                block.timestamp
            );
        }else{
            uniswapV2Caller.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    address(mainRouter),
                    tokenAmount,
                    0, // accept any amount of BaseToken
                    path,
                    block.timestamp
                );
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 baseTokenAmount)
        private
    {
        if (baseTokenForPair == mainRouter.WETH()) 
            mainRouter.addLiquidityETH{value: baseTokenAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                address(0xdead),
                block.timestamp
            );
        else{
            mainRouter.addLiquidity(
                address(this),
                baseTokenForPair,
                tokenAmount,
                baseTokenAmount,
                0,
                0,
                address(0xdead),
                block.timestamp
            );
        }           
    }
    function withdrawETH() external onlyOwner {
        (bool success, )=address(owner()).call{value: address(this).balance}("");
        require(success, "Failed in withdrawal");
    }
    function withdrawToken(address token) external onlyOwner{
        require(address(this) != token, "Not allowed");
        IERC20(token).safeTransfer(owner(), IERC20(token).balanceOf(address(this)));
    }
    receive() external payable {}
}