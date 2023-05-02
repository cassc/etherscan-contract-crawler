/**
 *Submitted for verification at BscScan.com on 2023-05-01
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/bearbull/bearBullV2.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IBEP20 {

    function decimals() external view returns (uint8);        
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

interface IPCSRouter {

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

}

interface IPancakeSwapFactory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);

}


contract BearBull {

    //This contract allows users to short tokens listed on pancakeswap

    using SafeMath for uint256;
    fallback() external payable {}
    receive() external payable {}

    constructor(IPCSRouter _pancakeSwapRouter){
        WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        token = IBEP20(0xf1bd7d72726628A40bdAC0D6852C021e1A424711);
        pcsRouter = _pancakeSwapRouter;
        tokenAddress = 0xf1bd7d72726628A40bdAC0D6852C021e1A424711;
    }

    struct shortPosition{
        address trader;
        uint256 amount; //without decimals
        uint256 tolerance; //int, must divide by 100 to multiply
        uint256 startPrice;
        bool inShort;
    }

    struct lendingInfo{
        address lender;
        uint256 amount;
        uint256 duration;
        uint256 endTime;
    }

    //variables

    mapping(address => shortPosition) public shortPositions;
    IBEP20 public token;
    address public tokenAddress;
    IPCSRouter public pcsRouter;
    address public WBNB;
    lendingInfo[] public lendings; 
    uint256 public totalLent;
    mapping (address => uint256) public lenderShares;

    //sub functions:

    //get collateral required, will return an amount of collateral required in wei.

    function getCollateral(uint256 amount, uint256 tolerance) public view returns (uint256){

        return (price() * amount * tolerance) / 100;

    }

    //get token price, returns value with decimal size.

    function price() private view returns (uint256) {

        uint256 amountIn = 10 ** token.decimals(); // 1 token
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(WBNB);
        uint256[] memory amountsOut = pcsRouter.getAmountsOut(amountIn, path);

        return amountsOut[1];
    }

    //allow user to view price from BSCScan:

    function checkPrice() external view returns (uint256) {

        uint256 amountIn = 10 ** token.decimals(); // 1 token
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(WBNB);
        uint256[] memory amountsOut = pcsRouter.getAmountsOut(amountIn, path);

        return amountsOut[1];
    }

    //get path from BNB to token:

    function getPathForETHToToken() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = tokenAddress;

        return path;
    }

    //get path from token to BNB:

    function getPathForTokenToETH() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[1] = WBNB;
        path[0] = tokenAddress;

        return path;
    }

    


    //Lend Tokens

    function lendTokens(uint256 amount, uint256 time) external {
        
        require(amount > 0, "Not enough tokens");
        require(time > 0, "Not long enough");

        bool success = token.transferFrom(msg.sender, address(this) , amount*10**token.decimals());

        require(success, "Token transfer failed.");

        totalLent += amount;
        uint256 lendTime = time * 1 hours;
        lenderShares[msg.sender] += amount;
        lendingInfo memory temp = lendingInfo({
            lender : msg.sender,
            amount : amount,
            duration : lendTime,
            endTime : block.timestamp + lendTime
        });

        lendings.push(temp);

        emit TokensLent(msg.sender, amount, time);
    }

    //Open Short

    function openShort(uint256 amount, uint256 riskTolerance) external payable {

        require(amount > 0, "Short position must be greater than zero");
        require(riskTolerance >= 25 && riskTolerance <= 50, "Risk tolerance must be between 25 and 50");
        uint256 collateralRequired = getCollateral(amount, riskTolerance);
        require(msg.value >= collateralRequired, "Insufficient collateral");
        
        uint256 contractBalance = token.balanceOf(address(this));
        uint256 tokenDecimals = token.decimals();
        uint256 trueAmount = amount * 10**tokenDecimals;

        require(contractBalance >= trueAmount, "Insufficient token balance in contract!");

        uint256 tokenPrice = price();

        address[] memory path = getPathForTokenToETH();

        bool success = token.approve(address(pcsRouter), trueAmount);
        require(success, "Token approval failed");

        uint256 deadline = block.timestamp + 100; // 5 minutes from now

        pcsRouter.swapExactTokensForETH(trueAmount, 0, path, address(this), deadline);

        shortPosition memory temp = shortPosition({
            trader : msg.sender,
            amount : amount,
            tolerance : riskTolerance,
            startPrice : tokenPrice,
            inShort : true
        });

        shortPositions[msg.sender] = temp;

        emit ShortOpened (msg.sender, amount, tokenPrice, msg.value);
    }

    function openShortWithFees(uint256 amount, uint256 riskTolerance) external payable {

        require(amount > 0, "Short position must be greater than zero");
        require(riskTolerance >= 25 && riskTolerance <= 50, "Risk tolerance must be between 25 and 50");
        uint256 collateralRequired = getCollateral(amount, riskTolerance);
        require(msg.value >= collateralRequired, "Insufficient collateral");
        
        uint256 contractBalance = token.balanceOf(address(this));
        uint256 tokenDecimals = token.decimals();
        uint256 trueAmount = amount * 10**tokenDecimals;

        require(contractBalance >= trueAmount, "Insufficient token balance in contract!");

        uint256 tokenPrice = price();

        address[] memory path = getPathForTokenToETH();

        bool success = token.approve(address(pcsRouter), trueAmount);
        require(success, "Token approval failed");

        uint256 deadline = block.timestamp + 100; // 5 minutes from now

        pcsRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(trueAmount, 0, path, address(this), deadline);

        shortPosition memory temp = shortPosition({
            trader : msg.sender,
            amount : amount,
            tolerance : riskTolerance,
            startPrice : tokenPrice,
            inShort : true
        });

        shortPositions[msg.sender] = temp;

        emit ShortOpened (msg.sender, amount, tokenPrice, msg.value);
    }

    //events:

    event ShortOpened(address indexed trader, uint256 amount, uint256 entryPrice, uint256 collateral);
    event ShortClosed(address indexed trader, uint256 amount, uint256 remainingCollateral);
    event TokensLent(address lender, uint256 amount, uint256 lendTime);
    event TokensDeposited(address indexed lender, uint256 amount);



//TODO: Withdraw tokens: 
//TODO: Close Short

}