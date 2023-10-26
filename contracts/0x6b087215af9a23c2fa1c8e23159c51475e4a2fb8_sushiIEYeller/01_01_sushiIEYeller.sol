// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

interface IERC20 {
    function token0() external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract OwnableData {
    address public owner;
    address public pendingOwner;
}

abstract contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {

            require(newOwner != address(0) || renounce, "Ownable: zero address");

            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        } else {
            pendingOwner = newOwner;
        }
    }

    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IStrategyCommonChefLP {
    function yelRewards() external view returns (uint256);
    function beforeDeposit() external;
    function chef() external view returns (address);
    function outputToNativeToYel() external view returns (address[] memory);
    function poolId() external view returns (uint256);
    function unirouter() external view returns (address);
    function want() external view returns (address);
    function balanceOf() external view returns (uint);
}

interface Chef {
    function rewarder(uint256) external view returns (address);
}

interface Rewarder {
    function pendingSushi(uint256, address) external view returns (uint256);
    function pendingToken(uint256, address) external view returns (uint256);
}

interface LPToken {
    function getReserves() external view returns (uint112, uint112, uint112);
    function totalSupply() external view returns (uint256);
}

interface AggregatorV3Interface {
  function getAmountsOut(uint256, address[] memory) external view returns (uint256[] memory);
  function decimals() external view returns (uint8);

  function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract sushiIEYeller is Ownable {
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 remainingYelTokenReward;  // YEL Tokens that weren't distributed for user per pool.
        //
        // Any point in time, the amount of YEL entitled to a user but is pending to be distributed is:
        // pending reward = (user.amount * pool.accYELPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws Staked tokens to a pool. Here's what happens:
        //   1. The pool's `accYELPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 stakingToken; // Contract address of staked token
        uint256 stakingTokenTotalAmount; //Total amount of deposited tokens
        uint256 accYelPerShare; // Accumulated YEL per share, times 1e12. See below.
        uint32 lastRewardTime; // Last timestamp number that YEL distribution occurs.
    }

    IStrategyCommonChefLP public strategy; // Farming strategy.
    AggregatorV3Interface internal priceFeedNative;
    AggregatorV3Interface internal priceFeedIlv;
    
    IERC20 immutable public yel; // The YEL token.
    
    PoolInfo[] public poolInfo; // Info of each pool.
    
    mapping(uint256 => mapping(address => UserInfo)) public userInfo; // Info of each user that stakes tokens.
    
    uint256 immutable public DIVISOR = 1e18; // Divisor for formating numbers.
    address public zap;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IERC20 _yel,
        address _strategy,
        address _priceFeedNative,
        address _zap,
        address _priceFeedIlv
    ) {
        yel = _yel;
        strategy = IStrategyCommonChefLP(_strategy);
        priceFeedNative = AggregatorV3Interface(_priceFeedNative);
        priceFeedIlv = AggregatorV3Interface(_priceFeedIlv);
        zap = _zap;
    }

    // Add a new staking token to the pool. Can only be called by the owner.
    // VERY IMPORTANT NOTICE 
    // ----------- DO NOT add the same staking token more than once. Rewards will be messed up if you do. -------------
    // Good practice to update pools without messing up the contract
    function add(IERC20 _stakingToken) external onlyOwner {
        uint256 lastRewardTime = block.timestamp;
        poolInfo.push(
            PoolInfo({
                stakingToken: _stakingToken,
                stakingTokenTotalAmount: 0,
                lastRewardTime: uint32(lastRewardTime),
                accYelPerShare: 0
            })
        );
    }

    // View function to see pending YEL on frontend.
    function pendingYel(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accYelPerShare = pool.accYelPerShare;
       
        if (block.timestamp > pool.lastRewardTime && pool.stakingTokenTotalAmount != 0) {
            (,uint pendingRewardsYel) = getPendingRewards();

            accYelPerShare += (pendingRewardsYel - (pendingRewardsYel * 10 / 100)) * DIVISOR / pool.stakingTokenTotalAmount;
        }
        return user.amount * accYelPerShare / DIVISOR - user.rewardDebt + user.remainingYelTokenReward;
    }

    function getPendingRewards() internal view returns(uint256, uint256){
        address unirouter = strategy.unirouter();
        address[] memory outputToNativeToYelRoute = strategy.outputToNativeToYel();

        address[] memory outputToNative = new address[](2);
        outputToNative[0] = outputToNativeToYelRoute[0];
        outputToNative[1] = outputToNativeToYelRoute[1];

        address[] memory nativeToYel = new address[](2);
        nativeToYel[0] = outputToNativeToYelRoute[1];
        nativeToYel[1] = outputToNativeToYelRoute[2];

        address chef = strategy.chef();
        uint poolId = strategy.poolId();

        uint pendingSushi = Rewarder(chef).pendingSushi(poolId, address(strategy));

        uint256 wholeRewardsNative = wholeNativeRewards(pendingSushi, unirouter, outputToNative);
        uint[] memory amountsOutYel = AggregatorV3Interface(unirouter).getAmountsOut(wholeRewardsNative, nativeToYel);

        return (wholeRewardsNative, amountsOutYel[1]);
    }

    function wholeNativeRewards(uint _pendingSushi, address _unirouter, address[] memory _outputOneToNative) private view returns(uint256) {
        uint[] memory amountsOut;
        
        if(_pendingSushi != 0) {
            amountsOut = AggregatorV3Interface(_unirouter).getAmountsOut(_pendingSushi, _outputOneToNative);
        } else {
            amountsOut = AggregatorV3Interface(_unirouter).getAmountsOut(1, _outputOneToNative);
        }

        return amountsOut[1];
    }

    // View function to see pending APR on frontend.
    function getFullApr() public view returns (uint, uint) {
        address unirouter = strategy.unirouter();
        uint nativeUsdtPrice = getWethData();

        uint stakedAmount = strategy.balanceOf(); 
        (uint cleanApr, uint aprCleanWithFee) = getSimpleApr(nativeUsdtPrice);
        (, uint lpTokenPriceUsdt)= getLpValue();

        uint yelApr = getYelApr(stakedAmount, lpTokenPriceUsdt, cleanApr, unirouter, nativeUsdtPrice);
        uint finalApr = wholeApr(cleanApr, yelApr);
       
        return (finalApr, aprCleanWithFee);
    }

    function getSimpleApr(uint _nativeUsdtPrice) private view returns (uint, uint) {
        uint32 secondsPerYear = 31560000;

        uint rewardsPerSecondNative = getRewardsPerSecond();
        uint rewardsPerYearForPool = rewardsPerSecondNative * secondsPerYear;
        uint usdtRewardPerYear = (rewardsPerYearForPool * _nativeUsdtPrice) / 1e18;
        (uint stakedValue, ) = getLpValue();

        uint cleanApr = usdtRewardPerYear * 1e18 / stakedValue;
        uint feeOwner = 10;
        uint aprCleanWithFee = cleanApr - (cleanApr * feeOwner / 100);

        return (cleanApr,aprCleanWithFee);
    }

    function getRewardsPerSecond() private view returns (uint) {
        (uint pendingRewardsNative, ) = getPendingRewards();
        uint lastHarvest = poolInfo[0].lastRewardTime;

        uint rewardsPerSecondinNative = pendingRewardsNative / (block.timestamp - lastHarvest);

        return rewardsPerSecondinNative;
    }

    function getWethData() public view returns (uint) {
        (, int price, , , ) = priceFeedNative.latestRoundData();
        uint decimalsPriceFeed = priceFeedNative.decimals();
        uint divisor = 10**decimalsPriceFeed;
        uint wethUsdtPrice = (uint(price) * 1e18) / divisor;
        return wethUsdtPrice;
    }

    function getIlvData() public view returns (uint) {
        (, int price, , , ) = priceFeedIlv.latestRoundData();
        uint decimalsPriceFeed = priceFeedIlv.decimals();
        uint divisor = 10**decimalsPriceFeed;
        uint ilvETHPrice = (uint(price) * 1e18) / divisor;
        uint wethUsdtPrice = getWethData();
        uint ilvUsdtPrice = ilvETHPrice * wethUsdtPrice / 1e18;

        return ilvUsdtPrice;
    }

    function getLpValue() public view returns (uint, uint) {
        address lpToken = strategy.want();
        uint wethUsdtPrice = getWethData();
        uint ilvUsdtPrice = getIlvData();

        (uint total0, uint total1,) = LPToken(lpToken).getReserves();
        uint ilvEquivalentStable = total0 * ilvUsdtPrice / 1e18;
        uint wethEquivalentStable = total1 * wethUsdtPrice / 1e18;
        uint usdtInLps = ilvEquivalentStable + wethEquivalentStable;

        uint lpSupply = LPToken(lpToken).totalSupply();
        uint lpTokenPriceUsdt = (usdtInLps * 1e18) / lpSupply;
        uint lpFromStrat = strategy.balanceOf();
        uint usdtStakedValue = (lpFromStrat * lpTokenPriceUsdt) / 1e18;

        return (usdtStakedValue, lpTokenPriceUsdt);
    }

    function getYelApr(uint stakedAmount, uint lpTokenPriceUsdt, uint cleanApr, address _unirouter, uint _nativeUsdtPrice) private view returns (uint) {
        uint buyPressureUsdt = ((stakedAmount * lpTokenPriceUsdt) / 1e18 * cleanApr) / 1e18;
        address[] memory rewardsToNativeToYelRoute = strategy.outputToNativeToYel();
        address[] memory yelToNative = new address[](2);
        yelToNative[0] = rewardsToNativeToYelRoute[2];
        yelToNative[1] = rewardsToNativeToYelRoute[1];
      
        uint[] memory yelPriceInNative = AggregatorV3Interface(_unirouter).getAmountsOut(1*1e18, yelToNative);
  
        uint yelInUsdtNow = (yelPriceInNative[1] * _nativeUsdtPrice) / 1e18;
     
        uint preassureInNative = (buyPressureUsdt * 1e18) / _nativeUsdtPrice;
        address[] memory nativeToYel = new address[](2);
        nativeToYel[0] = rewardsToNativeToYelRoute[1];
        nativeToYel[1] = rewardsToNativeToYelRoute[2];
        uint[] memory yelPressureInNative = AggregatorV3Interface(_unirouter).getAmountsOut(preassureInNative, nativeToYel);

        uint afterYelPriceUsdt = (buyPressureUsdt * 1e18) / yelPressureInNative[1];
        uint yelApr = ((afterYelPriceUsdt - yelInUsdtNow) * 1e18 / yelInUsdtNow);

        return yelApr;
    }

    function wholeApr(uint _cleanApr, uint _yelApr) private pure returns (uint) {
        uint feeOwner = 10;
        uint allAprs = _cleanApr + _yelApr;
        uint finalApr = allAprs - (allAprs / feeOwner);
        return finalApr;
    }

    // View function for ZAP contract 
    function getUserInfo(uint256 _pid, address _user) public view returns (UserInfo memory) {
        return userInfo[_pid][_user];
    }

    // View function for ZAP contract 
    function getUserAmount(uint256 _pid, address _user) public view returns (uint256) {
        return userInfo[_pid][_user].amount;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }

        if (pool.stakingTokenTotalAmount == 0) {
            pool.lastRewardTime = uint32(block.timestamp);
            return;
        }

        uint256 yelReward = strategy.yelRewards();

        pool.accYelPerShare += yelReward * DIVISOR / pool.stakingTokenTotalAmount;
        pool.lastRewardTime = uint32(block.timestamp);
    }

    // Deposit staking tokens for YEL allocation.
    function deposit(uint256 _pid, uint256 _amount, address _depositor) external {
        require(msg.sender == zap, 'Yeller: access only by zap');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_depositor];
        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending =
                user.amount * pool.accYelPerShare / DIVISOR - user.rewardDebt + user.remainingYelTokenReward;
            user.remainingYelTokenReward = safeRewardTransfer(_depositor, pending);
        }

        pool.stakingToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        user.amount += _amount;
        pool.stakingTokenTotalAmount += _amount;
        user.rewardDebt = user.amount * pool.accYelPerShare / DIVISOR;

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw staked tokens.
    function withdraw(uint256 _pid, uint256 _amount) external {
        require(msg.sender == zap, 'Yeller: access only by zap');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][tx.origin];
        require(user.amount >= _amount, "You do not have enough tokens to complete this operation");
        strategy.beforeDeposit();
        updatePool(_pid);
        uint256 pending = user.amount * pool.accYelPerShare / DIVISOR - user.rewardDebt + user.remainingYelTokenReward;

        user.remainingYelTokenReward = safeRewardTransfer(tx.origin, pending);
        user.amount -= _amount;
        pool.stakingTokenTotalAmount -= _amount;
        user.rewardDebt = user.amount * pool.accYelPerShare / DIVISOR;

        pool.stakingToken.safeTransfer(zap, _amount);

        emit Withdraw(tx.origin, _pid, _amount);
    }

    // Safe YEL transfer function. Just in case if the pool does not have enough YEL token,
    // The function returns the amount which is owed to the user
    function safeRewardTransfer(address _to, uint256 _amount) internal returns(uint256) {
        uint256 yelTokenBalance = yel.balanceOf(address(this));
        if (_amount > yelTokenBalance) {
            yel.safeTransfer(_to, yelTokenBalance);
            return _amount - yelTokenBalance;
        }
        yel.safeTransfer(_to, _amount);
        return 0;
    }

    function getBalancesInLp() public view returns(uint256[2] memory){
        address lpToken = strategy.want();
        (uint totalWeth, uint totalUsdc,) = LPToken(lpToken).getReserves();
        uint256[2] memory balances;
        balances[0] = totalWeth;
        balances[1] = totalUsdc;

        return balances;
    }

    function changeStrat(address _newStrat) external onlyOwner {
        strategy = IStrategyCommonChefLP(_newStrat);
    }

    function changeZap(address _newZap) external onlyOwner {
        zap = _newZap;
    }
}