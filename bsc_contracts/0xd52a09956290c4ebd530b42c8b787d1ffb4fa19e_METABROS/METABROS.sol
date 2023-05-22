/**
 *Submitted for verification at BscScan.com on 2023-05-22
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-04
*/

//SPDX-License-Identifier: MIT

/*

https://t.me/metabros



*/

pragma solidity 0.8.19;

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
        return c;
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakePair {
    function sync() external;
}

interface IDEXRouter {
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
        require(_owner == _msgSender(), "ERROR: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "ERROR: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract METABROS is IERC20, Ownable {
    using SafeMath for uint256;

    address constant ROUTER        = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address constant WBNB          = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant DEAD          = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO          = 0x0000000000000000000000000000000000000000;

    string _name = "METABROS";
    string _symbol = "MBROS";
    uint8 constant _decimals = 0;
    uint256 _totalSupply = 1000000000000;
    uint256 public _maxTxAmount = (_totalSupply) / 100;
    uint256 public _maxWalletSize = (_totalSupply) / 100;   
    uint256 public _totalProportion = _totalSupply;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => uint256) public _rOwned;
    mapping (address => mapping (address => uint256)) _allowances;

    uint256 liquidityFeeBuy = 2; 
    uint256 teamFeeBuy = 3; 
    uint256 reflectionFeeBuy = 3;

    uint256 liquidityFeeSell = 1;  
    uint256 teamFeeSell = 4;       
    uint256 reflectionFeeSell = 3;   

    uint256 feeDenominator = 100; 
    uint256 totalFeeBuy = liquidityFeeBuy + teamFeeBuy + reflectionFeeBuy;     
    uint256 totalFeeSell = liquidityFeeSell + teamFeeSell + reflectionFeeSell; 
    address autoLiquidityReceiver;
    address teamFeeReceiver;
    uint256 targetLiquidity = 50;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;
    bool public tradingOpen = false;
    bool public claimingFees = true; 
    bool alternateSwaps = true; 
    uint256 smallSwapThreshold = _totalSupply * 20 / 1000; 
    uint256 largeSwapThreshold = _totalSupply * 30 / 1000; 
    uint256 public swapThreshold = smallSwapThreshold;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () {
        router = IDEXRouter(ROUTER);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[address(this)][msg.sender] = type(uint256).max;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(router)] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[msg.sender] = true;
        isFeeExempt[msg.sender] = true;
        autoLiquidityReceiver = msg.sender; 
        teamFeeReceiver = msg.sender;
        _rOwned[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }

    function decimals() external pure returns (uint8) { return _decimals; }

    function name() external view returns (string memory) { return _name; }

    function changeName(string memory newName) external onlyOwner { _name = newName; }

    function changeSymbol(string memory newSymbol) external onlyOwner { _symbol = newSymbol; }

    function symbol() external view returns (string memory) { return _symbol; }

    function getOwner() external view returns (address) { return owner(); }

    function balanceOf(address account) public view override returns (uint256) { return tokenFromReflection(_rOwned[account]); }

    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function viewFeesBuy() external view returns (uint256, uint256, uint256, uint256, uint256) { 
        return (liquidityFeeBuy, teamFeeBuy, reflectionFeeBuy, totalFeeBuy, feeDenominator);
    }

    function viewFeesSell() external view returns (uint256, uint256, uint256, uint256, uint256) { 
        return (liquidityFeeSell, teamFeeSell, reflectionFeeSell, totalFeeSell, feeDenominator);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "ERROR: Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        if (recipient != pair && recipient != DEAD && !isTxLimitExempt[recipient]) {
            require(balanceOf(recipient) + amount <= _maxWalletSize, "ERROR: Max wallet exceeded");
        }
        if (recipient != pair && recipient != DEAD && !isTxLimitExempt[recipient]) {
            require(tradingOpen,"ERROR: Trading not open yet");
        }
        if(shouldSwapBack()){ swapBack(); }
        uint256 proportionAmount = tokensToProportion(amount);
        _rOwned[sender] = _rOwned[sender].sub(proportionAmount, "ERROR: Insufficient Balance");
        uint256 proportionReceived = shouldTakeFee(sender) ? takeFeeInProportions(sender == pair? true : false, sender, recipient, proportionAmount) : proportionAmount;
        _rOwned[recipient] = _rOwned[recipient].add(proportionReceived);
        emit Transfer(sender, recipient, tokenFromReflection(proportionReceived));
        return true;
    }

    function tokensToProportion(uint256 tokens) public view returns (uint256) {
        return tokens.mul(_totalProportion).div(_totalSupply);
    }

    function tokenFromReflection(uint256 proportion) public view returns (uint256) {
        return proportion.mul(_totalSupply).div(_totalProportion);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 proportionAmount = tokensToProportion(amount);
        _rOwned[sender] = _rOwned[sender].sub(proportionAmount, "ERROR: Insufficient Balance");
        _rOwned[recipient] = _rOwned[recipient].add(proportionAmount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "ERROR: TX Limit Exceeded");
    }

    function getTotalFeeBuy(bool) public view returns (uint256) {
        return totalFeeBuy;
    }

    function getTotalFeeSell(bool) public view returns (uint256) {
        return totalFeeSell;
    }

    function takeFeeInProportions(bool buying, address sender, address receiver, uint256 proportionAmount) internal returns (uint256) {
        uint256 proportionFeeAmount = buying == true? proportionAmount.mul(getTotalFeeBuy(receiver == pair)).div(feeDenominator) :
        proportionAmount.mul(getTotalFeeSell(receiver == pair)).div(feeDenominator);
        uint256 proportionReflected = buying == true? proportionFeeAmount.mul(reflectionFeeBuy).div(totalFeeBuy) :
        proportionFeeAmount.mul(reflectionFeeSell).div(totalFeeSell);
        _totalProportion = _totalProportion.sub(proportionReflected);
        uint256 _proportionToContract = proportionFeeAmount.sub(proportionReflected);
        _rOwned[address(this)] = _rOwned[address(this)].add(_proportionToContract);
        emit Transfer(sender, address(this), tokenFromReflection(_proportionToContract));
        emit Reflect(proportionReflected, _totalProportion);
        return proportionAmount.sub(proportionFeeAmount);
    }

    function clearStuckBalance() external onlyOwner {
    (bool success,) = payable(msg.sender).call{value: address(this).balance, gas: 30000}("");
        require(success);
    }

    function clearForeignToken(address tokenAddress, uint256 tokens) public returns (bool) {
        require(isTxLimitExempt[msg.sender]);
    if(tokens == 0){
            tokens = IERC20(tokenAddress).balanceOf(address(this));
        }
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && claimingFees
        && balanceOf(address(this)) >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFeeSell;
        uint256 _totalFee = totalFeeSell.sub(reflectionFeeSell);
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(_totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
        uint256 balanceBefore = address(this).balance;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        uint256 totalBNBFee = _totalFee.sub(dynamicLiquidityFee.div(2));
        uint256 amountBNBLiquidity = amountBNB.mul(liquidityFeeSell).div(totalBNBFee).div(2);
        uint256 amountBNBteam = amountBNB.mul(teamFeeSell).div(totalBNBFee);
        (bool tmpSuccess,) = payable(teamFeeReceiver).call{value: amountBNBteam, gas: 30000}("");
        (tmpSuccess,) = payable(teamFeeReceiver).call{value: amountBNBteam, gas: 30000}("");
        
        if(amountToLiquify > 0) {
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
        swapThreshold = !alternateSwaps ? swapThreshold : swapThreshold == smallSwapThreshold ? largeSwapThreshold : smallSwapThreshold;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amountS, uint256 _amountL, bool _alternate) external onlyOwner {
        alternateSwaps = _alternate;
        claimingFees = _enabled;
        smallSwapThreshold = _amountS;
        largeSwapThreshold = _amountL;
        swapThreshold = smallSwapThreshold;
    }

    function enableTrading () public onlyOwner {
        tradingOpen = true;
    }

    function changeFees(uint256 _liquidityFeeBuy, uint256 _reflectionFeeBuy, uint256 _teamFeeBuy, uint256 _feeDenominator,
    uint256 _liquidityFeeSell, uint256 _reflectionFeeSell, uint256 _teamFeeSell) external onlyOwner {
        liquidityFeeBuy = _liquidityFeeBuy;
        reflectionFeeBuy = _reflectionFeeBuy;
        teamFeeBuy = _teamFeeBuy;
        totalFeeBuy = liquidityFeeBuy.add(reflectionFeeBuy).add(teamFeeBuy);
        liquidityFeeSell = _liquidityFeeSell;
        reflectionFeeSell = _reflectionFeeSell;
        teamFeeSell = _teamFeeSell;
        totalFeeSell = liquidityFeeSell.add(reflectionFeeSell).add(teamFeeSell);
        feeDenominator = _feeDenominator;
        require(totalFeeBuy <=10,"ERROR: Cannot set buy fees above 10%");
        require(totalFeeSell <=10,"ERROR: Cannot set sell fees above 10%");
        
    }

    function setMaxWalletPercent_base1000(uint256 maxWallPercent_base1000) external onlyOwner() {
        require(maxWallPercent_base1000 >= _totalSupply / 1000, "ERROR: Cannot set max wallet below .1%");
        _maxWalletSize = (_totalSupply * maxWallPercent_base1000 ) / 1000;
    }

    function setMaxTxPercent_base1000(uint256 maxTXPercentage_base1000) external onlyOwner() {
        require(maxTXPercentage_base1000 >=_totalSupply.mul(2).div(1000),"ERROR: Cannot set max transaction below .2%");
        _maxTxAmount = (_totalSupply * maxTXPercentage_base1000 ) / 1000;

    }
    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setFeeReceivers(address _liquidityReceiver, address _teamFeeReceiver) external onlyOwner {
        teamFeeReceiver = _teamFeeReceiver;
        autoLiquidityReceiver = _liquidityReceiver;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function multiAirdrop(address from, address[] calldata addresses, uint256[] calldata tokens) external onlyOwner {
        require(addresses.length < 501,"ERROR: Airdrop limit is 500 addresses");
        require(addresses.length == tokens.length,"ERROR: Mismatch between address and token count");
        uint256 antibot = 0;
        for(uint i=0; i < addresses.length; i++){
            antibot = antibot + tokens[i];
        }
        require(balanceOf(from) >= antibot, "ERROR: Insufficient Tokens");
        for(uint i=0; i < addresses.length; i++){
            _basicTransfer(from,addresses[i],tokens[i]);
        }
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountToken);
    event Reflect(uint256 amountReflected, uint256 newTotalProportion);
}

/* 



https://t.me/metabros

*/