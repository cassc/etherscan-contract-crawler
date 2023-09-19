/**
 *Submitted for verification at Etherscan.io on 2023-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ILiquidityGauge {
    struct Reward {
        address token;
        address distributor;
        uint256 period_finish;
        uint256 rate;
        uint256 last_update;
        uint256 integral;
    }

    // solhint-disable-next-line
    function deposit_reward_token(address _rewardToken, uint256 _amount) external;

    // solhint-disable-next-line
    function claim_rewards_for(address _user, address _recipient) external;

    function working_balances(address _address) external view returns (uint256);

    // // solhint-disable-next-line
    // function claim_rewards_for(address _user) external;

    // solhint-disable-next-line
    function deposit(uint256 _value, address _addr) external;

    // solhint-disable-next-line
    function reward_tokens(uint256 _i) external view returns (address);

    // solhint-disable-next-line
    function reward_data(address _tokenReward) external view returns (Reward memory);

    function balanceOf(address) external returns (uint256);

    function claimable_reward(address _user, address _reward_token) external view returns (uint256);

    function claimable_tokens(address _user) external returns (uint256);

    function user_checkpoint(address _user) external returns (bool);

    function commit_transfer_ownership(address) external;

    function claim_rewards(address) external;

    function add_reward(address, address) external;

    function set_claimer(address) external;

    function admin() external view returns (address);

    function set_reward_distributor(address _rewardToken, address _newDistrib) external;

    function initialize(
        address staking_token,
        address admin,
        address SDT,
        address voting_escrow,
        address veBoost_proxy,
        address distributor
    ) external;
}

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface ILocker {
    function createLock(uint256, uint256) external;

    function claimAllRewards(address[] calldata _tokens, address _recipient) external;

    function increaseAmount(uint256) external;

    function increaseAmount(uint128) external;

    function increaseUnlockTime(uint256) external;

    function release() external;

    function claimRewards(address, address) external;

    function claimFXSRewards(address) external;

    function claimFPISRewards(address) external;

    function execute(address, uint256, bytes calldata) external returns (bool, bytes memory);

    function setGovernance(address) external;

    function voteGaugeWeight(address, uint256) external;

    function setAngleDepositor(address) external;

    function setFxsDepositor(address) external;

    function setYieldDistributor(address) external;

    function setGaugeController(address) external;

    function setAccumulator(address _accumulator) external;

    function governance() external view returns (address);
}

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

interface IVePendle {
    event BroadcastTotalSupply(VeBalance newTotalSupply, uint256[] chainIds);
    event BroadcastUserPosition(address indexed user, uint256[] chainIds);
    event Initialized(uint8 version);
    event NewLockPosition(address indexed user, uint128 amount, uint128 expiry);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Withdraw(address indexed user, uint128 amount);

    struct Checkpoint {
        uint128 timestamp;
        VeBalance value;
    }

    struct VeBalance {
        uint128 bias;
        uint128 slope;
    }

    function MAX_LOCK_TIME() external view returns (uint128);

    function MIN_LOCK_TIME() external view returns (uint128);

    function WEEK() external view returns (uint128);

    function addDestinationContract(address _address, uint256 _chainId) external payable;

    function approxDstExecutionGas() external view returns (uint256);

    function balanceOf(address user) external view returns (uint128);

    function broadcastTotalSupply(uint256[] memory chainIds) external payable;

    function broadcastUserPosition(address user, uint256[] memory chainIds) external payable;

    function claimOwnership() external;

    function getAllDestinationContracts() external view returns (uint256[] memory chainIds, address[] memory addrs);

    function getBroadcastPositionFee(uint256[] memory chainIds) external view returns (uint256 fee);

    function getBroadcastSupplyFee(uint256[] memory chainIds) external view returns (uint256 fee);

    function getUserHistoryAt(address user, uint256 index) external view returns (Checkpoint memory);

    function getUserHistoryLength(address user) external view returns (uint256);

    function increaseLockPosition(uint128 additionalAmountToLock, uint128 newExpiry)
        external
        returns (uint128 newVeBalance);

    function increaseLockPositionAndBroadcast(
        uint128 additionalAmountToLock,
        uint128 newExpiry,
        uint256[] memory chainIds
    ) external payable returns (uint128 newVeBalance);

    function lastSlopeChangeAppliedAt() external view returns (uint128);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function pendle() external view returns (address);

    function pendleMsgSendEndpoint() external view returns (address);

    function positionData(address) external view returns (uint128 amount, uint128 expiry);

    function setApproxDstExecutionGas(uint256 gas) external;

    function slopeChanges(uint128) external view returns (uint128);

    function totalSupplyAndBalanceCurrent(address user) external returns (uint128, uint128);

    function totalSupplyAt(uint128) external view returns (uint128);

    function totalSupplyCurrent() external returns (uint128);

    function totalSupplyStored() external view returns (uint128);

    function transferOwnership(address newOwner, bool direct, bool renounce) external;

    function withdraw() external returns (uint128 amount);
}

interface IPendleFeeDistributor {
    // ========================= STRUCT =========================
    struct UpdateProtocolStruct {
        address user;
        bytes32[] proof;
        address[] pools;
        uint256[] topUps;
    }

    // ========================= EVENTS =========================
    /// @notice Emit when a new merkleRoot is set & the fee is funded by the governance
    event SetMerkleRootAndFund(bytes32 indexed merkleRoot, uint256 amountFunded);

    /// @notice Emit when an user claims their fees
    event Claimed(address indexed user, uint256 amountOut);

    /// @notice Emit when the Pendle team populates data for a protocol
    event UpdateProtocolClaimable(address indexed user, uint256 sumTopUp);

    // ========================= FUNCTIONS =========================
    /**
     * @notice Submit total fee and proof to claim outstanding amount. Fee will be sent as raw ETH,
     *  so receiver should be an EOA or have receive() function.
     */
    function claimRetail(address receiver, uint256 totalAccrued, bytes32[] calldata proof)
        external
        returns (uint256 amountOut);

    /**
     * @notice Claim all outstanding fees for the specified pools. This function is intended for use
     * by protocols that have contacted the Pendle team. Note that the fee will be sent in raw ETH,
     * so the receiver should be an EOA or have a receive() function.
     * @notice Protocols should not use claimRetail, as it can make getProtocolFeeData unreliable.
     */
    function claimProtocol(address receiver, address[] calldata pools)
        external
        returns (uint256 totalAmountOut, uint256[] memory amountsOut);

    ///@notice Returns the claimable fees per pool. This function is only available if the Pendle
    ///team has specifically set up the data.
    function getProtocolClaimables(address user, address[] calldata pools)
        external
        view
        returns (uint256[] memory claimables);

    ///@notice Returns the lifetime totalAccrued fees for protocols. This function is only available
    ///if the Pendle team has specifically set up the data.
    function getProtocolTotalAccrued(address user) external view returns (uint256);
}

/// @title Pendle Locker
/// @author StakeDAO
/// @notice Locks the PENDLE tokens to vePENDLE contract
contract PendleLocker {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */
    address public governance;
    address public pendleDepositor;
    address public accumulator;

    address public constant TOKEN = 0x808507121B80c02388fAd14726482e061B8da827;
    address public constant VOTING_ESCROW = 0x4f30A9D41B80ecC5B94306AB4364951AE3170210;
    address public feeDistributor = 0x8C237520a8E14D658170A633D96F8e80764433b9;

    /* ========== EVENTS ========== */
    event LockCreated(address indexed user, uint256 value, uint256 duration);
    event TokenClaimed(address indexed user, uint256 value);
    event VotedOnGaugeWeight(address indexed _gauge, uint256 _weight);
    event Released(address indexed user, uint256 value);
    event GovernanceChanged(address indexed newGovernance);
    event PendleDepositorChanged(address indexed newApwDepositor);
    event AccumulatorChanged(address indexed newAccumulator);
    event FeeDistributorChanged(address indexed newFeeDistributor);

    /* ========== CONSTRUCTOR ========== */
    constructor(address _governance, address _accumulator) {
        governance = _governance;
        accumulator = _accumulator;
        IERC20(TOKEN).approve(VOTING_ESCROW, type(uint256).max);
    }

    /* ========== MODIFIERS ========== */
    modifier onlyGovernance() {
        require(msg.sender == governance, "!gov");
        _;
    }

    modifier onlyGovernanceOrAcc() {
        require(msg.sender == governance || msg.sender == accumulator, "!(gov||acc)");
        _;
    }

    modifier onlyGovernanceOrDepositor() {
        require(msg.sender == governance || msg.sender == pendleDepositor, "!(gov||PendleDepositor)");
        _;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    /// @notice Creates a lock by locking PENDLE token in the VEPENDLE contract for the specified time
    /// @dev Can only be called by governance or proxy
    /// @param _value The amount of token to be locked
    /// @param _unlockTime The duration for which the token is to be locked
    function createLock(uint128 _value, uint128 _unlockTime) external onlyGovernance {
        IVePendle(VOTING_ESCROW).increaseLockPosition(_value, _unlockTime);
        emit LockCreated(msg.sender, _value, _unlockTime);
    }

    /// @notice Increases the amount of PENDLE locked in VEPENDLE
    /// @dev The PENDLE needs to be transferred to this contract before calling
    /// @param _value The amount by which the lock amount is to be increased
    function increaseAmount(uint128 _value) external onlyGovernanceOrDepositor {
        (, uint128 expiry) = IVePendle(VOTING_ESCROW).positionData(address(this));
        IVePendle(VOTING_ESCROW).increaseLockPosition(_value, expiry);
    }

    /// @notice Increases the duration for which PENDLE is locked in VEPENDLE for the user calling the function
    /// @param _unlockTime The duration in seconds for which the token is to be locked
    function increaseUnlockTime(uint128 _unlockTime) external onlyGovernanceOrDepositor {
        IVePendle(VOTING_ESCROW).increaseLockPosition(0, _unlockTime);
    }

    /// @notice Claim the token reward from the PENDLE fee Distributor passing the tokens as input parameter
    /// @param _recipient The address which will receive the claimed token reward
    function claimRewards(address _recipient, address[] calldata _pools) external onlyGovernanceOrAcc {
        (uint256 totalAmount,) = IPendleFeeDistributor(feeDistributor).claimProtocol(_recipient, _pools);
        emit TokenClaimed(_recipient, totalAmount);
    }

    /// @notice Withdraw the PENDLE from VEPENDLE
    /// @dev call only after lock time expires
    /// @param _recipient The address which will receive the released PENDLE
    function release(address _recipient) external onlyGovernance {
        IVePendle(VOTING_ESCROW).withdraw();
        uint256 balance = IERC20(TOKEN).balanceOf(address(this));

        IERC20(TOKEN).safeTransfer(_recipient, balance);
        emit Released(_recipient, balance);
    }

    /// @notice Set new governance address
    /// @param _governance governance address
    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
        emit GovernanceChanged(_governance);
    }

    /// @notice Set the PENDLE Depositor
    /// @param _pendleDepositor PENDLE deppositor address
    function setPendleDepositor(address _pendleDepositor) external onlyGovernance {
        pendleDepositor = _pendleDepositor;
        emit PendleDepositorChanged(_pendleDepositor);
    }

    /// @notice Set the fee distributor
    /// @param _newFD fee distributor address
    function setFeeDistributor(address _newFD) external onlyGovernance {
        feeDistributor = _newFD;
        emit FeeDistributorChanged(_newFD);
    }

    /// @notice Set the accumulator
    /// @param _accumulator accumulator address
    function setAccumulator(address _accumulator) external onlyGovernance {
        accumulator = _accumulator;
        emit AccumulatorChanged(_accumulator);
    }

    /// @notice execute a function
    /// @param to Address to sent the value to
    /// @param value Value to be sent
    /// @param data Call function data
    function execute(address to, uint256 value, bytes calldata data)
        external
        onlyGovernance
        returns (bool, bytes memory)
    {
        (bool success, bytes memory result) = to.call{value: value}(data);
        return (success, result);
    }
}

interface ISDTDistributor {
    function distribute(address gaugeAddr) external;
}

interface IWETH {
    function deposit() external payable;
}

/// @title A contract that accumulates ETH rewards and notifies them to the LGV4
/// @author StakeDAO
contract PendleAccumulator {
    error FEE_TOO_HIGH();
    error NOT_ALLOWED();
    error ZERO_ADDRESS();
    error WRONG_CLAIM();
    error NO_REWARD();
    error ONGOING_PERIOD();

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant VE_PENDLE = 0x4f30A9D41B80ecC5B94306AB4364951AE3170210;

    // fee recipients
    address public bribeRecipient;
    address public daoRecipient;
    address public veSdtFeeProxy;
    address public votesRewardRecipient;
    uint256 public bribeFee;
    uint256 public daoFee;
    uint256 public veSdtFeeProxyFee;

    address public governance;
    address public locker;
    address public gauge;
    address public sdtDistributor;
    uint256 public claimerFee;

    mapping(uint256 => uint256) rewards; // period -> reward amount

    /// @notice If set, the rewards will be distributed to all the users of the gauge
    bool public distributeAllRewards;

    event DaoFeeSet(uint256 _old, uint256 _new);
    event BribeFeeSet(uint256 _old, uint256 _new);
    event ERC20Rescued(address token, uint256 amount);
    event DaoRecipientSet(address _old, address _new);
    event VeSdtFeeProxySet(address _old, address _new);
    event GaugeSet(address oldGauge, address newGauge);
    event GovernanceSet(address oldGov, address newGov);
    event BribeRecipientSet(address _old, address _new);
    event LockerSet(address oldLocker, address newLocker);
    event VeSdtFeeProxyFeeSet(uint256 _old, uint256 _new);
    event DistributeAllRewardsSet(bool distributeAllRewards);
    event SdtDistributorUpdated(address oldDistributor, address newDistributor);
    event RewardNotified(address gauge, address tokenReward, uint256 amountNotified, uint256 claimerFee);

    /* ========== CONSTRUCTOR ========== */
    constructor(address _gauge, address _daoRecipient, address _bribeRecipient, address _veSdtFeeProxy) {
        governance = msg.sender;
        gauge = _gauge;
        daoRecipient = _daoRecipient;
        bribeRecipient = _bribeRecipient;
        veSdtFeeProxy = _veSdtFeeProxy;
        daoFee = 500; // 5%
        bribeFee = 1000; // 10%
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    /// @notice Claims rewards from the locker and notify all to the LGV4
    function claimAndNotifyAll() external {
        if (locker == address(0)) revert ZERO_ADDRESS();

        uint256 currentWeek = block.timestamp * 1 weeks / 1 weeks;

        // reward for 1 months
        address[] memory pools = new address[](1);
        pools[0] = VE_PENDLE;

        PendleLocker(locker).claimRewards(address(this), pools);

        uint256 claimed = address(this).balance;
        if (claimed == 0) revert NO_REWARD();
        // Wrap Eth to WETH
        IWETH(WETH).deposit{value: claimed}();

        // split the reward in 4 weekly periods
        // charge fees once from the whole month reward
        uint256 gaugeAmount = _chargeFee(WETH, claimed);
        uint256 weekAmount = gaugeAmount / 4;

        rewards[currentWeek] += weekAmount;
        rewards[currentWeek + 1 weeks] += weekAmount;
        rewards[currentWeek + 2 weeks] += weekAmount;
        rewards[currentWeek + 3 weeks] += weekAmount;

        _notifyReward(WETH);
        _distributeSDT();
    }

    function claimAndNotifyAll(address[] calldata pools) external {
        if (locker == address(0)) revert ZERO_ADDRESS();
        if (!distributeAllRewards) revert NOT_ALLOWED();

        uint256 currentWeek = block.timestamp * 1 weeks / 1 weeks;

        // reward for 1 months
        PendleLocker(locker).claimRewards(address(this), pools);

        uint256 claimed = address(this).balance;
        if (claimed == 0) revert NO_REWARD();

        // Wrap Eth to WETH
        IWETH(WETH).deposit{value: claimed}();

        // split the reward in 4 weekly periods
        // charge fees once from the whole month reward
        uint256 gaugeAmount = _chargeFee(WETH, claimed);
        uint256 weekAmount = gaugeAmount / 4;

        rewards[currentWeek] += weekAmount;
        rewards[currentWeek + 1 weeks] += weekAmount;
        rewards[currentWeek + 2 weeks] += weekAmount;
        rewards[currentWeek + 3 weeks] += weekAmount;

        _notifyReward(WETH);
        _distributeSDT();
    }

    /// @notice Claims rewards for the voters and send to a recipient
    function claimForVoters(address[] calldata pools) external {
        if (locker == address(0)) revert ZERO_ADDRESS();

        for (uint256 i; i < pools.length;) {
            if (pools[i] == VE_PENDLE) revert WRONG_CLAIM();
            unchecked {
                ++i;
            }
        }

        PendleLocker(locker).claimRewards(address(this), pools);

        uint256 claimed = address(this).balance;
        if (claimed == 0) revert NO_REWARD();

        // Wrap Eth to WETH
        IWETH(WETH).deposit{value: claimed}();

        uint256 votesAmount = _chargeFee(WETH, claimed);
        IERC20(WETH).transfer(votesRewardRecipient, votesAmount);

        _distributeSDT();
    }

    /// @notice Notify the reward already claimed for the current period
    function notifyReward(address _token) external {
        _notifyReward(_token);
        _distributeSDT();
    }

    /// @notice Reserve fees for dao, bribe and veSdtFeeProxy
    /// @param _amount amount to charge fees
    function _chargeFee(address _token, uint256 _amount) internal returns (uint256) {
        uint256 gaugeAmount = _amount;
        // dao part
        if (daoFee > 0) {
            uint256 daoAmount = (_amount * daoFee) / 10_000;
            IERC20(_token).transfer(daoRecipient, daoAmount);
            gaugeAmount -= daoAmount;
        }

        // bribe part
        if (bribeFee > 0) {
            uint256 bribeAmount = (_amount * bribeFee) / 10_000;
            IERC20(_token).transfer(bribeRecipient, bribeAmount);
            gaugeAmount -= bribeAmount;
        }

        // veSDTFeeProxy part
        if (veSdtFeeProxyFee > 0) {
            uint256 veSdtFeeProxyAmount = (_amount * veSdtFeeProxyFee) / 10_000;
            IERC20(_token).transfer(veSdtFeeProxy, veSdtFeeProxyAmount);
            gaugeAmount -= veSdtFeeProxyAmount;
        }
        return gaugeAmount;
    }

    /// @notice Distribute SDT if there is any
    function _distributeSDT() internal {
        if (sdtDistributor != address(0)) {
            ISDTDistributor(sdtDistributor).distribute(gauge);
        }
    }

    /// @notice Notify the new reward to the LGV4
    /// @param _tokenReward token to notify
    function _notifyReward(address _tokenReward) internal {
        uint256 amountToNotify;
        if (_tokenReward == WETH) {
            uint256 currentWeek = block.timestamp * 1 weeks / 1 weeks;
            amountToNotify = rewards[currentWeek];
            rewards[currentWeek] = 0;
        } else {
            amountToNotify = IERC20(_tokenReward).balanceOf(address(this));
        }

        if (amountToNotify == 0) revert NO_REWARD();

        if (ILiquidityGauge(gauge).reward_data(_tokenReward).distributor == address(this)) {
            uint256 balanceBefore = IERC20(_tokenReward).balanceOf(address(this));
            uint256 claimerReward = (amountToNotify * claimerFee) / 10_000;
            IERC20(_tokenReward).transfer(msg.sender, claimerReward);
            amountToNotify -= claimerReward;
            IERC20(_tokenReward).approve(gauge, amountToNotify);
            ILiquidityGauge(gauge).deposit_reward_token(_tokenReward, amountToNotify);

            uint256 balanceAfter = IERC20(_tokenReward).balanceOf(address(this));

            require(balanceBefore - balanceAfter == amountToNotify + claimerReward, "wrong amount notified");

            emit RewardNotified(gauge, _tokenReward, amountToNotify, claimerReward);
        }
    }

    /// @notice Set DAO recipient
    /// @param _daoRecipient recipient address
    function setDaoRecipient(address _daoRecipient) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_daoRecipient == address(0)) revert ZERO_ADDRESS();
        emit DaoRecipientSet(daoRecipient, _daoRecipient);
        daoRecipient = _daoRecipient;
    }

    /// @notice Set Bribe recipient
    /// @param _bribeRecipient recipient address
    function setBribeRecipient(address _bribeRecipient) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_bribeRecipient == address(0)) revert ZERO_ADDRESS();
        emit BribeRecipientSet(bribeRecipient, _bribeRecipient);
        bribeRecipient = _bribeRecipient;
    }

    /// @notice Set VeSdtFeeProxy
    /// @param _veSdtFeeProxy proxy address
    function setVeSdtFeeProxy(address _veSdtFeeProxy) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_veSdtFeeProxy == address(0)) revert ZERO_ADDRESS();
        emit VeSdtFeeProxySet(veSdtFeeProxy, _veSdtFeeProxy);
        veSdtFeeProxy = _veSdtFeeProxy;
    }

    /// @notice Set fees reserved to the DAO at every claim
    /// @param _daoFee fee (100 = 1%)
    function setDaoFee(uint256 _daoFee) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_daoFee > 10_000 || _daoFee + bribeFee + veSdtFeeProxyFee > 10_000) {
            revert FEE_TOO_HIGH();
        }
        emit DaoFeeSet(daoFee, _daoFee);
        daoFee = _daoFee;
    }

    /// @notice Set fees reserved to bribes at every claim
    /// @param _bribeFee fee (100 = 1%)
    function setBribeFee(uint256 _bribeFee) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_bribeFee > 10_000 || _bribeFee + daoFee + veSdtFeeProxyFee > 10_000) revert FEE_TOO_HIGH();
        emit BribeFeeSet(bribeFee, _bribeFee);
        bribeFee = _bribeFee;
    }

    /// @notice Set fees reserved to bribes at every claim
    /// @param _veSdtFeeProxyFee fee (100 = 1%)
    function setVeSdtFeeProxyFee(uint256 _veSdtFeeProxyFee) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_veSdtFeeProxyFee > 10_000 || _veSdtFeeProxyFee + daoFee + bribeFee > 10_000) revert FEE_TOO_HIGH();
        emit VeSdtFeeProxyFeeSet(veSdtFeeProxyFee, _veSdtFeeProxyFee);
        veSdtFeeProxyFee = _veSdtFeeProxyFee;
    }

    /// @notice Sets gauge for the accumulator which will receive and distribute the rewards
    /// @dev Can be called only by the governance
    /// @param _gauge gauge address
    function setGauge(address _gauge) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_gauge == address(0)) revert ZERO_ADDRESS();
        emit GaugeSet(gauge, _gauge);
        gauge = _gauge;
    }

    /// @notice Sets SdtDistributor to distribute from the Accumulator SDT Rewards to Gauge.
    /// @dev Can be called only by the governance
    /// @param _sdtDistributor gauge address
    function setSdtDistributor(address _sdtDistributor) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_sdtDistributor == address(0)) revert ZERO_ADDRESS();

        emit SdtDistributorUpdated(sdtDistributor, _sdtDistributor);
        sdtDistributor = _sdtDistributor;
    }

    function setDistributeAllRewards(bool _distributeAllRewards) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        emit DistributeAllRewardsSet(distributeAllRewards = _distributeAllRewards);
    }

    /// @notice Allows the governance to set the new governance
    /// @dev Can be called only by the governance
    /// @param _governance governance address
    function setGovernance(address _governance) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_governance == address(0)) revert ZERO_ADDRESS();
        emit GovernanceSet(governance, _governance);
        governance = _governance;
    }

    /// @notice Allows the governance to set the locker
    /// @dev Can be called only by the governance
    /// @param _locker locker address
    function setLocker(address _locker) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_locker == address(0)) revert ZERO_ADDRESS();
        emit LockerSet(locker, _locker);
        locker = _locker;
    }

    /// @notice Allows the governance to set the claimer fee
    /// @dev Can be called only by the governance
    /// @param _claimerFee claimer fee
    function setClaimerFee(uint256 _claimerFee) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_claimerFee > 10_000) revert FEE_TOO_HIGH();
        claimerFee = _claimerFee;
    }

    /// @notice A function that rescue any ERC20 token
    /// @param _token token address
    /// @param _amount amount to rescue
    /// @param _recipient address to send token rescued
    function rescueERC20(address _token, uint256 _amount, address _recipient) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_recipient == address(0)) revert ZERO_ADDRESS();
        IERC20(_token).transfer(_recipient, _amount);
        emit ERC20Rescued(_token, _amount);
    }

    receive() external payable {}
}