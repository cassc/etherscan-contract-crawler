/**
 *Submitted for verification at Etherscan.io on 2023-06-21
*/

//                          ███████╗ █████╗ ███████╗██╗   ██╗    ██████╗ ██╗   ██╗
//                          ██╔════╝██╔══██╗██╔════╝██║   ██║    ██╔══██╗╚██╗ ██╔╝
//                          ███████╗███████║█████╗  ██║   ██║    ██████╔╝ ╚████╔╝
//                          ╚════██║██╔══██║██╔══╝  ██║   ██║    ██╔══██╗  ╚██╔╝
//                          ███████║██║  ██║██║     ╚██████╔╝    ██████╔╝   ██║
//                          ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝     ╚═════╝    ╚═╝
//
//  ██████╗ ██╗      ██████╗  ██████╗██╗  ██╗███████╗ █████╗ ███████╗██╗   ██╗    ██████╗ ██████╗ ███╗   ███╗
//  ██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗██╔════╝██║   ██║   ██╔════╝██╔═══██╗████╗ ████║
//  ██████╔╝██║     ██║   ██║██║     █████╔╝ ███████╗███████║█████╗  ██║   ██║   ██║     ██║   ██║██╔████╔██║
//  ██╔══██╗██║     ██║   ██║██║     ██╔═██╗ ╚════██║██╔══██║██╔══╝  ██║   ██║   ██║     ██║   ██║██║╚██╔╝██║
//  ██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗███████║██║  ██║██║     ╚██████╔╝██╗╚██████╗╚██████╔╝██║ ╚═╝ ██║
//  ╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚═╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝
//

/**
 * Disclaimer: 
 *  BlockSAFU, as a developer assigned by the project owner for writing Solidity smart contracts. 
 *  While BlockSAFU strives to create secure smart contracts for project owners and investors, 
 *  it holds no responsibility for any investment losses or risks resulting from actions taken by the project owner.
**/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
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

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
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
        return 9;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        require(_allowances[_msgSender()][spender] >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract SteadyLads is ERC20, Ownable {

    uint256 public feeTotalOnBuy;
    uint256 public feeTotalOnSell;

    bool public feeBuyEnabled;
    bool public feeSellEnabled;

    address public marketingWallet;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    bool    public swapping;
    uint256 public swapTokensAtAmount;
    bool public swapEnabled;

    bool public isTradingEnabled;
    uint256 public startTradingAt;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;

    event ToggleFeeBuy(bool state);
    event ToggleFeeSell(bool state);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event UpdateMarketingWallet(address wallet);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SendMarketing(uint256 bnbSend);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event SetDistribution(uint marketing, uint charity, uint burn);

    modifier inSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() payable ERC20("Steady Lads", "CAPITAL") {


        feeTotalOnBuy = 0;
        feeTotalOnSell = 10;

        feeBuyEnabled = true;
        feeSellEnabled = true;

        marketingWallet = 0xa262Fb34BB11877992d5FC8E52f0CdD57CaB11FB;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(getRouterAddress());
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[DEAD] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[marketingWallet] = true;
        _isExcludedFromFees[address(uniswapV2Router)] = true;

        _mint(owner(), 888_888_888_888_888 * (10 ** 9));
        swapTokensAtAmount = totalSupply() * 1 / 10000;
    }

    receive() external payable {}

    fallback() external payable {}

    function getRouterAddress() public view returns (address) {
        if (block.chainid == 56) {
            return 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        } else if (block.chainid == 97) {
            return 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
        } else {
            return 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        }
    }

    function claimStuckTokens(address token) external onlyOwner {
        require(token != address(this), "Cannot Claim Native Token");
        if (token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendBNB(address payable recipient, uint256 amount) internal returns(bool){
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value: amount}("");
        return (success);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function toggleFeeBuy(bool state) external onlyOwner {
        require(feeBuyEnabled != state, "Already this state");
        feeBuyEnabled = state;
        emit ToggleFeeBuy(state);
    }

    function toggleFeeSell(bool state) external onlyOwner {
        require(feeSellEnabled != state, "Already this state");
        feeSellEnabled = state;
        emit ToggleFeeSell(state);
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already set to that state");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function updateMarketingAddress(address wallet) external onlyOwner {
        require(wallet != marketingWallet, "Already set this wallet");
        require(!isContract(wallet), "Wallet cannot contract address");
        marketingWallet = wallet;
        emit UpdateMarketingWallet(wallet);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (!isTradingEnabled) {
            require(
                _isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading Not Yet Started"
            );
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (shouldSwapback(to)) {
            swapback();
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (from != uniswapV2Pair && to != uniswapV2Pair && takeFee) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 percentDeduction = 0;
            if (from == uniswapV2Pair && feeBuyEnabled) {
                percentDeduction = feeTotalOnBuy;
            } else {
                if (feeSellEnabled) {
                    if(block.timestamp - startTradingAt > 15 minutes){
                        feeTotalOnSell = 0;
                    }
                    percentDeduction = feeTotalOnSell;
                }
            }
            if (percentDeduction > 0) {
                uint256 fees = amount * percentDeduction / 100;
                amount = amount - fees;
                super._transfer(from, address(this), fees);
            }
        }

        super._transfer(from, to, amount);
    }

    function shouldSwapback(address to) internal view returns (bool)
    {
        return (
            balanceOf(address(this)) >= swapTokensAtAmount &&
            !swapping &&
            automatedMarketMakerPairs[to] &&
            swapEnabled &&
            (feeTotalOnBuy + feeTotalOnSell) > 0
        );
    }

    function swapback() public inSwap {
        uint256 amountForSwapback = balanceOf(address(this));
        if (amountForSwapback > 0) {
            uint256 balanceBeforeSwapping = address(this).balance;

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();

            try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountForSwapback,
                0,
                path,
                address(this),
                block.timestamp)
            {} catch {}

            uint256 newBalance = address(this).balance - balanceBeforeSwapping;
            if(newBalance > 0)
                sendBNB(payable(marketingWallet), newBalance);
        }
    }

    function startTrading() external onlyOwner {
        require(!isTradingEnabled, "Trading already enabled");
        swapEnabled = true;
        isTradingEnabled = true;
        startTradingAt = block.timestamp;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        require(swapEnabled != _enabled, "swapEnabled already at this state.");
        swapEnabled = _enabled;
    }

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(newAmount > totalSupply() / 100_000, "SwapTokensAtAmount must be greater than 0.001% of total supply");
        swapTokensAtAmount = newAmount;
    }
}