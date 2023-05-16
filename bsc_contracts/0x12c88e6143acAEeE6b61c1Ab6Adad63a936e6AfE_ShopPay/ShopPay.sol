/**
 *Submitted for verification at BscScan.com on 2023-05-16
*/

/**
https://T.me/shoppaybr
https://shoppaytoken.com/
https://T.me/jonhDeveloper owner of SmartTokenizer


*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;


interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */

    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ShopPay is IERC20, Ownable {
    using SafeMath for uint256;

    address constant ROUTER        = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address constant WBNB          = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant DEAD          = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO          = 0x0000000000000000000000000000000000000000;

    string _name = "Shop Pay";
    string _symbol = "SHP";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1 * 10**9 * 10**_decimals;
    uint256 public _maxTxAmount = (_totalSupply * 2) / 100;
    uint256 public _maxWalletSize = (_totalSupply * 2) / 100;   

    /* rOwned = ratio of tokens owned relative to circulating supply (NOT total supply, since circulating <= total) */
    mapping (address => uint256) public _rOwned;
    uint256 public _totalProportion = _totalSupply;

    mapping (address => mapping (address => uint256)) _allowances;
   

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
 
    uint256 APPFeeBuy = 0; 
    uint256 TokenizerFeeBuy = 1; 
    uint256 marketingFeeBuy = 9;  
    uint256 AutoSHPFeeBuy = 0;   

    uint256 APPFeeSell = 0;  
    uint256 TokenizerFeeSell = 1;      
    uint256 marketingFeeSell = 9;    
    uint256 AutoSHPFeeSell = 0;   
    
    uint256 feeDenominator = 100; 

    uint256 totalFeeBuy = marketingFeeBuy + APPFeeBuy + TokenizerFeeBuy + AutoSHPFeeBuy;     
    uint256 totalFeeSell = marketingFeeSell + APPFeeSell + TokenizerFeeSell + AutoSHPFeeSell; 
    
    address AppShopPay;
    address marketingFeeReceiver;
    address TokenizerFeeReceiver;

    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    bool public tradingOpen = true;

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

        AppShopPay = 0xD5900612eF15dB288B72BB09FD9d2F6a2958EA42; 
        TokenizerFeeReceiver = 0xE70bb54886fCb87C021FA40898B0b2430D2dCCF7;
        marketingFeeReceiver = 0x696Bd2ED83Ee56D0022E3518d507ED151076c6c7;

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
    function balanceOf(address account) public view override returns (uint256) { return tokenFromAutoSHP(_rOwned[account]); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    

       function viewFeesBuy() external view returns (uint256, uint256, uint256, uint256, uint256, uint256) { 
        return (APPFeeBuy, marketingFeeBuy, TokenizerFeeSell, AutoSHPFeeBuy, totalFeeBuy, feeDenominator);
    }

    
    function viewFeesSell() external view returns (uint256, uint256, uint256, uint256, uint256, uint256) { 
        return (APPFeeSell, marketingFeeSell, TokenizerFeeSell, AutoSHPFeeSell, totalFeeSell, feeDenominator);
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
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }


    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if (recipient != pair && recipient != DEAD && recipient != marketingFeeReceiver && !isTxLimitExempt[recipient]) {
            require(balanceOf(recipient) + amount <= _maxWalletSize, "Max Wallet Exceeded");

        }
     
        if (recipient != pair && recipient != DEAD && !isTxLimitExempt[recipient]) {
            require(tradingOpen,"Trading not open yet");
        
        }

        if(shouldSwapBack()){ swapBack(); }

        uint256 proportionAmount = tokensToProportion(amount);

        _rOwned[sender] = _rOwned[sender].sub(proportionAmount, "Insufficient Balance");

        uint256 proportionReceived = shouldTakeFee(sender) ? takeFeeInProportions(sender == pair? true : false, sender, recipient, proportionAmount) : proportionAmount;
        _rOwned[recipient] = _rOwned[recipient].add(proportionReceived);

        emit Transfer(sender, recipient, tokenFromAutoSHP(proportionReceived));
        return true;
    }

    function tokensToProportion(uint256 tokens) public view returns (uint256) {
        return tokens.mul(_totalProportion).div(_totalSupply);
    }

    function tokenFromAutoSHP(uint256 proportion) public view returns (uint256) {
        return proportion.mul(_totalSupply).div(_totalProportion);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 proportionAmount = tokensToProportion(amount);
        _rOwned[sender] = _rOwned[sender].sub(proportionAmount, "Insufficient Balance");
        _rOwned[recipient] = _rOwned[recipient].add(proportionAmount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];

    }

     function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
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

        // reflect
        uint256 proportionReflected = buying == true? proportionFeeAmount.mul(AutoSHPFeeBuy).div(totalFeeBuy) :
        proportionFeeAmount.mul(AutoSHPFeeSell).div(totalFeeSell);

        _totalProportion = _totalProportion.sub(proportionReflected);

        // take fees
        uint256 _proportionToContract = proportionFeeAmount.sub(proportionReflected);
        _rOwned[address(this)] = _rOwned[address(this)].add(_proportionToContract);

        emit Transfer(sender, address(this), tokenFromAutoSHP(_proportionToContract));
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
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : APPFeeSell;
        uint256 _totalFee = totalFeeSell.sub(AutoSHPFeeSell);
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
        uint256 amountBNBLiquidity = amountBNB.mul(APPFeeSell).div(totalBNBFee).div(2);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFeeSell).div(totalBNBFee);
        uint256 amountBNBTokenizer = amountBNB.mul(TokenizerFeeSell).div(totalBNBFee);

        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        (tmpSuccess,) = payable(TokenizerFeeReceiver).call{value: amountBNBTokenizer, gas: 30000}("");
        

        if(amountToLiquify > 0) {
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                AppShopPay,
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

       function changeFees(uint256 _liquidityFeeBuy, uint256 _AutoSHPFeeBuy, uint256 _marketingFeeBuy, uint256 _TokenizerFeeBuy, uint256 _feeDenominator,
    uint256 _liquidityFeeSell, uint256 _AutoSHPFeeSell, uint256 _marketingFeeSell, uint256 _TokenizerFeeSell) external onlyOwner {
        APPFeeBuy = _liquidityFeeBuy;
        AutoSHPFeeBuy = _AutoSHPFeeBuy;
        marketingFeeBuy = _marketingFeeBuy;
        TokenizerFeeBuy = _TokenizerFeeBuy;
        totalFeeBuy = APPFeeBuy.add(AutoSHPFeeBuy).add(marketingFeeBuy).add(TokenizerFeeBuy);

        APPFeeSell = _liquidityFeeSell;
        AutoSHPFeeSell = _AutoSHPFeeSell;
        marketingFeeSell = _marketingFeeSell;
        TokenizerFeeSell = _TokenizerFeeSell;
        totalFeeSell = APPFeeSell.add(AutoSHPFeeSell).add(marketingFeeSell).add(TokenizerFeeSell);

        feeDenominator = _feeDenominator;

        require(totalFeeBuy <=25,"Cannot set buy fees above 25%"); // set max fees you can set to here
        require(totalFeeSell <=25,"Cannot set sell fees above 25%"); // set max fees you can set to here
        
     }

   function setMaxWalletPercent_base1000(uint256 maxWallPercent_base1000) external onlyOwner() {
        require(maxWallPercent_base1000 >= _totalSupply / 1000, "cannot set max wallet below .1%");
        _maxWalletSize = (_totalSupply * maxWallPercent_base1000 ) / 1000;
    }

    function setMaxTxPercent_base1000(uint256 maxTXPercentage_base1000) external onlyOwner() {
        require(maxTXPercentage_base1000 >=_totalSupply.mul(2).div(1000),"cannot set max TX below .2%");
        _maxTxAmount = (_totalSupply * maxTXPercentage_base1000 ) / 1000;

    }
    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    
    function setFeeReceivers(address _marketingFeeReceiver, address _TokenizerFeeReceiver, address _liquidityReceiver) external onlyOwner {
        marketingFeeReceiver = _marketingFeeReceiver;
        AppShopPay = _liquidityReceiver;
        TokenizerFeeReceiver = _TokenizerFeeReceiver;
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



    event AutoLiquify(uint256 amountBNB, uint256 amountToken);
    event Reflect(uint256 amountReflected, uint256 newTotalProportion);
}