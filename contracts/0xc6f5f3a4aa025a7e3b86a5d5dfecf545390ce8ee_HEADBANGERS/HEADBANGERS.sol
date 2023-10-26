/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

/*
1% RFI
6% Marketing
2% Auto LP

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeRouter02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

abstract contract IBEP20Extented is IBEP20 {
    function decimals() external view virtual returns (uint8);
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
}

contract HEADBANGERS is Context, IBEP20, IBEP20Extented, Ownable {
    using SafeMath for uint256;
    
    string private constant _name = "Headbangers Club";
    string private constant _symbol = "Headbangers";
    uint8 private constant _decimals = 18;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 6_666_666_666 * 10 ** 18; // 6.66 bn tokens
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    // fees wrt to tax percentage 
    uint256 public _rfiFee = 1; // divided by 100
    uint256 private _previousRfiFee = _rfiFee;
    uint256 public _marketingFee = 6; // divided by 100
    uint256 private _previousMarketingFee = _marketingFee;
    uint256 public _liquidityFee = 2; // divided by 100
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 public totalFee = _liquidityFee + _marketingFee + _rfiFee;
    
    uint256 public _minTokenBeforeSwap = 10**4 * 10**18;

    address public marketingFeeReceiver = (0x98dA2c88A9b9da871038ab4a90237F83E1b2a760);
    IPancakeRouter02 private pancakeRouter;
    address public pancakePair;
    uint256 public _maxTxAmount = _tTotal; // 100%
    bool private inSwap = false;
    bool public swapAndLiquifyEnabled = false;

    event FeesUpdated(uint256 _rfiFee, uint256 _marketingFee, uint256 _liquidityFee);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor() {
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //bsc test 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);//bsc main net 0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pancakeRouter = _pancakeRouter;
        _approve(address(this), address(pancakeRouter), _tTotal);
        pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        IBEP20(pancakePair).approve(address(pancakeRouter),type(uint256).max);

        _rOwned[_msgSender()] = _rTotal;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() override external pure returns (string memory) {
        return _name;
    }

    function symbol() override external pure returns (string memory) {
        return _symbol;
    }

    function decimals() override external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
            return tokenFromReflection(_rOwned[account]);
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"BEP20: transfer amount exceeds allowance"));
        return true;
    }
    
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function isExcludeFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function setExcludeFromFee(address account, bool excluded) external onlyOwner() {
        _isExcludedFromFee[account] = excluded;
    }

    function setSwapAndLiquifyEnabled(bool enable) external onlyOwner() {
        swapAndLiquifyEnabled = enable;
    }

    function updateMinTokenBeforeSwap(uint256 minTokenBeforeSwap) external onlyOwner {
        _minTokenBeforeSwap = minTokenBeforeSwap;
    }

    function updateMaxTxAmount(uint256 newMaxTxAmount) external onlyOwner {
        require(newMaxTxAmount >= _tTotal.div(1000),"Max tx amount could not be less than 0.1% total supply");
        _maxTxAmount = newMaxTxAmount;
    }
    
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || _isExcludedFromFee[sender], "TX Limit Exceeded");
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }
    
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    
    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _rOwned[account] = _tOwned[account].mul(_getRate());
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function removeAllFee() private {
        if (_marketingFee == 0 && _liquidityFee == 0 && _rfiFee == 0) return;
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousRfiFee = _rfiFee;
        
        _marketingFee = 0;
        _liquidityFee = 0;
        _rfiFee = 0;
    }

    function restoreAllFee() private {
        _marketingFee = _previousMarketingFee;
        _liquidityFee = _previousLiquidityFee;
        _rfiFee = _previousRfiFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;

            
        if (!inSwap && swapAndLiquifyEnabled && from != pancakePair) { //sells, transfers
            uint256 contractTokenBalance = balanceOf(address(this));
            if (contractTokenBalance > _minTokenBeforeSwap) {
                swapAndLiquify(contractTokenBalance);
            }
        }
        
        checkTxLimit(from, amount);

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 tokenAmount) private lockTheSwap {
        uint256 amountToLiquify = tokenAmount.mul(_liquidityFee).div(_liquidityFee.add(_marketingFee)).div(2);
        uint256 amountToSwap = tokenAmount.sub(amountToLiquify);
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        uint256 balanceBefore = address(this).balance;

        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        uint256 totalBNBFee = _liquidityFee.add(_marketingFee).sub(_liquidityFee.div(2));

        uint256 amountBNBLiquidity = amountBNB.mul(_liquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBMarketing = amountBNB.mul(_marketingFee).div(totalBNBFee);

        (bool success,) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        require(success, "BNB transfer to marketingFeeReceiver failed");

        pancakeRouter.addLiquidityETH{value: amountBNBLiquidity}(
            address(this),
            amountToLiquify,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function clearStuckBalance(uint256 amountPercentage) external {
        require(msg.sender == marketingFeeReceiver, "Not authorized!");
        uint256 amountBNB = address(this).balance;
        payable(marketingFeeReceiver).transfer(amountBNB * amountPercentage / 100);
    }


    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) { 
                removeAllFee();
        }
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTax) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTax);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTax) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTax);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTax) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTax);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTax) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTax);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _takeTeam(uint256 tTax) private {
        uint256 currentRate =  _getRate();
        uint256 rTax = tTax.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTax);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tTax);
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    


    receive() external payable {}

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 taxFee = _marketingFee.add(_liquidityFee);
        (uint256 tTransferAmount, uint256 tRfi, uint256 tTax) = _getTValues(tAmount, _rfiFee, taxFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi) = _getRValues(tAmount, tRfi, tTax, currentRate);
        return (rAmount, rTransferAmount, rRfi, tTransferAmount, tRfi, tTax);
    }

    function _getTValues(uint256 tAmount, uint256 rfiFee, uint256 taxFee) private pure returns (uint256, uint256, uint256) {
        uint256 tRfi = tAmount.mul(rfiFee).div(100);
        uint256 tTax = tAmount.mul(taxFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tRfi).sub(tTax);
        return (tTransferAmount, tRfi, tTax);
    }


    function _getRValues(uint256 tAmount, uint256 tRfi, uint256 tTax, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rRfi = tRfi.mul(currentRate);
        uint256 rTax = tTax.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rRfi).sub(rTax);
        return (rAmount, rTransferAmount, rRfi);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function setTaxes(uint256 marketingFee, uint256 liquidityFee, uint256 rfiFee) external onlyOwner() {
        uint256 newTotalFee = marketingFee.add(liquidityFee).add(rfiFee);
        require(newTotalFee < 15, "Sum of fees must be less than 15");

        _marketingFee = marketingFee;
        _liquidityFee = liquidityFee;
        _rfiFee = rfiFee;
        
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousRfiFee = _rfiFee;
        
        totalFee = _marketingFee.add(_liquidityFee).add(_rfiFee);
        
        emit FeesUpdated(_rfiFee, _marketingFee, _liquidityFee);
    }
    
    function updateMarketingFeeReceiver(address newMarketingFeeReceiver) external onlyOwner() {
        marketingFeeReceiver = newMarketingFeeReceiver;
    }

}