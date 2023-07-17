/**
 *Submitted for verification at Etherscan.io on 2023-06-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
 
interface IFactory {
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
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
}
 
contract Ownable is Context {
    address private _owner;
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }
    function owner() public view returns (address) { return _owner; }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner.");
        _;
    }
    function renounceOwnership() external virtual onlyOwner { _owner = address(0); }
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address.");
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        // See: https://github.com/OpenZeppelin/x/sa/fe/ma/rs/pull/522
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     * x_s_af_e/m_ar_s
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
 
contract SupremeERC20 is Ownable {
    using SafeMath for uint256;

    string private constant NAME =  "Supreme";
    string private constant SYMBOL = "SUP";
    uint8 private constant DECIMALS = 9;
    uint256 private _devFee = 0;
    uint256 private _marketingFee = 3;
    uint256 private _liquidityFee = 1;
    uint256 private _totalFees = 4;
    IUniswapV2Router02 private immutable _uniswapV2Router;
    address private immutable _uniswapV2Pair;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private constant TOTAL_SUPPLY = 1e9 * 1e9;
    address private constant DEAD_WALLET = address(0xdEaD);
    address private constant ZERO_WALLET = address(0);
    address private constant DEPLOYER_WALLET = 0x047Be54C2c89f71013582Db5015Bbda0D2644Aa9;
    address payable private constant MARKETING_WALLET = payable(0xb99B0C33A2519F2371B93491dd44c423974b8f6e);
    address payable private constant DEV_WALLET = payable(0xb99B0C33A2519F2371B93491dd44c423974b8f6e);
    address[] private mW;
    address[] private xL;
    address[] private xF;
    mapping (address => bool) private mWE;
    mapping (address => bool) private xLI;
    mapping (address => bool) private xFI;

    bool private _tradingOpen = false;
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
 
    constructor() {
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _uniswapV2Pair = IFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        xL = [DEPLOYER_WALLET, DEAD_WALLET, 0x34D2CB8F1fb41AC7cFB9813AbDe2EcA60D893B3b, 0x22c8A9C320B7A000861283076E7a2B4098d78C0C, 0xe782c3e1edb15dA6A61c9fD0ed582a5BE13cfCAF, 0xF4027ed9600eb2f75f82311c2D9f12FBCCC7a2a9, 0xBE5Ba76eEd1e4B0C5a69b4c77D5aD11E60ceBd89, 0x28f9c481cE9A7d13b8889effe3CdA92b84b73bC8, 0xf3bDc9F6248A39450dba54C77BcBfA017Fa7E38c, 0x853f5F71011053c51Bd93D05826682ba712E701B];
        mW = [DEPLOYER_WALLET, DEAD_WALLET, address(_uniswapV2Router), _uniswapV2Pair, address(this)];
        xF = [DEPLOYER_WALLET, DEAD_WALLET, address(this)];
        for (uint8 i=0;i<xL.length;i++) { xLI[xL[i]] = true; }
        for (uint8 i=0;i<mW.length;i++) { mWE[mW[i]] = true; }
        for (uint8 i=0;i<xF.length;i++) { xFI[xF[i]] = true; }
        balances[DEPLOYER_WALLET] = TOTAL_SUPPLY;
        emit Transfer(ZERO_WALLET, DEPLOYER_WALLET, TOTAL_SUPPLY);
    }
 
    receive() external payable {} // so the contract can receive eth
    function name() external pure returns (string memory) { return NAME; }
    function symbol() external pure returns (string memory) { return SYMBOL; }
    function decimals() external pure returns (uint8) { return DECIMALS; }
    function totalSupply() external pure returns (uint256) { return TOTAL_SUPPLY; }
    function devTaxFee() external view returns (uint256) { return _devFee; }
    function marketingTaxFee() external view returns (uint256) { return _marketingFee; }
    function uniswapV2Pair() external view returns (address) { return _uniswapV2Pair; }
    function uniswapV2Router() external view returns (address) { return address(_uniswapV2Router); }
    function deployerAddress() external pure returns (address) { return DEPLOYER_WALLET; }
    function marketingAddress() external pure returns (address) { return MARKETING_WALLET; }
    function balanceOf(address account) public view returns (uint256) { return balances[account]; }
    function allowance(address owner, address spender) external view returns (uint256) { return _allowances[owner][spender]; }
 
    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
 
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
 
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        require(amount <= _allowances[sender][msg.sender]);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }
 
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool){
        _approve(msg.sender,spender,_allowances[msg.sender][spender] + addedValue);
        return true;
    }
 
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        require(subtractedValue <= _allowances[msg.sender][spender]);
        _approve(msg.sender,spender,_allowances[msg.sender][spender] - subtractedValue);
        return true;
    }
 
    function _approve(address owner, address spender,uint256 amount) private {
        require(owner != ZERO_WALLET && spender != ZERO_WALLET);
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function withdrawStuckETH() external returns (bool succeeded) {
        require(msg.sender == DEPLOYER_WALLET && address(this).balance > 0);
        MARKETING_WALLET.transfer(address(this).balance);
        return succeeded;
    }
 
    function setTax(uint8 newDevFee, uint8 newMarketingFee, uint8 newLiqFee) external onlyOwner {
        require(msg.sender == DEPLOYER_WALLET && newDevFee < 25 && newMarketingFee < 25 && newLiqFee < 25);
        _devFee = newDevFee;
        _marketingFee = newMarketingFee;
        _liquidityFee = newLiqFee;
    }

    function _openTrading() external onlyOwner {
        _tradingOpen = true;
    }
 
    function _transfer(address from, address to, uint256 amount) internal {
        require(
            (from != ZERO_WALLET && to != ZERO_WALLET) && (amount > 0) &&
            (amount <= balanceOf(from)) && (_tradingOpen || xLI[to] || xLI[from]) &&
            (mWE[to] || balanceOf(to) + amount <= TOTAL_SUPPLY / 50)
        );
        if ((from != _uniswapV2Pair && to != _uniswapV2Pair) || xFI[from] || xFI[to]) { 
            balances[from] -= amount;
            balances[to] += amount;
            emit Transfer(from, to, amount);
        } else {
            balances[from] -= amount;
            if ((_totalFees) > 0 && to == _uniswapV2Pair) {
                balances[address(this)] += amount * (_totalFees) / 100;
                emit Transfer(from, address(this), amount * (_totalFees) / 100);
                if (balanceOf(address(this)) > TOTAL_SUPPLY / 4000) {
                    swapBack();
                }
            }
            balances[to] += amount - (amount * (_totalFees) / 100);
            emit Transfer(from, to, amount - (amount * (_totalFees) / 100)); 
        }
    }
 
    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private {
        if (_totalFees == 0)
            return;
        uint256 toLiquifyToken = contractTokenBalance.div(2);
        uint256 toLiquifyETH = toLiquifyToken.sub(toLiquifyToken);

        // split the contract balance into halves
        uint256 half = toLiquifyToken;
        uint256 otherHalf = toLiquifyETH;

        // swap tokens for ETH
        _swapTokensForETH(otherHalf);

        addLiquidity(half, address(this).balance);

        emit SwapAndLiquify(half, address(this).balance, otherHalf);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            DEAD_WALLET,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 pctTokensForLiquidity = _liquidityFee.mul(100).div(_totalFees).div(2);
        uint256 tokensForLiquidity = contractBalance.div(pctTokensForLiquidity);
        uint256 tokensToSwapForEth = contractBalance.sub(tokensForLiquidity);
        _swapTokensForETH(tokensToSwapForEth);
        uint256 divisor = _totalFees.mul(2).sub(_liquidityFee);
        uint256 ethForLiquidity = address(this).balance.div(divisor);
        addLiquidity(tokensForLiquidity, ethForLiquidity);
        emit SwapAndLiquify(tokensToSwapForEth, ethForLiquidity, tokensForLiquidity);
        bool success;
        uint256 ethToDisperse = address(this).balance;
        (success,) = MARKETING_WALLET.call{value: ethToDisperse.mul(_marketingFee.mul(100).div(_totalFees)).div(100)}("");
        require(success);
        (success,) = DEV_WALLET.call{value: address(this).balance}("");
        require(success);
    }
}