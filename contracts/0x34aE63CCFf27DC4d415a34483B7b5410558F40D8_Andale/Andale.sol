/**
 *Submitted for verification at Etherscan.io on 2023-05-10
*/

// SPDX-License-Identifier: MIT

/**

➶➶➶➶➶ ₳₦Đ₳ⱠɆ ₳₦Đ₳ⱠɆ, ₳ⱤⱤł฿₳ ₳ⱤⱤł฿₳! ➶➶➶➶➶

telegram: https://t.me/AndalePepe
twitter: https://twitter.com/PepeAndale
website: https://andalepepe.com


*/


pragma solidity ^0.8.19;

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapRouter {
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

contract Andale is IERC20, Ownable {
    using Address for address;
    
    string constant _name = "Andale";
    string constant _symbol = "ANDALE";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 10 ** 11 * (10 ** _decimals);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    IUniswapRouter public router;
    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    mapping (address => bool) liquidityPools;

    address public pair;
    uint256 public launchedAt;
    uint256 public launchedTime;
    uint256 public deadBlocks;
    uint256 public launchCooldown;

    bool public andale = false;
    bool public enableLimits = true;
    bool public swapEnabled = false;
    uint256 public swapThreshold = _totalSupply / 500;
    uint256 public swapMinimum = _totalSupply / 1000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    

    event SwapAndLiquify(uint256 amountToSwap, uint256 marketingETH);

    constructor () {
        router = IUniswapRouter(routerAddress);
        pair = IUniswapFactory(router.factory()).createPair(router.WETH(), address(this));
        liquidityPools[pair] = true;
        _allowances[owner()][routerAddress] = type(uint256).max;
        _allowances[address(this)][routerAddress] = type(uint256).max;

        _balances[owner()] = _totalSupply;

        emit Transfer(address(0), owner(), _totalSupply);
    }


    
    function launch(uint256 _deadBlocks, uint256 _launchCooldown ) internal {   
        deadBlocks = _deadBlocks;
        andale = true;
        launchedAt = block.number;
        launchedTime = block.timestamp;
        swapEnabled = true;        
        launchCooldown = _launchCooldown;

    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "ERC20: transfer from 0x0");
        require(_balances[sender] >= amount, "Insufficient balance");

        if(inSwap || (sender != pair && recipient != pair ) ){ return _basicTransfer(sender, recipient, amount); }

        if(!andale){ require(sender == owner() || recipient == owner(), "Trading not open yet."); launch(12, 30 minutes ); }


        if(enableLimits && sender != owner() && recipient != owner() ){
            
            require(amount <= (_totalSupply  / 100), "TX Limit Exceeded");
            checkWalletLimit(recipient, amount);

        }

        if(shouldSwapBack(recipient)){ if (amount > 0) swapBack(amount); }
        

        _balances[sender] = _balances[sender] - amount;

        uint256 fee = getTotalFee(liquidityPools[recipient]);
        
        uint256 amountReceived =  (sender != owner() && fee > 0) ? takeFee(sender, amount, fee) : amount;
        
        
        _balances[recipient] = _balances[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }


    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function checkWalletLimit(address recipient, uint256 amount) internal view {
        uint256 walletLimit = _totalSupply  / 50;
        require(_balances[recipient] + amount <= walletLimit, "Max Wallet Exceeded");
    }


    function takeFee(address sender, uint256 amount, uint256 fee) internal returns (uint256) {
        uint256 feeAmount = (amount * fee) / 100;
        
        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if (block.timestamp - launchedTime  > launchCooldown)
            return 0;
        else if(launchedAt + deadBlocks >= block.number){ 
            return selling ? 99 : 25; 
        }
        else if( block.timestamp - launchedTime  < launchCooldown){
            return selling ? 30 : 25; 
        }
        return 0;
        }


    function shouldSwapBack(address recipient) internal view returns (bool) {
        return !liquidityPools[msg.sender]
        && !inSwap
        && swapEnabled
        && liquidityPools[recipient]
        && _balances[address(this)] >= swapMinimum;
    }

    function swapBack(uint256 amount) internal swapping {
        uint256 amountToSwap = amount < swapThreshold ? amount : swapThreshold;
        if (_balances[address(this)] < amountToSwap) amountToSwap = _balances[address(this)];
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );       
        
        if (address(this).balance > 0)
            payable(owner()).transfer(address(this).balance);
        
        emit SwapAndLiquify(amount, address(this).balance);
    }
    

    function disableLimits(bool enabled) external onlyOwner{
        enableLimits = enabled;
    }

    function setSwapBackSettings(bool _enabled, uint256 _denominator, uint256 _swapMinimum) external onlyOwner {
        require(_denominator > 0);
        swapEnabled = _enabled;
        swapThreshold = _totalSupply / _denominator;
        swapMinimum = _swapMinimum * (10 ** _decimals);
    }


    function sweepETH(uint256 amountPercentage, address receiver) external onlyOwner {
       uint256 amountETH = address(this).balance;
        payable(receiver).transfer((amountETH * amountPercentage) / 100);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }
        

}