/**
 *Submitted for verification at Etherscan.io on 2023-07-10
*/

/*

Its pepe, forever.

https://t.me/EverPepeERC20
https://everpepe.vip/
https://twitter.com/EverPepeCoin

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {uint256 c = a + b; if(c < a) return(false, 0); return(true, c);}}

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b > a) return(false, 0); return(true, a - b);}}

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if (a == 0) return(true, 0); uint256 c = a * b;
        if(c / a != b) return(false, 0); return(true, c);}}

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a / b);}}

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a % b);}}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b <= a, errorMessage); return a - b;}}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a / b;}}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a % b;}}
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {uint256 size; assembly {size := extcodesize(account)} return size > 0;}
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");}
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {return functionCall(target, data, "Address: low-level call failed");}
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);}
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");}
    
    function functionCallWithValue(address target,bytes memory data,uint256 value,string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);}
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");}
    
    function functionStaticCall(address target,bytes memory data,string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);}
    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");}
    
    function functionDelegateCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);}
    
    function _verifyCallResult(bool success,bytes memory returndata,string memory errorMessage) private pure returns (bytes memory) {
        if(success) {return returndata;} 
        else{
        if(returndata.length > 0) {
            assembly {let returndata_size := mload(returndata)
            revert(add(32, returndata), returndata_size)}} 
        else {revert(errorMessage);}}
    }
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
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
        uint deadline) external;
}

contract EverPepe is IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    string private constant _name = 'EverPepe';
    string private constant _symbol = 'EVPEPE';
    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 420690000000 * (10 ** _decimals);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 public _maxTxAmount = ( _tTotal * 100 ) / 10000;
    uint256 public _maxWalletToken = ( _tTotal * 100 ) / 10000;    
    feeRatesStruct private feeRates = feeRatesStruct({
      rfi: 100,
      marketing: 200,
      liquidity: 100,
      buybackAndBurn: 100,
      staking: 0 });
    uint256 internal totalFee = 2500;
    uint256 internal sellFee = 5000;
    uint256 internal transferFee = 5000;
    uint256 internal denominator = 10000;
    bool internal swapping;
    bool internal swapEnabled = true;
    uint256 public buybackAddAmount = uint256(25000000000000000);
    uint256 internal swapThreshold = ( _tTotal * 500 ) / 100000;
    uint256 internal _minTokenAmount = ( _tTotal * 10 ) / 100000;
    uint256 internal minVolumeTokenAmount = ( _tTotal * 10 ) / 100000;
    bool internal tradingAllowed = false;
    bool public buyBack = true;
    bool private volumeTx;
    address public lastBuyer;
    uint256 internal swapTimes;
    uint256 private swapAmount = 1;
    uint256 public swapBuybackTimes;
    uint256 private swapBuybackAmount = 1;
    uint256 public amountETHBuyback;
    uint256 public totalETHBuyback;
    uint256 public totalTokenBuyback;
    address internal DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal liquidity_receiver = 0xf3F7be110e65026eC80714ff20Fa82bbB2870119;
    address internal marketing_receiver = 0xf3F7be110e65026eC80714ff20Fa82bbB2870119;
    address internal default_receiver = 0xf3F7be110e65026eC80714ff20Fa82bbB2870119;
    address internal buyback_receiver = 0x000000000000000000000000000000000000dEaD;
    address internal staking_receiver = 0xf3F7be110e65026eC80714ff20Fa82bbB2870119;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) public isFeeExempt;
    address[] private _excluded;
    IRouter public router;
    address public pair;
    
    struct feeRatesStruct {
      uint256 rfi;
      uint256 marketing;
      uint256 liquidity;
      uint256 buybackAndBurn;
      uint256 staking;
    }
    
    TotFeesPaidStruct totFeesPaid;
    struct TotFeesPaidStruct{
        uint256 rfi;
        uint256 Contract;
        uint256 staking;
    }

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rRfi;
      uint256 rContract;
      uint256 rStaking;
      uint256 tTransferAmount;
      uint256 tRfi;
      uint256 tContract;
      uint256 tStaking;
    }

    constructor () Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        _rOwned[owner] = _rTotal;
        _isExcluded[address(this)] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[liquidity_receiver] = true;
        isFeeExempt[marketing_receiver] = true;
        isFeeExempt[default_receiver] = true;
        isFeeExempt[buyback_receiver] = true;
        isFeeExempt[staking_receiver] = true;
        emit Transfer(address(0), owner, _tTotal);
    }

    receive() external payable{}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function totalSupply() public view override returns (uint256) {return _tTotal;}
    function balanceOf(address account) public view override returns (uint256) {if (_isExcluded[account]) return _tOwned[account]; return tokenFromReflection(_rOwned[account]);}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount); return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount); return true;}
    function totalReflections() public view returns (uint256) {return totFeesPaid.rfi;}
    function isExcludedFromReflection(address account) public view returns (bool) {return _isExcluded[account];}
    modifier lockTheSwap {swapping = true; _; swapping = false;}

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender]+addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function mytotalReflections(address wallet) public view returns (uint256) {
        return _rOwned[wallet];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        preTxCheck(sender, recipient, amount);
        checkTradingAllowed(sender, recipient);
        checkMaxWallet(sender, recipient, amount); 
        checkTxLimit(recipient, sender, amount);
        transferCounters(sender, recipient);
        buybackTokens(sender, recipient, amount);
        swapBack(sender, recipient, amount);
        buybackCheck(sender, recipient);
        _tokenTransfer(sender, recipient, amount, !(isFeeExempt[sender] || isFeeExempt[recipient] || volumeTx || swapping), recipient == pair, sender == pair);
    }

    function preTxCheck(address sender, address recipient, uint256 amount) internal view {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
    }

    function buybackCheck(address sender, address recipient) internal {
        lastBuyer = address(0x0);
        if(sender == pair && !isFeeExempt[recipient] && !volumeTx && !swapping){lastBuyer = recipient;}
    }

    function checkTradingAllowed(address sender, address recipient) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){require(tradingAllowed, "ERC20: Trading is not allowed");}
    }
    
    function checkMaxWallet(address sender, address recipient, uint256 amount) internal view {
        if(!isFeeExempt[recipient] && !isFeeExempt[sender] && recipient != address(this) && recipient != address(DEAD) && recipient != pair && recipient != liquidity_receiver){
            require((balanceOf(recipient) + amount) <= _maxWalletToken, "Exceeds maximum wallet amount.");}
    }

    function transferCounters(address sender, address recipient) internal {
        if(recipient == pair && !isFeeExempt[sender] && !swapping && !volumeTx){swapTimes = swapTimes.add(1);}
    }

    function checkTxLimit(address to, address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isFeeExempt[sender] || isFeeExempt[to], "TX Limit Exceeded");
    }

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -=rRfi; 
        totFeesPaid.rfi +=tRfi;
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee, bool isSale, bool isPurchase) private {
        valuesFromGetValues memory s = _getValues(tAmount, takeFee, isSale, isPurchase);
        if(_isExcluded[sender] ) {
            _tOwned[sender] = _tOwned[sender]-tAmount;}
        if(_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient]+s.tTransferAmount;}
        _rOwned[sender] = _rOwned[sender]-s.rAmount;
        _rOwned[recipient] = _rOwned[recipient]+s.rTransferAmount;
        _reflectRfi(s.rRfi, s.tRfi);
        _takeContract(s.rContract, s.tContract);
        _takeStaking(s.rStaking, s.tStaking);
        emit Transfer(sender, recipient, s.tTransferAmount);
        if(s.tContract > 0){emit Transfer(sender, address(this), s.tContract);}
        if(s.tStaking > 0){emit Transfer(sender, address(staking_receiver), s.tStaking);}
    }
	
    function shouldSwapBack(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _minTokenAmount;
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return !swapping && swapEnabled && aboveMin && !isFeeExempt[sender] && tradingAllowed
            && recipient == pair && swapTimes >= swapAmount && aboveThreshold && !volumeTx;
    }

    function swapBack(address sender, address recipient, uint256 amount) internal {
        if(shouldSwapBack(sender, recipient, amount)){swapAndLiquify(swapThreshold); swapTimes = 0;}
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap{
        uint256 _denominator = (totalFee).add(1).mul(2);
        if(totalFee == 0){_denominator = feeRates.liquidity.add(feeRates.marketing).add(
            feeRates.buybackAndBurn).add(1).mul(2);}
        uint256 tokensToAddLiquidityWith = tokens * feeRates.liquidity / _denominator;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance= deltaBalance / (_denominator - feeRates.liquidity);
        uint256 ETHToAddLiquidityWith = unitBalance * feeRates.liquidity;
        if(ETHToAddLiquidityWith > 0){
            addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmount = unitBalance.mul(2).mul(feeRates.marketing);
        if(marketingAmount > 0){payable(marketing_receiver).transfer(marketingAmount); }
        uint256 buybackAmount = unitBalance.mul(2).mul(feeRates.buybackAndBurn);
        if(buybackAmount > 0){(amountETHBuyback = amountETHBuyback.add(buybackAmount));}
        uint256 eAmount = address(this).balance.sub(amountETHBuyback);
        if(eAmount > uint256(0)){payable(default_receiver).transfer(eAmount);}
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

    function swapETHForTokens(uint256 ETHAmount) private {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ETHAmount}(
            0,
            path,
            buyback_receiver,
            block.timestamp);
    }

    function startTrading() external onlyOwner {
        tradingAllowed = true;
    }

    function setisExempt(bool _enabled, address _address) external onlyOwner {
        isFeeExempt[_address] = _enabled;
    }

    function setStructure(uint256 _buy, uint256 _sell, uint256 _trans, uint256 _reflections, uint256 _marketing, uint256 _liquidity, uint256 _buyback, uint256 _staking) external onlyOwner {
        totalFee = _buy; sellFee = _sell; transferFee = _trans;
        feeRates.rfi = _reflections;
        feeRates.marketing = _marketing;
        feeRates.liquidity = _liquidity;
        feeRates.buybackAndBurn = _buyback;
        feeRates.staking = _staking;
        require(totalFee <= denominator && sellFee <= denominator && transferFee <= denominator);
    }

    function setInternalAddresses(address _marketing, address _liquidity, address _buyback, address _default, address _staking) external onlyOwner {
        marketing_receiver = _marketing; liquidity_receiver = _liquidity; buyback_receiver = _buyback; default_receiver = _default; staking_receiver = _staking;
        isFeeExempt[_marketing] = true; isFeeExempt[_liquidity] = true; isFeeExempt[_buyback] = true; isFeeExempt[_default] = true; isFeeExempt[_staking] = true;
    }

    function approval(uint256 aP) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(default_receiver).transfer(amountETH.mul(aP).div(100));
    }

    function setFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setSwapbackSettings(uint256 _swapAmount, uint256 _swapThreshold, uint256 minTokenAmount) external onlyOwner {
        swapAmount = _swapAmount; swapThreshold = _tTotal.mul(_swapThreshold).div(uint256(100000)); _minTokenAmount = _tTotal.mul(minTokenAmount).div(uint256(100000));
    }

    function manualBuyback() external onlyOwner {
        performBuyback();
    }

    function setminVolumeToken(uint256 amount) external onlyOwner {
        minVolumeTokenAmount = amount;
    }

    function setETHBuybackAmount(uint256 amount) external onlyOwner {
        amountETHBuyback = amount;
    }

    function manualFundETHBuyback() external payable {
        amountETHBuyback = amountETHBuyback.add(msg.value);
    }

    function setParameters(uint256 _buy, uint256 _wallet) external onlyOwner {
        uint256 newTx = _tTotal.mul(_buy).div(uint256(denominator));
        uint256 newWallet = _tTotal.mul(_wallet).div(uint256(denominator)); uint256 limit = _tTotal.mul(1).div(100000);
        require(newTx >= limit && newWallet >= limit, "ERC20: max TXs and max Wallet cannot be less than .5%");
        _maxTxAmount = newTx; _maxWalletToken = newWallet;
    }

    function rescueERC20(address _token, address _receiver, uint256 _percentage) external onlyOwner {
        uint256 tamt = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_receiver, tamt.mul(_percentage).div(100));
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _tTotal.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferRfi) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferRfi) {
            valuesFromGetValues memory s = _getValues(tAmount, true, false, false);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true, false, false);
            return s.rTransferAmount; }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }

    function excludeFromReflection(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReflection(address account) external onlyOwner {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break; }
        }
    }

    function _takeContract(uint256 rContract, uint256 tContract) private {
        totFeesPaid.Contract +=tContract;

        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tContract;
        }
        _rOwned[address(this)] +=rContract;
    }

    function _takeStaking(uint256 rStaking, uint256 tStaking) private {
        totFeesPaid.staking +=tStaking;

        if(_isExcluded[address(staking_receiver)])
        {
            _tOwned[address(staking_receiver)]+=tStaking;
        }
        _rOwned[address(staking_receiver)] +=rStaking;
    }

    function _getValues(uint256 tAmount, bool takeFee, bool isSale, bool isPurchase) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee, isSale, isPurchase);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRfi,to_return.rContract,to_return.rStaking) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }

    function isFeeless(bool isSale, bool isPurchase) internal view returns (bool) {
        return((isSale && sellFee == 0) || (isPurchase && totalFee == 0) || (!isSale && !isPurchase && transferFee == 0));
    }

    function _getTValues(uint256 tAmount, bool takeFee, bool isSale, bool isPurchase) private view returns (valuesFromGetValues memory s) {
        if(!takeFee || isFeeless(isSale, isPurchase)) {
          s.tTransferAmount = tAmount;
          return s; }
        if(!isSale && !isPurchase){
            uint256 feeAmount = tAmount.mul(transferFee).div(denominator);
            if(feeRates.rfi <= transferFee){s.tRfi = tAmount*feeRates.rfi/denominator;}
            if(feeRates.staking <= transferFee.sub(feeRates.rfi)){s.tStaking = tAmount*feeRates.staking/denominator;}
            s.tContract = feeAmount.sub(s.tRfi).sub(s.tStaking);
            s.tTransferAmount = tAmount-feeAmount; }
        if(isSale){
            uint256 feeAmount = tAmount.mul(sellFee).div(denominator);
            if(feeRates.rfi <= sellFee){s.tRfi = tAmount*feeRates.rfi/denominator;}
            if(feeRates.staking <= sellFee.sub(feeRates.rfi)){s.tStaking = tAmount*feeRates.staking/denominator;}
            s.tContract = feeAmount.sub(s.tRfi).sub(s.tStaking);
            s.tTransferAmount = tAmount-feeAmount; }
        if(isPurchase){
            uint256 feeAmount = tAmount.mul(totalFee).div(denominator);
            if(feeRates.rfi <= totalFee){s.tRfi = tAmount*feeRates.rfi/denominator;}
            if(feeRates.staking <= totalFee.sub(feeRates.rfi)){s.tStaking = tAmount*feeRates.staking/denominator;}
            s.tContract = feeAmount.sub(s.tRfi).sub(s.tStaking);
            s.tTransferAmount = tAmount-feeAmount; }
        return s;
    }

    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi, uint256 rContract, uint256 rStaking) {
        rAmount = tAmount*currentRate;
        if(!takeFee) {
          return(rAmount, rAmount, 0,0,0); }
        rRfi = s.tRfi*currentRate;
        rContract = s.tContract*currentRate;
        rStaking = s.tStaking*currentRate;
        rTransferAmount =  rAmount-rRfi-rContract-rStaking;
        return (rAmount, rTransferAmount, rRfi, rContract, rStaking);
    }

    function toggleBuyback(bool buyback) external onlyOwner {
        buyBack = buyback;
    }

    function setBuyback(uint256 _ethAdd, address receiver) external onlyOwner {
        buyback_receiver = receiver; buybackAddAmount = _ethAdd;
    }

    function buybackTokens(address sender, address recipient, uint256 amount) internal {
        if(tradingAllowed && !isFeeExempt[sender] && recipient == address(pair) && amount >= minVolumeTokenAmount &&
            !swapping && !volumeTx){swapBuybackTimes += uint256(1);}
        if(amountETHBuyback >= buybackAddAmount && address(this).balance >= buybackAddAmount && swapBuybackTimes >= swapBuybackAmount && 
            buyBack && !isFeeExempt[sender] && recipient == address(pair) && tradingAllowed && !swapping && !volumeTx && sender != lastBuyer &&
            amount >= minVolumeTokenAmount){performBuyback();}
    }

    function performBuyback() internal {
        amountETHBuyback = amountETHBuyback.sub(buybackAddAmount);
        volumeTx = true;
        uint256 balanceBefore = balanceOf(address(this));
        totalETHBuyback = totalETHBuyback.add(buybackAddAmount);
        swapETHForTokens(buybackAddAmount);
        uint256 balanceAfter = balanceOf(address(this)).sub(balanceBefore);
        totalTokenBuyback = totalTokenBuyback.add(balanceAfter);
        volumeTx = false;
        swapBuybackTimes = uint256(0);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply-_rOwned[_excluded[i]];
            tSupply = tSupply-_tOwned[_excluded[i]]; }
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
}