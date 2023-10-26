// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./utils/Initializable.sol";

import "./interface/ICRVDepositor.sol";
import "./interface/IClaimRewards.sol";
import "./interface/ICRVFactory.sol";
import "./interface/ICRVGauge.sol";
import "./interface/IDelegation.sol";
import "./interface/IPool.sol";
import "./interface/IRegistry.sol";
import "./interface/IERC20.sol";
import "./sdCRV3.sol";
import "./ReentrancyGuard.sol";
import "./libraries/Errors.sol";


contract sdCurveCDP is Initializable, ReentrancyGuardUpgradeable {
    struct PoolData {
        address rewardToken;
        uint256 accRewardPerShare; // Accumulated Rewards per share, times 1e36. See below.
        uint256 rewardRate;
        uint256 reserves;
    }
    address public admin;
    address public crvAddress; // CRV Token Address
    address public sdCRV3Address; // bentCVX3 Token Address - Use this Address to Mint sdCRV3 Address
    address public sdCRVAddress; // sdCRV Token Address
    address public crvDepositAddress; // CRV Depositor Address
    address public crvFactoryAddress; // Stake Dao Factory Address
    address public sdGaugeAddress; // Gaude To Deposit sdCRV
    address public claimContractAddress; // Claim Contract
    uint256 public totalSupply;
    uint256 public rewardPoolsCount;

    uint256 public windowLength; // amount of blocks where we assume around 12 sec per block
    uint256 public minWindowLength; // minimum amount of blocks where 7200 = 1 day
    uint256 public endRewardBlock; // end block of rewards stream
    uint256 public lastRewardBlock; // last block of rewards streamed
    uint256 public harvesterFee; // percentage fee to onReward caller where 100 = 1%
    bool public unLocked; //for locking claims
    //Fees distribution
    mapping(address => uint256) public onRewardFee;
    mapping(address => uint256) public reStakeFee;
    mapping(address => uint256) public newRewardFinal;
    uint256 public onRewardPercentage;
    uint256 public reStakePercentage;
    uint256 public masterClaimPercentage;
    uint256 public adminPercentage;
    struct FeeData {
        address feeToken;
        uint256 feeReserves;
    }
    mapping(uint256 => FeeData) public feePools;
    mapping(address => bool) public isFeeToken;
    uint256 public feePoolsCount;
    //swap
    address public pool;
    address public registry;
    uint256 public minBalance;

    mapping(address => uint256) public balanceOf;
    mapping(uint256 => PoolData) public rewardPools;
    mapping(address => bool) public isRewardToken;
    mapping(uint256 => mapping(address => uint256)) internal userRewardDebt;
    mapping(uint256 => mapping(address => uint256)) internal userPendingRewards;

    event DepositCRV(address indexed _from, uint _value);
    event DepositsdCRV(address indexed _from, uint _value);
    event WithdrawCRV(address indexed _from, uint _value);
    event ClaimAll(address indexed _from);
    event userClaim(address indexed _from, uint _amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Invalid Admin");
        _;
    }
    modifier unlocked() {
        require(unLocked == true, "Locked! Can't claim at the moment.");
        _;
    }

    function initialize(
        address _crvAddress,
        address _sdCRVAddress,
        address _crvDepositAddress,
        address _claimAddress,
        address _sdGaugeAddress,
        address _sdCRV3Address,
        address _pool,
        address _registry,
        uint256 _widowLength
    ) external initializer {
        admin = msg.sender;
        crvAddress = _crvAddress;
        sdCRVAddress = _sdCRVAddress;
        crvDepositAddress = _crvDepositAddress;
        claimContractAddress = _claimAddress;
        sdGaugeAddress = _sdGaugeAddress;
        sdCRV3Address = _sdCRV3Address;
        pool = _pool;
        registry = _registry;
        windowLength = _widowLength;
        minWindowLength = 300;
        totalSupply = 0;
        harvesterFee = 100;
        onRewardPercentage = 2500;
        reStakePercentage = 2500;
        masterClaimPercentage = 2500;
        adminPercentage = 2500;
    }

    /**
     * @notice set Reward Harvest Fee.
     * @param _address The Fee to Charge 1 = 1%;
     **/
    function setCRVAddress(address _address) public onlyAdmin {
        require(address(0) == _address, "Null Address Provided");
        crvAddress = _address;
    }

    function setsdCRVAddress(address _address) public onlyAdmin {
        require(address(0) == _address, "Null Address Provided");
        sdCRVAddress = _address;
    }

    function setcrvDepositAddress(address _address) public onlyAdmin {
        require(address(0) == _address, "Null Address Provided");
        crvDepositAddress = _address;
    }

    function setclaimAddress(address _address) public onlyAdmin {
        require(address(0) == _address, "Null Address Provided");
        claimContractAddress = _address;
    }

    function setsdGaugeAddress(address _address) public onlyAdmin {
        require(address(0) == _address, "Null Address Provided");
        sdGaugeAddress = _address;
    }

    function setsdCRV3Address(address _address) public onlyAdmin {
        require(address(0) == _address, "Null Address Provided");
        sdCRV3Address = _address;
    }

    /**
     * @notice set Reward Harvest Fee.
     * @param _fee The Fee to Charge 1 = 1%;
     **/
    function setHarvesterFee(uint256 _fee) public onlyAdmin {
        harvesterFee = _fee;
    }

    //Fee Distribution
    function setOnRewardPercentage(uint256 _fee) external onlyAdmin {
        onRewardPercentage = _fee;
    }

    function setreStakePercentage(uint256 _fee) external onlyAdmin {
        reStakePercentage = _fee;
    }

    function setmasterClaimPercentage(uint256 _fee) external onlyAdmin {
        masterClaimPercentage = _fee;
    }

    function setadminPercentage(uint256 _fee) external onlyAdmin {
        adminPercentage = _fee;
    }

    function setPoolAddress(address _pool) external onlyAdmin {
        pool = _pool;
    }

    /**
     * @notice set Window Length.
     * @param _windowLength Number of Blocks. 7200 =  1 day ;
     **/
    function setWindowLength(uint256 _windowLength) public onlyAdmin {
        require(_windowLength >= minWindowLength, Errors.INVALID_WINDOW_LENGTH);
        windowLength = _windowLength;
    }

    /**
     * @notice set Window Length.
     * @param _windowLength The Window Length. Its Number of Blocks;
     **/
    function setMinWindowLength(uint256 _windowLength) public onlyAdmin {
        require(_windowLength >= minWindowLength, Errors.INVALID_WINDOW_LENGTH);
        minWindowLength = _windowLength;
    }

    function addRewardTokens(address[] memory _rewardTokens) public onlyAdmin {
        uint256 length = _rewardTokens.length;
        for (uint256 i = 0; i < length; ++i) {
            require(!isRewardToken[_rewardTokens[i]], Errors.ALREADY_EXISTS);
            rewardPools[rewardPoolsCount + i].rewardToken = _rewardTokens[i];
            isRewardToken[_rewardTokens[i]] = true;
        }
        rewardPoolsCount += length;
    }

    function removeRewardToken(uint256 _index) external onlyAdmin {
        require(_index < rewardPoolsCount, Errors.INVALID_INDEX);
        isRewardToken[rewardPools[_index].rewardToken] = false;
        delete rewardPools[_index];
    }

    function addFeeTokens(address[] memory _feeTokens) public onlyAdmin {
        uint256 length = _feeTokens.length;
        for (uint256 i = 0; i < length; ++i) {
            require(!isFeeToken[_feeTokens[i]], Errors.ALREADY_EXISTS);
            feePools[feePoolsCount + i].feeToken = _feeTokens[i];
            isFeeToken[_feeTokens[i]] = true;
        }
        feePoolsCount += length;
    }

    function removeFeeToken(uint256 _index) external onlyAdmin {
        require(_index < feePoolsCount, Errors.INVALID_INDEX);
        isFeeToken[feePools[_index].feeToken] = false;
        delete feePools[_index];
    }
    function setminBalance(uint256 _minBlance) external onlyAdmin {
        minBalance = _minBlance;
    }

    /**
     * @notice onTransfer transfer the ownership of deposits .
     * @param _user old owner of the deposit
     * @param _newOwner new Owner of the deposit
     * @param _amount Amount to Transfer
     **/
    function onTransfer(
        address _user,
        address _newOwner,
        uint256 _amount
    ) external nonReentrant {
        require(msg.sender == sdCRV3Address, "No Right To Call Transfer");
        require(balanceOf[_user] >= _amount, "User Dont have enough deposit");
        uint256 userBalance = balanceOf[_user];
        _updateAccPerShare(true, _user);
        _updateAccPerShare(true, _newOwner);
        unchecked {
            balanceOf[_user] = userBalance - _amount;
            balanceOf[_newOwner] = balanceOf[_newOwner] + _amount;
        }

        _updateUserRewardDebt(_user);
        _updateUserRewardDebt(_newOwner);
    }

    /**
     * @notice User Pending Reward
     * @param user User Address
     **/
    function pendingReward(
        address user
    ) external view returns (uint256[] memory pending) {
        uint256 _rewardPoolsCount = rewardPoolsCount;
        pending = new uint256[](_rewardPoolsCount);
        if (totalSupply != 0) {
            uint256[] memory addedRewards = _calcAddedRewards();
            for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
                PoolData memory pool = rewardPools[i];
                if (pool.rewardToken == address(0)) {
                    continue;
                }
                uint256 newAccRewardPerShare = pool.accRewardPerShare +
                    ((addedRewards[i] * 1e36) / totalSupply);

                pending[i] =
                    userPendingRewards[i][user] +
                    ((balanceOf[user] * newAccRewardPerShare) / 1e36) -
                    userRewardDebt[i][user];
            }
        }
    }

    /**
     * @dev Deposit CVX to Get bentCVX3
     * @param _amount Amount to deposit. 1 CVX for 1 3vlCVX
     **/
    function depositCRV(uint256 _amount) external nonReentrant {
        require(_amount > 0, "DepositCRV: Zero Amount is not acceptable");
        IERC20 crvToken = IERC20(crvAddress);
        IERC20 sdcrvToken = IERC20(sdCRVAddress);
        ICrvDepositor crvDepositor = ICrvDepositor(crvDepositAddress);
        uint256 userCRVBalance = crvToken.balanceOf(msg.sender);
        require(userCRVBalance >= _amount, "Not Enough CRV Balance");
        uint256 userAmount = balanceOf[msg.sender];
        sdCRV3 sdCRV3Contract = sdCRV3(sdCRV3Address);
        _updateAccPerShare(true, msg.sender);
        crvToken.transferFrom(msg.sender, address(this), _amount);

        uint256 quantity = getQuantity(_amount);
        uint256 depositAmount = 0;

        if (quantity > _amount) {
            depositAmount = swap(_amount, quantity);
            ICRVGauge sdcrvDepositor = ICRVGauge(sdGaugeAddress);
            sdcrvToken.approve(sdGaugeAddress, depositAmount);
            sdcrvDepositor.deposit(depositAmount);
        } else {
            depositAmount = _amount;
            crvToken.approve(crvDepositAddress, depositAmount);
            crvDepositor.deposit(_amount, false, true, address(this));
        }

        sdCRV3Contract.mintRequest(msg.sender, depositAmount);
        totalSupply += depositAmount;

        unchecked {
            balanceOf[msg.sender] = userAmount + depositAmount;
        }
        _updateUserRewardDebt(msg.sender);
        emit DepositCRV(msg.sender, depositAmount);
    }

    /**
     * @dev Deposit BentCVX to Get bentCVX3
     * @param _amount Amount to deposit. 1 bentCVX for 1 3vlCVX
     **/

    function depositsdCRV(uint256 _amount) external nonReentrant {
        require(_amount > 0, "DepositsdCRV: Zero Amount is not acceptable");
        IERC20 sdcrvToken = IERC20(sdCRVAddress);
        ICRVGauge sdcrvDepositor = ICRVGauge(sdGaugeAddress);
        uint256 usersdCRVBalance = sdcrvToken.balanceOf(msg.sender);
        sdCRV3 sdCRV3Contract = sdCRV3(sdCRV3Address);
        require(usersdCRVBalance >= _amount, "Not Enough sdCRV Balance");
        uint256 userAmount = balanceOf[msg.sender];
        _updateAccPerShare(true, msg.sender);
        sdcrvToken.transferFrom(msg.sender, address(this), _amount);
        sdcrvToken.approve(sdGaugeAddress, _amount);
        sdcrvDepositor.deposit(_amount);
        sdCRV3Contract.mintRequest(msg.sender, _amount);
        totalSupply += _amount;
        unchecked {
            balanceOf[msg.sender] = userAmount + _amount;
        }
        _updateUserRewardDebt(msg.sender);
        emit DepositsdCRV(msg.sender, _amount);
    }

    /**
     * @notice withdraw CVX to Get bentCVX3
     * @param _amount Amount to Withdraw. 1 CVX for 1 3vlCVX
     **/
    function withdrawsdCRV(uint256 _amount) external nonReentrant {
        require(_amount > 0, "WithdrawsdCRV: Zero Amount is not acceptable");
        uint256 userBalance = balanceOf[msg.sender];
        sdCRV3 sdCRV3Contract = sdCRV3(sdCRV3Address);
        ICRVGauge sdcrvDepositor = ICRVGauge(sdGaugeAddress);
        IERC20 sdCRVContract = IERC20(sdCRVAddress);
        require(userBalance >= _amount, "Sender have no enough Deposit");
        _updateAccPerShare(true, msg.sender);
        sdcrvDepositor.withdraw(_amount);
        sdCRV3Contract.burnRequest(msg.sender, _amount);
        sdCRVContract.transfer(msg.sender, _amount);
        totalSupply -= _amount;
        unchecked {
            balanceOf[msg.sender] = userBalance - _amount;
        }
        _updateUserRewardDebt(msg.sender);
        emit WithdrawCRV(msg.sender, _amount);
    }

    function claimAll(
        address _user
    ) external nonReentrant unlocked returns (bool claimed) {
        _updateAccPerShare(true, _user);
        //update
        _updateAccPerShare(true, address(this));
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            uint256 claimAmount = _claim(i, _user);
            if (claimAmount > 0) {
                claimed = true;
            }
        }
        _updateUserRewardDebt(_user);
        //update
        _updateUserRewardDebt(address(this));
    }

    /**
     * @notice Claim User Reward
     * @param pid Reward Pool Index
     **/
    function claim(uint256 pid) external unlocked nonReentrant {
        _updateAccPerShare(true, msg.sender);
        //update
        _updateAccPerShare(true, address(this));
        _claim(pid, msg.sender);
        _updateUserRewardDebt(msg.sender);
        //update
        _updateUserRewardDebt(address(this));
    }

    function setDelegate(
        bytes32 id,
        address _delegateContract,
        address _delegate
    ) external nonReentrant onlyAdmin {
        IDelegation(_delegateContract).setDelegate(id, _delegate);
    }

    function updateReserve() external nonReentrant onlyAdmin {
        for (uint256 i = 0; i < rewardPoolsCount; ++i) {
            PoolData storage pool = rewardPools[i];
            if (pool.rewardToken == address(0)) {
                continue;
            }
            uint256 newRewards = IERC20(pool.rewardToken).balanceOf(
                address(this)
            ) - pool.reserves;
            pool.reserves += newRewards;
            newRewardFinal[pool.rewardToken] += newRewards;
        }
    }

    function change_admin(address _address) external onlyAdmin {
        require(address(0) != _address, "Can not Set Zero Address");
        admin = _address;
    }

    /**
     * @notice withdraw Any Token By Owner of Contract
     * @param _token token Address to withdraw
     * @param _amount Amount of token to withdraw
     **/
    function withdraw_admin(
        address _token,
        uint256 _amount
    ) external nonReentrant onlyAdmin {
        IERC20(_token).transfer(admin, _amount);
    }

    function _updateAccPerShare(bool withdrawReward, address user) internal {
        uint256[] memory addedRewards = _calcAddedRewards();
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            PoolData storage pool = rewardPools[i];
            if (pool.rewardToken == address(0)) {
                continue;
            }

            if (totalSupply == 0) {
                pool.accRewardPerShare = block.number;
            } else {
                pool.accRewardPerShare +=
                    (addedRewards[i] * (1e36)) /
                    totalSupply;
            }

            if (withdrawReward) {
                uint256 pending = ((balanceOf[user] * pool.accRewardPerShare) /
                    1e36) - userRewardDebt[i][user];
                if (pending > 0) {
                    userPendingRewards[i][user] += pending;
                }
            }
        }

        lastRewardBlock = block.number;
    }

    function _updateUserRewardDebt(address user) internal {
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            if (rewardPools[i].rewardToken != address(0)) {
                userRewardDebt[i][user] =
                    (balanceOf[user] * rewardPools[i].accRewardPerShare) /
                    1e36;
            }
        }
    }

    // Should We Call Rewarder or Staker Contract For Getting Claim. Make Sure of it!!
    function masterClaim() external nonReentrant {
        // Master Claim Functionaltiy
        address[] memory _gauges = new address[](1);
        _gauges[0] = address(sdGaugeAddress);
        IClaimRewards claimContract = IClaimRewards(claimContractAddress);
        claimContract.claimRewards(_gauges);
        //Fee Percentrage
        _updateAccPerShare(false, address(0)); //to update lastrewardblock

        for (uint256 i = 0; i < feePoolsCount; ++i) {
            FeeData storage feePool = feePools[i];
            if (feePool.feeToken == address(0)) {
                continue;
            }

            uint256 newRewards = IERC20(feePool.feeToken).balanceOf(
                address(this)
            ) - feePool.feeReserves;

            uint256 newRewardsFees = (newRewards * harvesterFee) / 10000;
            // uint256 newRewardsFinal = newRewards - newRewardsFees;

            feePool.feeReserves += newRewardsFees;

            uint256 masterClaimReward = (newRewardsFees *
                masterClaimPercentage) / 10000;
            uint256 adminReward = (newRewardsFees * adminPercentage) / 10000;
            uint256 onRewardReward = (newRewardsFees * onRewardPercentage) /
                10000;
            uint256 reStakeReward = (newRewardsFees * reStakePercentage) /
                10000;

            onRewardFee[feePool.feeToken] += onRewardReward;
            reStakeFee[feePool.feeToken] += reStakeReward;

            if (masterClaimReward > 0) {
                 feePool.feeReserves =
                    feePool.feeReserves -
                    (masterClaimReward + adminReward);

                IERC20(feePool.feeToken).transfer(
                    msg.sender,
                    masterClaimReward
                );
                IERC20(feePool.feeToken).transfer(admin, adminReward);
            }
        }

    }

    function masterWithdraw() external onlyAdmin {
        ICRVGauge sdcrvDepositor = ICRVGauge(sdGaugeAddress);
        sdcrvDepositor.withdraw(sdcrvDepositor.balanceOf(address(this)));
    }

    function onReward(address[9] memory _route1,
        uint256[3][4] calldata i1,
        address[4] memory pools,
        address[9] memory _route2,
        uint256[3][4] calldata i2,
        address[9] memory _route3,
        uint256[3][4] calldata i3
        ) external nonReentrant {
 
        for (uint256 i = 0; i < feePoolsCount; ++i) {
            FeeData storage feePool = feePools[i];
            require(IERC20(feePool.feeToken).balanceOf(address(this)) >= minBalance,"OnReward: Contract has not enough balance");
        }  
        //swapping Rewards into sdCRV
        AllRewardsSwap(_route1, i1, pools, _route2, i2, _route3, i3);
        
        _updateAccPerShare(false, address(0));

        bool newRewardsAvailable = false;
        for (uint256 i = 0; i < rewardPoolsCount; ++i) {
            PoolData storage pool = rewardPools[i];
            if (pool.rewardToken == address(0)) {
                continue;
            }

            uint256 newRewardsFinal = newRewardFinal[pool.rewardToken];
    
            if (newRewardsFinal > 0) {
                newRewardsAvailable = true;
            }
            if (endRewardBlock > lastRewardBlock) {
                pool.rewardRate =
                    (pool.rewardRate *
                        (endRewardBlock - lastRewardBlock) +
                        newRewardsFinal *
                        1e36) /
                    windowLength;
            } else {
                pool.rewardRate = (newRewardsFinal * 1e36) / windowLength;
            }
            newRewardFinal[pool.rewardToken] = 0;
        }

        for (uint256 i = 0; i < feePoolsCount; ++i) {
            FeeData storage feePool = feePools[i];
            if (onRewardFee[feePool.feeToken] > 0) {
                uint256 amount = onRewardFee[feePool.feeToken];
                onRewardFee[feePool.feeToken] = 0;

                IERC20(feePool.feeToken).transfer(msg.sender, amount);
            }
        }

        require(newRewardsAvailable, Errors.ZERO_AMOUNT);
        endRewardBlock = lastRewardBlock + windowLength;
    }

    function _claim(
        uint256 pid,
        address user
    ) internal returns (uint256 claimAmount) {
        if (rewardPools[pid].rewardToken == address(0)) {
            return 0;
        } //update
        uint256 _claimAmount = userPendingRewards[pid][user];
        uint256 compoundRewards = userPendingRewards[pid][address(this)];
        uint256 beneficiaries = totalSupply - balanceOf[address(this)]; //total user staked
        uint256 finalAmountPerShare = compoundRewards / beneficiaries;
        uint256 userCompoundShare = balanceOf[user] * finalAmountPerShare;
        claimAmount = _claimAmount + userCompoundShare;
        userPendingRewards[pid][address(this)] -= userCompoundShare;

        if (claimAmount > 0) {
            // update for reward restaked
            uint256 contractBalance = (
                IERC20(rewardPools[pid].rewardToken).balanceOf(address(this))
            );
            if (claimAmount > contractBalance) {
                uint256 _amount = claimAmount - contractBalance;
                withdrawRestaked(_amount);
            }

            IERC20(rewardPools[pid].rewardToken).transfer(user, claimAmount);
           
            rewardPools[pid].reserves -= _claimAmount;
            userPendingRewards[pid][user] = 0;
        }
    }

    function _calcAddedRewards()
        internal
        view
        returns (uint256[] memory addedRewards)
    {
        uint256 startBlock = endRewardBlock > lastRewardBlock + windowLength
            ? endRewardBlock - windowLength
            : lastRewardBlock;
        uint256 endBlock = block.number > endRewardBlock
            ? endRewardBlock
            : block.number;
        uint256 duration = endBlock > startBlock ? endBlock - startBlock : 0;
        uint256 _rewardPoolsCount = rewardPoolsCount;
        addedRewards = new uint256[](_rewardPoolsCount);
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            addedRewards[i] = (rewardPools[i].rewardRate * duration) / 1e36;
        }
    }

    //update
    function reStake(uint256 _amount) external {
        require(_amount > 0, "reStake: Zero Amount is not acceptable");
        IERC20 sdcrvToken = IERC20(sdCRVAddress);
        ICRVGauge sdcrvDepositor = ICRVGauge(sdGaugeAddress);
        uint256 contractsdCRVBalance = sdcrvToken.balanceOf(address(this));
        require(contractsdCRVBalance >= _amount, "Not Enough sdCRV Balance");
        uint256 userAmount = balanceOf[address(this)];
        sdCRV3 sdCRV3Contract = sdCRV3(sdCRV3Address);
        _updateAccPerShare(true, address(this));

        sdcrvToken.approve(sdGaugeAddress, _amount);
        sdcrvDepositor.deposit(_amount);

        sdCRV3Contract.mintRequest(address(this), _amount);
        totalSupply += _amount;
        unchecked {
            balanceOf[address(this)] = userAmount + _amount;
        }
        //fee distribution
        for (uint256 i = 0; i < feePoolsCount; ++i) {
            FeeData storage feePool = feePools[i];
            if (feePool.feeToken == address(0)) {
                continue;
            }
            if (reStakeFee[feePool.feeToken] > 0) {
                uint256 amount = reStakeFee[feePool.feeToken];
                reStakeFee[feePool.feeToken] = 0;

                IERC20(feePool.feeToken).transfer(msg.sender, amount);
            }
        }
        _updateUserRewardDebt(address(this));
    }

    function reStakedAmount() public view returns (uint256 amount) {
        amount = balanceOf[address(this)];
    }

    function withdrawRestaked(uint256 _amount) private {
        require(_amount > 0, "WithdrawRestaked: Zero Amount is not acceptable");
        uint256 userBalance = balanceOf[address(this)];
        sdCRV3 sdCRV3Contract = sdCRV3(sdCRV3Address);
        require(userBalance >= _amount, "Not enough Deposit");
        _updateAccPerShare(true, address(this));
        sdCRV3Contract.burnRequest(address(this), _amount);
        ICRVGauge sdcrvDepositor = ICRVGauge(sdGaugeAddress);
        sdcrvDepositor.withdraw(_amount);

        totalSupply -= _amount;
        unchecked {
            balanceOf[address(this)] = userBalance - (_amount);
        }
        _updateUserRewardDebt(address(this));
    }

    function withdrawsdCRVAndClaimAll()
        external
        nonReentrant
        returns (bool claimed)
    {
        uint256 userBalance = balanceOf[msg.sender];
        sdCRV3 sdCRV3Contract = sdCRV3(sdCRV3Address);
        ICRVGauge sdcrvDepositor = ICRVGauge(sdGaugeAddress);
        IERC20 sdCRVContract = IERC20(sdCRVAddress);
        require(userBalance > 0, "Sender have no Deposit");
        _updateAccPerShare(true, msg.sender);

        _updateAccPerShare(true, address(this));
        sdcrvDepositor.withdraw(userBalance);

        sdCRV3Contract.burnRequest(msg.sender, userBalance);
        sdCRVContract.transfer(msg.sender, userBalance);

        //update
        unchecked {
            totalSupply -= userBalance;
            balanceOf[msg.sender] = 0;
        }
        // claim
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            uint256 claimAmount = _claim(i, msg.sender);
            if (claimAmount > 0) {
                claimed = true;
            }
        }

        _updateUserRewardDebt(msg.sender);
        _updateUserRewardDebt(address(this));

        emit WithdrawCRV(msg.sender, userBalance); //change event name
        emit ClaimAll(msg.sender);
    }

    function unlockClaiming() external onlyAdmin {
        require(unLocked == false, "Already un-locked");
        unLocked = true;
    }

    function lockClaiming() external onlyAdmin {
        require(unLocked == true, "Already Locked");
        unLocked = false;
    }

    function getQuantity(uint256 amountA) public returns (uint256 quantity) {
        quantity = Ipool(pool).get_dy(0, 1, amountA);
    }

    function swap(
        uint256 amountA,
        uint256 amountB
    ) public returns (uint256 _swapped) {
        IERC20 crvToken = IERC20(crvAddress);
        crvToken.approve(pool, amountA);
        _swapped = Ipool(pool).exchange(0, 1, amountA, amountB);
    }

    function grandSwap(
        address[9] memory _route,
        uint256[3][4] calldata i,
        uint256 _amountA,
        address[4] memory pools
    ) internal {
        IERC20 Token = IERC20(_route[0]);
        Token.approve(registry, _amountA);
        Iregistry(registry).exchange_multiple(_route, i, _amountA, 0, pools);
    }

    function AllRewardsSwap(
        address[9] memory _route1,
        uint256[3][4] calldata i1,
        address[4] memory pools,
        address[9] memory _route2,
        uint256[3][4] calldata i2,
        address[9] memory _route3,
        uint256[3][4] calldata i3
    ) internal {
        //for swapping all reward into sdCRV
        address sdtAddress = address(
            0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F
        );
        address crv3Address = address(
            0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490
        );
        uint256 balance1 = (IERC20(crv3Address).balanceOf(address(this)) >
            (onRewardFee[crv3Address] + reStakeFee[crv3Address]))
            ? (IERC20(crv3Address).balanceOf(address(this)) -
                (onRewardFee[crv3Address] + reStakeFee[crv3Address]))
            : 0;

        uint256 balance2 = (IERC20(crvAddress).balanceOf(address(this)) >
            (onRewardFee[crvAddress] + reStakeFee[crvAddress]))
            ? (IERC20(crvAddress).balanceOf(address(this)) -
                (onRewardFee[crvAddress] + reStakeFee[crvAddress]))
            : 0;

        uint256 balance3 = (IERC20(sdtAddress).balanceOf(address(this)) >
            (onRewardFee[sdtAddress] + reStakeFee[sdtAddress]))
            ? (IERC20(sdtAddress).balanceOf(address(this)) -
                (onRewardFee[sdtAddress] + reStakeFee[sdtAddress]))
            : 0;
        uint256 balanceBefore = IERC20(sdCRVAddress).balanceOf(address(this));
        if (balance1 > 0) {
            grandSwap(_route1, i1, balance1, pools);
        }
        if (balance2 > 0) {
            grandSwap(_route2, i2, balance2, pools);
        }
        if (balance3 > 0) {
            grandSwap(_route3, i3, balance3, pools);
        }
        uint256 balanceAfter = IERC20(sdCRVAddress).balanceOf(address(this));
        uint256 newRewards = balanceAfter - balanceBefore;

        newRewardFinal[sdCRVAddress] += newRewards;
        PoolData storage _pool = rewardPools[0];
        _pool.reserves += newRewards;
    }
}