//SPDX-License-Identifier: Unlicense
pragma solidity = 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/pools/common/RealWorldAssetReceipt.sol";

/// @title Stablz Incentive Cannavest - Real world asset pool
contract StablzIncentiveCannavestPool is RealWorldAssetReceipt, Ownable {

    using SafeERC20 for IERC20;

    address public rwaHandler;
    IERC20 public stablz;
    address private constant STABLZ = 0xA4Eb9C64eC359D093eAc7B65F51Ef933D6e5F7cd;
    /// @dev this is used to allow for decimals in the currentRewardValue as well as to convert USDT amount to 18 decimals
    uint private constant REWARD_FACTOR_ACCURACY = 1_000_000_000_000 ether;
    uint private constant LOCK_UP_PERIOD = 365 days;
    uint private constant INCENTIVE_PERIOD = 30 days;
    uint private constant INCENTIVE_VESTING_PERIOD = 30 days;
    /// @dev max number of incentive claims that can be made in a given transaction
    uint private constant MAX_CLAIM_SIZE = 100;
    uint private constant ONE_USDT = 10 ** 6;
    uint private constant MAX_AMOUNT = 5_000_000 * ONE_USDT;
    uint private constant INITIAL_STABLZ_REWARDS = 5_000_000 ether;
    uint public startedAt;
    uint public incentivesEndAt;
    bool public isDepositingEnabled;
    uint public finalAmount;
    uint public finalSupply;
    uint public currentRewardFactor;
    uint public allTimeRewards;
    uint public allTimeRewardsClaimed;
    uint public allTimeCirculatingSupplyAtDistribution;
    uint public totalStablzAllocated;
    uint public totalStablzClaimed;
    uint public totalVestments;

    struct Reward {
        uint factor;
        uint held;
    }

    struct Vestment {
        uint vestmentId;
        address user;
        uint amount;
        uint withdrawn;
        uint startDate;
    }

    mapping(uint => Vestment) public vestments;
    mapping(address => uint[]) private _userVestments;
    mapping(address => Reward) private _rewards;

    event Started();
    event Ended(uint finalAmount, uint finalSupply);
    event RealWorldAssetHandlerUpdated(address rwaHandler);
    event DepositingEnabled();
    event DepositingDisabled();
    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint expected, uint actual);
    event Claimed(address indexed user, uint rewards);
    event ClaimedIncentive(address indexed user, uint rewards);
    event Distributed(uint rewards, uint circulatingSupply);
    event Clawback(uint unallocated);

    modifier onlyRWAHandler() {
        require(_msgSender() == rwaHandler, "StablzIncentiveCannavestPool: Only the real world asset handler can call this function");
        _;
    }

    /// @param _rwaHandler Real world asset handler
    constructor(address _rwaHandler) RealWorldAssetReceipt("STABLZ-CANNAVEST", "CANNAVEST") {
        require(_rwaHandler != address(0), "StablzIncentiveCannavestPool: _rwaHandler cannot be the zero address");
        rwaHandler = _rwaHandler;
        stablz = IERC20(STABLZ);
    }

    /// @notice Start the pool
    function start() external onlyOwner {
        require(startedAt == 0, "StablzIncentiveCannavestPool: Already started");
        startedAt = block.timestamp;
        incentivesEndAt = startedAt + INCENTIVE_PERIOD;
        isDepositingEnabled = true;
        uint stablzBalance = stablz.balanceOf(address(this));
        if (stablzBalance < INITIAL_STABLZ_REWARDS) {
            stablz.safeTransferFrom(_msgSender(), address(this), INITIAL_STABLZ_REWARDS - stablzBalance);
        } else if (stablzBalance > INITIAL_STABLZ_REWARDS) {
            stablz.safeTransfer(_msgSender(), stablzBalance - INITIAL_STABLZ_REWARDS);
        }
        emit Started();
    }

    /// @notice End the pool (after the lock up period)
    /// @param _amount Principal amount
    function end(uint _amount) external onlyOwner {
        require(block.timestamp > getEndDate(), "StablzIncentiveCannavestPool: You cannot end before the end date");
        require(!hasEnded(), "StablzIncentiveCannavestPool: Already ended");
        require(0 < _amount && _amount <= totalSupply(), "StablzIncentiveCannavestPool: _amount must be greater than zero and less than or equal to the total staked");
        isDepositingEnabled = false;
        finalAmount = _amount;
        /// @dev totalSupply is user balances + OTC
        finalSupply = totalSupply();
        usdt.safeTransferFrom(_msgSender(), address(this), _amount);
        emit Ended(finalAmount, finalSupply);
    }

    /// @notice Update the real world asset handler address
    /// @param _rwaHandler Real world asset handler
    function updateRealWorldAssetHandler(address _rwaHandler) external onlyOwner {
        require(_rwaHandler != address(0), "StablzIncentiveCannavestPool: _rwaHandler cannot be the zero address");
        rwaHandler = _rwaHandler;
        emit RealWorldAssetHandlerUpdated(_rwaHandler);
    }

    /// @notice Enable depositing
    function enableDepositing() external onlyOwner {
        require(startedAt > 0, "StablzIncentiveCannavestPool: Pool not started yet");
        require(_isPoolActive(), "StablzIncentiveCannavestPool: Pool has already stopped");
        require(!isDepositingEnabled, "StablzIncentiveCannavestPool: Depositing is already enabled");
        isDepositingEnabled = true;
        emit DepositingEnabled();
    }

    /// @notice Disable depositing
    function disableDepositing() external onlyOwner {
        require(isDepositingEnabled, "StablzIncentiveCannavestPool: Depositing is already disabled");
        isDepositingEnabled = false;
        emit DepositingDisabled();
    }

    /// @notice Deposit USDT and receive STABLZ-CANNAVEST
    /// @param _amount USDT to deposit
    function deposit(uint _amount) external nonReentrant {
        require(_isPoolActive(), "StablzIncentiveCannavestPool: Depositing is not allowed because the pool has ended");
        require(isDepositingEnabled, "StablzIncentiveCannavestPool: Depositing is not allowed at this time");
        require(ONE_USDT <= _amount, "StablzIncentiveCannavestPool: _amount must be greater than or equal to 1 USDT");
        require(_amount <= usdt.balanceOf(_msgSender()), "StablzIncentiveCannavestPool: Insufficient USDT balance");
        require(_amount <= usdt.allowance(_msgSender(), address(this)), "StablzIncentiveCannavestPool: Insufficient USDT allowance");
        require(totalSupply() + _amount <= MAX_AMOUNT, "StablzIncentiveCannavestPool: Max amount reached");
        if (block.timestamp < incentivesEndAt) {
            _allocateIncentiveRewards(_amount);
        }
        _mint(_msgSender(), _amount);
        usdt.safeTransferFrom(_msgSender(), rwaHandler, _amount);
        emit Deposit(_msgSender(), _amount);
    }

    /// @notice Withdraw USDT after lockup and give back STABLZ-CANNAVEST
    function withdraw() external nonReentrant {
        require(hasEnded(), "StablzIncentiveCannavestPool: You can only withdraw once the pool has ended");
        uint balance = balanceOf(_msgSender());
        uint otc = _getUserAmountListed(_msgSender());
        require(0 < balance + otc, "StablzIncentiveCannavestPool: Receipt balance must be greater than zero");
        uint amount = _calculateFinalAmount(_msgSender());
        if (0 < balance) {
            _burn(_msgSender(), balance);
        }
        if (0 < otc) {
            _clearUserAmountListed(_msgSender());
            _burn(address(this), otc);
        }
        usdt.safeTransfer(_msgSender(), amount);
        emit Withdraw(_msgSender(), balance, amount);
    }

    /// @notice Claim USDT rewards
    function claimRewards() external nonReentrant {
        _mergeRewards(_msgSender());
        uint held = _getHeldRewards(_msgSender());
        require(0 < held, "StablzIncentiveCannavestPool: No rewards available to claim");
        _rewards[_msgSender()].held = 0;
        allTimeRewardsClaimed += held;
        usdt.safeTransfer(_msgSender(), held);
        emit Claimed(_msgSender(), held);
    }

    /// @notice Claim incentive
    /// @param _vestmentId Vestment ID
    function claimStablzRewards(uint _vestmentId) external nonReentrant {
        uint incentive = _claimStablzRewards(_vestmentId);
        totalStablzClaimed += incentive;
        stablz.safeTransfer(_msgSender(), incentive);
        emit ClaimedIncentive(_msgSender(), incentive);
    }

    /// @notice Claim multiple incentives
    /// @param _vestmentIds Vestment IDs
    function claimMultipleStablzRewards(uint[] calldata _vestmentIds) external nonReentrant {
        require(_vestmentIds.length <= MAX_CLAIM_SIZE, "StablzIncentiveCannavestPool: _vestmentIds can only contain up to 100 vestment IDs");
        uint incentive;
        for (uint i; i < _vestmentIds.length; i++) {
            incentive += _claimStablzRewards(_vestmentIds[i]);
        }
        totalStablzClaimed += incentive;
        stablz.safeTransfer(_msgSender(), incentive);
        emit ClaimedIncentive(_msgSender(), incentive);
    }

    /// @notice Distribute USDT to receipt token holders (RWA handler only)
    /// @param _amount Amount of USDT to distribute
    function distribute(uint _amount) external onlyRWAHandler {
        /// @dev checks !hasEnded() and not block.timestamp <= getEndDate() in case the final distribution occurs slightly after 1 year
        require(!hasEnded(), "StablzIncentiveCannavestPool: Distributions are disabled because the pool has ended");
        uint circulatingSupply = _getCirculatingSupply();
        require(ONE_USDT <= circulatingSupply, "StablzIncentiveCannavestPool: Total staked must be greater than 1 receipt token");
        require(ONE_USDT <= _amount, "StablzIncentiveCannavestPool: _amount must be greater than or equal to 1 USDT");
        require(_amount <= usdt.balanceOf(rwaHandler), "StablzIncentiveCannavestPool: Insufficient balance");
        require(_amount <= usdt.allowance(rwaHandler, address(this)), "StablzIncentiveCannavestPool: Insufficient allowance");
        allTimeCirculatingSupplyAtDistribution += circulatingSupply;
        allTimeRewards += _amount;
        currentRewardFactor += REWARD_FACTOR_ACCURACY * _amount / circulatingSupply;
        usdt.safeTransferFrom(rwaHandler, address(this), _amount);
        emit Distributed(_amount, circulatingSupply);
    }

    /// @notice Clawback unallocated STABLZ rewards (after the incentive period)
    function clawback() external onlyOwner {
        require(incentivesEndAt <= block.timestamp, "StablzIncentiveCannavestPool: Clawback can only occur after the incentive period");
        uint unallocated = getUnallocatedStablz();
        require(0 < unallocated, "StablzIncentiveCannavestPool: Nothing to clawback");
        stablz.safeTransfer(owner(), unallocated);
        emit Clawback(unallocated);
    }

    /// @notice Get unallocated STABLZ
    /// @return uint Amount of unallocated STABLZ
    function getUnallocatedStablz() public view returns (uint) {
        uint stablzBalance = stablz.balanceOf(address(this));
        uint inUse = totalStablzAllocated - totalStablzClaimed;
        return stablzBalance - inUse;
    }

    /// @notice Get the end date
    /// @return uint End date
    function getEndDate() public view returns (uint) {
        require(startedAt > 0, "StablzIncentiveCannavestPool: Pool has not started yet");
        return startedAt + LOCK_UP_PERIOD;
    }

    /// @notice Get the current rewards for a user
    /// @param _user User address
    /// @return uint Current rewards for _user
    function getReward(address _user) external view returns (uint) {
        require(_user != address(0), "StablzIncentiveCannavestPool: _user cannot equal the zero address");
        return _getHeldRewards(_user) + _getCalculatedRewards(_user);
    }

    /// @notice Calculate the final amount to withdraw
    /// @param _user User address
    /// @return uint Final amount to withdraw for _user
    function calculateFinalAmount(address _user) external view returns (uint) {
        require(hasEnded(), "StablzIncentiveCannavestPool: The pool has not ended yet");
        require(_user != address(0), "StablzIncentiveCannavestPool: _user cannot equal the zero address");
        return _calculateFinalAmount(_user);
    }

    /// @notice Has the pool ended
    /// @return bool true - ended, false - not ended
    function hasEnded() public view returns (bool) {
        return finalAmount > 0;
    }

    /// @notice Total vestments for a given user
    /// @param _user User
    /// @return uint Total vestments for _user
    function getTotalUserVestments(address _user) public view returns (uint) {
        require(_user != address(0), "StablzIncentiveCannavestPool: _user cannot equal the zero address");
        return _userVestments[_user].length;
    }

    /// @notice Get a list of vestments for a given user
    /// @param _user User
    /// @param _startIndex Start index
    /// @param _endIndex End index
    /// @return list List of vestments for _user between _startIndex and _endIndex
    function getUserVestments(address _user, uint _startIndex, uint _endIndex) external view returns (Vestment[] memory list) {
        uint total = getTotalUserVestments(_user);

        require(_startIndex <= _endIndex, "StablzIncentiveCannavestPool: Start index must be less than or equal to end index");
        require(_startIndex < total, "StablzIncentiveCannavestPool: Invalid start index");
        require(_endIndex < total, "StablzIncentiveCannavestPool: Invalid end index");

        list = new Vestment[](_endIndex - _startIndex + 1);
        uint listIndex;
        for (uint index = _startIndex; index <= _endIndex; index++) {
            list[listIndex] = vestments[_userVestments[_user][index]];
            listIndex++;
        }
        return list;
    }

    /// @notice Get a list of vestments
    /// @param _startIndex Start index
    /// @param _endIndex End index
    /// @return list List of vestments between _startIndex and _endIndex
    function getVestments(uint _startIndex, uint _endIndex) external view returns (Vestment[] memory list) {
        require(_startIndex <= _endIndex, "StablzIncentiveCannavestPool: Start index must be less than or equal to end index");
        require(_startIndex < totalVestments, "StablzIncentiveCannavestPool: Invalid start index");
        require(_endIndex < totalVestments, "StablzIncentiveCannavestPool: Invalid end index");

        list = new Vestment[](_endIndex - _startIndex + 1);
        uint listIndex;
        for (uint vestmentId = _startIndex; vestmentId <= _endIndex; vestmentId++) {
            list[listIndex] = vestments[vestmentId];
            listIndex++;
        }
        return list;
    }

    /// @param _amount Amount of USDT
    function _allocateIncentiveRewards(uint _amount) private {
        uint rewards = _amount * 10 ** 12;
        require(rewards <= getUnallocatedStablz(), "StablzIncentiveCannavestPool: There aren't enough stablz rewards available");
        totalStablzAllocated += rewards;
        uint vestmentId = totalVestments;
        vestments[vestmentId] = Vestment(vestmentId, _msgSender(), rewards, 0, block.timestamp);
        _userVestments[_msgSender()].push(vestmentId);
        totalVestments++;
    }

    /// @param _vestmentId Vestment ID
    /// @return amount Amount available to claim for _vestmentId
    function _claimStablzRewards(uint _vestmentId) private returns (uint amount) {
        require(_vestmentId < totalVestments, "StablzIncentiveCannavestPool: _vestmentId does not exist");
        Vestment storage vestment = vestments[_vestmentId];
        require(vestment.user == _msgSender(), "StablzIncentiveCannavestPool: Vestment does not belong to you");
        require(vestment.withdrawn < vestment.amount, "StablzIncentiveCannavestPool: Already withdrawn full amount for a specific vestment");
        uint endDate = vestment.startDate + INCENTIVE_VESTING_PERIOD;
        if (block.timestamp >= endDate) {
            amount = vestment.amount - vestment.withdrawn;
        } else {
            uint timeDifference = block.timestamp - vestment.startDate;
            amount = (vestment.amount * timeDifference / INCENTIVE_VESTING_PERIOD) - vestment.withdrawn;
        }
        vestment.withdrawn += amount;
        return amount;
    }

    /// @inheritdoc ERC20
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint _amount
    ) internal override {
        super._beforeTokenTransfer(_from, _to, _amount);
        if (_inbound) {
            require(incentivesEndAt <= block.timestamp, "StablzIncentiveCannavestPool: Unable to list during the incentive period");
        }
        require(0 < _amount, "StablzIncentiveCannavestPool: _amount must be greater than zero");
        require(
            /// @dev mint
            _from == address(0) ||
            /// @dev delist or purchase
            _from == address(this) ||
            /// @dev burn
            _to == address(0) ||
            /// @dev list
            (_to == address(this) && _inbound),
            "StablzIncentiveCannavestPool: Receipt token is only transferrable via OTC, depositing, and withdrawing"
        );
        if (_from != address(0) && _from != address(this)) {
            _mergeRewards(_from);
        }
        if (_to != address(0) && _to != address(this)) {
            _mergeRewards(_to);
        }
    }

    /// @param _user User address
    /// @return uint Final amount to withdraw for _user
    function _calculateFinalAmount(address _user) private view returns (uint) {
        return finalAmount * _getTotalBalance(_user) / finalSupply;
    }

    /// @param _user User address
    /// @return uint Balance of _user + OTC amount listed by _user
    function _getTotalBalance(address _user) private view returns (uint) {
        return balanceOf(_user) + _getUserAmountListed(_user);
    }

    /// @dev get the total amount staked (not including otc listings)
    /// @return uint Circulating supply
    function _getCirculatingSupply() private view returns (uint) {
        return totalSupply() - totalAmountListed;
    }

    /// @dev Merge calculated rewards with held rewards
    /// @param _user User address
    function _mergeRewards(address _user) private {
        /// @dev move calculated rewards into held rewards
        _holdCalculatedRewards(_user);
        /// @dev clear calculated rewards
        _rewards[_user].factor = currentRewardFactor;
    }

    /// @dev Convert calculated rewards into held rewards
    /// @dev Used when the user carries out an action that would cause their calculated rewards to change
    function _holdCalculatedRewards(address _user) private {
        uint calculatedReward = _getCalculatedRewards(_user);
        if (calculatedReward > 0) {
            _rewards[_user].held += calculatedReward;
        }
    }

    /// @param _user User address
    /// @return uint Held rewards
    function _getHeldRewards(address _user) private view returns (uint) {
        return _rewards[_user].held;
    }

    /// @param _user User address
    /// @return uint Calculated rewards
    function _getCalculatedRewards(address _user) private view returns (uint) {
        uint balance = balanceOf(_user);
        return balance * (currentRewardFactor - _rewards[_user].factor) / REWARD_FACTOR_ACCURACY;
    }

    /// @return bool true - active, false - not active
    function _isPoolActive() internal view override returns (bool) {
        /// @dev checks !hasEnded() too because block.timestamp can vary
        return block.timestamp <= getEndDate() && !hasEnded();
    }
}