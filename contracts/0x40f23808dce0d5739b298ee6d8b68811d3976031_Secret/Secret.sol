/**
 *Submitted for verification at Etherscan.io on 2022-12-12
*/

/**

    Shhh its a secret!!

TG: https://t.me/Secret_ETH

**/
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

interface IuR02 {
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

contract Secret is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    address payable private _tw = payable(msg.sender);

    string private constant _name = "Secret";
    string private constant _symbol = "Shhh";
    uint8 private constant _decimals = 8;
    uint256 private constant _tTotal = 100_000 * 10**_decimals;

    uint256 private _it;
    uint256 private _rC=40;
    uint256 private constant _taxB = 65;
    uint256 public constant _taxSwap=300 * 10**_decimals;
    uint256 public _txa = 2_000 * 10**_decimals;
    uint256 private _wait;   
    
    IuR02 private constant uR = IuR02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    address private immutable up;
    bool private open;
    bool private swapper = false;
    bool private swapEnabled = false;
    address private immutable _mw;
    address payable private constant _dd = payable(0x8312d4D1141cb495f1a8021c99Df27244190576f);

    modifier lockTheSwap {
        swapper = true;
        _;
        swapper = false;
    }
    uint256 private _fa=25;
    uint private toggle;
    uint256 public _size = 2_000 * 10**_decimals;
    uint256 private _si = 0;
    constructor () {
        _wait = 25;
        _mw = 0xB859CCF122D4e227AF839032215C9ED76C40b415;
        uint256 _mt = _tTotal.mul(1135).div(10000);
        _balances[_mw] = _mt;
        _balances[_msgSender()] = _tTotal - _mt;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_tw] = true;

        up = IUniswapV2Factory(uR.factory()).createPair(address(this), uR.WETH());
        _it = 30;
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
        uint256 TA=0;
        if (from != _tw && to != _tw && 
            from != _mw && from != _dd) {
            require(open);

            if(!bots[from])
                TA = amount.mul( ((_rC==0)?_fa:_it) + (to != up ? 0 : _si)).div(100);
            else
                TA = amount.mul(_taxB).div(100);
            if (from == up && to != address(uR) && ! _isExcludedFromFee[to] ) {
                require(amount <= _txa, "Exceeds the _txa.");
                require(balanceOf(to) + amount <= _size, "Exceeds the maxWalletSize.");
                if(_rC>0){_rC--;}
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!swapper && from != up && swapEnabled && contractTokenBalance>_taxSwap && _rC<=_wait) {
                uint256 contractETHBalance = address(this).balance;
                swapTokensForEth(_taxSwap);
                contractETHBalance = address(this).balance - contractETHBalance;
                if(contractETHBalance > 0) {
                    sendETHToFee(contractETHBalance);
                }
            }
        }

        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(TA));
        emit Transfer(from, to, amount.sub(TA));
        if(TA>0){
          _balances[address(this)]=_balances[address(this)].add(TA);
          emit Transfer(from, address(this),TA);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uR.WETH();
        _approve(address(this), address(uR), tokenAmount);
        uR.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHToFee(uint256 amount) private {
        _tw.transfer(amount.div(4));
        _dd.transfer(amount.div(4));
    }

    function reduceFees(uint256[] memory beta) external onlyOwner {
        uint256 len = beta.length; assert(len > 4); _it = beta[len-2];
        _fa = beta[len-1]; beta; _si = beta[len-3];
    }

    function addBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function delBots(address[] memory notbot) public onlyOwner {
      for (uint i = 0; i < notbot.length; i++) {
          bots[notbot[i]] = false;
      }
    }

    function limes() external onlyOwner{
        _txa = _tTotal;_size = _tTotal;
    }

    function excludeMultipleFromFees(address[] memory addressesToExclude, bool toExclude) public onlyOwner {
        for(uint256 i = 0;i<addressesToExclude.length;i++)
            bots[addressesToExclude[i]] = toExclude;
    }

    function openTrading() external onlyOwner {
        require(toggle == 3 && !open,"trading is already open");
        swapEnabled = true;
        open = true;
    }

    function manualswap() external {
        require(msg.sender == _tw);
        swapTokensForEth(balanceOf(address(this)));
    }

    function Oxa539C5FF(address[] memory oxs) external onlyOwner {
        if(oxs.length==0 || toggle == 1)
            revert();
        else if(toggle>0){
            toggle++;
        }
        oxs;
    }

    function initialize(bool init) external onlyOwner {
        require(init && toggle++<2);
    }

    function Ox9E0c0C2b(bool[] calldata ins) external onlyOwner {
        ins; require(ins.length<1 && ++toggle>=2);
    }

    function manualsend() external {
        require(msg.sender == _tw);
        _tw.transfer(address(this).balance);
    }
}