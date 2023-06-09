/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
/*.

Bring it on! SEC has charged Binance and CZ in its latest lawsuit. Who wins? 

    https://twitter.com/GaryGensler/status/1665815051846950917?s=20
    https://t.me/CZvsSECETH
/*. */
abstract contract Context 
{
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }


    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }


    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }


    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }


    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


interface IUniswapV2Factory 
{
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}



interface IUniswapV2Pair {
    function factory() external view returns (address);
}


interface IUniswapV2Router01 
{
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}


interface IUniswapV2Router02 is IUniswapV2Router01 
{
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}



contract CZvsSEC is Context, IERC20, Ownable 
{
      using SafeMath for uint256;
      event SwapTokensForETH(uint256 amountIn, address[] path);
      event SwapAndLiquifyEnabledUpdated(bool enabled);
      event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

      bool inSwapAndLiquify;
      bool public swapAndLiquifyEnabled = true;
   
      modifier lockTheSwap 
      {
         inSwapAndLiquify = true;
         _;
         inSwapAndLiquify = false;
      }

      mapping (address => uint256) private _balances;
      mapping (address => mapping (address => uint256)) private _allowances;
      mapping (address => bool) private _isExcludedFromFee;
      mapping (address => bool) private _isExcludedFromWhale;

      uint256 private _totalSupply;

      string private _name;
      string private _symbol;
      uint8 private _decimals;
      address payable public marketingAddress; 
      IUniswapV2Router02 public immutable uniswapV2Router;
      address public uniswapV2Pair;
      uint256 public marketingFee;
      uint256 public minimumTokensBeforeSwap;
    
     

    constructor() 
    { 
      _name = "CZvsSEC";
      _symbol = "$CZSEC";
      _decimals = 18;

      _mint(msg.sender, 1000_000_000 * 10**18);

      IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
      uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
      .createPair(address(this), _uniswapV2Router.WETH());
      uniswapV2Router = _uniswapV2Router;  
      minimumTokensBeforeSwap = totalSupply().div(100000);  


      marketingFee = 20;

      _isExcludedFromFee[owner()] = true;
      _isExcludedFromFee[address(this)] = true;

      _isExcludedFromWhale[owner()]=true;
      _isExcludedFromWhale[address(this)]=true;
      _isExcludedFromWhale[address(0)]=true;
      _isExcludedFromWhale[uniswapV2Pair]=true;
      
      marketingAddress = payable(0xb80c6B74aa77a314249c88DD21EE49496AD88cFd);

    }



   


    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transferTokens(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transferTokens(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }



   function setFeeRate(uint256 _marketingFee) external onlyOwner
   {
      marketingFee = _marketingFee;
      require(marketingFee<=20, "Too High Fee");
   }



    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap 
    {
        swapTokensForEth(contractTokenBalance); 
    }


    function swapTokensForEth(uint256 tokenAmount) private 
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            marketingAddress, 
            block.timestamp
        );
        emit SwapTokensForETH(tokenAmount, path);
    }





    function _transferTokens(address from, address to, uint256 amount) internal virtual 
    {
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
        if (!inSwapAndLiquify && swapAndLiquifyEnabled && from != uniswapV2Pair && balanceOf(uniswapV2Pair)>100000) 
        {
            if (overMinimumTokenBalance) 
            {
                contractTokenBalance = minimumTokensBeforeSwap;
                swapAndLiquify(contractTokenBalance);
            }
        }


         if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to])
         {
            uint256 _feeTokens = amount.div(100).mul(marketingFee);
            _transfer(from, address(this), _feeTokens);
            amount = amount.sub(_feeTokens);
         }
         
         _transfer(from, to, amount);

    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual 
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);

    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }



    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function setExcludedFromWhale(address account, bool _enabled) public onlyOwner 
    {
        _isExcludedFromWhale[account] = _enabled;
    } 


    function setMinimumTokensBeforeSwap(uint256 _minimumTokensBeforeSwap) external onlyOwner() 
    {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner 
    {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }


    function setMarketingAddress(address _marketingAddress) external onlyOwner() 
    {
        marketingAddress = payable(_marketingAddress);
    }

   receive() external payable {}

}