/*

TG: https://t.me/GOATverify
TWITTER: https://twitter.com/GOATonETH
Website: https://goateth.info
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GOAT is ERC20, Ownable {
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    // Limits
    uint256 public maxTx = 10; // 10 = 1%
    uint256 public maxWallet = 20; // 20 = 2%

    // Fees
    uint256 public marketingFee = 215; // 20 = 2%
    uint256 public liquidityFee = 10; // 20 = 2%
    uint256 public totalFees = marketingFee + liquidityFee;
    uint256 public numTokensToLiquify = 3000 * 10 ** 18;
    address public marketingWallet = 0x6aB81297e2E9F075d7F6C1B95722629E9C90B8E6;
    bool inSwapAndLiq;
    bool public SwapAndSendEnabled = true;

    //Mappings
    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) public _isExcluded;
    mapping(address => bool) public _isBlacklisted;

    // Anti-Bot/Sniper
    mapping(address => bool) public earlyBuyerHODL;
    mapping(address => uint256) public earlyBuyerTimeOut;
    uint8 public HODLBLOCKS;
    uint8 public botsCaught;
    uint32 public tradingStartBlock = 77777777;

    modifier lockTheSwap() {
        inSwapAndLiq = true;
        _;
        inSwapAndLiq = false;
    }

    receive() external payable {}

    constructor() ERC20("Greatest Of All Tokens", "GOAT") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[uniswapV2Pair] = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 maxTxAmount = (totalSupply() * maxTx) / 1000;
        uint256 maxWalletAmount = (totalSupply() * maxWallet) / 1000;
        uint256 taxAmount;

        if (block.number <= tradingStartBlock) {
            require(from == owner(), "Trading hasnt started");
        }

        if (from == uniswapV2Pair) {
            //Buy
            if (!_isExcludedFromFee[to]) {
                require(amount <= maxTxAmount, "Amount over max tx");
                require(
                    balanceOf(to) + amount <= maxWalletAmount,
                    "Max wallet in effect"
                );
                taxAmount = (amount * totalFees) / 1000;
            }

            if (block.number <= tradingStartBlock + HODLBLOCKS) {
                earlyBuyerHODL[to] = true;
                earlyBuyerTimeOut[to] = block.timestamp + 1 weeks;
                botsCaught += 1;
            }
        }

        if (to == uniswapV2Pair) {
            //Sell
            if (!_isExcludedFromFee[from]) {
                require(amount <= maxTxAmount, "Amount over max tx");
                require(!_isBlacklisted[from], "Account blacklisted");
                taxAmount = (amount * totalFees) / 1000;
            }

            if (earlyBuyerHODL[from]) {
                require(block.timestamp > earlyBuyerTimeOut[from]);
            }
        }

        if (to != uniswapV2Pair && from != uniswapV2Pair) {
            if (!_isExcludedFromFee[to] || !_isExcludedFromFee[from]) {
                require(
                    balanceOf(to) + amount <= maxWalletAmount,
                    "Max wallet in effect"
                );
            }

            if (earlyBuyerHODL[to])
                require(block.timestamp > earlyBuyerTimeOut[to]);
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= numTokensToLiquify;

        if (contractTokenBalance >= numTokensToLiquify) {
            contractTokenBalance = numTokensToLiquify;
        }

        if (
            overMinTokenBalance &&
            !inSwapAndLiq &&
            from != uniswapV2Pair &&
            SwapAndSendEnabled
        ) {
            handleTax(contractTokenBalance);
        }
        // Fees
        if (taxAmount > 0) {
            uint256 userAmount = amount - taxAmount;

            super._transfer(from, address(this), taxAmount);
            super._transfer(from, to, userAmount);
        } else {
            super._transfer(from, to, amount);
        }
    }

    function handleTax(uint256 _contractTokenBalance) internal lockTheSwap {
        uint256 tokensToLiquidity = (((((liquidityFee) * 1000) / totalFees)) *
            _contractTokenBalance) / 1000;

        uint256 tokensToMarketing = _contractTokenBalance - tokensToLiquidity;
        _transfer(address(this), marketingWallet, tokensToMarketing);
        addLiquidity(tokensToLiquidity);
    }

    function addLiquidity(uint256 amount) internal {
        uint256 half = amount / 2;
        uint256 otherHalf = amount - half;
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance - initialBalance;
        _addLiquidity(otherHalf, newBalance);
    }

    function swapTokensForEth(uint256 tokenAmount) internal {
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

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
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

    // SETTERS

    function startTrading(uint8 _blacklistBlocks) external onlyOwner {
        tradingStartBlock = uint32(block.number);
        HODLBLOCKS = _blacklistBlocks;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function addToBlackList(address _address) external onlyOwner {
        _isBlacklisted[_address] = true;
    }

    function removeFromBlackList(address account) external onlyOwner {
        _isBlacklisted[account] = false;
    }

    function _setMarketingWallet(address payable wallet) external onlyOwner {
        marketingWallet = wallet;
    }

    function _setMaxTxAmount(uint256 _maxTxAmount) external onlyOwner {
        maxTx = _maxTxAmount;
    }

    function _setMaxWalletAmount(uint256 _maxWalletAmount) external onlyOwner {
        maxWallet = _maxWalletAmount;
    }

    function setNewFees(uint256 _marketingFee, uint256 _liquidityFee) external onlyOwner {
        marketingFee = _marketingFee;
        liquidityFee = _liquidityFee;
         totalFees = marketingFee + liquidityFee;
    }

    function setSwapAndSendEnabled(bool _active) external onlyOwner {
        SwapAndSendEnabled = _active;
    }

    function decreaseEarlyBuyerTimeOut(
        address _address,
        uint256 _newTimeOut
    ) external onlyOwner {
        require(
            _newTimeOut < earlyBuyerTimeOut[_address],
            "Cannot increase time, only decrease"
        );
        earlyBuyerTimeOut[_address] = _newTimeOut;
    }

    function removeEarlyBuyerHODL(address _address) external onlyOwner {
        require(earlyBuyerHODL[_address], "Address is not on forced HODL");
        earlyBuyerHODL[_address] = false;
    }
}

// Interfaces
interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
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
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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