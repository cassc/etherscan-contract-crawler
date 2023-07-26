/**
 *Submitted for verification at Etherscan.io on 2023-07-06
*/

/**
(w) : https://aerielab.io/ | (tg) : https://t.me/aerieofficial
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IDEXRouter {
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
    // K8u#El(o)nG3a#t!e c&oP0Y
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

/**
 * Main Contract Starts Here 
 */

contract AERIE is IERC20, Ownable {
    using SafeMath for uint256;
    
    // About Amnesty
    struct AmnestyTier {
        string name;
        bool active;
        uint256 cost;
        uint256 discount;
        uint256 blocks;
        uint index;
    }
    // these two variables will later store about all package available
    uint public lastTierIndex = 0;
    AmnestyTier[] public tiers;
    
    // these variables will later store about user active tier
    struct UserTier {
        bool usingTier;
        uint256 lastBlock;
        uint256 discount;
        uint activeIndex;
    }
    mapping (address => UserTier) _userTier;
    mapping (address => uint256) _amnestyGivenToUser;
    uint256 public _totalBurnFromTier;
    uint256 public _totalAmnesty;
    uint public _totalSubscriber;

    // Name, Symbol, and Decimals Initialization
    string constant _name = "AERIE";
    string constant _symbol = "AER";
    uint8 constant _decimals = 18;
    
    // Important Addresses
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IDEXRouter public router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    // Supply
    uint256 _totalSupply = 1000000000 * (10 ** _decimals); // 1,000,000,000 AER
    
    // Max Buy & Sell on each transaction
    uint256 public _maxBuyTxAmount = (_totalSupply * 10) / 1000; // 1% are default
    uint256 public _maxSellTxAmount = (_totalSupply * 10) / 1000; // 1% are default
    uint256 public _maxWalletSize = (_totalSupply * 10) / 1000; // 1% are default

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    
    // Fees Variables
    uint256 liqFee; 
    uint256 buybackFee; 
    uint256 mktFee; 
    uint256[3] devFee;

    // Total Fee
    uint256 totalFee;
    uint256 feeDenominator = 10000;
    

    address autoLiquidityReceiver;
    address secDevFeeReceiver;
    address primDevFeeReceiver;
    address thirdDevFeeReceiver;
    address mktFeeReceiver;
    address buybackFeeReceiver; 
    
    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    // Router & Pair
    address public pair;

    // Treshold & etc
    bool public swapEnabled = true;

    uint256 public swapThreshold = _totalSupply / 1000; // 0.1%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (
        address[] memory _receivers,
        uint256[] memory _fees
    ) {
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        // Set Fee Receivers
        primDevFeeReceiver = address(_receivers[0]);
        secDevFeeReceiver = address(_receivers[1]);
        thirdDevFeeReceiver = address(_receivers[2]);
        mktFeeReceiver = address(_receivers[3]);
        buybackFeeReceiver = address(_receivers[4]);
        
        // Set Default Taxes
        liqFee = _fees[0]; 
        buybackFee = _fees[1]; 
        mktFee = _fees[2]; 
        devFee = [_fees[3],_fees[4],_fees[5]];
        totalFee = liqFee.add(buybackFee).add(mktFee).add(devFee[0]).add(devFee[1]).add(devFee[2]);
        
        // Another Initialization
        _allowances[address(this)][address(router)] = type(uint256).max;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[primDevFeeReceiver] = true;
        isFeeExempt[secDevFeeReceiver] = true;
        isFeeExempt[thirdDevFeeReceiver] = true;
        isFeeExempt[mktFeeReceiver] = true;
        
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[primDevFeeReceiver] = true;
        isTxLimitExempt[secDevFeeReceiver] = true;
        isTxLimitExempt[thirdDevFeeReceiver] = true;
        isTxLimitExempt[mktFeeReceiver] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;
        isTxLimitExempt[address(this)] = true;
        
        autoLiquidityReceiver = owner();
        
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

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
        
        // coniditional Boolean
        bool isTxExempted = (isTxLimitExempt[sender] || isTxLimitExempt[recipient]);
        bool isContractTransfer = (sender==address(this) || recipient==address(this));
        bool isLiquidityTransfer = ((sender == pair && recipient == address(router)) || (recipient == pair && sender == address(router) ));
        
        if(!isTxExempted && !isContractTransfer && !isLiquidityTransfer ){
            txLimitter(sender,recipient, amount);
        }
        if (recipient != pair && recipient != DEAD) {
            require(isTxLimitExempt[recipient] || _balances[recipient] + amount <= _maxWalletSize, "Transfer amount exceeds the wallet size.");
        }
        if(shouldSwapBack()){ swapBack(); }
    
        uint256 amountReceived = shouldTakeFee(sender,recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amountReceived);
        

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function txLimitter(address sender, address recipient, uint256 amount) internal view {
        
        bool isBuy = sender == pair || sender == address(router);
        bool isSell = recipient== pair || recipient == address(router);
        
        if(isBuy){
            require(amount <= _maxBuyTxAmount, "TX Limit Exceeded");
        }else if(isSell){
            require(amount <= _maxSellTxAmount, "TX Limit Exceeded");
        }
        
    }
    
    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function getTotalFee() public view returns (uint256) {
        return totalFee;
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee()).div(feeDenominator);
        uint256 amnestyAmount;
        uint256 finalFeeAmount;
        UserTier memory _userFee;
        bool isBuy = sender == pair || sender == address(router);
        bool isSell = receiver== pair || receiver == address(router);
        bool isNormalTransfer = sender != pair && sender != address(router) && receiver != pair && receiver != address(router);

        // check wether the sender are subscribe for amnesty or not
        if(isBuy){
            // when buy, then the user are receiver
            _userFee = _userTier[receiver];        
        }else if(isSell){
            // when sell, then the user are sender
            _userFee = _userTier[sender];
        }else if(isNormalTransfer){
            // if its normal transfer, we take consideration from sender perspective
            _userFee = _userTier[sender];
        }

        if(_userFee.usingTier && block.number <= _userFee.lastBlock){
            amnestyAmount = feeAmount.mul(_userFee.discount).div(feeDenominator);
        }

        if(amnestyAmount >= 0){
             _totalAmnesty = _totalAmnesty.add(amnestyAmount); // record total token saved from amnesty
             // set to specific user
             if(isBuy){
                 _amnestyGivenToUser[receiver] = _amnestyGivenToUser[receiver].add(amnestyAmount);
             }else if(isSell || isNormalTransfer){
                 _amnestyGivenToUser[sender] = _amnestyGivenToUser[sender].add(amnestyAmount);
             }
        }
        finalFeeAmount = feeAmount.sub(amnestyAmount); // apply the amnesty into the fee
        
        _balances[address(this)] = _balances[address(this)].add(finalFeeAmount);
        emit Transfer(sender, address(this), finalFeeAmount);

        return amount.sub(finalFeeAmount);
    }
    
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }
    
    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liqFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);

        uint256 totalETHFee = totalFee.sub(dynamicLiquidityFee.div(2));

        uint256 amountETHLiquidity = amountETH.mul(dynamicLiquidityFee).div(totalETHFee).div(2);
        uint256 amountETHDev = amountETH.mul(devFee[0]).div(totalETHFee);
        uint256 amountETHTeam = amountETH.mul(devFee[1]).div(totalETHFee);
        uint256 amountETHTeamOther = amountETH.mul(devFee[2]).div(totalETHFee);
        uint256 amountETHMkt = amountETH.mul(mktFee).div(totalETHFee);
        uint256 amountETHBuyBack = amountETH.mul(buybackFee).div(totalETHFee);
        
        sendPayable(amountETHDev, amountETHMkt, amountETHTeam, amountETHTeamOther, amountETHBuyBack);

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    function sendPayable(uint256 amtDev, uint256 amtMkt, uint256 amtTeam, uint256 amtTeamOther, uint256 amtBuyback) internal {
        (bool successone,) = payable(primDevFeeReceiver).call{value: amtDev, gas: 30000}("");
        (bool successtwo,) = payable(mktFeeReceiver).call{value: amtMkt, gas: 30000}("");
        (bool successthree,) = payable(secDevFeeReceiver).call{value: amtTeam, gas: 30000}("");
        (bool successfour,) = payable(buybackFeeReceiver).call{value: amtBuyback, gas: 30000}("");
        (bool successfive,) = payable(buybackFeeReceiver).call{value: amtTeamOther, gas: 30000}("");
        require(successone && successtwo && successthree && successfour && successfive, "receiver rejected ETH transfer");
    }

    // used for flushing stuck Native token on Contract
    function flushStuckBalance() external onlyOwner {
        uint256 bal = address(this).balance; // return the native token ( ETH )
        (bool success,) = payable(primDevFeeReceiver).call{value: bal, gas: 30000}("");
        require(success, "receiver rejected ETH transfer");
    }
    
    /**
     * 
     * CONFIGURATIONS
     * 
     */

    function addNewTier(
        string memory _tierName,
        uint256 cost,
        uint256 discount,
        uint256 blocks
    ) external onlyOwner {
        AmnestyTier memory _newTier = AmnestyTier(
            _tierName,
            true,
            (cost * (10 ** _decimals)),
            discount,
            blocks,
            lastTierIndex
        );
        tiers.push(_newTier);
        lastTierIndex = lastTierIndex.add(1);
    }

    function modifyTier(
        uint index,
        bool _active,
        string memory _tierName,
        uint256 cost,
        uint256 discount,
        uint256 blocks
    ) external onlyOwner {
        tiers[index].active = _active;
        tiers[index].name = _tierName;
        tiers[index].cost = (cost * (10 ** _decimals));
        tiers[index].discount = discount;
        tiers[index].blocks = blocks;
    }

    function getAllTiers() public view returns (AmnestyTier[] memory){
        return tiers;
    }

    function getTierDetail(uint index) public view returns (AmnestyTier memory){
        return tiers[index];
    }
    function getTierDetailByUser(address user) public view returns (AmnestyTier memory){
        return tiers[_userTier[user].activeIndex];
    }

    function getUserTier(address user) public view returns (UserTier memory){
        return _userTier[user];
    }
    function getAmnestyGivenToUser(address user) public view returns (uint256){
        return _amnestyGivenToUser[user];
    }
    function subscribeForAmnesty(uint index) public{
        // obtain the tier package
        AmnestyTier memory _selectedTier = tiers[index];
        // now we get the cost
        uint256 _costToSubscribe = _selectedTier.cost;
        uint256 balance = balanceOf(_msgSender());
        require(balance >= _costToSubscribe, "INS: Insufficient Balance");
        require(_selectedTier.active,"INACTIVE: The Tier is not active");
        
        _transferFrom(_msgSender(), DEAD, _costToSubscribe); // the cost are burn to dead wallet
        
        // then, we increment
        _totalBurnFromTier = _totalBurnFromTier.add(_costToSubscribe);
        // now check wether the user has been subscribed before or not
        if(!_userTier[_msgSender()].usingTier){
            // means that the user never pay for subscription before
            _totalSubscriber = _totalSubscriber.add(1);
        }
        _userTier[_msgSender()] = UserTier(
            true,
            (block.number).add(_selectedTier.blocks),
            _selectedTier.discount,
            index
        );
    }
    
    function setDevFee(uint256[] memory fee) external onlyOwner {
        // total fee should not be more than 10%;
        uint256 simulatedFee = fee[0].add(fee[1]).add(fee[2]).add(liqFee).add(buybackFee).add(mktFee);
        require(simulatedFee <= 1000, "Fees too high !!");
        devFee[0] = fee[0];
        devFee[1] = fee[1];
        devFee[2] = fee[2];
        totalFee = simulatedFee;
    }
    function setBuybackFee(uint256 fee) external onlyOwner {
        // total fee should not be more than 10%;
        uint256 simulatedFee = fee.add(liqFee).add(devFee[0]).add(devFee[1]).add(devFee[2]).add(mktFee);
        require(simulatedFee <= 1000, "Fees too high !!");
        buybackFee = fee;
        totalFee = simulatedFee;
    }
    function setLpFee(uint256 fee) external onlyOwner {
        // total fee should not be more than 10%;
        uint256 simulatedFee = fee.add(devFee[0]).add(buybackFee).add(devFee[1]).add(devFee[2]).add(mktFee);
        require(simulatedFee <= 1000, "Fees too high !!");
        liqFee = fee;
        totalFee = simulatedFee;
    }
    
    function setMarketingFee(uint256 fee) external onlyOwner {
        // total fee should not be more than 10%;
        uint256 simulatedFee = fee.add(devFee[0]).add(buybackFee).add(liqFee).add(devFee[1]).add(devFee[2]);
        require(simulatedFee < 1000, "Fees too high !!");
        mktFee = fee;
        totalFee = simulatedFee;
    }
    
    function setBuyTxMaximum(uint256 max) external onlyOwner{
        uint256 minimumTreshold = (_totalSupply * 7) / 1000; // 0.7% is the minimum tx limit, we cant set below this
        uint256 simulatedMaxTx = (_totalSupply * max) / 1000;
        require(simulatedMaxTx >= minimumTreshold, "Tx Limit is too low");
        _maxBuyTxAmount = simulatedMaxTx;
    }
    
    function setSellTxMaximum(uint256 max) external onlyOwner {
        uint256 minimumTreshold = (_totalSupply * 7) / 1000; // 0.7% is the minimum tx limit, we cant set below this
        uint256 simulatedMaxTx = (_totalSupply * max) / 1000;
        require(simulatedMaxTx >= minimumTreshold, "Tx Limit is too low");
        _maxSellTxAmount = simulatedMaxTx;
    }

    function setMaxWallet(uint256 numerator, uint256 divisor) external onlyOwner{
        require(numerator > 0 && divisor > 0 && divisor <= 10000);
        _maxWalletSize = _totalSupply.mul(numerator).div(divisor);
    }
    
    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }
    
    function setFeeReceivers(address _autoLiquidityReceiver, address _primDevFeeReceiver, address _mktFeeReceiver, address _secDevFeeReceiver,address _thirdDevFeeReceiver, address _buybackFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        primDevFeeReceiver = _primDevFeeReceiver;
        mktFeeReceiver = _mktFeeReceiver;
        secDevFeeReceiver = _secDevFeeReceiver;
        buybackFeeReceiver = _buybackFeeReceiver;
        thirdDevFeeReceiver = _thirdDevFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount.div(100);
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
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
    
    
    

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
    
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
}