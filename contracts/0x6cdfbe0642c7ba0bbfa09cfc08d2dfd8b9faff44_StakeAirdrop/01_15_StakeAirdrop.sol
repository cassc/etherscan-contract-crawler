// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import {AirdropAccessControl} from "../src/utils/AirdropAccessControl.sol";
import {FireCatTransfer} from "../src/utils/FireCatTransfer.sol";
import {IStakeAirdrop} from "../src/interfaces/IStakeAirdrop.sol";

/**
 * @title FireCat's StakeAirdrop contract
 * @notice main: stake, claim, topUP
 * @author FireCat Finance
 */
contract StakeAirdrop is IStakeAirdrop, FireCatTransfer, AirdropAccessControl {
    using SafeMath for uint256;

    event SetStakeOn(bool isStakeOn_);
    event SetClaimOn(bool isClaimOn_);
    event SetImportOn(bool isImportOn_);
    event SetTopUpAmount(uint256 topUpAmount_);
    event SetCycleTime(uint256 startAt_, uint256 expiredAt_);
    event SetReleaseConfig(uint256[] releaseTimePeriod_, uint256[] releaseNumFactor_);
    event TopUp(address user_, uint256 amount_, uint256 totalSupplyNew_);
    event Staked(address user_, uint256 actualAddAmount_, uint256 totalStakedNew_);
    event Claimed(address user_, uint256 actualSubAmount_, uint256 totalClaimedNew_);
    event ExportStaked(uint256 startIndex_, uint256 endIndex_);

    /**
    * @dev switch on/off the stake function.
    */
    bool public isStakeOn = false;

    /**
    * @dev switch on/off the claim function.
    */
    bool public isClaimOn = false;

     /**
    * @dev switch on/off the importStaked function.
    */
    bool public isImportOn = false;

    address public airdropToken;
    address public stakeToken;
    uint256 public cycleId;

    /**
    * @dev the start timestamp of the stake.
    */
    uint256 private _startAt;

    /**
    * @dev the expired timestamp of the stake.
    */
    uint256 private _expiredAt;

    /**
    * @dev the release time period, such as: [1660000000, 1660000010, 1660000020]
    */
    uint256[] private _releaseTimePeriod;

    /**
    * @dev the release num factor, such as: [30, 30, 40]
    */
    uint256[] private _releaseNumFactor;

    /**
    * @dev the total airdrop amount which is alread exists in the contract.
    */
    uint256 private _totalSupply;
    
    /**
    * @dev the total staked amount which is alread exists in the contract.
    */
    uint256 private _totalStaked;

    /**
    * @dev the total claimed amount which is already transfer from this contract.
    */
    uint256 private _totalClaimed;

    /**
    * @dev the airdrop amount which is shoule be transfer to this contract.
    */
    uint256 private _topUpAmount;

    /**
    * @dev the number of user.
    */
    uint256 private _totalUser;

    /**
    * @dev the array of user
    */
    address[] private _totalUserArray;
    
    /**
    * @dev the label of user who has staked.
    */
    mapping(address => bool) _isMarked;

    /**
    * @dev the staked amount of user.
    */
    mapping(address => uint256) private _staked;

    /**
    * @dev the claimed amount of user.
    */
    mapping(address => uint256) private _claimed;

    function initialize(address admin, uint256 cycleId_, address airdropToken_, address stakeToken_) initializer public {
        cycleId = cycleId_;
        airdropToken = airdropToken_;
        stakeToken = stakeToken_;
        __AccessControl_init();
        __ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    modifier modifyLocked() {
        require(_totalClaimed == 0, "ARD:E07");
        _;
    }

    modifier beforeStake() {
        require(isStakeOn, "ARD:E05");
        _;
    }

    modifier beforeClaim() {
        require(isClaimOn, "ARD:E05");
        _;
    }

    /// @inheritdoc IStakeAirdrop
    function cycle() public view returns (uint256, uint256) {
        return (_startAt, _expiredAt);
    }

    /// @inheritdoc IStakeAirdrop
    function releaseTimePeriod() public view returns (uint256[] memory) {
        return _releaseTimePeriod;
    }

    /// @inheritdoc IStakeAirdrop
    function releaseNumFactor() public view returns (uint256[] memory) {
        return _releaseNumFactor;
    }

    /// @inheritdoc IStakeAirdrop
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IStakeAirdrop
    function topUpAmount() public view returns (uint256) {
        return _topUpAmount;
    }

    /// @inheritdoc IStakeAirdrop
    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    /// @inheritdoc IStakeAirdrop
    function totalClaimed() public view returns (uint256) {
        return _totalClaimed;
    }

    /// @inheritdoc IStakeAirdrop
    function totalUser() public view returns (uint256) {
        return _totalUser;
    }

    /// @inheritdoc IStakeAirdrop
    function stakedOf(address user_) public view returns (uint256) {
        return _staked[user_];
    }

    /// @inheritdoc IStakeAirdrop
    function claimedOf(address user_) public view returns (uint256) {
        return _claimed[user_];
    }

    /// @inheritdoc IStakeAirdrop
    function exportStaked(uint256 startIndex, uint256 endIndex) public view returns(address[] memory, uint256[] memory) {
        uint256 arrayLen = endIndex + 1;
        address[] memory userArray = new address[](arrayLen);
        uint256[] memory userStaked = new uint256[](arrayLen);
        for (uint256 i = startIndex; i < arrayLen; i++) {
            uint256 index = i - startIndex;
            address user = _totalUserArray[i];

            userArray[index] = user;
            userStaked[index] = _staked[user];
        }
        return (userArray, userStaked);
    }

    /// @inheritdoc IStakeAirdrop
    function reviewOf(address user_) public view returns (uint256, uint256, uint256) {
        // totalClaim = _totalSupply * userStaked / totalStaked;
        uint256 totalClaim = _totalSupply.mul(_staked[user_]).div(_totalStaked);

        // _claimFactor = _releaseNumFactor[0] + _releaseNumFactor[1] + _releaseNumFactor[n] + ...;
        uint256 _claimFactor = _selectSumFactor();

        // _maxFakeClaim = totalClaim * _claimFactor / 100;
        uint256 _maxFakeClaim = totalClaim.mul(_claimFactor).div(100);

        // _availableClaim = _maxFakeClaim - user_claimed;
        uint256 availableClaim = _maxFakeClaim.sub(_claimed[user_]);

        // lockedClaim = totalClaim - _maxFakeClaim; 
        uint256 lockedClaim = totalClaim.sub(_maxFakeClaim);

        require(totalClaim <= _totalSupply, "ADR:E08");
        require(availableClaim + _claimed[user_] <= _maxFakeClaim, "ADR:E09");
        require(lockedClaim + _maxFakeClaim <= totalClaim, "ARD:E10");

        return (availableClaim, lockedClaim, totalClaim);
    }

    /**
    * @notice record user address when user stake the token.
    * @param user_ address
    */
    function _markUser(address user_) internal {
        if (!_isMarked[user_]) {
            _isMarked[user_] = true;
            _totalUserArray.push(user_);
            _totalUser += 1;
        }
    }

    /**
    * @notice calculate the sum of releaseNumFactor when timestamp is bigger than last release timePeriod.
    * @return claimFactor
    */
    function _selectSumFactor() internal view returns (uint256) {
        uint256 claimFactor = 0;
        for (uint256 i = 0; i < _releaseTimePeriod.length; i++) {
            if (block.timestamp > _releaseTimePeriod[i]) {
                // _releaseNumFactor[0] + _releaseNumFactor[1] + _releaseNumFactor[n] + ...;
                claimFactor += _releaseNumFactor[i];
            }
        }
        return claimFactor;
    }

    /**
    * @notice calculate the sum of totalStaked.
    * @return totalStaked
    */
    function _updateTotalStaked() internal returns (uint256) {
        uint256 totalStakedNew = 0;
        for (uint256 i = 0; i < _totalUserArray.length; i++) {
            totalStakedNew += _staked[_totalUserArray[i]];
        }
        _totalStaked = totalStakedNew;
        return _totalStaked;
    }

    /// @inheritdoc IStakeAirdrop
    function setStakeOn(bool isStakeOn_) external onlyRole(DATA_ADMIN) {
        isStakeOn = isStakeOn_;
        emit SetStakeOn(isStakeOn_);
    }

    /// @inheritdoc IStakeAirdrop
    function setClaimOn(bool isClaimOn_) external onlyRole(DATA_ADMIN) {
        isClaimOn = isClaimOn_;
        emit SetClaimOn(isClaimOn_);
    }

    /// @inheritdoc IStakeAirdrop
    function setImportOn(bool isImportOn_) external onlyRole(DATA_ADMIN) {
        isImportOn = isImportOn_;
        emit SetImportOn(isImportOn_);
    }

    /// @inheritdoc IStakeAirdrop
    function setTopUpAmount(uint256 topUpAmount_) external modifyLocked onlyRole(DATA_ADMIN) {
        _topUpAmount = topUpAmount_;
        emit SetTopUpAmount(topUpAmount_);
    }

    /// @inheritdoc IStakeAirdrop
    function setCycleTime(uint256 startAt_, uint256 expiredAt_) external modifyLocked onlyRole(DATA_ADMIN) {
        require(startAt_ > block.timestamp && expiredAt_ > startAt_, "ARD:E11");
        _startAt = startAt_;
        _expiredAt = expiredAt_;
        emit SetCycleTime(startAt_, expiredAt_);
    }

    /// @inheritdoc IStakeAirdrop
    function setReleaseConfig(uint256[] memory releaseTimePeriod_, uint256[] memory releaseNumFactor_) external modifyLocked onlyRole(DATA_ADMIN) {
        require(releaseTimePeriod_.length > 0, "ARD:E12");
        require(releaseTimePeriod_.length == releaseNumFactor_.length, "ARD:E06");
        require(releaseTimePeriod_[0] > _expiredAt, "ARD:E13");

        uint256 arrayLen = releaseTimePeriod_.length;
        uint256 releaseNumTotal = 0;
        for (uint256 i = 0; i < arrayLen; i++) {
            if (i + 1 < arrayLen) {
                require(releaseTimePeriod_[i] < releaseTimePeriod_[i + 1], "ARD:E14");
            }

            releaseNumTotal += releaseNumFactor_[i];
        }
        require(releaseNumTotal == 100, "ARD:E15");

        _releaseTimePeriod = releaseTimePeriod_;
        _releaseNumFactor = releaseNumFactor_;
        emit SetReleaseConfig(releaseTimePeriod_, releaseNumFactor_);
    }

    /// @inheritdoc IStakeAirdrop
    function importStaked(address[] memory userArray_, uint256[] memory userStaked_) external modifyLocked onlyRole(DATA_ADMIN) returns (uint256) {
        require(isImportOn, "ARD:E05");
        require(userArray_.length == userStaked_.length, "ARD:E06");

        for (uint256 i = 0; i < userArray_.length; i++) {
            address uesr = userArray_[i];
            uint256 userStaked = userStaked_[i];
            _staked[uesr] = userStaked;
            _markUser(uesr);
        }
        isImportOn = false;
        return _updateTotalStaked();
    }

    /// @inheritdoc IStakeAirdrop
    function withdrawRemaining(address token, uint256 amount) external nonReentrant onlyRole(DATA_ADMIN) returns (uint256) {
        require(!isClaimOn, "ARD:E16");
        return withdraw(token, amount);
    }

    /// @inheritdoc IStakeAirdrop
    function topUp(uint256 addAmount) external modifyLocked onlyRole(DATA_ADMIN) returns (uint256) {
        require(IERC20(airdropToken).balanceOf(msg.sender) >= addAmount, "ARD:E02");
        require(addAmount == _topUpAmount, "ARD:E04");

        uint256 actualAddAmount = doTransferIn(airdropToken, msg.sender, addAmount);
        // totalReservesNew + actualAddAmount
        uint256 totalSupplyNew = _totalSupply.add(actualAddAmount);

        /* Revert on overflow */
        require(totalSupplyNew > _totalSupply, "ARD:E03");

        _totalSupply = totalSupplyNew;
        emit TopUp(msg.sender, actualAddAmount, totalSupplyNew);
        return actualAddAmount;
    }

    /// @inheritdoc IStakeAirdrop
    function stake(uint256 amount) external beforeStake nonReentrant returns (uint256) {
        require(block.timestamp > _startAt && block.timestamp < _expiredAt, "ARD:E01");
        require(IERC20(stakeToken).balanceOf(msg.sender) >= amount, "ARD:E02");

        uint256 actualAddAmount = doTransferIn(stakeToken, msg.sender, amount);
        uint256 totalStakedNew = _totalStaked.add(actualAddAmount);

        require(totalStakedNew > _totalStaked, "ARD:E03");

        _totalStaked = totalStakedNew;
        _staked[msg.sender] = _staked[msg.sender].add(actualAddAmount);

        _markUser(msg.sender);
        emit Staked(msg.sender, actualAddAmount, totalStakedNew);
        return actualAddAmount;
    }

    /// @inheritdoc IStakeAirdrop
    function claim() external beforeClaim nonReentrant returns (uint256) {
        (uint256 availableClaim, uint256 lockedClaim, uint256 totalClaim) = reviewOf(msg.sender);
        require(availableClaim > 0, "ARD:E00");

        IERC20(airdropToken).approve(msg.sender, availableClaim);
        uint256 actualClaimedAmount = doTransferOut(airdropToken, msg.sender, availableClaim);
        _claimed[msg.sender] = _claimed[msg.sender].add(actualClaimedAmount);
        _totalClaimed = _totalClaimed.add(actualClaimedAmount);
        emit Claimed(msg.sender, actualClaimedAmount, _totalClaimed);
        return actualClaimedAmount;
    }

}