/**
 *Submitted for verification at Etherscan.io on 2023-08-06
*/

// SPDX-License-Identifier: UNLICENSED
/**
 * 
 * Website : https://joyboytoken.com
 * Portal : https://t.me/JoyBoyErcPortal
 * Twitter : https://twitter.com/JoyBoyErcToken
 * Medium : https://medium.com/@JoyBoyErc
 * 
 **/

pragma solidity 0.8.21;

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

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract ERC20JOYBOY is ERC20, Auth {
    using SafeMath for uint256;

    address immutable WETH;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    string public constant name = "Joy Boy";
    string public constant symbol = unicode'ジョイボーイ';
    uint8 public constant decimals = 18;

    uint256 public constant totalSupply = 100 * 10**9 * 10**decimals;

    uint256 public _maxWalletToken = totalSupply / 50;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isWalletLimitExempt;

    uint256 public marketingFee = 2;
    uint256 public operationsFee = 1;
    uint256 public totalFee = marketingFee + operationsFee;
    uint256 public constant feeDenominator = 100;
    
    uint256 buyMultiplier = 800;
    uint256 sellMultiplier = 800;
    uint256 transferMultiplier = 3000;

    address public marketingFeeReceiver;
    address public operationsFeeReceiver;

    IDEXRouter public router;
    address public immutable pair;

    bool public tradingOpen = false;

    bool public swapEnabled = false;
    uint256 swapThreshold = totalSupply / 200;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();

        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        marketingFeeReceiver = 0x5268Cd26c117f0186b1A30027c79Fa2ffB40BDF0;
        operationsFeeReceiver = 0x16720008Af0e1b1Be314bDd9522FD29Edd7eC625;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[marketingFeeReceiver] = true;

        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[DEAD] = true;
        isWalletLimitExempt[marketingFeeReceiver] = true;

        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    receive() external payable { }

    function getOwner() external view override returns (address) { return owner; }
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

    function setMaxWallet(uint256 maxWallet) external onlyOwner {
        require(maxWallet >= 2,"Cannot set max wallet less than 2%");
        _maxWalletToken = (totalSupply * maxWallet ) / 100;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){
            require(tradingOpen,"trading not open yet");
        }

        if (!isWalletLimitExempt[sender] && !isWalletLimitExempt[recipient] && recipient != pair) {
            require((balanceOf[recipient] + amount) <= _maxWalletToken,"max wallet limit reached");
        }

        if(shouldSwapBack()){ swapBack(); }

        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = (isFeeExempt[sender] || isFeeExempt[recipient]) ? amount : takeFee(sender, amount, recipient);

        balanceOf[recipient] = balanceOf[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, uint256 amount, address recipient) internal returns (uint256) {
        if(amount == 0 || totalFee == 0){
            return amount;
        }

        uint256 multiplier = transferMultiplier;

        if(recipient == pair) {
            multiplier = sellMultiplier;
        } else if(sender == pair) {
            multiplier = buyMultiplier;
        }

        uint256 feeAmount = amount.mul(totalFee).mul(multiplier).div(feeDenominator * 100);

        if(feeAmount > 0){
            balanceOf[address(this)] = balanceOf[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && balanceOf[address(this)] >= swapThreshold;
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountETH = address(this).balance;
        uint256 amountToClear = ( amountETH * amountPercentage ) / 100;
        payable(msg.sender).transfer(amountToClear);
    }

    function clearStuckToken(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success) {
        if(tokens == 0){
            tokens = ERC20(tokenAddress).balanceOf(address(this));
        }

        return ERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function takeitlive() external onlyOwner {
        tradingOpen = true;
        swapEnabled = true;
    }

    function removeLimits() external onlyOwner {
        swapThreshold = totalSupply / 500;
        swapEnabled = true;
        _maxWalletToken = totalSupply;
        operationsFee = 1;
        marketingFee = 2;
        totalFee = 3;
        buyMultiplier = 100;
        sellMultiplier = 100;
        transferMultiplier = 0;
    }

    function swapBack() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapThreshold,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;

        uint256 amountETHMarketing = (amountETH * marketingFee) / totalFee;
        uint256 amountETHOperations = (amountETH * operationsFee) / totalFee;

        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountETHMarketing}("");
        (tmpSuccess,) = payable(operationsFeeReceiver).call{value: amountETHOperations}("");
    }

    function update_fees() view internal {
        require(totalFee.mul(buyMultiplier).div(100) <= 5, "Buy tax cannot be more than 10%");
        require(totalFee.mul(sellMultiplier).div(100) <= 5, "Sell tax cannot be more than 10%");
        require(totalFee.mul(transferMultiplier).div(100) <= 5, "Transfer tax cannot be more than 10%");
    }

    function setMultipliers(uint256 _buy, uint256 _sell, uint256 _trans) external onlyOwner {
        sellMultiplier = _sell;
        buyMultiplier = _buy;
        transferMultiplier = _trans;
        update_fees();
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (totalSupply - balanceOf[DEAD] - balanceOf[ZERO]);
    }
}