// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./WarpStakingV2Mothership.sol";
import "./utils/BalanceAccounting.sol";
import "./pancake/interfaces/IPancakePair.sol";

contract WarpStakingV2 is AccessControl, BalanceAccounting {
    using SafeMath for uint256;

    struct UserData {
        uint256 startTime; // Start time of first stake
        uint256 startBlock; // Start block of first stake
        uint256 lastStakeTime; // Last time staked
        uint256 lastStakeBlock; // Last block staked
        uint256 lastResetTime; // Last time harvested
        uint256 totalHarvested; // Total amount harvested in _rewardToken
        uint256 lastTimeHarvested; // Last time harvested
        uint256 lastBlockHarvested; // Last block harvested
        uint256 currentRewards; // Current rewards in _token (will be set when requesting with userData(_), don't use directly from _userDatas)
    }

    bytes32 public constant MOTHER_ROLE = keccak256("MOTHER_ROLE");

    WarpStakingV2Mothership private _mother;

    IERC20 private _token;
    IERC20 private _rewardToken;
    IPancakePair private _lp;
    uint256 private _tokenLpIndex;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private _apr;
    uint256 private _rewardPerTokenPerSec; // Per ETH reward in WEI
    uint256 private _period;

    uint256 private _stoppedTimestamp;

    mapping(address => UserData) private _userDatas;

    constructor(
        WarpStakingV2Mothership mother_,
        IERC20 token_,
        IERC20 rewardToken_,
        IPancakePair lp_,
        string memory name_,
        string memory symbol_,
        uint256 apr_,
        uint256 period_
    ) {
        require(
            address(token_) == lp_.token0() || address(token_) == lp_.token1(),
            "WS: Missing token in lp"
        );
        require(
            address(rewardToken_) == lp_.token0() ||
                address(rewardToken_) == lp_.token1(),
            "WS: Missing reward token in lp"
        );

        _token = token_;
        _rewardToken = rewardToken_;
        _lp = lp_;
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _apr = apr_;
        _period = period_;

        _tokenLpIndex = address(_token) != _lp.token0() ? 0 : 1;

        _rewardPerTokenPerSec = _apr
            .mul(10**_decimals)
            .div(100)
            .div(365)
            .div(24)
            .div(60)
            .div(60);

        _setMother(mother_);
    }

    function mother() public view returns (WarpStakingV2Mothership) {
        return _mother;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function token() public view returns (address) {
        return address(_token);
    }

    function rewardToken() public view returns (address) {
        return address(_rewardToken);
    }

    function lp() public view returns (address) {
        return address(_lp);
    }

    function apr() public view returns (uint256) {
        return _apr;
    }

    function period() public view returns (uint256) {
        return _period;
    }

    function fee() public view returns (uint256) {
        return _mother.baseFee();
    }

    function nativeFee() public view returns (uint256) {
        return _mother.nativeFee();
    }

    /// @notice Set new mother contract
    /// @param mother_ contract to replace current
    function setMother(WarpStakingV2Mothership mother_)
        public
        onlyRole(MOTHER_ROLE)
    {
        _setMother(mother_);
    }

    /**
     * @dev Returns the price of _token in _rewardToken
     */
    function tokenPriceInRewardToken() public view returns (uint256) {
        (uint256 lpReserve0, uint256 lpReserve1, uint256 lpTimestamp) = _lp
            .getReserves();

        return
            (_tokenLpIndex == 0 ? lpReserve1 : lpReserve0).mul(10**18).div(
                _tokenLpIndex == 0 ? lpReserve0 : lpReserve1
            );
    }

    /**
     * @dev Returns the price of _rewardToken in _token
     */
    function rewardTokenPriceInToken() public view returns (uint256) {
        (uint256 lpReserve0, uint256 lpReserve1, uint256 lpTimestamp) = _lp
            .getReserves();

        return
            (_tokenLpIndex == 0 ? lpReserve0 : lpReserve1).mul(10**18).div(
                _tokenLpIndex == 0 ? lpReserve1 : lpReserve0
            );
    }

    function rewardPerTokenPerSec() public view returns (uint256) {
        return _rewardPerTokenPerSec;
    }

    function isStopped() public view returns (bool) {
        return _stoppedTimestamp > 0 && _stoppedTimestamp <= block.timestamp;
    }

    /**
     * @dev Returns the userData of an address and also sets the currentRewards property
     */
    function userData(address account) public view returns (UserData memory) {
        UserData memory user = _userDatas[account];
        user.currentRewards = this.currentRewards(account);
        return user;
    }

    function totalHarvested(address account) public view returns (uint256) {
        return _userDatas[account].totalHarvested;
    }

    /**
     * @dev Returns pending rewards in _token
     * Rewards are always in _token and when harvested converted to the _rewardToken
     *
     * The reward is based on time since last time stake/harvest to now or if the
     * contract is stopped based on the stopped time
     */
    function currentRewards(address account) public view returns (uint256) {
        UserData memory user = _userDatas[account];

        if (user.lastResetTime == 0 && user.startTime == 0) {
            return 0;
        }

        uint256 lastReset = (
            user.lastResetTime != 0 ? user.lastResetTime : user.startTime
        );
        uint256 elapsedTime = (isStopped() && lastReset >= _stoppedTimestamp)
            ? 0
            : (
                (isStopped() ? _stoppedTimestamp : block.timestamp).sub(
                    lastReset,
                    "ghtrjhge"
                )
            );

        if (elapsedTime <= 0) {
            return 0;
        }

        return
            _rewardPerTokenPerSec.mul(elapsedTime).mul(balanceOf(account)).div(
                10**_decimals
            );
    }

    /**
     * @dev Returns pending rewards converted to the _rewardToken
     * Rewards are always in _token and when harvested converted to the _rewardToken
     */
    function currentRewardsInRewardToken(address account)
        public
        view
        returns (uint256)
    {
        uint256 reward = this.currentRewards(account);
        if (reward <= 0) {
            return 0;
        }

        return reward.mul(rewardTokenPriceInToken()).div(10**18);
    }

    /**
     * @dev Stops staking by setting the _stoppedTimestamp
     * Rewards will be only calculated up to the time of _stoppedTimestamp
     * Harvesting and unstaking is still possible.
     */
    function stop(uint256 timestamp) external onlyRole(MOTHER_ROLE) {
        require(timestamp > 0, "WS: Empty timestamp is not allowed");
        _stoppedTimestamp = timestamp;
        emit Stopped(timestamp);
    }

    /**
     * @dev Resumes the contract by setting _stoppedTimestamp to 0
     */
    function resume() external onlyRole(MOTHER_ROLE) {
        require(isStopped(), "WS: Staking is not stopped");
        _stoppedTimestamp = 0;
        emit Resumed();
    }

    /**
     * @dev Stakes amount of _token and also calls _harvest()
     * The userData will be updated to current block data
     */
    function stake(uint256 amount) public payable virtual {
        require(amount > 0, "WS: Empty stake is not allowed");
        require(!isStopped(), "WS: Staking is stopped");
        require(msg.value == nativeFee(), "WS: Fee incorrect");

        address feeReceiver = _mother.feeReceiver();
        if (msg.value != 0) {
            payable(feeReceiver).transfer(msg.value);
        }

        _harvest(msg.sender, msg.sender);

        _token.transferFrom(msg.sender, address(this), amount);

        uint256 feeAmount = amount.mul(fee()).div(10000);
        uint256 finalAmount = amount.sub(feeAmount);

        if (feeReceiver != address(0)) {
            _token.transfer(feeReceiver, feeAmount);
        }

        _mother.childDeposit(finalAmount);
        _mint(msg.sender, finalAmount);

        UserData storage user = _userDatas[msg.sender];
        if (user.startTime == 0) {
            user.startBlock = block.number;
            user.startTime = block.timestamp;
        }
        user.lastStakeTime = block.timestamp;
        user.lastStakeBlock = block.number;

        emit Transfer(address(0), msg.sender, finalAmount);
    }

    /**
     * @dev Unstakes amount of _token and also calls _harvest()
     * The userData will be updated to current block data
     */
    function unstake(uint256 amount) public payable {
        require(amount > 0, "WS: Empty unstake is not allowed");

        uint256 periodInSec = _period.mul(24).mul(60).mul(60);
        require(
            block.timestamp >
                _userDatas[msg.sender].lastStakeTime.add(periodInSec),
            "WS: Staking period is not over"
        );

        require(msg.value == nativeFee(), "WS: Fee incorrect");

        address feeReceiver = _mother.feeReceiver();
        if (msg.value != 0) {
            payable(feeReceiver).transfer(msg.value);
        }

        _harvest(msg.sender, msg.sender);

        _burn(msg.sender, amount);
        _mother.childWithdraw(amount);

        uint256 feeAmount = amount.mul(fee()).div(10000);
        uint256 finalAmount = amount.sub(feeAmount);

        if (feeReceiver != address(0)) {
            _token.transfer(feeReceiver, feeAmount);
        }

        _token.transfer(msg.sender, finalAmount);

        emit Transfer(msg.sender, address(0), amount);
    }

    /**
     * @dev Forces a user to unstake
     * Harvesting rewards can be ignored
     */
    function forceUnstake(
        address account,
        uint256 amount,
        bool ignoreHarvest
    ) public onlyRole(MOTHER_ROLE) {
        require(amount > 0, "WS: Empty unstake is not allowed");

        if (!ignoreHarvest) {
            _harvest(account, account);
        }

        _burn(account, amount);
        _token.transfer(account, amount);
        emit Transfer(account, address(0), amount);
    }

    function harvest() external payable returns (uint256) {
        require(msg.value == nativeFee(), "WS: Fee incorrect");

        if (msg.value != 0) {
            payable(_mother.feeReceiver()).transfer(msg.value);
        }

        return _harvest(msg.sender, msg.sender);
    }

    /*function harvestAll(address[] memory stakers) public onlyOwner {
        for (uint256 i = 0; i < stakers.length; i++) {
            _harvest(stakers[i], stakers[i]);
        }
    }*/

    /**
     * @dev Harvest rewards and update userData to current block
     */
    function _harvest(address account, address receiver)
        internal
        virtual
        returns (uint256)
    {
        UserData storage user = _userDatas[account];

        uint256 rewards = this.currentRewardsInRewardToken(account);
        user.lastResetTime = block.timestamp;

        if (rewards <= 0) {
            return 0;
        }

        _mother.childHarvest(rewards);
        _rewardToken.transfer(receiver, rewards);

        user.lastTimeHarvested = block.timestamp;
        user.lastBlockHarvested = block.number;
        user.totalHarvested = user.totalHarvested.add(rewards);

        emit Harvest(account, receiver, rewards);
        return rewards;
    }

    /// @notice Set new mother contract
    /// @param mother_ contract to replace current
    function _setMother(WarpStakingV2Mothership mother_) internal {
        require(address(mother_) != address(0), "WS: Cant be null address");

        if (address(_mother) != address(0x0)) {
            _revokeRole(MOTHER_ROLE, address(_mother));
            _token.approve(address(_mother), 0);
        }

        _mother = mother_;

        _grantRole(MOTHER_ROLE, address(_mother));
        _token.approve(address(_mother), 2**256 - 1);
    }

    /**
     * @dev Rescue tokens out of the contract
     */
    function rescueToken(
        IERC20 token_,
        address to_,
        uint256 amount_
    ) external onlyRole(MOTHER_ROLE) {
        token_.transfer(to_, amount_);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Harvest(
        address indexed from,
        address indexed receiver,
        uint256 value
    );
    event Stopped(uint256 timestamp);
    event Resumed();
}