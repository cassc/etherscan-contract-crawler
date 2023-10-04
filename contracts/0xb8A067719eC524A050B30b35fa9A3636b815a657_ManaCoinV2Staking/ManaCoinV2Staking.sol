/**
 *Submitted for verification at Etherscan.io on 2023-09-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.1;

library Address {
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

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
}

pragma solidity ^0.8.0;

interface IERC20Permit {
  
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

pragma solidity ^0.8.0;

interface IERC20 {
  
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity ^0.8.0;

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

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


pragma solidity ^0.8.0;

contract ManaCoinV2Staking is Ownable, ReentrancyGuard {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool public isInitialized;
    uint256 public duration;

    uint256 public slot;

    bool public hasUserLimit;
    uint256 public poolLimitPerUser;
    uint256 public startBlock;
    uint256 public bonusEndBlock;

    address public walletA;

    uint256 private constant  MIN_SLOT = 1;
    uint256 private constant  MAX_SLOT = 60 * 60 * 24;
    uint256 private constant  DAY_LENGTH = 60 * 60 * 24;
    uint256 private constant  MAX_INT = type(uint256).max;

    address stakingToken;

    uint256 private totalEarnedTokenDeposed;

    struct Lockup {
        uint8 stakeType;
        uint256 duration;
        uint256 depositFee;
        uint256 withdrawFee;
        uint256 rate;
        uint256 lastRewardBlock;
        uint256 totalStaked;
        uint256 totalEarned;
        uint256 totalCompounded;
        uint256 totalWithdrawn;
        bool depositFeeReverse;
        bool withdrawFeeReverse;
    }

    struct UserInfo {
        uint256 lastRewardBlock;
        uint256 totalStaked;
        uint256 totalEarned;
        uint256 totalCompounded;
        uint256 totalWithdrawn;
    }

    struct Stake {
        uint8 stakeType;
        uint256 duration;
        uint256 end;
        uint256 lastRewardBlock;
        uint256 staked;
        uint256 earned;
        uint256 compounded;
        uint256 withdrawn;
    }

    uint256 constant MAX_STAKES = 2048;

    Lockup[] public lockups;
    mapping(address => Stake[]) public userStakes;
    mapping(address => mapping(uint8 => UserInfo)) public userStaked;

    event Deposit(address indexed user, uint256 stakeType, uint256 amount, uint256 depositFee, bool depositFeeReverse, uint256 fee);
    event Withdraw(address indexed user, uint256 stakeType, uint256 amount, uint256 depositFee, bool depositFeeReverse, uint256 fee);
    event AdminTokenRecovered(address tokenRecovered, uint256 amount);

    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event LockupUpdated(uint8 _type, uint256 _duration, uint256 _fee0, uint256 _fee1, uint256 _rate, bool _depositFeeReverse, bool _withdrawFeeReverse);
    event NewPoolLimit(bool hasUserLimit, uint256 poolLimitPerUser);
    event RewardsStop(uint256 blockNumber);
    event DurationUpdated(uint256 duration);

    event SettingUp(
        address _walletA
    );

    function initDefaultValues(
        address _stakingToken,
        uint256 _slot,
        uint256 _duration
    ) external onlyOwner {
        require(!isInitialized, "Already initialized");
        require(_slot >= MIN_SLOT && _slot <= MAX_SLOT, "Incorrect slot!");
        require((DAY_LENGTH / _slot) * _slot == DAY_LENGTH, "Incorrect slot!");
        require(_duration > 0, "Incorrect duration!");

        slot = _slot;
        duration = _duration;

        // Make this contract initialized
        isInitialized = true;
        stakingToken = _stakingToken;
        walletA = msg.sender;
        lockups.push(Lockup(0, 0, 0, 200, 1500, 0, 0, 0, 0, 0, false, false));

    }

    function deposit(uint256 _amount, uint8 _stakeType) external nonReentrant {
        require(isInitialized, "Not initialized");
        require(startBlock > 0, "Pool not started");
        require(_amount > 0, "Amount should be greater than 0");
        require(_stakeType < lockups.length, "Invalid stake type");

        UserInfo storage user = userStaked[msg.sender][_stakeType];
        Lockup storage lockup = lockups[_stakeType];

        //calc user and lockup reward
        _calcUserLockupReward(_stakeType);

        uint256 beforeAmount = IERC20(stakingToken).balanceOf(address(this));
        IERC20(stakingToken).safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        uint256 afterAmount = IERC20(stakingToken).balanceOf(address(this));
        uint256 realAmount = afterAmount.sub(beforeAmount);

        if (hasUserLimit) {
            require(
                realAmount.add(user.totalStaked) <= poolLimitPerUser,
                "User amount above limit"
            );
        }
        uint256 fee;
        if (lockup.depositFee > 0) {
            fee = realAmount.mul(lockup.depositFee).div(10000);
            if (fee > 0) {
                if(lockup.depositFeeReverse == false){
                    IERC20(stakingToken).safeTransfer(walletA, fee);
                    realAmount = realAmount.sub(fee);
                } else {
                    realAmount = realAmount.add(fee);
                }
            }
        }

        _addStake(_stakeType, msg.sender, lockup.duration, realAmount);

        user.totalStaked = user.totalStaked.add(realAmount);
        lockup.totalStaked = lockup.totalStaked.add(realAmount);

        emit Deposit(msg.sender, _stakeType, realAmount, lockup.depositFee, lockup.depositFeeReverse, fee);
    }

    function _addStake(uint8 _stakeType, address _account, uint256 _duration, uint256 _amount) internal {
        Stake[] storage stakes = userStakes[_account];

        uint256 end = block.timestamp.add(_duration).div(slot);

        uint256 i = stakes.length;
        require(i < MAX_STAKES, "Max stakes");

        stakes.push();

        Stake storage newStake = stakes[i];
        newStake.stakeType = _stakeType;
        newStake.duration = _duration;
        newStake.end = end;
        newStake.staked = _amount;
        newStake.lastRewardBlock = _getSlot();

    }

    function withdraw(uint256 _amount, uint8 _stakeType) external nonReentrant {
        require(isInitialized, "Not initialized");
        require(startBlock > 0, "Pool not started");
        require(_amount > 0, "Amount should be greator than 0");
        require(_stakeType < lockups.length, "Invalid stake type");

        UserInfo storage user = userStaked[msg.sender][_stakeType];
        Stake[] storage stakes = userStakes[msg.sender];
        Lockup storage lockup = lockups[_stakeType];

        uint256 remained = _amount;
        uint256 rewardAmount = _claimReward(_stakeType, _amount);
        if (rewardAmount >= remained) {
            remained = 0;
        } else {
            remained = remained.sub(rewardAmount);
        }

        uint256 pending = 0;

        for (uint256 j = 0; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if (stake.stakeType != _stakeType) continue;
            if (stake.staked == 0) continue;
            if (_getSlot() <= stake.end) continue;
            if (remained == 0) break;

            uint256 _pending = stake.staked;
            if (_pending > remained) {
                _pending = remained;
            }

            stake.staked = stake.staked.sub(_pending);
            remained = remained.sub(_pending);
            pending = pending.add(_pending);
        }

        if (pending > 0) {
            require(availableRewardTokens() >= pending, "Insufficient reward tokens");

            lockup.totalStaked = lockup.totalStaked.sub(pending);
            user.totalStaked = user.totalStaked.sub(pending);

            uint256 fee;
            if (lockup.withdrawFee > 0) {
                fee = pending.mul(lockup.withdrawFee).div(10000);
                if(fee > 0){
                    if(lockup.withdrawFeeReverse == false){
                        IERC20(stakingToken).safeTransfer(walletA, fee);
                        pending = pending.sub(fee);
                    } else {
                        pending = pending.add(fee);
                    }
                }
            }

            IERC20(stakingToken).safeTransfer(address(msg.sender), pending);
            emit Withdraw(msg.sender, _stakeType, pending, lockup.withdrawFee, lockup.withdrawFeeReverse, fee);

        }

    }

    function _claimReward(uint8 _stakeType, uint256 _amount) internal returns (uint256){
        require(isInitialized, "Not initialized");
        require(startBlock > 0, "Pool not started");
        require(_amount > 0, "Amount should be greator than 0");
        require(_stakeType < lockups.length, "Invalid stake type");

        UserInfo storage user = userStaked[msg.sender][_stakeType];
        Stake[] storage stakes = userStakes[msg.sender];
        Lockup storage lockup = lockups[_stakeType];

        _calcUserLockupReward(_stakeType);
        _calcStakeReward(_stakeType);

        uint256 remained = _amount;
        uint256 pending = 0;

        for (uint256 j = 0; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if (stake.stakeType != _stakeType) continue;
            if (_getSlot() <= stake.end) continue;

            uint256 _pending = stake.earned.sub(stake.compounded).sub(stake.withdrawn);

            if (_pending > remained) {
                _pending = remained;
            }

            remained = remained.sub(_pending);

            pending = pending.add(_pending);
            stake.withdrawn = stake.withdrawn + _pending;

            if (remained == 0) {
                break;
            }

        }

        if (pending > 0) {
            require(availableRewardTokens() >= pending, "Insufficient reward tokens");
            IERC20(stakingToken).safeTransfer(address(msg.sender), pending);

            lockup.totalWithdrawn = lockup.totalWithdrawn + pending;
            user.totalWithdrawn = user.totalWithdrawn + pending;

            emit Withdraw(msg.sender, _stakeType, pending, lockup.withdrawFee, lockup.withdrawFeeReverse, 0);

        }

        return pending;
    }

    function claimReward(uint8 _stakeType) external payable nonReentrant {
        require(isInitialized, "Not initialized");
        require(startBlock > 0, "Pool not started");
        require(_stakeType < lockups.length, "Invalid stake type");

        _claimReward(_stakeType, MAX_INT);
    }

    function claimReward(uint8 _stakeType, uint256 _amount) external payable nonReentrant {
        require(isInitialized, "Not initialized");
        require(startBlock > 0, "Pool not started");
        require(_stakeType < lockups.length, "Invalid stake type");

        _claimReward(_stakeType, _amount);
    }

    function compoundReward(uint8 _stakeType) external payable nonReentrant {
        require(isInitialized, "Not initialized");
        require(startBlock > 0, "Pool not started");
        require(_stakeType < lockups.length, "Invalid stake type");

        UserInfo storage user = userStaked[msg.sender][_stakeType];
        Stake[] storage stakes = userStakes[msg.sender];
        Lockup storage lockup = lockups[_stakeType];

        _calcUserLockupReward(_stakeType);
        _calcStakeReward(_stakeType);

        uint256 pending = 0;
        for (uint256 j = 0; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if (stake.stakeType != _stakeType) continue;

            uint256 _pending = stake.earned.sub(stake.compounded).sub(stake.withdrawn);
            pending = pending.add(_pending);

            stake.staked = stake.staked.add(_pending);
            stake.compounded = stake.compounded.add(_pending);
        }

        if (pending > 0) {

            user.totalStaked = user.totalStaked.add(pending);
            user.totalCompounded = user.totalCompounded.add(pending);
            lockup.totalStaked = lockup.totalStaked.add(pending);
            lockup.totalCompounded = lockup.totalCompounded.add(pending);

            emit Deposit(msg.sender, _stakeType, pending, lockup.depositFee, lockup.depositFeeReverse, 0);
        }
    }

    function _calcUserLockupReward(uint8 _stakeType) internal {
        require(isInitialized, "Not initialized");
        require(startBlock > 0, "Pool not started");
        require(_stakeType < lockups.length, "Invalid stake type");

        Lockup storage lockup = lockups[_stakeType];
        UserInfo storage user = userStaked[msg.sender][_stakeType];
        uint256 currentSlot = _getSlot();
        uint256 rate;
        uint256 pending;

        rate = _getRate(lockup.rate).mul(_getMultiplier(lockup.lastRewardBlock, currentSlot));
        pending = lockup.totalStaked.mul(rate).div(10 ** 24);
        lockup.totalEarned = lockup.totalEarned + pending;
        lockup.lastRewardBlock = currentSlot;

        rate = _getRate(lockup.rate).mul(_getMultiplier(user.lastRewardBlock, currentSlot));
        pending = user.totalStaked.mul(rate).div(10 ** 24);
        user.totalEarned = user.totalEarned + pending;
        user.lastRewardBlock = currentSlot;

    }

    function _calcStakeReward(uint8 _stakeType) internal {
        require(isInitialized, "Not initialized");
        require(startBlock > 0, "Pool not started");
        require(_stakeType < lockups.length, "Invalid stake type");

        Stake[] storage stakes = userStakes[msg.sender];
        Lockup storage lockup = lockups[_stakeType];

        uint256 currentSlot = _getSlot();
        uint256 rate;
        uint256 pending;

        for (uint256 j = 0; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if (stake.stakeType != _stakeType) continue;
            if (stake.staked == 0) continue;

            rate = _getRate(lockup.rate).mul(_getMultiplier(stake.lastRewardBlock, currentSlot));

            pending = stake.staked.mul(rate).div(10 ** 24);
            stake.earned = stake.earned.add(pending);
            stake.lastRewardBlock = currentSlot;
        }

    }

    function rewardPerStakeType(uint8 _stakeType) public view returns (uint256) {
        if (_stakeType >= lockups.length) return 0;

        return lockups[_stakeType].rate;
    }

    function availableRewardTokens() public view returns (uint256) {

        uint256 _amount = IERC20(stakingToken).balanceOf(address(this));

        uint256 reserved;

        if (_amount > reserved)
            return _amount.sub(reserved);
        else
            return 0;
    }

    function userInfo(uint8 _stakeType, address _account) public view returns (uint256 amount, uint256 available, uint256 locked) {
        Stake[] storage stakes = userStakes[_account];

        for (uint256 i = 0; i < stakes.length; i++) {
            Stake storage stake = stakes[i];

            if (stake.stakeType != _stakeType) continue;
            if (stake.staked == 0) continue;

            amount = amount.add(stake.staked);
            if (_getSlot() > stake.end) {
                available = available.add(stake.staked);
            } else {
                locked = locked.add(stake.staked);
            }
        }
    }

    function pendingReward(address _account, uint8 _stakeType) external view returns (uint256) {
        if (_stakeType >= lockups.length) return 0;
        if (startBlock == 0) return 0;

        Stake[] storage stakes = userStakes[_account];
        Lockup storage lockup = lockups[_stakeType];

        if (lockup.totalStaked == 0) return 0;

        uint256 pending = 0;
        for (uint256 i = 0; i < stakes.length; i++) {
            Stake storage stake = stakes[i];
            if (stake.stakeType != _stakeType) continue;
            pending = pending.add(stake.earned - stake.compounded - stake.withdrawn);
            uint256 rate = _getRate(lockup.rate).mul(_getMultiplier(stake.lastRewardBlock, _getSlot()));
            uint256 reward = stake.staked.mul(rate).div(10 ** 24);
            pending = pending.add(reward);

        }
        return pending;
    }

    function injectRewards(uint _amount) external onlyOwner nonReentrant {
        require(_amount > 0);

        uint256 beforeAmt = IERC20(stakingToken).balanceOf(address(this));
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 afterAmt = IERC20(stakingToken).balanceOf(address(this));

        totalEarnedTokenDeposed = totalEarnedTokenDeposed.add(afterAmt).sub(beforeAmt);
    }

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        uint256 reserved;

        if (_tokenAddress == stakingToken) {
            for (uint256 j = 0; j < lockups.length; j++) {
                Lockup storage lockup = lockups[j];
                reserved = reserved.add(lockup.totalStaked + lockup.totalEarned - lockup.totalCompounded - lockup.totalWithdrawn);
            }
        }

        if (reserved > 0) {
            uint256 tokenBal = IERC20(_tokenAddress).balanceOf(address(this));
            require(_tokenAmount <= tokenBal.sub(reserved), "Insufficient balance");
        }

        if (_tokenAddress == address(0x0)) {
            payable(msg.sender).transfer(_tokenAmount);
        } else {
            IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
        }

        emit AdminTokenRecovered(_tokenAddress, _tokenAmount);
    }

    function startRewards() external onlyOwner {
        require(startBlock == 0, "Pool was already started");

        startBlock = _getSlot().add(1);
        bonusEndBlock = startBlock.add(duration.mul(DAY_LENGTH / slot));

        emit NewStartAndEndBlocks(startBlock, bonusEndBlock);
    }

    function stopReward() external onlyOwner {
        bonusEndBlock = _getSlot();
    }

    function updatePoolLimitPerUser(bool _hasUserLimit, uint256 _poolLimitPerUser) external onlyOwner {
        hasUserLimit = _hasUserLimit;
        if (_hasUserLimit) {
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            poolLimitPerUser = 0;
        }
        emit NewPoolLimit(hasUserLimit, poolLimitPerUser);
    }

    function updateLockup(uint8 _stakeType, uint256 _duration, uint256 _depositFee, uint256 _withdrawFee, uint256 _rate, bool _depositFeeReverse, bool _withdrawFeeReverse) external onlyOwner {
        require(_stakeType < lockups.length, "Lockup Not found");
        require(_depositFee < 2000, "Invalid deposit fee");
        require(_withdrawFee < 2000, "Invalid withdraw fee");

        Lockup storage _lockup = lockups[_stakeType];
        if(_lockup.totalStaked == 0){
            _lockup.duration = _duration;
            _lockup.rate = _rate;
        }
        
        _lockup.depositFee = _depositFee;
        _lockup.withdrawFee = _withdrawFee;        
        _lockup.depositFeeReverse = _depositFeeReverse;
        _lockup.withdrawFeeReverse = _withdrawFeeReverse;

        emit LockupUpdated(_stakeType, _lockup.duration, _depositFee, _withdrawFee, _lockup.rate, _depositFeeReverse, _withdrawFeeReverse);
    }

    function AddTimeLock(uint256 _duration, uint256 _depositFee, uint256 _withdrawFee, uint256 _rate, bool _depositFeeReverse, bool _withdrawFeeReverse) external onlyOwner {
        require(_depositFee < 2000, "Invalid deposit fee");
        require(_withdrawFee < 2000, "Invalid withdraw fee");

        lockups.push();

        Lockup storage _lockup = lockups[lockups.length - 1];
        _lockup.duration = _duration;
        _lockup.depositFee = _depositFee;
        _lockup.withdrawFee = _withdrawFee;
        _lockup.rate = _rate;
        _lockup.depositFeeReverse = _depositFeeReverse;
        _lockup.withdrawFeeReverse = _withdrawFeeReverse;

        emit LockupUpdated(uint8(lockups.length - 1), _duration, _depositFee, _withdrawFee, _rate, _depositFeeReverse, _withdrawFeeReverse);
    }

    function setDuration(uint256 _duration) external onlyOwner {
        require(startBlock == 0, "Pool was already started");
        require(_duration >= 30, "lower limit reached");

        duration = _duration;
        emit DurationUpdated(_duration);
    }

    function settingUp(
        address _feeAddr
    ) external onlyOwner {
        require(_feeAddr != address(0x0), "Invalid Address");
        walletA = _feeAddr;

        emit SettingUp(_feeAddr);
    }

    function _getRate(uint256 _rate)
    internal
    view
    returns (uint256)
    {

        uint256 rate = _rate.mul(10 ** 20).div(365).div(DAY_LENGTH / slot);
        return rate;

    }

    function _getMultiplier(uint256 _from, uint256 _to)
    internal
    view
    returns (uint256)
    {
        if (_from >= bonusEndBlock) {
            return 0;
        } else if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    function _getSlot()
    internal
    view
    returns (uint256 _slot)
    {
        _slot = block.timestamp.div(slot);
    }


receive() external payable {}
}