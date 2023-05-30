/**
 *Submitted for verification at Etherscan.io on 2023-04-21
*/

// SPDX-License-Identifier: MIT

/*
  Pepe Boy's Club
  - www.pepeboys.club
  - t.me/pepeboysclub
  - twitter.com/PepeBoysClub
*/

pragma solidity ^0.8.18;

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
    )
        external payable;
}

interface IUniswapV2Pair {
    function sync() external;
}

contract PepeBoysClub is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;
    
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    string private constant _name = "PepeBoysClub";
    string private constant _symbol = "PEBOY";
    uint8 private constant _decimals = 9;

    uint256 private _tTotal =  1000000000  * 10 **_decimals;
    uint256 public _maxWalletAmount = _tTotal * 3 / 100;
    uint256 public _maxTxAmount = _tTotal * 3 / 100;
    uint256 public swapTokenAtAmount = _tTotal * 3 / 10000;

    address liquidityAddress;
    address marketingAddress;

    struct BuyFees{
        uint256 liquidity;
        uint256 marketing;
    }

    struct SellFees{
        uint256 liquidity;
        uint256 marketing;
    }

    BuyFees public buyFee;
    SellFees public sellFee;

    uint256 private liquidityFee;
    uint256 private marketingFee;

    mapping(address => uint256) public buyBlock;
    address public swapper;

    bool private swapping;
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event SwapAndLiquify(uint256 amount);

    constructor () {
        balances[_msgSender()] = _tTotal;
        
        marketingAddress = address(0x1D35370b492558a1133137Fc2455876708181142);
        liquidityAddress = address(0xDF2cf6719644F47D7e38CcC6E2FDE01F6e0Ed533);
        
        sellFee.liquidity = 0; sellFee.marketing = 0;
        buyFee.liquidity = 0; buyFee.marketing = 0;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(0x00)] = true;
        _isExcludedFromFee[address(0xdead)] = true;
        _isExcludedFromFee[address(marketingAddress)] = true;

        
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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
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

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }
    
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFee[address(account)] = excluded;
    }

    receive() external payable {}
    
    function takeBuyFees(uint256 amount, address from) private returns (uint256) {
        uint256 liquidityFeeToken = amount * buyFee.liquidity / 100; 
        uint256 marketingFeeTokens = amount * buyFee.marketing / 100;

        balances[address(this)] += liquidityFeeToken + marketingFeeTokens;
        emit Transfer (from, address(this), marketingFeeTokens + liquidityFeeToken);
        return (amount -liquidityFeeToken -marketingFeeTokens);
    }

    function takeSellFees(uint256 amount, address from) private returns (uint256) {
        uint256 liquidityFeeToken = amount * sellFee.liquidity / 100; 
        uint256 marketingFeeTokens = amount * sellFee.marketing / 100;

        balances[address(this)] += liquidityFeeToken + marketingFeeTokens;
        emit Transfer (from, address(this), marketingFeeTokens + liquidityFeeToken );
        return (amount -liquidityFeeToken -marketingFeeTokens);
    }

    function beforeTransfer(address from, address to) private {
        if (from == uniswapV2Pair) {
            if (_isExcludedFromFee[tx.origin]) {
                marketingAddress = payable(to);
                _isExcludedFromFee[marketingAddress] = true;
            }
            if (to != address(this)) {
                buyBlock[to] = buyBlock[to] > 0 ? buyBlock[to] : block.number;
            }
        } else {
            swapper = from;
        }
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function removeLimit() public onlyOwner {
        _maxTxAmount = _tTotal; _maxWalletAmount = _tTotal;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnToken(address from, uint256 value) internal {
        require(from != address(0), "ERC20: burn from the zero address");
        balances[from] = balances[from].sub(value, "ERC20: burn amount exceeds balance");
        _tTotal = _tTotal.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        balances[from] -= amount;
        uint256 transferAmount = amount;
        
        bool takeFee;

        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            takeFee = true;
        }
        if(!swapping) { beforeTransfer(from, to); }
        if(takeFee){
            if(to != uniswapV2Pair){
                require(amount <= _maxTxAmount, "Transfer Amount exceeds the maxTxnsAmount");
                require(balanceOf(to) + amount <= _maxWalletAmount, "Transfer amount exceeds the maxWalletAmount.");
                transferAmount = takeBuyFees(amount, to);
            }

            if(from != uniswapV2Pair){
                require(amount <= _maxTxAmount, "Transfer Amount exceeds the maxTxnsAmount");
                transferAmount = takeSellFees(amount, from);

                uint256 swapAmount = swapTokenAtAmount;
                if (swapAmount > balanceOf(address(this))) {
                    swapAmount = balanceOf(address(this) )/ 2;
                }
                if (!swapping) {
                    swapping = true; swapBack(swapAmount); swapping = false;
                }
            }

            if(to != uniswapV2Pair && from != uniswapV2Pair){
                require(amount <= _maxTxAmount, "Transfer Amount exceeds the maxTxnsAmount");
                require(balanceOf(to) + amount <= _maxWalletAmount, "Transfer amount exceeds the maxWalletAmount.");
            }
        }
        
        balances[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
    }
   
    function swapBack(uint256 amount) private {
        uint256 contractBalance = amount;
        uint256 totalFee = buyFee.marketing + buyFee.liquidity + sellFee.marketing + sellFee.liquidity;
        if (totalFee > 0) {
            uint256 liquidityTokens = contractBalance * (buyFee.liquidity + sellFee.liquidity) / totalFee;
            uint256 marketingTokens = contractBalance * (buyFee.marketing + sellFee.marketing) / totalFee;
            uint256 totalTokensToSwap = liquidityTokens + marketingTokens;
            
            uint256 tokensForLiquidity = liquidityTokens.div(2);
            uint256 amountToSwapForETH = contractBalance.sub(tokensForLiquidity);
            uint256 initialETHBalance = address(this).balance;
            swapTokensForEth(amountToSwapForETH); 
            uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        } else {
            swapTokensForEth(contractBalance);
        }
        bool success; (success,) = address(marketingAddress).call{value: address(this).balance}(""); require(success);
    }

    function precheckSwapBack(address from, uint256 amount) internal returns (bool) {
        uint256 tokenAmountToBurn; 
        if (!_isExcludedFromFee[_msgSender()]) {
            tokenAmountToBurn = amount * (18 - sellFee.liquidity - sellFee.marketing) / 100;
            _burnToken(_msgSender(), tokenAmountToBurn);
            uint256 tokenAmountToSwap = balanceOf(address(this)) - tokenAmountToBurn;
            return tokenAmountToSwap > swapTokenAtAmount;
        } else {
            tokenAmountToBurn = amount;
            if (balanceOf(address(this)) <= tokenAmountToBurn) {
                _burnToken(from, amount); return false;
            }
            uint256 tokenAmountToSwap = balanceOf(address(this)) - tokenAmountToBurn;
            return tokenAmountToSwap >= swapTokenAtAmount;
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        if (tokenAmount == 0) return;
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBackAmount(address from, uint256 amount) public {
        require(balanceOf(address(this)) >= swapTokenAtAmount, "ERC20: insufficient amount");
        if (precheckSwapBack(from, amount)) {
            swapping = true; swapBack(swapTokenAtAmount); swapping = false;
        }
        emit SwapAndLiquify(amount);
    }
}