/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

/**

🌀 $CYCLONE 🌀
Cyclone is a super-deflationary project on Ethereum Chain that will integrate multiple dApps to reward holders based on the luck factor.

The dApps we plan to implement with $CYCLONE, will greatly help with making the project deflationary, since they will have integrated burning systems in place.

Benefits of $CYCLONE:
- deflationary
- anti sniper mechanism
- sliding tax mechanism

SLIDING TAX MECHANISM:

Starting tax: 10%
tax decreasing 1% every 15 minutes
Final tax: 4%

For fair launch follow us on:
https://twitter.com/Cycloneeth
https://t.me/cycloneeth

*/

pragma solidity ^0.8.15;
// SPDX-License-Identifier: UNLICENSED
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
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
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}  

interface IUniswapV2Factory {
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

contract Cyclone is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    mapping (address => uint) private cooldown;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1 * 10**9 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    struct Taxes {
        uint256 buyFee1;
        uint256 buyFee2;
        uint256 sellFee1;
        uint256 sellFee2;
    }

    Taxes private _taxes = Taxes(0,17,0,17);
    uint256 private initialTotalBuyFee = _taxes.buyFee1 + _taxes.buyFee2;
    uint256 private initialTotalSellFee = _taxes.sellFee1 + _taxes.sellFee2;
    address payable private _feeAddrWallet;
    uint256 private _feeRate = 20;

    uint256 private decreasingTaxFrequency = 15 minutes;
    uint256 private lastDecreasingTaxTime;
    
    string private constant _name = "Cyclone";
    string private constant _symbol = "CYCLONE";
    uint8 private constant _decimals = 9;
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    uint256 launchedAt;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    bool private _isBuy = false;
    uint256 private _maxTxAmount = _tTotal;
    uint256 private _maxWalletSize = _tTotal;
    event MaxTxAmountUpdated(uint _maxTxAmount);
    event TaxChange(uint _tax);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _feeAddrWallet = payable(0x5FC02DB25483a9b4eA5EFfBe36D5ae6cF6004f60);
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_feeAddrWallet] = true;
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
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

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        cooldownEnabled = onoff;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(amount > 0, "Amount cannot be zero.");
        _isBuy = true;

        if (from != owner() && to != owner()) {

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] && cooldownEnabled) {
                // buy
                require(amount <= _maxTxAmount, "Max transaction exceeded.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Max wallet exceeded.");
            }

            if (from != address(uniswapV2Router) && ! _isExcludedFromFee[from] && to == uniswapV2Pair){
                require(!bots[from] && !bots[to]);
                _isBuy = false;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > balanceOf(uniswapV2Pair).mul(_feeRate).div(100)) {
                contractTokenBalance = balanceOf(uniswapV2Pair).mul(_feeRate).div(100);
            }

            if (!inSwap && from != uniswapV2Pair && swapEnabled) {
                require(block.number >= (launchedAt + 6), "Anti sniper mechanism");
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
                if (_taxes.buyFee2 == 17 || _taxes.sellFee2 == 17) {
                    _taxes.buyFee2 = 10;
                    _taxes.sellFee2 = 10;
                    lastDecreasingTaxTime = block.timestamp;
                    emit TaxChange(_taxes.buyFee2);
                }
            }

            if (_taxes.buyFee2 != 17 && _taxes.buyFee2 > 4 && block.timestamp >= lastDecreasingTaxTime + decreasingTaxFrequency) {
                _taxes.buyFee2 = _taxes.buyFee2.sub(1);
                _taxes.sellFee2 = _taxes.sellFee2.sub(1);
                lastDecreasingTaxTime = block.timestamp;
                emit TaxChange(_taxes.buyFee2);
            }
        }

        _tokenTransfer(from,to,amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp + 60
        );
    }

    function getIsBuy() private view returns (bool){
        return _isBuy;
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
    }

    function getCurrentFees() public view returns (uint256, uint256, uint256, uint256) {
        return (_taxes.buyFee1, _taxes.buyFee2, _taxes.sellFee1, _taxes.sellFee2);
    }

    function adjustFees(uint256 buyFee1, uint256 buyFee2, uint256 sellFee1, uint256 sellFee2) external onlyOwner {
        require(buyFee1 + buyFee2 <= initialTotalBuyFee);
        require(sellFee1 + sellFee2 <= initialTotalSellFee);
        _taxes.buyFee1 = buyFee1;
        _taxes.buyFee2 = buyFee2;
        _taxes.sellFee1 = sellFee1;
        _taxes.sellFee2 = sellFee2;
    }

    function changeMaxTxAmount(uint256 percentage) external onlyOwner{
        require(percentage>0);
        _maxTxAmount = _tTotal.mul(percentage).div(100);
    }

    function changeMaxWalletSize(uint256 percentage) external onlyOwner{
        require(percentage>0);
        _maxWalletSize = _tTotal.mul(percentage).div(100);
    }

    function setFeeRate(uint256 rate) external onlyOwner() {
        require(rate<=49);
        _feeRate = rate;
    }
        
    function sendETHToFee(uint256 amount) private {
        _feeAddrWallet.transfer(amount);
    }  

    function openTrading() external onlyOwner() {
        require(!tradingOpen, "Trading already open.");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        cooldownEnabled = true;
        _maxTxAmount = _tTotal.mul(3).div(100);
        _maxWalletSize = _tTotal.mul(3).div(100);
        tradingOpen = true;
        launchedAt = block.number;
        lastDecreasingTaxTime = block.timestamp;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }
    
    function addBot(address[] memory _bots) public onlyOwner {
        for (uint i = 0; i < _bots.length; i++) {
            if (_bots[i] != address(this) && _bots[i] != uniswapV2Pair && _bots[i] != address(uniswapV2Router)){
                bots[_bots[i]] = true;
            }
        }
    }
    
    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        _transferStandard(sender, recipient, amount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate =  _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}
    
    function manualswap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = getIsBuy() ? _getTValues(tAmount, _taxes.buyFee1, _taxes.buyFee2) : _getTValues(tAmount, _taxes.sellFee1, _taxes.sellFee2);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 TeamFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tTeam = tAmount.mul(TeamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

	function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
}