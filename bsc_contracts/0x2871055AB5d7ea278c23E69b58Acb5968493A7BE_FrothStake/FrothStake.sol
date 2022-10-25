/**
 *Submitted for verification at BscScan.com on 2022-10-24
*/

//SPDX-License-Identifier: MIT


 
pragma solidity ^0.8.5;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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

/**
 * ERC20 standard interface.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

     function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * Allows for contract ownership along with multi-address authorization
 */
contract Ownable is Context {
    address internal _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner {
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

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

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



contract FrothStake is IERC20, Ownable {
    using SafeMath for uint256;

    address public WETH;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string  _name = "Froth Stake";
    string  _symbol = "FROTH";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 2 * 10 ** 6 * (10 ** _decimals);
    uint256 public _maxWalletToken = _totalSupply / 20; // 5%
    uint256 public _minWalletToken = _totalSupply / 500; // .2%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isLimitExempt;

    bool public tradingEnabled = false;
    bool public utilityMode = false;
    bool public utilityBuyMode = true;

    uint256 marketingFee = 20;
    uint256 ecosystemFee = 20;
    uint256 liquidityFee = 10;
    uint256 extraFee1 = 0;
    uint256 extraFee2 = 0;
    uint256 totalFee = 50;

    uint256 maxNumberHolders = 100;
    uint256 public numberHolders = 0;

    uint256 feeDenominator = 1000;
    uint256 feeAmount;

    address marketingFeeReceiver;
    address ecosystemFeeReceiver;
    address extraFee1Receiver;
    address extraFee2Receiver;

    IDEXRouter public router;
    address public pair;
    address public stakingCA;

    // Cooldown & timer functionality

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply.div(5000); // 0.02% of supply
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    modifier onlyStakingCa {
        require(stakingCA == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor ()  {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        // No timelock for these people
        
        isLimitExempt[address(this)] = true;
        isLimitExempt[DEAD] = true;
        isLimitExempt[msg.sender]= true;
        
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        
        marketingFeeReceiver = msg.sender;
        ecosystemFeeReceiver = msg.sender;
        
        _balances[msg.sender] = _totalSupply;
        _allowances[msg.sender][address(router)] = _totalSupply;
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return _owner; }
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

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function removeLimits() external onlyOwner() {
        _maxWalletToken = _totalSupply;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        require(tradingEnabled || isLimitExempt[sender] , "Trading is not enabled!");

        // Once utility is finished, utilityMode will be set to true to activate the marketplace
        if (utilityMode && !isLimitExempt[sender] && !isLimitExempt[recipient] && msg.sender != _owner){
            // If selling on PCS require holder to sell entire wallet
            if (recipient == pair){
                require(amount == _balances[sender] , "You can only sell your full wallet on PCS. Otherwise you must use the marketplace.");
            }
            // If buying make sure buying is enabled
            if(sender == pair){
                require(utilityBuyMode, "You cannot buy from PCS at this time. Please use the marketplace or wait for a position to open up.");
            }
        }
        
        // Make sure amount to buy is between minimum and maximum wallets
        if (msg.sender != _owner && !isLimitExempt[sender] && !isLimitExempt[recipient] && recipient != pair){
            uint256 heldTokens = balanceOf(recipient);
            if(utilityMode){
                require((heldTokens + amount) >= _minWalletToken, "Utility mode in effect. You must buy more tokens.");
            }
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
        }

        // Liquidity, Maintained at 25%
        if(recipient == pair){
            if(shouldSwapBack(sender)){ 
                swapBack();
            }
        }

        if (_balances[recipient] == 0 && recipient != _owner && !isLimitExempt[recipient] && recipient != pair){
            numberHolders ++;
        }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if (_balances[sender] == 0 && sender != _owner && !isLimitExempt[sender]){
            numberHolders --;
        }

        checkHolderCount();

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return msg.sender != _owner && !isFeeExempt[tx.origin] && !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {

        feeAmount = amount.mul(totalFee).div(feeDenominator);
        
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack(address sender) internal view returns (bool) {
        return sender != pair
        && tx.origin != _owner
        && !isLimitExempt[sender]
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }


    function swapBack() internal swapping {
        uint256 contractBalance = balanceOf(address(this));

        if (contractBalance > swapThreshold * 20) {
            contractBalance = swapThreshold * 20;
        }

        uint256 amountToLiquify = contractBalance.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = contractBalance.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balanceBefore = address(this).balance;

        _allowances[address(this)][address(router)] = type(uint256).max;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountETHEcosystem = amountETH.mul(ecosystemFee).div(totalETHFee);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);
        uint256 amountETHExtraFee1 = amountETH.mul(extraFee1).div(totalETHFee);
        uint256 amountETHExtraFee2 = amountETH.mul(extraFee2).div(totalETHFee);
        uint256 amountETHLiquidity = amountETH.sub(amountETHEcosystem).sub(amountETHMarketing).sub(amountETHExtraFee1).sub(amountETHExtraFee2);
        
        if (amountETHMarketing > 0){
            (bool success, /* bytes memory data */) = payable(marketingFeeReceiver).call{value: amountETHMarketing, gas: 30000}("");
            require(success, "receiver rejected ETH Transfer");
        }
        if (amountETHEcosystem > 0){
            (bool success2, /* bytes memory data */) = payable(ecosystemFeeReceiver).call{value: amountETHEcosystem, gas: 30000}("");
            require(success2, "receiver rejected ETH Transfer");
        }
        if (amountETHExtraFee1 > 0){
            (bool success3, /* bytes memory data */) = payable(extraFee1Receiver).call{value: amountETHExtraFee1, gas: 30000}("");
            require(success3, "receiver rejected ETH Transfer");
        }
        if (amountETHExtraFee2 > 0){
            (bool success4, /* bytes memory data */) = payable(extraFee2Receiver).call{value: amountETHExtraFee2, gas: 30000}("");
            require(success4, "receiver rejected ETH Transfer");
        }

        // add liquidity to uniswap
        if (amountToLiquify > 0 && amountETHLiquidity > 0){
            addLiquidity(amountToLiquify, amountETHLiquidity);
        }
        
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) public {

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            marketingFeeReceiver,
            block.timestamp
        );
    }

    function setFees(uint256 marketing, uint256 ecosystem, uint256 liquidity, uint256 fee4, uint256 fee5) external onlyOwner{
        require(marketing + ecosystem <= 30, "You can not set fees this high");
        marketingFee = marketing;
        ecosystemFee = ecosystem;
        liquidityFee = liquidity;
        extraFee1 = fee4;
        extraFee2 = fee5;
        totalFee = marketingFee.add(ecosystemFee).add(liquidityFee).add(extraFee1).add(extraFee2);
    }

    function checkHolderCount() internal {
        if(numberHolders >= maxNumberHolders){
            utilityBuyMode = false;
        }else{
            utilityBuyMode = true;
        }
    }

    function enableTrading() external onlyOwner{
        tradingEnabled = true;
    }

    function isContract(address _addr) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function setStakingCa(address CA) external onlyOwner{
        require(isContract(CA), "You can only set a contract as the Staking CA");
        stakingCA = CA;
        isLimitExempt[CA] = true;
        isFeeExempt[CA] = true;
    }

    function increaseSupplyForStakingCA(uint256 amount) external onlyStakingCa{
        _balances[stakingCA] += amount;
        _totalSupply += amount;
    }

    function switchUtilityMode() external onlyOwner {
        utilityMode = !utilityMode;
        checkHolderCount();
    }

    function switchUtilityBuyMode() external onlyOwner {
        utilityBuyMode = !utilityBuyMode;
    }

    function setMinWalletPercent(uint256 percent) external onlyOwner {
        _minWalletToken = _totalSupply.mul(percent).div(feeDenominator);
    }

    function setMaxWalletPercent(uint256 percent) external onlyOwner {
        _maxWalletToken = _totalSupply.mul(percent).div(feeDenominator);
    }

    function setMaxNumberHolders(uint256 number) external onlyOwner {
        maxNumberHolders = number;
        checkHolderCount();
    }

    function setIsLimitExempt(address holder, bool exempt) external onlyOwner {
        isLimitExempt[holder] = exempt;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setFeeReceivers( address _marketingFeeReceiver) external onlyOwner {
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function getStuckBalance() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(marketingFeeReceiver).transfer(contractETHBalance);
    }

    function getStuckTokens(address token) external onlyOwner {
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(marketingFeeReceiver, tokenBalance);
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

}