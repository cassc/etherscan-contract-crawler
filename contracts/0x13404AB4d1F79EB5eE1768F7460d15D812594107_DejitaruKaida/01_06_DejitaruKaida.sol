// SPDX-License-Identifier: Unlicensed

/** 
 * Twitter: https://twitter.com/dejitarukaida
 * Website: https://dejitarukaida.com
*/

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

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

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
// Subject to the MIT license.

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract DejitaruKaida is ERC20, Ownable, ReentrancyGuard {
    uint256 private constant DENOMENATOR_PERCENT = 1000;
    address private constant DEAD = address(0xdead);

    address private _devWallet;

    mapping(address => bool) private _isTaxExcluded;
    mapping(address => bool) private _isLimitless;

    uint256 public taxBuyRate = (DENOMENATOR_PERCENT * 5) / 100;
    uint256 public taxSellRate = (DENOMENATOR_PERCENT * 20) / 100;

    uint256 public maxTx = (DENOMENATOR_PERCENT * 1) / 100;
    uint256 public maxWallet = (DENOMENATOR_PERCENT * 1) / 100;
    bool public enableLimits = true;

    bool private _taxesOff;

    uint256 private _liquifyRate = (DENOMENATOR_PERCENT * 5) / 1000;
    uint256 public launchTime;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private _swapEnabled = true;
    bool private _swapping = false;
    bool    public  tradingEnabled;

    modifier swapLock() {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor() ERC20('Dejitaru Kaida', 'Tkaida')  {
        _mint(owner(), 1_000_000_000 * 10 ** 18);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        _devWallet = owner();
        uniswapV2Router = _uniswapV2Router;
        _isTaxExcluded[address(this)] = true;
        _isTaxExcluded[msg.sender] = true;
        _isLimitless[address(this)] = true;
        _isLimitless[msg.sender] = true;
    }

    function openTrading() external payable onlyOwner {
        tradingEnabled = true;
        launchTime = block.timestamp;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        bool _isOwner = sender == owner() || recipient == owner();
        uint256 contractTokenBalance = balanceOf(address(this));

        bool _isBuy = sender == uniswapV2Pair && recipient != address(uniswapV2Router);
        bool _isSell = recipient == uniswapV2Pair;
        bool _isSwap = _isBuy || _isSell;

        require(
            tradingEnabled ||
            _isLimitless[recipient] || 
            _isLimitless[sender],
            "Trading is not enabled yet"
        );

        if (_isSwap && enableLimits) {
            bool _skipCheck = _isLimitless[recipient] || _isLimitless[sender];
            uint256 _maxTx = totalSupply() * maxTx / DENOMENATOR_PERCENT;
            require(_maxTx >= amount || _skipCheck, "Tx amount exceed limit");
            if (_isBuy) {
                uint256 _maxWallet = totalSupply() * maxWallet / DENOMENATOR_PERCENT;
                require(_maxWallet >= balanceOf(recipient) + amount || _skipCheck, "Total amount exceed wallet limit");
            }
        }
        
        uint256 _minSwap = (balanceOf(uniswapV2Pair) * _liquifyRate) / DENOMENATOR_PERCENT;
        bool _overMin = contractTokenBalance >= _minSwap;

        if (_swapEnabled && !_swapping && !_isOwner && _overMin && launchTime != 0 && sender != uniswapV2Pair) {
            _swap(_minSwap);
        }

        uint256 tax = 0;
        if (launchTime != 0 && _isSwap && !_taxesOff && !(_isTaxExcluded[sender] || _isTaxExcluded[recipient])) {
            uint256 transferFeeRate = recipient == uniswapV2Pair ? taxSellRate : taxBuyRate;
            tax = (amount * transferFeeRate) / DENOMENATOR_PERCENT;
            if (tax > 0) {
                super._transfer(sender, address(this), tax);
            }
        }
        super._transfer(sender, recipient, amount - tax);
    }

    function _swap(uint256 _amountToSwap) private swapLock {
        uint256 balBefore = address(this).balance;
        uint256 tokensToSwap = _amountToSwap;

        _swapTokensForEth(tokensToSwap);

        uint256 balToProcess = address(this).balance - balBefore;
        if (balToProcess > 0) {
            _processFees(balToProcess);
        }
    }

    function _swapTokensForEth(uint256 tokensToSwap) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokensToSwap);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    receive() external payable {}

    function _processFees(uint256 amountETH) private {
        payable(_devWallet).transfer(address(this).balance);
    }

    function setMaxWallet(uint256 _maxWallet) external onlyOwner {
        require(_maxWallet >= 10, 'max wallet cannot be below 0.1%');
        maxWallet = _maxWallet;
    }

    function setMaxTx(uint256 _maxTx) external onlyOwner {
        require(_maxTx >= 10, 'max tx cannot be below 0.1%');
        maxTx = _maxTx;
    }

    function setTax(uint256 _buy, uint256 _sell) external onlyOwner {
        taxBuyRate = _buy;
        taxSellRate = _sell;
    }

    function setEnableLimits(bool _enable) external onlyOwner {
        enableLimits = _enable;
    }

    function setLiquifyRate(uint256 _rate) external onlyOwner {
        require(_rate <= DENOMENATOR_PERCENT / 10, 'cannot be more than 10%');
        _liquifyRate = _rate;
    }

    function setIsLimitless(address _wallet, bool _isLimitLess) external onlyOwner {
        _isLimitless[_wallet] = _isLimitLess;
    }

    function setIsTaxExcluded(address _wallet, bool _isExcluded) external onlyOwner {
        _isTaxExcluded[_wallet] = _isExcluded;
    }

    function setTaxesOff(bool _areOff) external onlyOwner {
        _taxesOff = _areOff;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        _swapEnabled = _enabled;
    }

    function forceSwap() external onlyOwner nonReentrant{
        _swapTokensForEth(balanceOf(address(this)));
        (bool success,) = address(_devWallet).call{value : address(this).balance}("");
    }

    function forceSend() external onlyOwner nonReentrant{
        (bool success,) = address(_devWallet).call{value : address(this).balance}("");
    }
}