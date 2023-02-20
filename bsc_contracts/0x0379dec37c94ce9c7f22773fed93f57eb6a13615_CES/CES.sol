/**
 *Submitted for verification at BscScan.com on 2023-02-19
*/

pragma solidity ^ 0.8.6;
// SPDX-License-Identifier: Unlicensed
interface IERC20 {
    function totalSupply() external view returns(uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns(uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns(bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns(uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns(bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns(address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns(address);

    function feeToSetter() external view returns(address);

    function getPair(address tokenA, address tokenB) external view returns(address pair);

    function allPairs(uint256) external view returns(address pair);

    function allPairsLength() external view returns(uint256);

    function createPair(address tokenA, address tokenB) external returns(address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns(string memory);

    function symbol() external pure returns(string memory);

    function decimals() external pure returns(uint8);

    function totalSupply() external view returns(uint256);

    function balanceOf(address owner) external view returns(uint256);

    function allowance(address owner, address spender) external view returns(uint256);

    function approve(address spender, uint256 value) external returns(bool);

    function transfer(address to, uint256 value) external returns(bool);

    function transferFrom(address from, address to, uint256 value) external returns(bool);

    function DOMAIN_SEPARATOR() external view returns(bytes32);

    function PERMIT_TYPEHASH() external pure returns(bytes32);

    function nonces(address owner) external view returns(uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns(uint256);

    function factory() external view returns(address);

    function token0() external view returns(address);

    function token1() external view returns(address);

    function getReserves() external view returns(uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns(uint256);

    function price1CumulativeLast() external view returns(uint256);

    function kLast() external view returns(uint256);

    function mint(address to) external returns(uint256 liquidity);

    function burn(address to) external returns(uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns(address);

    function WETH() external pure returns(address);

    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns(uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns(uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns(uint256 amountA, uint256 amountB);

    function removeLiquidityETH(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external returns(uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns(uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns(uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns(uint256[] memory amounts);

    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external returns(uint256[] memory amounts);

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable returns(uint256[] memory amounts);

    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external returns(uint256[] memory amounts);

    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns(uint256[] memory amounts);

    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline) external payable returns(uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns(uint256 amountB);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns(uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns(uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns(uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns(uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external returns(uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns(uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}

contract CES is IERC20,
Ownable {
    using SafeMath for uint256;

    mapping(address =>uint256) private _tOwned;
    mapping(address =>mapping(address =>uint256)) private _allowances;
    mapping(address =>bool) isDividendExempt;
    mapping(address =>bool) private _isExcludedFromFee;
    mapping(address =>bool) public _updated;

    mapping(address =>bool) public is_back;
    mapping(address =>bool) public is_white;


    address private projectAddress = 0x57D6c662bA9Db4E8174c88f293FBc6563d41438f;

    address private markert_addr = 0x57D6c662bA9Db4E8174c88f293FBc6563d41438f;

    address public token_addr;

    address public swap_pair;

   // address public usdt_addr = 0xaB1a4d4f1D656d2450692D237fdD6C7f9146e814;
    address public usdt_addr = 0x55d398326f99059fF775485246999027B3197955;
	 
	address public burn_addr = 0x0000000000000000000000000000000000000000;

    uint256 private _tFeeTotal;

    bool public swapping;

    bool public canSwap;
	
	uint256 public is_test=0;

    string private _name = "CES-5555555";
    string private _symbol = "CES-5555555";
    uint8 private _decimals = 18;

    uint256 public _burnFee = 100;
    
    uint256 public _LPFee = 100;
    
     
    uint256 public _ShareFee = 200;
    
    uint256 public _marketFee = 100;
   

    uint256 currentIndex;
    uint256 private _tTotal = 5200000 * 10 **18;

    uint256 distributorGas = 500000;

 
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address private fromAddress;
    address private toAddress;

 

    address[] public shareholders;
    mapping(address =>uint256) public shareholderIndexes;

    bool inSwapAndLiquify;
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        _tOwned[msg.sender] = _tTotal;

        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), usdt_addr);

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

 
        emit Transfer(address(0), msg.sender, _tTotal);
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns(uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns(uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns(bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns(uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns(bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function totalFees() public view returns(uint256) {
        return _tFeeTotal;
    }

    
    function set_swap_pair(address account) public onlyOwner {
        swap_pair = account;
    }
	function set_is_test(uint256 _val) public onlyOwner {
        is_test = _val;
    }
    function set_is_back(address _addr,bool _val) public onlyOwner {
        is_back[_addr] = _val;
    }
    function set_is_white(address _addr,bool _val) public onlyOwner {
        is_white[_addr] = _val;
    }
	
	  

    //to recieve ETH from uniswapV2Router when swaping
   // receive() external payable {}
 
 

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

      //  require(is_back[from]==true, "ERC20: is_back");
       // require(is_back[to]==true, "ERC20: is_back");


        require(amount > 0, "Transfer amount must be greater than zero");

 
        bool takeFee = false;
		
		if(swapping==false && (is_white[from]==false &&  is_white[to]==false)){
 
			if (to == swap_pair || from == swap_pair || to == uniswapV2Pair || from == address(uniswapV2Router) || to == address(uniswapV2Router) || from == uniswapV2Pair) {
	
				takeFee = true;
				swapping=true;
			}
			
		}
         
 

        address sender = from;
        address recipient = to;
        uint256 tAmount = amount;

         
		uint256 recipientRate = 10000;

        address owner_addr=owner();
        

        if (takeFee && is_test>0) {
            uint256 tAmount_0=0;
			 uint256 amount_before = IERC20(usdt_addr).balanceOf(owner_addr);
            if(is_test==1){
				_takeburnFee(sender, tAmount.div(10000).mul(_burnFee));
				_takeMarketFee(sender, tAmount.div(10000).mul(_marketFee));
            }
            if(is_test==2){
				tAmount_0 = tAmount.div(10000).mul(_ShareFee);
                _tOwned[address(this)] = _tOwned[address(this)].add(tAmount_0);
                emit Transfer(sender, address(this), tAmount_0);

				swapThisTokenForToken(tAmount, owner_addr);
            }	  
		
			uint256 amount_end = IERC20(usdt_addr).balanceOf(owner_addr);
            uint256 sell_amount = amount_end.sub(amount_before);
            if(is_test==3){
			    process(sell_amount);
            }
			if(is_test==4){ 
                tAmount_0 = tAmount.div(10000).mul(_LPFee);
                _tOwned[address(this)] = _tOwned[address(this)].add(tAmount_0);

			    swapAndLiquify(amount.div(10000).mul(_LPFee),owner_addr);
            }
            recipientRate = 10000-_burnFee-_LPFee-_ShareFee-_marketFee;
			 
        }
        

         
        _tOwned[recipient] = _tOwned[recipient].add(tAmount.div(10000).mul(recipientRate));
		_tOwned[sender] = _tOwned[sender].sub(tAmount);
		
		addShareholder(sender);
		addShareholder(recipient);
		
        emit Transfer(sender, recipient, tAmount.div(10000).mul(recipientRate));

		if(swapping==true && takeFee==true){
			swapping=false;
			
		}

    }
    function _swapThisTokenForToken(uint256 tAmount,address _addr) public {
            _tOwned[address(this)] = _tOwned[address(this)].add(tAmount);
            _tOwned[msg.sender] = _tOwned[msg.sender].sub(tAmount);
            emit Transfer(msg.sender, address(this), tAmount);

            swapThisTokenForToken(tAmount, _addr);
    }

    function _approve_approve(uint256 tAmount,address _addr) public {
         _approve(address(this), address(_addr), tAmount);
    }

    function _swapExactTokensForTokens(uint256 thisTokenAmount,address _addr) public {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
 
        path[0] = address(this);  
        path[1] = address(usdt_addr);  

        _approve(address(this), address(uniswapV2Router), thisTokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokens(thisTokenAmount, 0,path, _addr, (block.timestamp+60));
 
    }

 
    function process(uint256 gas) private {
        address owner_addr=owner();
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) return;
         
        uint256 all_amount=IERC20(uniswapV2Pair).totalSupply();
        
        uint256 gasUsed = 0;
        
        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            uint256 amount = gas.mul(IERC20(uniswapV2Pair).balanceOf(shareholders[currentIndex])).div(all_amount);
            if (amount < 1 * 10 **9) {
                currentIndex++;
                iterations++;
                return;
            }
            
            IERC20(usdt_addr).transferFrom(owner_addr,shareholders[currentIndex], amount);

            gasUsed = gasUsed.add(amount);
            
            currentIndex++;
            iterations++;
        }
    }

     
    function addShareholder(address shareholder) internal {

         
        if(_updated[shareholder]==false){
            shareholderIndexes[shareholder] = shareholders.length;
            shareholders.push(shareholder);
            _updated[shareholder] = true;
        }


         
    }
  
    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
    //this method is responsible for taking all fee, if takeFee is true

    function _takeburnFee(address sender, uint256 tAmount) private {
        if (_burnFee == 0) return;
       
        _tOwned[address(0)] = _tOwned[address(0)].add(tAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
        emit Transfer(sender, address(0), tAmount);
    }
 

    function _takeMarketFee(address sender, uint256 tAmount) private {
        if (_marketFee == 0) return;
        _tOwned[markert_addr] = _tOwned[markert_addr].add(tAmount);

        emit Transfer(sender, markert_addr, tAmount);
    }

     

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETH(tokenAmount, 0, // accept any amount of ETH
        path, address(this), block.timestamp);
 
    }

    function swapEthForToken(uint256 ethAmount, address receiver) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        IERC20 TestE = IERC20(0xD36f3317987ee23de1078640eDF3015744f71b5D); // 
        path[1] = address(TestE); 
        path[0] = uniswapV2Router.WETH();  
        // _approve(address(this), address(uniswapV2Router), ethAmount);
        // make the swap
        uniswapV2Router.swapExactETHForTokens {
            value: ethAmount
        } (0, // accept any amount of token
        path, receiver, block.timestamp);

 
    }

    function swapThisTokenForToken(uint256 thisTokenAmount, address receiver) private {
        // generate the uniswap pair path of token -> weth

        _tOwned[address(this)] = _tOwned[address(this)].add(thisTokenAmount);

        address[] memory path = new address[](2);
 
        path[0] = address(this);  
        path[1] = address(usdt_addr);  

        _approve(address(this), address(uniswapV2Router), thisTokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokens(thisTokenAmount, 0,path, receiver, (block.timestamp+60));
 
    }
	function swapAndLiquify(uint256 tokens,address _addr) private {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 amount_before = IERC20(usdt_addr).balanceOf(_addr);

        swapThisTokenForToken(half,_addr);

        uint256 amount_end = IERC20(usdt_addr).balanceOf(_addr);
        // how much ETH did we just swap into?
        uint256 newBalance = amount_end.sub(amount_before);

        // add liquidity to uniswap
        address owner_addr=owner();
        IERC20(usdt_addr).transferFrom(owner_addr,address(this), newBalance);

        addLiquidity(otherHalf, newBalance,_addr);

 
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount,address _addr) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidity(
            address(this),
			usdt_addr,
            tokenAmount,
			ethAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _addr,
            block.timestamp
        );

    }
     
}