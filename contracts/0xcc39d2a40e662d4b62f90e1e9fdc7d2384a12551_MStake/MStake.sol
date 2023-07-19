/**
 *Submitted for verification at Etherscan.io on 2023-07-04
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)
pragma solidity ^0.8.7;

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
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

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @uniswap\lib\contracts\libraries\TransferHelper.sol

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

pragma solidity ^0.8.0;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract MStake is Ownable {
    IERC20 public mCoin;
    uint256 public maxIndex;
    // time of detail
    mapping(uint256 => TimeDetail) public timeOf;
    // user stakes
    mapping(address => StakeDetail[]) public userStakesOf;
    // The total amount that the user has completed in each time
    mapping(address => mapping(uint256 => uint256)) public userTimeFinishedOf;
    // The total amount that the user staked in each time
    mapping(address => mapping(uint256 => uint256)) public userTimeStakedOf;
    uint256 constant TENTHOUSANDTH = 10000;
    mapping(address => bool) public controllers;

    modifier onlyController() {
        require(controllers[msg.sender]);
        _;
    }

    struct TimeDetail {
        uint256 cycle;
        uint256 min;
        uint256 reward;
        uint256 perCount;
    }

    struct StakeDetail {
        uint256 start;
        uint256 end;
        uint256 index;
        uint256 amount;
        uint256 autoIndex;
        bool closed;
    }

    // User stake event
    event Stake(
        address indexed addr,
        uint256 indexed amount,
        uint256 indexed index,
        uint256 end
    );

    // User withdrawal event
    event Withdraw(
        address indexed addr,
        uint256 indexed amount,
        uint256 indexed reward
    );

    constructor(IERC20 _mCoin) {
        mCoin = _mCoin;
        controllers[msg.sender] = true;
        timeOf[1] = TimeDetail(7776000, 1000 * 1e8, 2000, 0);
        timeOf[2] = TimeDetail(7776000, 1000 * 1e8, 5000, 0);
        timeOf[3] = TimeDetail(7776000, 1000 * 1e8, 5000, 0);
        maxIndex = 3;
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    /**
     *   pre the amount that can be pledged in each time
     */
    function preQuotaOfTimes(address _addr)
        public
        view
        returns (uint256[] memory _result)
    {
        _result = new uint256[](maxIndex);
        _result[0] = 0;
        for (uint256 i = 2; i <= maxIndex; i++) {
            _result[i - 1] =
                userTimeFinishedOf[_addr][i - 1] -
                userTimeStakedOf[_addr][i];
        }
    }

    function preTimes() public view returns (TimeDetail[] memory _result) {
        _result = new TimeDetail[](maxIndex);
        for (uint256 i = 1; i <= maxIndex; i++) {
            _result[i - 1] = timeOf[i];
        }
    }

    function preTotal(address _addr)
        public
        view
        returns (uint256[2] memory _result)
    {
        uint256 _stakingTotal;
        uint256 _total;
        for (uint256 i = 0; i < userStakesOf[_addr].length; i++) {
            StakeDetail memory stakeDetail = userStakesOf[_addr][i];
            if (stakeDetail.closed) continue;
            _stakingTotal += stakeDetail.amount;
        }
        for (uint256 i = 0; i <= maxIndex; i++) {
            _total += userTimeStakedOf[_addr][i];
        }
        _result[0] = _stakingTotal;
        _result[1] = _total;
    }

    function preTotalReward(address _addr, uint256 _index)
        public
        view
        returns (uint256 _result)
    {
        for (uint256 i = 0; i < userStakesOf[_addr].length; i++) {
            StakeDetail memory stakeDetail = userStakesOf[_addr][i];
            if (stakeDetail.closed) continue;
            if (_index == 0 && stakeDetail.index != 0) continue;

            if (stakeDetail.index == 0) {
                uint256 _cycle = 0;
                for (uint256 j = 1; j <= maxIndex; j++) {
                    _cycle += timeOf[j].cycle;
                    if (
                        stakeDetail.start + _cycle < block.timestamp &&
                        stakeDetail.autoIndex < j
                    ) {
                        _result +=
                            (timeOf[j].reward * stakeDetail.amount) /
                            TENTHOUSANDTH;
                        if (j == maxIndex) _result += stakeDetail.amount;
                    }
                }
            } else if (stakeDetail.end < block.timestamp) {
                _result += stakeDetail.amount;
                _result +=
                    (stakeDetail.amount * timeOf[stakeDetail.index].reward) /
                    TENTHOUSANDTH;
            }
        }
    }

    function userStakes(
        address _addr,
        uint256 _from,
        uint256 _limit
    ) public view returns (StakeDetail[] memory _result) {
        if (_from == 0) _from = 1;
        uint256 totalStakes = userStakesOf[_addr].length;
        uint256 endIndex = _from - 1 + _limit;
        if (totalStakes < endIndex) endIndex = totalStakes;
        if (totalStakes == 0 || _from > endIndex) return new StakeDetail[](0);

        _result = new StakeDetail[](endIndex - _from + 1);

        for (uint256 i = _from - 1; i < endIndex; i++) {
            _result[i + 1 - _from] = userStakesOf[_addr][totalStakes - i - 1];
        }
    }

    function setTime(uint256 _time, TimeDetail memory _detail)
        public
        onlyOwner
    {
        timeOf[_time] = _detail;
    }

    function setToken(address _token)
        public
        onlyOwner
    {
        require(_token != address(0));
        mCoin = IERC20(_token);
    }

    function move(address _addr, uint256 _amount) public onlyController {
        require(_addr != address(0) && _amount > 0);

        uint256 _cycle = 0;
        for (uint256 i = 1; i <= maxIndex; i++) {
            _cycle += timeOf[i].cycle;
        }

        uint256 _end = block.timestamp + _cycle;
        userStakesOf[_addr].push(
            StakeDetail(block.timestamp, _end, 0, _amount, 0, false)
        );

        userTimeStakedOf[_addr][0] += _amount;
        emit Stake(_addr, _amount, 0, _end);
    }

    function stake(uint256 _time, uint256 _amount) public {
        TimeDetail memory timeDetail = timeOf[_time];
        require(timeDetail.cycle > 0, "no current period.");
        require(
            _amount > 0 && _amount >= timeDetail.min,
            "less than the minimum amount."
        );
        if (timeDetail.perCount > 0)
            require(_amount % timeDetail.perCount == 0, "must be a multiple.");
        if (_time > 1) {
            require(
                userTimeFinishedOf[msg.sender][_time - 1] -
                    userTimeStakedOf[msg.sender][_time] >=
                    _amount,
                "greater than the principal of the previous period."
            );
        }

        TransferHelper.safeTransferFrom(
            address(mCoin),
            msg.sender,
            address(this),
            _amount
        );

        uint256 _end = block.timestamp + timeDetail.cycle;
        userStakesOf[msg.sender].push(
            StakeDetail(block.timestamp, _end, _time, _amount, 0, false)
        );
        userTimeStakedOf[msg.sender][_time] += _amount;
        emit Stake(msg.sender, _amount, _time, _end);
    }

    // user withdraw
    function userWithdraw(uint256 _index) public {
        uint256 _totalAmount = 0;
        uint256 _stake = 0;

        for (uint256 i = 0; i < userStakesOf[msg.sender].length; i++) {
            StakeDetail memory stakeDetail = userStakesOf[msg.sender][i];
            if (stakeDetail.closed) continue;
            if (_index == 0 && stakeDetail.index != 0) continue;

            if (stakeDetail.index == 0) {
                uint256 cycle = 0;
                for (uint256 j = 1; j <= maxIndex; j++) {
                    cycle += timeOf[j].cycle;
                    if (
                        stakeDetail.start + cycle < block.timestamp &&
                        stakeDetail.autoIndex < j
                    ) {
                        _totalAmount +=
                            (timeOf[j].reward * stakeDetail.amount) /
                            TENTHOUSANDTH;
                        if (j == maxIndex) {
                            _totalAmount += stakeDetail.amount;
                            _stake += stakeDetail.amount;
                            userTimeFinishedOf[msg.sender][
                                stakeDetail.index
                            ] += stakeDetail.amount;
                            userStakesOf[msg.sender][i].closed = true;
                        } else {
                            userStakesOf[msg.sender][i].autoIndex = j;
                        }
                    }
                }
            } else if (stakeDetail.end < block.timestamp) {
                _totalAmount += stakeDetail.amount;
                _stake += stakeDetail.amount;
                _totalAmount +=
                    (stakeDetail.amount * timeOf[stakeDetail.index].reward) /
                    TENTHOUSANDTH;
                userTimeFinishedOf[msg.sender][stakeDetail.index] += stakeDetail
                    .amount;
                userStakesOf[msg.sender][i].closed = true;
            }
        }
        require(_totalAmount > 0);
        TransferHelper.safeTransfer(address(mCoin), msg.sender, _totalAmount);
        emit Withdraw(msg.sender, _stake, _totalAmount - _stake);
    }

    // withdraw
    function withdraw(address _token, uint256 _amount) public onlyOwner {
        if (_token == address(0)) {
            payable(msg.sender).transfer(_amount);
        } else {
            uint256 balance = IERC20(_token).balanceOf(address(this));
            require(balance >= _amount, "Insufficient contract assets!!!");
            TransferHelper.safeTransfer(_token, msg.sender, _amount);
        }
    }
}