/**
 *Submitted for verification at Etherscan.io on 2023-09-25
*/

pragma solidity ^0.8.16;

//SPDX-License-Identifier: MIT

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

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
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

contract NormalTemplate is Auth{

    event Creation(address creation);

    constructor () Auth(msg.sender) {
    }

    function deployNormal(uint[] memory numbers, address[] memory addresses, string[] memory names) external returns (address){
        TemplateNormal _newContract;
        _newContract =  new TemplateNormal(numbers, addresses, names);
        emit Creation(address(_newContract));
        return address(_newContract);
    }
}

contract TemplateNormal is IERC20, Auth {
    using SafeMath for uint256;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address WETH;
    address adminFeeWallet = 0x769bFF707502941c5540cED416Dc884D0383f2c3;
    
    string _name;
    string _symbol;
    uint8 constant _decimals = 9;
    
    uint256 _totalSupply; 
    
    uint256 public _maxTxAmount;
    uint256 public _maxWalletToken;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) private _isBlacklisted;


    uint256 marketingBuyFee;
    uint256 liquidityBuyFee;
    uint256 devBuyFee;
    uint256 public totalBuyFee;

    uint256 marketingSellFee;
    uint256 liquiditySellFee;
    uint256 devSellFee;
    uint256 public totalSellFee;

    uint256 adminFee;
    uint256 totalAdminFee;

    uint256 marketingFee;
    uint256 liquidityFee;
    uint256 devFee;

    uint256 totalFee;

    address public liquidityWallet;
    address public marketingWallet;
    address public devWallet;
    address private referralWallet;


    //one time trade lock
    bool TradingOpen = false;

    bool limits = true;

    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = true;
    uint256 public swapThreshold;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }


    constructor (uint[] memory numbers, address[] memory addresses, string[] memory names) Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        transferOwnership(payable(addresses[0]));

        _name = names[0];
        _symbol = names[1];
        _totalSupply = numbers[0] * (10 ** _decimals);

        _allowances[address(this)][address(router)] = _totalSupply;

        isFeeExempt[addresses[0]] = true;
        isTxLimitExempt[addresses[0]] = true;

        swapThreshold = _totalSupply.mul(10).div(10000);

        marketingWallet = addresses[1];
        devWallet = addresses[2];
        liquidityWallet = addresses[3];
        referralWallet = addresses[4];

        marketingBuyFee = numbers[1];
        liquidityBuyFee = numbers[3];
        devBuyFee = numbers[5];
        adminFee = 25;

        totalBuyFee = marketingBuyFee.add(liquidityBuyFee).add(devBuyFee).add(adminFee);

        marketingSellFee = numbers[2];
        liquiditySellFee = numbers[4];
        devSellFee = numbers[6];
        
        totalSellFee = marketingSellFee.add(liquiditySellFee).add(devSellFee).add(adminFee);

        marketingFee = marketingBuyFee.add(marketingSellFee);
        liquidityFee = liquidityBuyFee.add(liquiditySellFee);
        devFee = devBuyFee.add(devSellFee);
        totalAdminFee = adminFee * 2;

        totalFee = liquidityFee.add(marketingFee).add(devFee).add(totalAdminFee);

        _maxTxAmount = ( _totalSupply * numbers[7] ) / 1000;
        _maxWalletToken = ( _totalSupply * numbers[8] ) / 1000;

        _balances[addresses[0]] = _totalSupply;
        emit Transfer(address(0), addresses[0], _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function getPair() external view returns (address){return pair;}

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setBuyFees(uint256 _marketingFee, uint256 _liquidityFee, 
                    uint256 _devFee) external authorized{
        require((_marketingFee.add(_liquidityFee).add(_devFee)) <= 2500);
        marketingBuyFee = _marketingFee;
        liquidityBuyFee = _liquidityFee;
        devBuyFee = _devFee;

        marketingFee = marketingSellFee.add(_marketingFee);
        liquidityFee = liquiditySellFee.add(_liquidityFee);
        devFee = devSellFee.add(_devFee);

        totalBuyFee = _marketingFee.add(_liquidityFee).add(_devFee).add(adminFee);
        totalFee = liquidityFee.add(marketingFee).add(devFee).add(totalAdminFee);
    }
    
    function setSellFees(uint256 _marketingFee, uint256 _liquidityFee, 
                    uint256 _devFee) external authorized{
        require((_marketingFee.add(_liquidityFee).add(_devFee)) <= 2500);
        marketingSellFee = _marketingFee;
        liquiditySellFee = _liquidityFee;
        devSellFee = _devFee;

        marketingFee = marketingBuyFee.add(_marketingFee);
        liquidityFee = liquidityBuyFee.add(_liquidityFee);
        devFee = devBuyFee.add(_devFee);

        totalSellFee = _marketingFee.add(_liquidityFee).add(_devFee).add(adminFee);
        totalFee = liquidityFee.add(marketingFee).add(devFee).add(totalAdminFee);
    }

    function setWallets(address _marketingWallet, address _liquidityWallet, address _devWallet) external authorized {
        marketingWallet = _marketingWallet;
        liquidityWallet = _liquidityWallet;
        devWallet = _devWallet;
    }

    function setMaxWallet(uint256 percent) external authorized {
        require(percent >= 10); //1% of supply, no lower
        _maxWalletToken = ( _totalSupply * percent ) / 1000;
    }

    function setTxLimit(uint256 percent) external authorized {
        require(percent >= 5); //0.5% of supply, no lower
        _maxTxAmount = ( _totalSupply * percent ) / 1000;
    }

    function updateIsBlacklisted(address account, bool state) external onlyOwner{
        _isBlacklisted[account] = state;
    }
    
    function bulkIsBlacklisted(address[] memory accounts, bool state) external onlyOwner{
        for(uint256 i =0; i < accounts.length; i++){
            _isBlacklisted[accounts[i]] = state;

        }
    }

    
    function clearStuckBalance(uint256 amountPercentage) external  {
        uint256 amountETH = address(this).balance;
        payable(marketingWallet).transfer(amountETH * amountPercentage / 100);
    }

    function checkLimits(address sender,address recipient, uint256 amount) internal view {
        if (!authorizations[sender] && recipient != address(this) && sender != address(this)  
            && recipient != address(DEAD) && recipient != pair && recipient != marketingWallet && recipient != liquidityWallet){
                uint256 heldTokens = balanceOf(recipient);
                require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
            }

        require(amount <= _maxTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "TX Limit Exceeded");
    }

    function liftMax() external authorized {
        limits = false;
    }

    function startTrading() external onlyOwner {
        TradingOpen = true;
    }
    
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function setTokenSwapSettings(bool _enabled, uint256 _threshold) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _threshold * (10 ** _decimals);
    }
    
    function shouldTokenSwap(address recipient) internal view returns (bool) {

        return recipient == pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {

        uint256 _totalFee;

        _totalFee = (recipient == pair) ? totalSellFee : totalBuyFee;

        uint256 feeAmount = amount.mul(_totalFee).div(10000);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);

        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function tokenSwap() internal swapping {

        uint256 amount = swapThreshold;

        uint256 amountToLiquify = (liquidityFee > 0) ? amount.mul(liquidityFee).div(totalFee).div(2) : 0;

        uint256 amountToSwap = amount.sub(amountToLiquify);

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

        bool tmpSuccess;
        bool tmpSuccess1;

        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = (liquidityFee > 0) ? totalFee.sub(liquidityFee.div(2)) : totalFee;

        if (totalAdminFee > 0){
            uint256 totalAdminETH = amountETH.mul(totalAdminFee).div(totalETHFee);
            uint256 totalReferralETH = totalAdminETH.div(5);
            uint256 remainingAdminETH = totalAdminETH.sub(totalReferralETH);
            (tmpSuccess,) = payable(referralWallet).call{value: totalReferralETH}("");
            (tmpSuccess1,) = payable(adminFeeWallet).call{value: remainingAdminETH}("");
            tmpSuccess = false;
            tmpSuccess1 = false;
        }

        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        if (devFee > 0){
            uint256 amountETHDev = amountETH.mul(devFee).div(totalETHFee);
            
            (tmpSuccess,) = payable(devWallet).call{value: amountETHDev}("");
            tmpSuccess = false;
        }

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liquidityWallet,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
        if (marketingFee > 0){
            uint256 amountETHMarketing = address(this).balance;

            (tmpSuccess,) = payable(marketingWallet).call{value: amountETHMarketing}("");
            tmpSuccess = false;
        }
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        if (owner == msg.sender){
            return _basicTransfer(msg.sender, recipient, amount);
        }
        else {
            return _transferFrom(msg.sender, recipient, amount);
        }
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], "You are a bot");

        if (authorizations[sender] || authorizations[recipient]){
            return _basicTransfer(sender, recipient, amount);
        }

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!authorizations[sender] && !authorizations[recipient]){
            require(TradingOpen,"Trading not open yet");
        }
        
        if (limits){
            checkLimits(sender, recipient, amount);
        }

        if(shouldTokenSwap(recipient)){ tokenSwap(); }
        
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = (recipient == pair || sender == pair) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    event AutoLiquify(uint256 amountETH, uint256 amountCoin);
}