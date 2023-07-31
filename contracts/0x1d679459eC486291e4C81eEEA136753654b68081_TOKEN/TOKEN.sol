/**
 *Submitted for verification at Etherscan.io on 2023-07-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface IERC20 {
function decimals() external view returns (uint8);
function symbol() external view returns (string memory);
function name() external view returns (string memory);
function totalSupply() external view returns (uint256);
function balanceOf(address account) external view returns (uint256);
function transfer(address recipient, uint256 amount) external returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
function approve(address spender, uint256 amount) external returns (bool);
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISwapPair {
function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
function token0() external view returns (address);
function balanceOf(address account) external view returns (uint256);
function totalSupply() external view returns (uint256);
}


interface ISwapRouter {
function factory() external pure returns (address);
function WETH() external pure returns (address);
function swapExactTokensForETHSupportingFeeOnTransferTokens(
uint amountIn,
uint amountOutMin,
address[] calldata path,
address to,
uint deadline
) external;
}

interface ISwapFactory {
function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Ownable {
address internal _owner;

event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

constructor () {
address msgSender = msg.sender;
_owner = msgSender;
emit OwnershipTransferred(address(0), msgSender);
}

function owner() public view returns (address) {
return _owner;
}

modifier onlyOwner() {
require(_owner == msg.sender, "!owner");
_;
}

function renounceOwnership() public virtual onlyOwner {
emit OwnershipTransferred(_owner, address(0));
_owner = address(0);
}

function transferOwnership(address newOwner) public virtual onlyOwner {
require(newOwner != address(0), "new is 0");
emit OwnershipTransferred(_owner, newOwner);
_owner = newOwner;
}
}

abstract contract AbsToken is IERC20, Ownable {
mapping(address => uint256) private _balances;
mapping(address => mapping(address => uint256)) private _allowances;

address public fundAddress;

string private _name;
string private _symbol;
uint8 private _decimals;

uint256 public walletLimit;
bool public limitEnable = false;

mapping(address => bool) public _isExcludeFromFee;
mapping (address => bool) public isMaxEatExempt;

uint256 private _tTotal;

ISwapRouter public _swapRouter;
address public _weth;
mapping(address => bool) public _swapPairList;

bool private inSwap;

uint256 private constant MAX = ~uint256(0);

uint256 public _buyFundFee = 200;
uint256 public _sellFundFee = 200;

address public _mainPair;

modifier lockTheSwap {
inSwap = true;
_;
inSwap = false;
}

constructor (
address RouterAddress, address USDTAddress,
string memory Name, string memory Symbol, uint8 Decimals, uint256 Supply,
address _Fund, address ReceiveAddress
){
_name = Name;
_symbol = Symbol;
_decimals = Decimals;

ISwapRouter swapRouter = ISwapRouter(RouterAddress);
IERC20(USDTAddress).approve(address(swapRouter), MAX);

_weth = USDTAddress;

_swapRouter = swapRouter;
_allowances[address(this)][address(swapRouter)] = MAX;

ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
address swapPair = swapFactory.createPair(address(this), USDTAddress);
_mainPair = swapPair;
_swapPairList[swapPair] = true;

uint256 total = Supply * 10 ** Decimals;
_tTotal = total;
swapAtAmount = 0;

walletLimit =  (Supply * 10** Decimals) / 10**2;

_balances[ReceiveAddress] = total;

emit Transfer(address(0), ReceiveAddress, total);

fundAddress = _Fund;

_isExcludeFromFee[_Fund] = true;
_isExcludeFromFee[ReceiveAddress] = true;
_isExcludeFromFee[address(this)] = true;
_isExcludeFromFee[address(swapRouter)] = true;
_isExcludeFromFee[msg.sender] = true;

isMaxEatExempt[msg.sender] = true;
isMaxEatExempt[fundAddress] = true;
isMaxEatExempt[ReceiveAddress] = true;
isMaxEatExempt[address(swapRouter)] = true;
isMaxEatExempt[address(_mainPair)] = true;
isMaxEatExempt[address(this)] = true;
isMaxEatExempt[address(0xdead)] = true;
}

function symbol() external view override returns (string memory) {
return _symbol;
}

function name() external view override returns (string memory) {
return _name;
}

function decimals() external view override returns (uint8) {
return _decimals;
}

function totalSupply() public view override returns (uint256) {
return _tTotal;
}

function balanceOf(address account) public view override returns (uint256) {
return _balances[account];
}

function transfer(address recipient, uint256 amount) public override returns (bool) {
_transfer(msg.sender, recipient, amount);
return true;
}

function allowance(address owner, address spender) public view override returns (uint256) {
return _allowances[owner][spender];
}

function approve(address spender, uint256 amount) public override returns (bool) {
_approve(msg.sender, spender, amount);
return true;
}

function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
_transfer(sender, recipient, amount);
if (_allowances[sender][msg.sender] != MAX) {
_allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
}
return true;
}

function _approve(address owner, address spender, uint256 amount) private {
_allowances[owner][spender] = amount;
emit Approval(owner, spender, amount);
}

function setWalletLimit(uint256 _walletLimit) public onlyOwner{
walletLimit = _walletLimit;
}

function setLimitEnable(bool status) public onlyOwner {
limitEnable = status;
}

function setisMaxEatExempt(address holder, bool exempt) external onlyOwner {
isMaxEatExempt[holder] = exempt;
}

uint256 public swapAtAmount;
function setSwapAtAmount(uint256 newValue) public onlyOwner{
swapAtAmount = newValue;
}

function _transfer(
address from,
address to,
uint256 amount
) private {

uint256 balance = balanceOf(from);
require(balance >= amount, "balanceNotEnough");
bool takeFee;
bool isSell;

bool isRemove;
bool isAdd;

if (_swapPairList[to]) {
isAdd = _isAddLiquidity();
}else if(_swapPairList[from]){
isRemove = _isRemoveLiquidity();
}

if (_swapPairList[from] || _swapPairList[to]) {
if (!_isExcludeFromFee[from] && !_isExcludeFromFee[to]) {
if (_swapPairList[to]) {
if (!inSwap && !isAdd) {
uint256 contractTokenBalance = balanceOf(address(this));
if (contractTokenBalance > swapAtAmount) {
uint256 swapFee = _buyFundFee + _sellFundFee ;
uint256 numTokensSellToFund = amount * swapFee / 1000;
if (numTokensSellToFund > contractTokenBalance) {
numTokensSellToFund = contractTokenBalance;
}
swapTokenForFund(numTokensSellToFund, swapFee);
}
}
}
if (!isAdd && !isRemove) takeFee = true; // just swap fee
}
if (_swapPairList[to]) {
isSell = true;
}
}

_tokenTransfer(from, to, amount, takeFee, isSell);

}


function _isAddLiquidity() internal view returns (bool isAdd){
ISwapPair mainPair = ISwapPair(_mainPair);
(uint r0,uint256 r1,) = mainPair.getReserves();

address tokenOther = _weth;
uint256 r;
if (tokenOther < address(this)) {
r = r0;
} else {
r = r1;
}

uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
isAdd = bal > r;
}

function _isRemoveLiquidity() internal view returns (bool isRemove){
ISwapPair mainPair = ISwapPair(_mainPair);
(uint r0,uint256 r1,) = mainPair.getReserves();

address tokenOther = _weth;
uint256 r;
if (tokenOther < address(this)) {
r = r0;
} else {
r = r1;
}

uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
isRemove = r >= bal;
}

function _tokenTransfer(
address sender,
address recipient,
uint256 tAmount,
bool takeFee,
bool isSell
) private {
_balances[sender] = _balances[sender] - tAmount;
uint256 feeAmount;

if (takeFee) {
uint256 swapFee;
if (isSell) {
swapFee = _sellFundFee;
} else {
swapFee = _buyFundFee;
}

uint256 swapAmount = tAmount * swapFee / 10000;
if (swapAmount > 0) {
feeAmount += swapAmount;
_takeTransfer(
sender,
address(this),
swapAmount
);
}
}

if(!isMaxEatExempt[recipient] && limitEnable)
require((balanceOf(recipient) + tAmount - feeAmount) <= walletLimit,"over max wallet limit");
_takeTransfer(sender, recipient, tAmount - feeAmount);
}

event FAILED_SWAP(uint256);
function swapTokenForFund(uint256 tokenAmount, uint256 swapFee) private lockTheSwap {
if (swapFee == 0) return;
address[] memory path = new address[](2);
path[0] = address(this);
path[1] = _weth;
try _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
tokenAmount,
0,
path,
address(fundAddress),
block.timestamp
) {} catch { emit FAILED_SWAP(0); }
}

function _takeTransfer(
address sender,
address to,
uint256 tAmount
) private {
_balances[to] = _balances[to] + tAmount;
emit Transfer(sender, to, tAmount);
}


function setIsExcludeFromFee(address addr, bool enable) external onlyOwner {
_isExcludeFromFee[addr] = enable;
}

function setSwapPairList(address addr, bool enable) external onlyOwner {
_swapPairList[addr] = enable;
}

receive() external payable {}

function multiExcludeFromFee(address[] calldata addresses, bool status) public onlyOwner {
require(addresses.length < 201);
for (uint256 i; i < addresses.length; ++i) {
_isExcludeFromFee[addresses[i]] = status;
}
}
}

contract TOKEN is AbsToken {
constructor() AbsToken(
address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D),
address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2),
"YCC",
"YCC",
9,
500000000000,
address(0xC5E03D7Dd05eb201ACd198A9eECb16afd4A9eC71), //fund 
address(msg.sender) //receiver  
){
}
}