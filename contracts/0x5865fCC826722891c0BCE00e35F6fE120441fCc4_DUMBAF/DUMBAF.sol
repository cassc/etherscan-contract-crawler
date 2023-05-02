/**
 *Submitted for verification at Etherscan.io on 2023-05-01
*/

/**
 * SPDX-License-Identifier: MIT
 */ 

// $DUMBAF...This has a lot of meanings. But to keep it short, these past pumps are DUMBAF
// We have seen PEPE go from 5k to 300 million and this is just DUMBAF
// For everyone that missed PEPE this is for you, buy it because you were DUMBAF for not buying PEPE
// TO EVERYONE THAT IS DUMAF THIS FOR YOU....ONE LAST BANG
// LP WILL BE BURNT. CONTRACT WILL BE RENOUNCED. NO UTILITY. 
// Fortune favours the FOMO
// TG: https://t.me/DUMBAFTOKEN


pragma solidity ^0.8.6;



library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }


    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

 
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {this; return msg.data;}
}

library Address {
    function isContract(address account) internal view returns (bool) { 
        uint256 size; assembly { size := extcodesize(account) } return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");(bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
        
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
        
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
        
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) { return returndata; } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {revert(errorMessage);}
        }
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

interface IPancakeV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeV2Router {
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

contract DUMBAF is IERC20Metadata, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    address internal deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    address public marketingWallet = 0x361550d68B24731d9586f97113577407Eb7578D6;
    
    string constant _name = "DUMBAF";
    string constant _symbol = "DUMBAF";
    uint8 constant _decimals = 18;
    
    uint256 internal constant _totalSupply = 10_000_000 * (10**18);
  
    uint256 public maxTxAmount = _totalSupply / 1000; // 0.1% of the total supply
    uint256 public maxWalletBalance = _totalSupply / 50; // 2% of the total supply
    
    bool public takeFeeEnabled = true;
    bool public tradingIsEnabled = true;
    
    bool private swapping;
    bool public swapEnabled = true;
    uint256 public swapTokensAtAmount = 100_000 * (10**18);

    uint256 private constant FEES_DIVISOR = 10**3;
    
    uint256 public marketingFee = 10; // 1%
    uint256 public lpFee = 5; // 0.5%
    uint256 private totalFee;
    
    // Total = 100% (1000)
    uint256 public marketingPortionOfSwap = 800; // 80%
    uint256 public lpPortionOfSwap = 200; // 20%
    
    IPancakeV2Router public router;
    address public pair;
    
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    mapping(address => bool) public _isBlacklisted;
    mapping (address => bool) internal _isExcludedFromFee;
    
    event UpdatePancakeswapRouter(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    
    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    
    event LiquidityAdded(uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity);
    
    event SwapTokensForETH(uint256 amountIn, address[] path);

    modifier zeroAddressCheck(address _theAddress) {
        require(_theAddress != address(0), "Address cannot be the zero address");
        _;
    }
    
    constructor () {
        _balances[msg.sender] = _totalSupply;
        
        IPancakeV2Router _newPancakeRouter = IPancakeV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IPancakeV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        router = _newPancakeRouter;

        // set fees
        totalFee = marketingFee.add(lpFee);
        
        // exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        _approve(owner(), address(router), ~uint256(0));
        
        emit Transfer(address(0), owner(), _totalSupply);
    }
    
    receive() external payable { }
    
    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) { 
        return _balances[account]; 
    }
    
        
    function transfer(address recipient, uint256 amount) external override returns (bool){
        _transfer(_msgSender(), recipient, amount);
        return true;
        }
        
    function allowance(address owner, address spender) external view override returns (uint256){
        return _allowances[owner][spender];
        }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
        }
        
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool){
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
        }
        
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BaseRfiToken: approve from the zero address");
        require(spender != address(0), "BaseRfiToken: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function setExcludedFromFee(address account, bool value) external onlyOwner { 
        _isExcludedFromFee[account] = value; 
    }

    
    function isExcludedFromFee(address account) public view returns(bool) { 
        return _isExcludedFromFee[account]; 
    }
    

    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled  = _enabled;
    }
    
    function updateSwapTokensAt(uint256 _swaptokens) external onlyOwner {
        swapTokensAtAmount = _swaptokens * (10**18);
    }
    
    function updateWalletMax(uint256 _walletMax) external onlyOwner {
        maxWalletBalance = _walletMax * (10**18);
    }
    
    function updateTransactionMax(uint256 _txMax) external onlyOwner {
        maxTxAmount = _txMax * (10**18);
    }

    function updateFees( uint256 _marketing, uint256 _lp) external onlyOwner {
       totalFee = _marketing.add(_lp); 
       require(totalFee <= 100, "Total Fees cannot be greater than 10% (100)");

       marketingFee = _marketing;
       lpFee = _lp;
    }

   
    function updateMarketingWallet(address newWallet) external onlyOwner zeroAddressCheck(newWallet) {
        require(newWallet != marketingWallet, "The Marketing wallet is already this address");
        emit MarketingWalletUpdated(newWallet, marketingWallet);
        
        marketingWallet = newWallet;
    }
    
    
    function updatePortionsOfSwap(uint256 marketingPortion, uint256 lpPortion) 
    external onlyOwner {
        
        uint256 totalPortion = marketingPortion.add(lpPortion);
        require(totalPortion == 1000, "Total must be equal to 1000 (100%)");
        
        marketingPortionOfSwap = marketingPortion;
        lpPortionOfSwap = lpPortion;
    }
    
    function updateTradingIsEnabled(bool tradingStatus) external onlyOwner() {
        tradingIsEnabled = tradingStatus;
    }

    function updateTakeFeeEnabled(bool _value) external onlyOwner {
        takeFeeEnabled = _value;
    }
    
    function updateRouterAddress(address newAddress) external onlyOwner {
        require(newAddress != address(router), "The router already has that address");
        emit UpdatePancakeswapRouter(newAddress, address(router));
        
        router = IPancakeV2Router(newAddress);   
    }

    
    function takeFee(address sender, uint256 amount) internal returns (uint256)  {
        uint256 feeAmount = amount.mul(totalFee).div(FEES_DIVISOR);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }
        
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Token: transfer from the zero address");
        require(recipient != address(0), "Token: transfer to the zero address");
        require(sender != address(deadAddress), "Token: transfer from the burn address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        require(tradingIsEnabled, "This account cannot send tokens until trading is enabled");

        require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], "Blacklisted address");
        
        if (
            sender != address(router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFee[recipient] && //no max for those excluded from fees
            !_isExcludedFromFee[sender] 
        ) {
            require(amount <= maxTxAmount, "Transfer amount exceeds the Max Transaction Amount.");
            
        }
        
        if ( maxWalletBalance > 0 && !_isExcludedFromFee[recipient] && !_isExcludedFromFee[sender] && recipient != address(pair) ) {
                uint256 recipientBalance = balanceOf(recipient);
                require(recipientBalance + amount <= maxWalletBalance, "New balance would exceed the maxWalletBalance");
            }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            
         // indicates whether or not fee should be deducted from the transfer
        bool _isTakeFee = takeFeeEnabled;
        
         // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) { 
            _isTakeFee = false; 
        }

        // transfer between wallets
        if(sender != pair && recipient != pair) {
           _isTakeFee = false;
        }
        
        _beforeTokenTransfer(recipient);
        
         uint256 amountReceived = _isTakeFee ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        
    }
    
    function _beforeTokenTransfer(address recipient) private {
            
        uint256 contractTokenBalance = balanceOf(address(this));
         // swap
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            
        if (!swapping && canSwap && swapEnabled && recipient == pair) {
            swapping = true;
                
            swapBack();
                
            swapping = false;
        }        
    }
    
    function swapBack() private {
        uint256 splitLiquidityPortion = lpPortionOfSwap.div(2);
        uint256 amountToLiquify = balanceOf(address(this)).mul(splitLiquidityPortion).div(FEES_DIVISOR);
        uint256 amountToSwap = balanceOf(address(this)).sub(amountToLiquify);

        uint256 balanceBefore = address(this).balance;
        
        swapTokensForETH(amountToSwap);

        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        
        uint256 amountBNBMarketing = amountBNB.mul(marketingPortionOfSwap).div(FEES_DIVISOR);
        uint256 amountBNBLiquidity = amountBNB.mul(splitLiquidityPortion).div(FEES_DIVISOR);
        
          //Send to addresses
        transferToAddress(payable(marketingWallet), amountBNBMarketing);
        
        // add liquidity
        _addLiquidity(amountToLiquify, amountBNBLiquidity);
    }
    
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        (uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity) = router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );

        emit LiquidityAdded(tokenAmountSent, ethAmountSent, liquidity);
    }
    
    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }
    
    function transferToAddress(address payable recipient, uint256 amount) private {
        require(recipient != address(0), "Cannot transfer the ETH to a zero address");
        recipient.transfer(amount);
    }
    
    function TransferETH(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Cannot withdraw the ETH balance to a zero address");
        recipient.transfer(amount);
    }
    
}