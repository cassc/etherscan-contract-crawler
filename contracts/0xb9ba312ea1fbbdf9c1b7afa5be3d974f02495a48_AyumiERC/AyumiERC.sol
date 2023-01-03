/**
 *Submitted for verification at Etherscan.io on 2023-01-02
*/

/*
Welcome to the mystical world of AYUMI!

The word Ayumi means a beautiful reason ! 

In a world that brings many challenges, only the strongest who embody these characteristics win!

Defined by her courage and strenth, AYUMI is a warrior of the highest regard.

$AYUMI is a token on the Ethereum network. 

We aim to bridge the gap between anime & blockchain by introducing a unique NFT collection. 

Additionally, AYUMI aspires to develop P2E gaming where you are capable of immersing yourself in a newfound, exclusive & far-away world, dueling the best sword fighters internationally.

"There are things you can only share with someone by fighting. For instance, how serious you are." 

Are you ready for the fight of your life?

Website : https://ayumicoin.com
Medium : https://medium.com/@ayumicoinerc20/ayumi-coin-e89c80e4c8be
TG : https://t.me/AyumiPortal
Twitter : https://twitter.com/ayumicoin

*/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

contract AyumiERC is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _blacklisted;
    address private _TeamWallet=0x2C6d1B9b87c172ca23C8F3143620c8E806e874Ef;
    address private _routerAddress=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 private _totalfees=10;
    uint256 private _swapAfter=25;
    uint256 private _Txs=0;

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1e9 * 10**_decimals;
    string private constant _name = unicode"AYUMI";
    string private constant _symbol = unicode"AYUMI";
    uint256 public _maxTxAmount = ((_tTotal*2)/100);
    uint256 public _maxWalletSize = ((_tTotal*2)/100);
    uint256 public _taxSwap=((_tTotal*1)/100);

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private _tradingEnabled;
    uint private _launchBlock;
    uint private _deadblocks = 0;
    bool private swaplock = false;
    bool private swapEnabled = false;

    event RemoveLimitTriggered(bool _status);
    modifier Swapping {
        swaplock = true;
        _;
        swaplock = false;
    }

    constructor () {
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_TeamWallet] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    receive() external payable {}
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
        return _balances[account];
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        uint256 tfees=0;
        if (from != owner() && to != owner()) {
            require(!_blacklisted[from] && !_blacklisted[to]);
            if(!swaplock){
              tfees = amount.mul(_totalfees).div(100);
            }
            if(_launchBlock + _deadblocks >= block.number && _tradingEnabled==true){
                tfees = amount.mul(99).div(100);
            }
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _Txs++;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!swaplock && from != uniswapV2Pair && swapEnabled && contractTokenBalance>_taxSwap && _Txs>_swapAfter) {
                swapTokensForEth(_taxSwap>amount?amount:_taxSwap);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    _distributeTaxes(address(this).balance);
                }
            }
        }

        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(tfees));
        emit Transfer(from, to, amount.sub(tfees));
        if(tfees>0){
          _balances[address(this)]=_balances[address(this)].add(tfees);
          emit Transfer(from, address(this),tfees);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private Swapping {
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

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        emit RemoveLimitTriggered(true);
    }

    function _distributeTaxes(uint256 amount) private {
        payable(_TeamWallet).transfer(amount);
    }

    function _restrictbots(address[] memory addys) public onlyOwner {
        for (uint i = 0; i < addys.length; i++) {
            //avoid bl pair & router 
            if(addys[i] != address(uniswapV2Router) && addys[i] != address(uniswapV2Pair)){
                _blacklisted[addys[i]] = true;
            }
            
        }
    }

    function _unrestrictbots(address[] memory addys) public onlyOwner {
      for (uint i = 0; i < addys.length; i++) {
          _blacklisted[addys[i]] = false;
      }
    }

    function ActivateMarket() external onlyOwner() {
        require(!_tradingEnabled,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(_routerAddress);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        _launchBlock = block.number;
        _tradingEnabled = true;
        swapEnabled = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function _reducefees(uint256 _newfees) external onlyOwner{
        require(_newfees < _totalfees,"Fees can't go up");
        _totalfees=_newfees;
    }
    function _forceswapback() external onlyOwner{
        //avoid nuking lp set swap to max swapAmount
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance>_taxSwap?_taxSwap:contractBalance);
    }
    function _WithdrawETH() external onlyOwner{
        _distributeTaxes(address(this).balance);
    }
    function _WithdrawERC(uint256 amount) external onlyOwner{
        if (amount == 0 || amount > balanceOf(address(this))) {
            amount = balanceOf(address(this));
        }
        _transfer(address(this),owner(),amount);       
    }
    function _setTeamWallet(address _new_addy) external onlyOwner{
        _TeamWallet=_new_addy;
        _isExcludedFromFee[_new_addy] = true;
    }
    function _ssb(uint _n) external onlyOwner{
        require(_tradingEnabled==false,"Trading already enabled");
        _deadblocks=_n;
    }
}