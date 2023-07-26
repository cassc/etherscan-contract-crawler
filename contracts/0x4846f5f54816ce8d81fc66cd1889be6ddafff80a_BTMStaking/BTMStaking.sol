/**
 *Submitted for verification at Etherscan.io on 2023-07-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * SAFEMATH LIBRARY
 */
library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

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

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
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

contract BTMStaking is ReentrancyGuard,Ownable {
    using SafeMath for uint256;
	using SafeERC20 for IERC20;

	IERC20 public _BTM = IERC20(0xC9D21E5A24110b67af31aF464edfDC2dAe5Ec7D5);
	
    struct Stake {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    struct AllInfo {
        uint256 totalStakes;
        uint256 totalDistributed;
        uint256 totalRewards;
        uint256 stakingStart;
        uint256 stakingEnd;

        uint256 userStaked;
        uint256 pendingRewards;
        uint256 totalClaimed;
        uint256 stakeTime;
        uint256 lastClaim;
        bool earlyWithdraw;
    }
    
	struct BalanceTransaction {
        uint256 balanceBeforeSend;
        uint256 balanceAfterSend;
    }
	
    address[] stakeholders;
    mapping (address => uint256) stakeholderIndexes;
    mapping (address => uint256) stakeholderClaims;
    mapping (address => uint256) stakeholderStaking;

    mapping (address => Stake) public stakes;

    uint256 public totalStakes;
    uint256 public totalDistributed;
    uint256 public totalRewards;
    uint256 public totalDays = 120 days; // 4 month
    uint256 public totalDuration = 86400; // 1 day
    uint256 public dividendsPerStake;
    uint256 public dividendsPerStakeAccuracyFactor = 10 ** 36;
	
	uint256 public stakingStart = 0;
	uint256 public stakingEnd = 0;
    uint256 public dividendsCheckPoint;
	
    uint256 public earlyWithdrawPenalty = 25; // 5%
	bool public activePenalty = true;
	
	uint256 private _weiDecimal = 18;

    constructor (
		uint256 _totalRewards
		, uint256 _stakingStart
	) payable {
		totalRewards = _totalRewards;
		stakingStart = _stakingStart;
		dividendsCheckPoint = stakingStart;
		stakingEnd = stakingStart + totalDays;
	}

    function deposit(uint256 amount) payable external nonReentrant {
        require(amount > 0, "No deposit amount");
        // require(msg.value == amount, "Amount not match");
        require(block.timestamp < stakingEnd, "Staking Ended");
        require(block.timestamp >= stakingStart, "Staking Not Started");
		
		uint256 _amount;
		
		BalanceTransaction memory balanceTransaction;
		balanceTransaction.balanceBeforeSend = _BTM.balanceOf(address(this));
		_BTM.safeTransferFrom(msg.sender, address(this), _getTokenAmount(address(_BTM),amount));
		balanceTransaction.balanceAfterSend = _BTM.balanceOf(address(this));
		_amount = balanceTransaction.balanceAfterSend - balanceTransaction.balanceBeforeSend;
		_amount = _getReverseTokenAmount(address(_BTM),_amount);
		
		if(stakes[msg.sender].amount > 0){
            distributeReward(msg.sender);
        }

        if(stakes[msg.sender].amount == 0){
            addStakeholder(msg.sender);
        }
		
        totalStakes = totalStakes.add(_amount);
        stakes[msg.sender].amount += _amount;
        stakes[msg.sender].totalExcluded = getCumulativeDividends(stakes[msg.sender].amount);
		stakeholderStaking[msg.sender] = block.timestamp;
		updateCumulativeDividends();
    }

    function withdraw(uint256 amount) external nonReentrant {
		address stakeholder = msg.sender;
		
		require(amount > 0, "No withdraw amount");
        require(stakes[stakeholder].amount >= amount, "insufficient balance");
		
		distributeReward(stakeholder);
		
		totalStakes = totalStakes.sub(amount);
		stakes[stakeholder].amount -= amount;
		stakes[stakeholder].totalExcluded = getCumulativeDividends(stakes[stakeholder].amount);
		
		if(stakes[stakeholder].amount == 0){
            removeStakeholder(stakeholder);
        }
		
		updateCumulativeDividends();
		
		uint256 withdrawAmount = amount;
		uint256 penaltyFee = 0;
		
		if(block.timestamp < (stakingStart + totalDays) && activePenalty){
			penaltyFee = (amount * earlyWithdrawPenalty) / 100;
			withdrawAmount -= penaltyFee;
			_BTM.safeTransfer(address(0xdead), _getTokenAmount(address(_BTM),penaltyFee));
		}
		
		_BTM.safeTransfer(msg.sender, _getTokenAmount(address(_BTM),withdrawAmount));
    }
    
    function distributeReward(address stakeholder) internal {
        if(stakes[stakeholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(stakeholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            stakeholderClaims[stakeholder] = block.timestamp;
            stakes[stakeholder].totalRealised = stakes[stakeholder].totalRealised.add(amount);
            stakes[stakeholder].totalExcluded = getCumulativeDividends(stakes[stakeholder].amount);
			_BTM.safeTransfer(stakeholder, _getTokenAmount(address(_BTM),amount));
        }
    }

    function claimReward() external nonReentrant{
        distributeReward(msg.sender);
    }
	
	function updateCumulativeDividends() internal {
        uint256 timestamp = block.timestamp;
		
		if(timestamp > stakingEnd){
			timestamp = stakingEnd;
		}
		
		uint256 pendingDividendsShare = (timestamp - dividendsCheckPoint) / totalDuration;
        uint256 rewardPerDay = totalRewards / (totalDays / totalDuration);
        uint256 valueShare = pendingDividendsShare * rewardPerDay;
		
		dividendsPerStake = dividendsPerStake.add(dividendsPerStakeAccuracyFactor.mul(valueShare).div(totalStakes));
		if (pendingDividendsShare > 0) {
            dividendsCheckPoint += timestamp - dividendsCheckPoint;
        }
    }
	
	function getCumulativeDividends(uint256 stake) internal view returns (uint256) {
        uint256 timestamp = block.timestamp;
		
		if(timestamp > stakingEnd){
			timestamp = stakingEnd;
		}
		
		uint256 pendingDividendsShare = (timestamp - dividendsCheckPoint) / totalDuration;
        uint256 rewardPerDay = (totalRewards / (totalDays / totalDuration));
        uint256 valueShare = pendingDividendsShare * rewardPerDay;
		

        // timestamp - dividendsCheckPoint = time passed since last update / 
		uint256 _dividendsPerStake = dividendsPerStake.add(dividendsPerStakeAccuracyFactor.mul(valueShare).div(totalStakes));
		return stake.mul(_dividendsPerStake).div(dividendsPerStakeAccuracyFactor);
    }
	
    function getUnpaidEarnings(address stakeholder) public view returns (uint256) {
        if(stakes[stakeholder].amount == 0){ return 0; }

        uint256 stakeholderTotalDividends = getCumulativeDividends(stakes[stakeholder].amount);
        uint256 stakeholderTotalExcluded = stakes[stakeholder].totalExcluded;

        if(stakeholderTotalDividends <= stakeholderTotalExcluded){ return 0; }

        return stakeholderTotalDividends.sub(stakeholderTotalExcluded);
    }

    function addStakeholder(address stakeholder) internal {
        stakeholderIndexes[stakeholder] = stakeholders.length;
        stakeholders.push(stakeholder);
    }

    function removeStakeholder(address stakeholder) internal {
        stakeholders[stakeholderIndexes[stakeholder]] = stakeholders[stakeholders.length-1];
        stakeholderIndexes[stakeholders[stakeholders.length-1]] = stakeholderIndexes[stakeholder];
        stakeholders.pop();
    }
	
	function setActivePenalty(bool _activePenalty) external onlyOwner{
        activePenalty = _activePenalty;
    }
	
    function getAllInfo(address user) public view returns (AllInfo memory) {
        return AllInfo(
            totalStakes,
            totalDistributed,
            totalRewards,
            stakingStart,
            stakingEnd,

            stakes[user].amount,
            getUnpaidEarnings(user),
            stakes[user].totalRealised,
            stakeholderStaking[user],
            stakeholderClaims[user],
            block.timestamp < (stakingStart + totalDays * totalDuration)
        );
    }
	
	function clearStuckBalance() external onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }
	
	function clearStuckToken(address TokenAddress, uint256 amount) external onlyOwner {
        IERC20(TokenAddress).safeTransfer(msg.sender, _getTokenAmount(TokenAddress, amount));
    }
	
	function _getTokenAmount(address _tokenAddress, uint256 _amount) internal view returns (uint256 quotient) {
		IERC20 tokenAddress = IERC20(_tokenAddress);
		uint256 tokenDecimal = tokenAddress.decimals();
		uint256 decimalDiff = 0;
		uint256 decimalDiffConverter = 0;
		uint256 amount = 0;
			
		if(_weiDecimal != tokenDecimal){
			if(_weiDecimal > tokenDecimal){
				decimalDiff = _weiDecimal - tokenDecimal;
				decimalDiffConverter = 10**decimalDiff;
				amount = _amount.div(decimalDiffConverter);
			} else {
				decimalDiff = tokenDecimal - _weiDecimal;
				decimalDiffConverter = 10**decimalDiff;
				amount = _amount.mul(decimalDiffConverter);
			}		
		} else {
			amount = _amount;
		}
		
		uint256 _quotient = amount;
		
		return (_quotient);
    }
	
	function _getReverseTokenAmount(address _tokenAddress, uint256 _amount) internal view returns (uint256 quotient) {
		IERC20 tokenAddress = IERC20(_tokenAddress);
		uint256 tokenDecimal = tokenAddress.decimals();
		uint256 decimalDiff = 0;
		uint256 decimalDiffConverter = 0;
		uint256 amount = 0;
			
		if(_weiDecimal != tokenDecimal){
			if(_weiDecimal > tokenDecimal){
				decimalDiff = _weiDecimal - tokenDecimal;
				decimalDiffConverter = 10**decimalDiff;
				amount = _amount.mul(decimalDiffConverter);
			} else {
				decimalDiff = tokenDecimal - _weiDecimal;
				decimalDiffConverter = 10**decimalDiff;
				amount = _amount.div(decimalDiffConverter);
			}		
		} else {
			amount = _amount;
		}
		
		uint256 _quotient = amount;
		
		return (_quotient);
    }
}