/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

// TELEGRAM: https://t.me/FujiETH
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

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
interface ERC20 {
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


/**
 * Allows for contract ownership.
 */
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal _intAddr;
     event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _owner) {
        owner = _owner;
        _intAddr[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Transfer ownership to new address. Caller must be owner.
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        _intAddr[adr] = true;
        emit OwnershipTransferred(adr);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function renounceOwnership() public onlyOwner {
        _setOwner(address(0));
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

contract FUJI is ERC20, Auth {
    using SafeMath for uint256;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // MAINNET

    string constant _name = "The Shiba Killer";
    string constant _symbol = "FUJI";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1_000_000_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply; 
    uint256 public _maxWalletSize = (_totalSupply * 3) / 100; 

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isTimelockExempt;
    mapping (address => bool) public isBot;

    uint256 liquidityFee = 0;
    uint256 devFee = 1; 
    uint256 marketingFee = 2;
    uint256 totalFee = 3;
    uint256 feeDenominator = 100;
    uint256 public _sellMultiplier = 1;
    
    address public marketingFeeReceiver = 0xb8DB1279941145cAD50925C3412147Ad09812A70;
    address public devFeeReceiver = msg.sender;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 10000 * 40; // 0.4%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

        // Cooldown & timer functionality
    bool public opCooldownEnabled = true;
    uint8 public cooldownTimerInterval = 3;
    mapping (address => uint) private cooldownTimer;

    constructor () Auth(msg.sender) {
        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[routerAddress] = true;
        isTxLimitExempt[msg.sender] = true;
        isTimelockExempt[DEAD] = true;
        isTimelockExempt[address(this)] = true;


        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
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

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender, amount);
        // Check if address is excluded.
        require(!isBot[recipient] && !isBot[sender], 'Address is excluded.');
        if (recipient != pair && recipient != DEAD) {
            require(isTxLimitExempt[recipient] || _balances[recipient] + amount <= _maxWalletSize, "Transfer amount exceeds the bag size.");
        }
        if (sender == pair &&
            opCooldownEnabled &&
            !isTimelockExempt[recipient]) {
            require(cooldownTimer[recipient] < block.timestamp,"Please wait for 1min between two operations");
            cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
        }
        if(shouldSwapBack()){ swapBack(); }

        if(!launched() && recipient == pair){ require(_balances[sender] > 0); launch(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
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

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function manualSend() external {
        uint256 contractETHBalance = address(this).balance;
        payable(devFeeReceiver).transfer(contractETHBalance);
    }
    
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if(selling) { return totalFee.mul(_sellMultiplier); }
        return totalFee;
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = swapThreshold;
        uint256 amountToLiquify = contractTokenBalance.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

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
        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        uint256 amountETHdev = amountETH.mul(devFee).div(totalETHFee);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);


        (bool MarketingSuccess, /* bytes memory data */) = payable(marketingFeeReceiver).call{value: amountETHMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");
        (bool devSuccess, /* bytes memory data */) = payable(devFeeReceiver).call{value: amountETHdev, gas: 30000}("");
        require(devSuccess, "receiver rejected ETH transfer");

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                devFeeReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

   function setMaxWallet(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 1000 );
        _maxWalletSize = amount;
    }

    function setFees(uint256 _liquidityFee, uint256 _marketingFee, uint256 _devFee, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        devFee = _devFee;
        totalFee = _liquidityFee.add(_marketingFee).add(_devFee);
        feeDenominator = _feeDenominator;
    }

    function cooldownEnabled(bool _status, uint8 _interval) public onlyOwner() {
        opCooldownEnabled = _status;
        cooldownTimerInterval = _interval;
    }

    function setFeeReceiver(address _marketingFeeReceiver, address _devFeeReceiver) external onlyOwner {
        marketingFeeReceiver = _marketingFeeReceiver;
        devFeeReceiver = _devFeeReceiver;
    }

    function setTxLimit(uint256 amountBuy) external onlyOwner {
        _maxTxAmount = amountBuy;
        
    }

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
}