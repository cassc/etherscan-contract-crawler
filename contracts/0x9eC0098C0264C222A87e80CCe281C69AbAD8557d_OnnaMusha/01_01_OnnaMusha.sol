// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
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

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
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

contract OnnaMusha is ERC20, Ownable {
    using SafeMath for uint256;
    address routerAdress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Onna Musha";
    string constant _symbol = "MUSHA";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1000_000_000_000 * (10 ** _decimals);
    uint256 public _maxWalletAmount = _totalSupply.mul(1).div(100);
    uint256 public _maxTx = _totalSupply.mul(1).div(100);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isWhitelist;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    uint256 marketingFee = 2;
    uint256 liquidityFee = 1; 
    uint256 developmentFee = 1;
    uint256 stakingFee = 1;
    uint256 burnFee = 1;
    uint256 totalFee = liquidityFee + marketingFee + developmentFee + stakingFee + burnFee;
    uint256 feeDenominator = 100;

    address public marketingFeeReceiver = 0xE9F4Eb1862572bC66B4E4cb545aeB312BC40013A;
    address public liquidityFeeReceiver = 0xe8730C785256fd32Bc87fc7B0795a7686c5AD3e7;
    address public developmentFeeReceiver = 0xca8C8169A3B86b2D355129FB801738fe6D9C28a7;
    address public stakingFeeReceiver = 0x3ab71c09FEA5451179603a107A4563582032Bcb1;
    address public burnFeeReceiver = 0xEBB612Cd86f8Ae8d19B30Fc31CD67618ff7b9611;

    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = false;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Ownable(msg.sender) {
        router = IDEXRouter(routerAdress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        isFeeExempt[_owner] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        isFeeExempt[liquidityFeeReceiver] = true;
        isFeeExempt[developmentFeeReceiver] = true;
        isFeeExempt[stakingFeeReceiver] = true;
        isFeeExempt[burnFeeReceiver] = true;

        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[DEAD] = true;

        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[liquidityFeeReceiver] = true;
        isTxLimitExempt[developmentFeeReceiver] = true;
        isTxLimitExempt[stakingFeeReceiver] = true;
        isTxLimitExempt[burnFeeReceiver] = true;

        isWhitelist[_owner] = true;
        isWhitelist[marketingFeeReceiver] = true;
        isWhitelist[liquidityFeeReceiver] = true;
        isWhitelist[developmentFeeReceiver] = true;
        isWhitelist[stakingFeeReceiver] = true;
        isWhitelist[burnFeeReceiver] = true;

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
        
        if (!swapEnabled && sender == pair && !isWhitelist[recipient]) {
            return false;
        }

        if (!isTxLimitExempt[sender] && (recipient == pair || sender == pair)) {
            require(amount <= _maxTx, "Buy/Sell exceeds the max tx");
        }

        if (recipient != pair && recipient != DEAD) {
            require(isTxLimitExempt[recipient] || _balances[recipient] + amount <= _maxWalletAmount, "Transfer amount exceeds the bag size.");
        }
        
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = (shouldTakeFee(sender) && shouldTakeFee(recipient)) ? takeFee(sender, amount) : amount;
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

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function setFeeExempt(address adr, bool _isFeeExempt) external onlyOwner{
        isFeeExempt[adr] = _isFeeExempt; 
    }
    
    function setWhitelist(address[] memory adr, bool _isWhitelist) external onlyOwner{
        for (uint256 i = 0; i < adr.length; i++) {
            isWhitelist[adr[i]] = _isWhitelist; 
        }
    }

    function setMaxTx(uint256 amountPercent) external onlyOwner {
        require(amountPercent >= 1, "Max tx amount must not be less than 0.1% percent");
        _maxTx = _totalSupply.mul(amountPercent).div(1000);
    }

    function setTxLimitExempt(address adr, bool _isTxLimitExempt) external onlyOwner{
        isTxLimitExempt[adr] = _isTxLimitExempt;
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function enableSwap() external onlyOwner{
        swapEnabled = true;
    }

    function sendTaxToWallets() external onlyOwner {
        require(_balances[address(this)] > 0,"Insufficient Balance");

        uint256 contractTokenBalance = _balances[address(this)];
        uint256 amountToMarketing = contractTokenBalance.mul(marketingFee).div(totalFee);
        uint256 amountToLiquidity = contractTokenBalance.mul(liquidityFee).div(totalFee);
        uint256 amountToDevelopment = contractTokenBalance.mul(developmentFee).div(totalFee);
        uint256 amountToStaking = contractTokenBalance.mul(stakingFee).div(totalFee);
        uint256 amountToBurn = contractTokenBalance.sub(amountToMarketing.add(amountToLiquidity).add(amountToDevelopment).add(amountToStaking));

        _balances[marketingFeeReceiver] = _balances[marketingFeeReceiver].add(amountToMarketing);
        _balances[liquidityFeeReceiver] = _balances[liquidityFeeReceiver].add(amountToLiquidity);
        _balances[developmentFeeReceiver] = _balances[developmentFeeReceiver].add(amountToDevelopment);
        _balances[stakingFeeReceiver] = _balances[stakingFeeReceiver].add(amountToStaking);
        _balances[burnFeeReceiver] = _balances[burnFeeReceiver].add(amountToBurn);
        _balances[address(this)] = 0;
    }

    function clearStuckBalance() external {
        payable(marketingFeeReceiver).transfer(address(this).balance);
    }

    function setWalletLimit(uint256 amountPercent) external onlyOwner {
        require(amountPercent >= 1,"wallet limit mush be not less than 0.1 percent");
        _maxWalletAmount = (_totalSupply * amountPercent ) / 1000;
    }

    function setFee(uint256 _liquidityFee, uint256 _marketingFee, uint256 _developmentFee, uint256 _stakingFee, uint256 _burnFee) external onlyOwner {
         liquidityFee = _liquidityFee; 
         marketingFee = _marketingFee;
         developmentFee = _developmentFee;
         stakingFee = _stakingFee;
         burnFee = _burnFee;
         totalFee = liquidityFee + marketingFee + developmentFee + stakingFee + burnFee;
    }    

    function updateMarketingFeeReceiver(address _address) external onlyOwner {
        marketingFeeReceiver = _address;
    }

    function updateLiquidityFeeReceiver(address _address) external onlyOwner {
        liquidityFeeReceiver = _address;
    }

    function updateDevelopmentFeeReceiver(address _address) external onlyOwner {
        developmentFeeReceiver = _address;
    }

    function updateStakingFeeReceiver(address _address) external onlyOwner {
        stakingFeeReceiver = _address;
    }

    function updateBurnFeeReceiver(address _address) external onlyOwner {
        burnFeeReceiver = _address;
    }
}