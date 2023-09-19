/**
 *Submitted for verification at Etherscan.io on 2023-09-10
*/

/*
                                                                                                                               
Telegram Portal : https://t.me/binancepepe_eth1
Twitter : https://twitter.com/Binancepepe_eth
Website : https://binance-pepe.vip/

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
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

}

abstract contract Ownable is Context {

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
    
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renouncedOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
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
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router01 {
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

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Token is Context, IERC20, Ownable {
    
    using SafeMath for uint256;
    
    string private _name = "Binance Pepe";
    string private _symbol = "bPEPE";
    uint8 private _decimals = 8;

    address marketingWallet = 0x50be03F01c62c49a95016A1911127065C22b9852;

    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public constant zeroAddress = 0x0000000000000000000000000000000000000000;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isMarketPair;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isTxLimitExempt;

    uint256 totalBuy = 20;
    uint256 totalSell = 35;

    uint256 constant denominator = 100;

    uint256 private _totalSupply = 10_000_000 * 10 ** _decimals;   

    uint256 public minimumTokensBeforeSwap = 2000 * 10 ** _decimals;

    uint256 public _maxTxAmount =  _totalSupply.mul(2).div(denominator);     //2%
    uint256 public _walletMax = _totalSupply.mul(2).div(denominator);    //2%

    bool public EnableTxLimit = true;
    bool public checkWalletLimit = true;
    bool public ActiveTrade = false;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {

        address dev = msg.sender;            
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 

        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = ~uint256(0);

        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[dev] = true;

        isWalletLimitExempt[dev] = true;
        isWalletLimitExempt[address(uniswapPair)] = true;
        isWalletLimitExempt[address(this)] = true;
        
        isTxLimitExempt[dev] = true;
        isTxLimitExempt[address(this)] = true;

        isMarketPair[address(uniswapPair)] = true;

        _balances[dev] = _totalSupply;
        emit Transfer(address(0), dev, _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
       return _balances[account];     
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress)).sub(balanceOf(zeroAddress));
    }

     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0), "ERC20:from zero");
        require(recipient != address(0), "ERC20:to zero");
        require(amount > 0, "Invalid Amount");

        if(!ActiveTrade){
            require(isExcludedFromFee[sender] || isExcludedFromFee[recipient],"Trading is Paused!");
        }

        if(inSwapAndLiquify)
        { 
            return _basicTransfer(sender, recipient, amount); 
        }
        else
        {  
            if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient] && EnableTxLimit) {
                require(amount <= _maxTxAmount,"Max Tx");
            } 

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
            
            if (overMinimumTokenBalance && !inSwapAndLiquify && !isMarketPair[sender] && swapAndLiquifyEnabled) 
            {
                swapAndLiquify(contractTokenBalance);
            }

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            uint256 finalAmount = shouldTakeFee(sender,recipient) ? amount : takeFee(sender, recipient, amount);

            if(checkWalletLimit && !isWalletLimitExempt[recipient]) {
                require(balanceOf(recipient).add(finalAmount) <= _walletMax,"Max Wallet");
            }

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 contractBalance) private lockTheSwap {
        
        if(contractBalance == 0) return;

        uint totalShares = totalBuy.add(totalSell);
        if(totalShares == 0) return;

        uint256 initialBalance = address(this).balance;
        swapTokensForEth(contractBalance);
        uint256 amountReceived = address(this).balance.sub(initialBalance);

        if(amountReceived > 0) {
            (bool os,) = payable(marketingWallet).call{value: amountReceived}("");  
            if(os) {}
        }
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        if(isExcludedFromFee[sender] || isExcludedFromFee[recipient]) {
            return true;
        }
        else if (isMarketPair[sender] || isMarketPair[recipient]) {
            return false;
        }
        else {
            return false;
        }
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint feeAmount;
        
        unchecked {

            if(isMarketPair[sender]) {

                feeAmount = amount.mul(totalBuy).div(denominator);
            
            }
            else if(isMarketPair[recipient]) {
                
                feeAmount = amount.mul(totalSell).div(denominator);
                
            }     

            if(feeAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(feeAmount);
                emit Transfer(sender, address(this), feeAmount);
            }

            return amount.sub(feeAmount);
        }
        
    }

    //To Rescue Stucked Balance
    function rescueFunds() external onlyOwner { 
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        require(os,"Transaction Failed!!");
    }

    //To Rescue Stucked Tokens
    function rescueTokens(IERC20 adr,address recipient,uint amount) external onlyOwner {
        adr.transfer(recipient,amount);
    }

    function enableTrading(bool _status) external onlyOwner {
        ActiveTrade = _status;
    }

    function removeLimits() external onlyOwner {
        checkWalletLimit = false;
        EnableTxLimit = false;
    }

    function enableLimits() external onlyOwner {
        checkWalletLimit = true;
        EnableTxLimit = true;   
    }

    function setFee(uint _buyside, uint _sellside) external onlyOwner {        
        totalBuy = _buyside;
        totalSell = _sellside;
    }

    function setMarketingWallets(address _newWallet) external onlyOwner {
        marketingWallet = _newWallet;
    }

    function setExcludeFromFee(address _adr,bool _status) external onlyOwner {
        require(isExcludedFromFee[_adr] != _status,"Not Changed!!");
        isExcludedFromFee[_adr] = _status;
    }

    function ExcludeWalletLimit(address _adr,bool _status) external onlyOwner {
        require(isWalletLimitExempt[_adr] != _status,"Not Changed!!");
        isWalletLimitExempt[_adr] = _status;
    }

    function ExcludeTxLimit(address _adr,bool _status) external onlyOwner {
        require(isTxLimitExempt[_adr] != _status,"Not Changed!!");
        isTxLimitExempt[_adr] = _status;
    }

    function setNumTokensBeforeSwap(uint256 newLimit) external onlyOwner() {
        minimumTokensBeforeSwap = newLimit;
    }

    function setMaxWalletLimit(uint256 newLimit) external onlyOwner() {
        _walletMax = newLimit;
    }

    function setTxLimit(uint256 newLimit) external onlyOwner() {
        _maxTxAmount = newLimit;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner() {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setMarketPair(address _pair, bool _status) external onlyOwner {
        isMarketPair[_pair] = _status;
        if(_status) {
            isWalletLimitExempt[address(_pair)] = true;
        }
    }

}