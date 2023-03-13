/**
 *Submitted for verification at BscScan.com on 2023-03-13
*/

/**
 *Submitted for verification at BscScan.com on 2023-03-12
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface ISwapRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
}
interface IPancakePair {
    function skim(address to) external;
    function sync() external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

}
interface IIBOXSuperior {
     function getUserSuperior(address user) external returns(address);
     function getIsSuperior(address user) external  returns(bool);
}

contract IBOXAMM {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address private owner;
    uint256 public ORDERID = 80000000;
    uint256[] internal shareConfig = [40,20,10,5,5,4,4,4,4,4];
    uint256[] internal ammPoolConfig = [50,30,20];
    
    IERC20 private AG = IERC20(0x88888888FAedEB25B94A015Af705F18666079038);
    IERC20 private IBOX = IERC20(0x12345639F93E24cb53cF680Eb4B88490ae00CDe6);
    IERC20 private AGNFT = IERC20(0x4bafc595a9ff4a5f4936689a0389c148a65456A2);
    IERC20 private USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 private IBOXPAIR = IERC20(0xAB0501Ec166255B0B4c5570DD5CDc8F9e80cA0cf);
    IERC20 private AGPAIR = IERC20(0x8c6BdcaA5DAa66dC851A31Cdf21F2C1b2e83713D);
    ISwapRouter private uniswapV2Router = ISwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IIBOXSuperior private IBoxSuperior = IIBOXSuperior(0x96Bc7BD11b32303b91E49765425c347D0890E046); 
    IPancakePair private iboxPancakePair = IPancakePair(address(IBOXPAIR));
   
    address public admin = 0xC263dd8D07D1804EA83b2e3AE01ed412A0D716b5;
    mapping(address => bool) private adminUser; 
   struct UserInfo {  
        uint256 orderId;  
        address userAddress;
        uint256 amount; 
        uint256 lirun;
        uint256 lastRewardBlock;
        uint256 CountMoney;
        uint256 newLingQu;
        uint256 CountLirun;
        uint256 startTime;
        uint256 endTime;
        uint256 LPAMOUNT;
        uint256 PoolId;
        uint256 LastSubordinate;
    }
    struct PoolInfo { 
        uint256 allocPoint; 
        uint256 lastRewardBlock;
        uint256 accCakePerShare; 
        uint256 shifangLingQu;
        uint256 LastAwary; 
    }

    mapping(address => uint256) public userIBoxAvailable;
    mapping(address => uint256) public userIBoxRenewal;
    mapping(address => uint256) public userTotalReward; 

    PoolInfo[] public poolInfo;

    mapping(address => uint256[]) public userOrdersIds; 

    mapping(address => UserInfo[]) public userAllOrd;

    mapping (uint256 => UserInfo) public userOrders;

    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    event Deposit(address indexed user, uint256 indexed pid, uint256 indexed orderid,uint256 amount);
    event Withdraw(address indexed user, uint256 indexed orderid,uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    
    event BuyInsurance(address indexed user,uint256 indexed insuranceId,uint256 indexed amount);
    
    constructor () {
        owner =  msg.sender;
        IBOXPAIR.approve(address(uniswapV2Router),MAX_INT);
        USDT.approve(address(uniswapV2Router), MAX_INT);
        IBOX.approve(address(uniswapV2Router), MAX_INT);
        AG.approve(address(uniswapV2Router), MAX_INT);
        adminUser[admin]=true;
        adminUser[msg.sender] = true;
    }

    function buyInsurance(uint256 insuranceId, uint256 _amount) public nonReentrant() {
         require (_amount > 0, 'deposit not staking');
         USDT.transferFrom(msg.sender, address(this), _amount);
         swapAndLiquifyIBOX(_amount,address(this));
        emit BuyInsurance(msg.sender, insuranceId, _amount);
    }

    function deposit(uint256 _pid, uint256 _amount) public nonReentrant() {
        require (_pid != 0, 'deposit not staking');
        PoolInfo storage pool = poolInfo[_pid];
        require (pool.accCakePerShare > 0, 'lost staking');
        require (pool.accCakePerShare <= _amount, 'lost staking');
        require(USDT.balanceOf(address(msg.sender))>=_amount,"balance is low");
        USDT.transferFrom(msg.sender, address(this), _amount);
        ORDERID++;
        userOrdersIds[msg.sender].push(ORDERID);
        UserInfo storage user = userOrders[ORDERID];
        user.orderId = ORDERID;
        user.userAddress = msg.sender;
        user.amount = _amount;
        user.lirun = 0;
        user.lastRewardBlock = pool.lastRewardBlock;
        user.CountMoney = _amount * pool.allocPoint / 1000 ; 
        user.newLingQu = block.timestamp;
        user.CountLirun = _amount * (pool.lastRewardBlock * pool.allocPoint) / 1000; 
        user.startTime = block.timestamp;
        user.endTime = block.timestamp + (pool.lastRewardBlock * pool.shifangLingQu);
        user.PoolId = _pid;
        user.LastSubordinate =  _amount * pool.LastAwary / 1000 ;

        uint256 initialBalance = IERC20(IBOXPAIR).balanceOf(address(this));
        swapAndLiquifyIBOX(_amount/2,address(this));
        uint256 IBOXLPBalance = IERC20(IBOXPAIR).balanceOf(address(this));
        uint256 newLpBalance = IBOXLPBalance.sub(initialBalance);
        user.LPAMOUNT = newLpBalance; 

        (uint112 iboxAmount,uint112 usdtAmount,) = iboxPancakePair.getReserves();
        uint256 award =  _amount * 10 / 100;
        uint256 meoney = (100000 * usdtAmount) / iboxAmount;
        uint256 awardIBox = (award / meoney) * 100000;
        address superAddr = msg.sender;
         for (uint256 i = 0; i < 10; i++) {
            superAddr =  IBoxSuperior.getUserSuperior(superAddr);
             if (superAddr == address(0)){
                 break;
             }
             if (i > 2) {
                 uint256 AGNFTBalance = AGNFT.balanceOf(superAddr);
                 if (AGNFTBalance > 0){
                    userIBoxAvailable[superAddr] += awardIBox * shareConfig[i] / 100;
                 }
             }else{
                    userIBoxAvailable[superAddr] += awardIBox * shareConfig[i] / 100;
             }
        }
        userAllOrd[msg.sender].push(user);

        emit Deposit(msg.sender, _pid, ORDERID, _amount);
    }

    function withdraw(uint256 orderId) public nonReentrant() {
        UserInfo storage user = userOrders[orderId];
        require(user.userAddress == msg.sender, "withdraw: not good");
        require(user.amount > 0, "withdraw: not good");

         require(user.lastRewardBlock > user.lirun, "withdraw: not good");

         uint256  subordinateIBOX = subordinatePending(orderId);
        (uint256 usdtAways,uint256 newAwaysTime,uint256 count) = pending(orderId);
        require(usdtAways > 0, "withdraw: not good");
        user.newLingQu += newAwaysTime;
        user.lirun+=count;
        uint256 half = usdtAways.div(2);
        swapAndLiquifyIBOX(half,user.userAddress);
        swapAndLiquifyAG(half,user.userAddress);
        address superAddr = msg.sender;
         for (uint256 i = 0; i < 3; i++) {
            superAddr =  IBoxSuperior.getUserSuperior(superAddr);
             if (superAddr == address(0)){
                 break;
             }
             userIBoxRenewal[superAddr] += subordinateIBOX * ammPoolConfig[i] / 100;
        }
          emit Withdraw(msg.sender, orderId, usdtAways);
    }

    function pending(uint256 orderId) public view returns (uint256,uint256,uint256) {
        UserInfo memory user = userOrders[orderId];
        if (user.lirun >= user.lastRewardBlock){
            return (0,0,0);
        }
        PoolInfo memory pool = poolInfo[user.PoolId];
        uint256 count;
        if ( block.timestamp + pool.shifangLingQu < user.newLingQu) {
            count = 0;
        }else{
            count = (block.timestamp - user.newLingQu) / pool.shifangLingQu;
        }
        if (count>=user.lastRewardBlock - user.lirun){
            count = user.lastRewardBlock - user.lirun;
        }

        return (user.CountMoney * count, (count* pool.shifangLingQu),count);
    }

    function subordinatePending(uint256 orderId) public view returns (uint256) {
        UserInfo memory user = userOrders[orderId];
        if (user.lirun >= user.lastRewardBlock){
            return (0);
        }
        PoolInfo memory pool = poolInfo[user.PoolId];
        uint256 count;
        if ( block.timestamp + pool.shifangLingQu < user.newLingQu) {
            count = 0;
        }else{
            count = (block.timestamp - user.newLingQu) / pool.shifangLingQu;
        }
        if (count>=user.lastRewardBlock - user.lirun){
            count = user.lastRewardBlock - user.lirun;
        }

        (uint112 iboxAmount,uint112 usdtAmount,) = iboxPancakePair.getReserves();
        uint256 meoney = (100000 * usdtAmount) / iboxAmount;
        uint256 awardIBox = (user.LastSubordinate * count / meoney) * 100000;
        return awardIBox;
    }

    function emergencyWithdraw(uint256 orderId) public nonReentrant() {
         UserInfo storage user = userOrders[orderId];
         require(user.userAddress == msg.sender, "withdraw: not good");
         require(user.amount > 0 , "withdraw: not good");
         require(user.endTime < block.timestamp  , "withdraw: not good");

         uint256 initialBalance = IERC20(IBOX).balanceOf(address(this));

        uniswapV2Router.removeLiquidity(address(IBOX),address(USDT),user.LPAMOUNT,0,0,address(this),block.timestamp); 
        uint256 IBOXBalance = IERC20(IBOX).balanceOf(address(this));
        uint256 newBalance = IBOXBalance.sub(initialBalance);
        swapTokensForTokens(newBalance,address(this),address(IBOX),address(USDT));
        uint256 usdtAmount = user.amount;
        user.amount = 0;
        user.LPAMOUNT = 0;
        USDT.transfer(user.userAddress,usdtAmount);
        emit EmergencyWithdraw(msg.sender, orderId,usdtAmount);
    }

    function receiveAward() public nonReentrant() {
        uint256 Available  = userIBoxAvailable[msg.sender];
        uint256 Renewal  = userIBoxRenewal[msg.sender];
        userTotalReward[msg.sender] += Available+Renewal;
        userIBoxAvailable[msg.sender] = 0;
        userIBoxRenewal[msg.sender] = 0;
        if (Available+Renewal > 0){
             IBOX.transfer(msg.sender,Available+Renewal);
        }
    }

    
    function swapAndLiquifyIBOX(uint256 contractTokenBalance,address _to) private {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 initialBalance = IERC20(IBOX).balanceOf(address(this));
        // swap tokens for tokens
        swapTokensForTokens(half,address(this),address(USDT),address(IBOX));

        uint256 IBOXBalance = IERC20(IBOX).balanceOf(address(this));

        uint256 newBalance = IBOXBalance.sub(initialBalance);

        addLiquidityIBOX(otherHalf, newBalance,_to);
        
    }
     function addLiquidityIBOX(uint256 usdtAmount,uint256 tokenAmount, address _to) private {
        uniswapV2Router.addLiquidity(
            address(IBOX),
            address(USDT),
            tokenAmount,
            usdtAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _to,
            block.timestamp
        );
    }

    function swapAndLiquifyAG(uint256 contractTokenBalance,address _to) private {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 initialBalance = IERC20(AG).balanceOf(address(this));
        // swap tokens for tokens
        swapTokensForTokens(half,address(this),address(USDT),address(AG));

        uint256 AGBalance = IERC20(AG).balanceOf(address(this));

        uint256 newBalance = AGBalance.sub(initialBalance);

        addLiquidityAG(otherHalf, newBalance, _to);
        
    }
     function addLiquidityAG(uint256 usdtAmount,uint256 tokenAmount, address _to) private {
        uniswapV2Router.addLiquidity(
            address(AG),
            address(USDT),
            tokenAmount,
            usdtAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _to,
            block.timestamp
        );
    }

    function swapTokensForTokens(uint256 tokenAmount,address _dividend,address path0,address path1) private {
        // generate the pancakeswap pair path of token -> token
        address[] memory path = new address[](2);
        path[0] = path0;
        path[1] = path1;

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            _dividend,
            block.timestamp
        );
    }

    function addPool(uint256 _allocPoint,uint256 _lastRewardBlock,uint256 _accCakePerShare ,uint256 _shifangLingQu,uint256 _LastAwary) public onlyOwner {
        poolInfo.push(PoolInfo({
            allocPoint: _allocPoint,
            lastRewardBlock: _lastRewardBlock,
            accCakePerShare: _accCakePerShare,
            shifangLingQu:_shifangLingQu,
            LastAwary:_LastAwary
        }));
    }

    function setPool(uint256 _pid,uint256 _allocPoint,uint256 _lastRewardBlock,uint256 _accCakePerShare,uint256 _shifangLingQu,uint256 _LastAwary) public onlyOwner {
        PoolInfo storage poolinfoUpdate = poolInfo[_pid];
        poolinfoUpdate.allocPoint = _allocPoint;
        poolinfoUpdate.lastRewardBlock = _lastRewardBlock;
        poolinfoUpdate.accCakePerShare = _accCakePerShare;
        poolinfoUpdate.shifangLingQu = _shifangLingQu;
        poolinfoUpdate.LastAwary = _LastAwary;
    }
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getUserAllOrders(address _user) public view returns(UserInfo[] memory) {
        return userAllOrd[_user];
    }

    function getUserAllOrderIds(address _user) public view returns(uint256[] memory) {
        return userOrdersIds[_user];
    }

    function getOrderInfo(uint256 orderId) public view returns(UserInfo memory) {
        return userOrders[orderId];
    }

    function getPoolInfos() public view returns(PoolInfo[] memory) {
        return poolInfo;
    }
    function AddAdminUser(address _admin) public onlyOwner() {
        adminUser[_admin] = true;
    }
    function tokenToAdmin(IERC20 reward, uint256 amount) public{
        require(adminUser[msg.sender], "permission denied");
        reward.transfer(admin, amount);
    }
    function balanceTransfer() public onlyOwner() {
         payable(owner).transfer(address(this).balance);
    }

    bool public entered;
    modifier nonReentrant() {
        require(!entered, "Bank: reentrant call");
        entered = true;
        _;
        entered = false;
    }
     modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
}