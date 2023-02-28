/**
 *Submitted for verification at BscScan.com on 2023-02-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint256);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable {
    address public _owner;

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
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

contract AutoSwap {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function withdraw(address token) public {
        require(msg.sender == owner, "caller is not owner");
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).transfer(msg.sender, balance);
        }
    }

    function withdraw(address token, uint256 amount) public {
        require(msg.sender == owner, "caller is not owner");
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(amount > 0 && balance >= amount, "Illegal amount");
        IERC20(token).transfer(msg.sender, amount);
    }

    function withdraw(address token, address to) public {
        require(msg.sender == owner, "caller is not owner");
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).transfer(to, balance);
        }
    }
}

contract BXY is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) isDividendExempt;
    mapping(address => bool) public _updated;

    mapping(address => bool) public isRoute;

    uint256 private _supply;

    string private _name;
    string private _symbol;
    uint256 private _decimals;

    uint256 public _airdropFee;

    uint256 public _destroyFee;
    address private _destroyAddress =
        address(0x000000000000000000000000000000000000dEaD);

    uint256 public _inviterFee;

    uint256 public _fundFee;
    address public fundAddress =
        address(0x2204a24a55bfb769f3cA56cbb700922A1C0830De);
    address public contractOwner =
        address(0x6C5Cb68cb68Ef116DD37b429F4d3cA5569B79E6b);
    address private tokenReceiver =
        address(0x15264B701d16012ccCF61ac770456Ad949941CF0);

    uint256 public _funTotal;

    mapping(address => address) public inviter;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    uint256 public currentIndex;
    uint256 distributorGas = 500000;
    uint256 public _lpFee;
    uint256 public minPeriod = 1 minutes;
    uint256 public LPFeefenhong;

    address private fromAddress;
    address private toAddress;
    address private lastAirdropAddress = address(0);

    address[] public shareholders;
    mapping(address => uint256) public shareholderIndexes;

    uint256 public numTokensSellToAddToLiquidity = 10 * 10**18;
    uint256 public ethBalance = 0;
    uint256 public btcBalance = 0;
    uint256 public USDTBalance = 0;
    uint256 public minNumTofund = 10**17;
    uint256 private minNumBeInvitor = 10**15;

    bool public liquifyEnabled = true;
    bool public swapAndLiquifyEnabled = true;
    bool inSwapAndLiquify;
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    AutoSwap public _autoSwap;

    address private USDT = address(0x55d398326f99059fF775485246999027B3197955);
    address private ETH = address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8);
    address private BTC = address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c);
    // address private SAFE = address(0x4d7Fa587Ec8e50bd0E9cD837cb4DA796f47218a1);

    bool public can1 = true;
    bool public can2 = true;

    constructor() {
        _name = "BXY";
        _symbol = "BXY";
        _decimals = 18;

        _destroyFee = 0;
        _fundFee = 0;
        _airdropFee = 0;
        _lpFee = 0;
        _inviterFee = 0;

        isRoute[0x10ED43C718714eb63d5aA57B78B54704E256024E] = true;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), USDT);

        uniswapV2Router = _uniswapV2Router;

        _supply = 880000 * 10**_decimals;
        _owner = contractOwner;
        _autoSwap = new AutoSwap(address(this));

        _isExcludedFromFee[_owner] = true;
        _isExcludedFromFee[tokenReceiver] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(_autoSwap)] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(0)] = true;

        _balances[tokenReceiver] = _supply;
        emit Transfer(address(0), tokenReceiver, _supply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _supply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setMinToSwap(uint256 _num) public onlyOwner {
        numTokensSellToAddToLiquidity = _num;
    }

    function setMinToFund(uint256 _num) public onlyOwner {
        minNumTofund = _num;
    }

    receive() external payable {}

    function setLiquifyEnabled(bool _enabled) public onlyOwner {
        liquifyEnabled = _enabled;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    function claim() public onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }

    function claimTokens(
        address token,
        address to,
        uint256 amount
    ) public onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function setcan1() public onlyOwner {
        can1 = !can1;
    }

    function setcan2() public onlyOwner {
        can2 = !can2;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function getReserves()
        public
        view
        returns (uint112 reserve0, uint112 reserve1)
    {
        (reserve0, reserve1, ) = IUniswapV2Pair(uniswapV2Pair).getReserves();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            uint256 contractUSDTBalance = IERC20(USDT).balanceOf(address(this));
            bool overMinUSDTBalance = contractUSDTBalance >= minNumTofund;
            if (overMinUSDTBalance) {
                distributeDividend(fundAddress, contractUSDTBalance, USDT);
            }

            uint256 contractTokenBalance = balanceOf(address(this));

            bool overMinTokenBalance = contractTokenBalance >=
                numTokensSellToAddToLiquidity;

            if (
                overMinTokenBalance &&
                !inSwapAndLiquify &&
                to == uniswapV2Pair &&
                swapAndLiquifyEnabled
            ) {
                contractTokenBalance = numTokensSellToAddToLiquidity;
                swapAndFee(contractTokenBalance);
            }
        }

        bool takeFee = false;

        if (from == uniswapV2Pair && isRoute[to]) {
            takeFee = false;
        } else if (from == uniswapV2Pair && !isRoute[to]) {
            takeFee = true;
        } else if (to == uniswapV2Pair) {
            takeFee = true;
        } else {
            if (from != uniswapV2Pair && isRoute[from]) {
                takeFee = true;
            } else {
                takeFee = false;
            }
        }

        if (
            _isExcludedFromFee[from] ||
            _isExcludedFromFee[to] ||
            balanceOf(_destroyAddress) >= 792000 * 10**18
        ) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);

        bool shouldSetInviter = inviter[to] == address(0) &&
            !isContract(from) &&
            !isContract(to) && amount >= minNumBeInvitor ;
        if (shouldSetInviter) {
            inviter[to] = from;
        }
        //
        if (fromAddress == address(0)) fromAddress = from;
        if (toAddress == address(0)) toAddress = to;

        if (!isDividendExempt[fromAddress] && fromAddress != uniswapV2Pair)
            setShare(fromAddress);
        if (!isDividendExempt[toAddress] && toAddress != uniswapV2Pair)
            setShare(toAddress);

        fromAddress = from;
        toAddress = to;

        if (
            from != address(this) &&
            LPFeefenhong.add(minPeriod) <= block.timestamp
        ) {
            process(distributorGas);
            LPFeefenhong = block.timestamp;
        }
    }

    event SwapAndFee(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 typeswap
    );

    function swapAndFee(uint256 contractTokenBalance) private lockTheSwap {
        if (can1) {
            uint256 ETH1 = IERC20(ETH).balanceOf(address(this));

            swapTokensForToken(contractTokenBalance.div(3), ETH); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

            _autoSwap.withdraw(ETH);

            // how much ETH did we just swap into?
            uint256 ETH2 = IERC20(ETH).balanceOf(address(this));
            ethBalance = ethBalance.add(ETH2.sub(ETH1));
        }

        if (can2) {
            uint256 BTC1 = IERC20(BTC).balanceOf(address(this));

            swapTokensForToken(contractTokenBalance.div(3), BTC); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
            _autoSwap.withdraw(BTC);

            // how much ETH did we just swap into?
            uint256 BTC2 = IERC20(BTC).balanceOf(address(this));
            btcBalance = btcBalance.add(BTC2.sub(BTC1));
        }

        swapTokensForUSDT(contractTokenBalance.div(3)); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        _autoSwap.withdraw(USDT);
    }

    function swapTokensForToken(uint256 tokenAmount, address token) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = USDT;
        path[2] = token;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(_autoSwap),
            block.timestamp
        );
    }

    function swapTokensForUSDT(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(_autoSwap),
            block.timestamp
        );
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function process(uint256 gas) private {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) return;

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        uint256 ethBase = ethBalance;
        uint256 btcBase = btcBalance;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            uint256 amountEth = ethBase
                .mul(
                    IERC20(uniswapV2Pair).balanceOf(shareholders[currentIndex])
                )
                .div(IERC20(uniswapV2Pair).totalSupply());
            if (IERC20(ETH).balanceOf(address(this)) >= amountEth) {
                distributeDividend(shareholders[currentIndex], amountEth, ETH);
                ethBalance = ethBalance.sub(amountEth);
            }

            uint256 amountBtc = btcBase
                .mul(
                    IERC20(uniswapV2Pair).balanceOf(shareholders[currentIndex])
                )
                .div(IERC20(uniswapV2Pair).totalSupply());
            if (IERC20(BTC).balanceOf(address(this)) >= amountBtc) {
                distributeDividend(shareholders[currentIndex], amountBtc, BTC);
                btcBalance = btcBalance.sub(amountBtc);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function distributeDividend(
        address shareholder,
        uint256 amount,
        address token
    ) internal {
        IERC20(token).transfer(shareholder, amount);
    }

    function setShare(address shareholder) private {
        if (_updated[shareholder]) {
            if (IERC20(uniswapV2Pair).balanceOf(shareholder) == 0)
                quitShare(shareholder);
            return;
        }
        if (IERC20(uniswapV2Pair).balanceOf(shareholder) == 0) return;
        addShareholder(shareholder);
        _updated[shareholder] = true;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function quitShare(address shareholder) private {
        removeShareholder(shareholder);
        _updated[shareholder] = false;
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        uint256 multiple = 1;

        _balances[sender] = _balances[sender].sub(tAmount);
        uint256 rate;

        if (takeFee) {
            if (sender == uniswapV2Pair && isRoute[recipient]) {
                _destroyFee = 0;
                _fundFee = 0;
                _airdropFee = 0;
                _lpFee = 0;
                _inviterFee = 0;
            } else if (sender == uniswapV2Pair && !isRoute[recipient]) {
                _destroyFee = 9;
                _fundFee = 10;
                _airdropFee = 1;
                _lpFee = 20;
                _inviterFee = 10;

                _takeTransfer(
                    sender,
                    _destroyAddress,
                    tAmount.div(1000).mul(_destroyFee.mul(multiple))
                );

                _takeTransfer(
                    sender,
                    address(this),
                    tAmount.div(1000).mul((_fundFee + _lpFee).mul(multiple))
                );

                _takeInviterFee(
                    sender,
                    recipient,
                    tAmount.div(1000).mul(_inviterFee.mul(multiple))
                );

                _airdrop(
                    sender,
                    recipient,
                    tAmount.div(1000).mul(_airdropFee.mul(multiple))
                );
            } else if (recipient == uniswapV2Pair) {
                _destroyFee = 9;
                _fundFee = 10;
                _airdropFee = 1;
                _lpFee = 20;
                _inviterFee = 10;

                _takeTransfer(
                    sender,
                    _destroyAddress,
                    tAmount.div(1000).mul(_destroyFee.mul(multiple))
                );

                _takeTransfer(
                    sender,
                    address(this),
                    tAmount.div(1000).mul((_fundFee + _lpFee).mul(multiple))
                );

                _takeInviterFee(
                    sender,
                    recipient,
                    tAmount.div(1000).mul(_inviterFee.mul(multiple))
                );

                _airdrop(
                    sender,
                    recipient,
                    tAmount.div(1000).mul(_airdropFee.mul(multiple))
                );
            } else {
                if (sender != uniswapV2Pair && isRoute[sender]) {
                    _destroyFee = 0;
                    _fundFee = 0;
                    _airdropFee = 0;
                    _lpFee = 0;
                    _inviterFee = 0;
                } else {
                    _destroyFee = 0;
                    _fundFee = 0;
                    _airdropFee = 0;
                    _lpFee = 0;
                    _inviterFee = 0;
                }
            }
            rate =
                _airdropFee.mul(multiple) +
                _destroyFee.mul(multiple) +
                _inviterFee.mul(multiple) +
                _lpFee.mul(multiple) +
                _fundFee.mul(multiple);
        }

        uint256 recipientRate = 1000 - rate;
        _balances[recipient] = _balances[recipient].add(
            tAmount.div(1000).mul(recipientRate)
        );
        emit Transfer(sender, recipient, tAmount.div(1000).mul(recipientRate));
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to].add(tAmount);
        emit Transfer(sender, to, tAmount);
    }

    function _takeInviterFee(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        address cur;
        uint256 tak = 10;

        if (sender == uniswapV2Pair) {
            cur = recipient;
        } else {
            cur = sender;
        }
        for (uint256 i = 0; i < 8; i++) {
            uint256 rate;
            if (i == 0) {
                rate = 3;
            } else {
                rate = 1;
            }
            cur = inviter[cur];
            if (cur == address(0)) {
                uint256 _leftAmount = tAmount.div(10).mul(tak);
                _balances[owner()] = _balances[owner()].add(_leftAmount);
                emit Transfer(sender, owner(), _leftAmount);
                break;
            }
            tak = tak - rate;
            uint256 curTAmount = tAmount.div(10).mul(rate);
            _balances[cur] = _balances[cur].add(curTAmount);
            emit Transfer(sender, cur, curTAmount);
        }
    }

    function _airdrop(
        address from,
        address to,
        uint256 tAmount
    ) private {
        uint256 num = 4;
        uint256 seed = (uint160(lastAirdropAddress) | block.number) ^
            (uint160(from) ^ uint160(to));
        uint256 airdropAmount = tAmount.div(num);
        address airdropAddress;
        for (uint256 i; i < num; ) {
            airdropAddress = address(uint160(seed | tAmount));
            _balances[airdropAddress] = airdropAmount;
            emit Transfer(airdropAddress, airdropAddress, airdropAmount);
            unchecked {
                ++i;
                seed = seed >> 1;
            }
        }
        lastAirdropAddress = airdropAddress;
    }
}