// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./utils/Initializable.sol";
import "./interface/IERC20.sol";
import "./vlBENT.sol";
import "./interface/IBentLocker.sol";
import "./ReentrancyGuard.sol";

contract BentCDP is Initializable, ReentrancyGuardUpgradeable {
    address public admin;
    address public bentAddress;
    address public webentAddress;
    address public vlBENT3Address;
    uint256 public depositors;
    uint256 public totalRewardClaimed;
    uint256 public totalSupply;
    mapping(address => uint256) public totalBalances;
    uint256 public windowLength; // amount of blocks where we assume around 12 sec per block
    // uint256 public minWindowLength = 7200; // minimum amount of blocks where 7200 = 1 day
    uint256 public endRewardBlock; // end block of rewards stream
    uint256 public lastRewardBlock; // last block of rewards streamed
    uint256 public harvesterFee; // percentage fee to onReward caller where 100 = 1%

    struct PoolData {
        address rewardToken;
        uint256 accRewardPerShare; // Accumulated Rewards per share, times 1e36. See below.
        uint256 rewardRate;
        uint256 reserves;
    }
    mapping(address => uint256) internal userRewardDebt;
    mapping(address => uint256) internal userPendingRewards;
    PoolData poolData;

    event Deposit(address indexed _from, uint _value);
    event Withdraw(address indexed _from, uint _value);
    event ClaimAll(address indexed _from, uint _value);
    event userClaim(address indexed _from, uint _amount);
    event userWithdraw(address indexed _from, uint _amount);
    event ownerWithdraw(address indexed _from, uint _amount);
    modifier onlyAdmin() {
        require(msg.sender == admin, "Invalid Owner");
        _;
    }

    function initialize(
        address _bentAddress,
        address _webentAddress,
        address _vlBENT3Address
    ) external initializer {
        admin = msg.sender;
        bentAddress = _bentAddress;
        webentAddress = _webentAddress;
        vlBENT3Address = _vlBENT3Address;
        poolData.rewardToken = _bentAddress;
        windowLength = 7200;
        totalSupply = 0;
        harvesterFee = 0;
        totalSupply = 0;
    }

    /**
     * @notice set Reward Harvest Fee.
     * @param _fee The Fee to Charge 1 = 1%;
     **/
    function setHarvesterFee(uint256 _fee) public onlyAdmin {
        //require(_fee <= 100, Errors.EXCEED_MAX_HARVESTER_FEE);
        harvesterFee = _fee;
    }

    /**
     * @notice set BENT Token Address.
     * @param _address Address For Bent Token;
     **/
    function setBentTokenAddress(address _address) external onlyAdmin {
        bentAddress = _address;
    }

    /**
     * @notice set weBENT Token Address.
     * @param _address Address For weBENT Token;
     **/
    function setWeBentAddress(address _address) external onlyAdmin {
        webentAddress = _address;
    }

    /**
     * @notice set 3vlBENT Token Address.
     * @param _address Address For 3vlBENT Token;
     **/
    function setvlvlBENT3Address(address _address) external onlyAdmin {
        vlBENT3Address = _address;
    }

    function pendingReward(
        address user
    ) external view returns (uint256 pending) {
        if (pending != 0) {
            PoolData memory pool = poolData;

            uint256 addedRewards = _calcAddedRewards();
            uint256 newAccRewardPerShare = pool.accRewardPerShare +
                ((addedRewards * 1e36) / totalSupply);

            pending =
                userPendingRewards[user] +
                ((totalBalances[user] * newAccRewardPerShare) / 1e36) -
                userRewardDebt[user];
        }
    }

    function _calcAddedRewards() internal view returns (uint256 addedRewards) {
        uint256 startBlock = endRewardBlock > lastRewardBlock + windowLength
            ? endRewardBlock - windowLength
            : lastRewardBlock;
        uint256 endBlock = block.number > endRewardBlock
            ? endRewardBlock
            : block.number;
        uint256 duration = endBlock > startBlock ? endBlock - startBlock : 0;
        addedRewards = (poolData.rewardRate * duration) / 1e36;
    }

    /**
     * @notice Deposit BENT Tokens.
     * @param amount Amount of Bent Tokens to deposit
     **/
    function depositBent(uint256 amount) external nonReentrant {
        require(amount > 0, "Zero Amount is not acceptable");
        IERC20 bentContract = IERC20(bentAddress);
        require(bentContract.balanceOf(msg.sender) > 0, "Not Enough Balance");
        bentContract.transferFrom(msg.sender, address(this), amount);
        bentContract.approve(webentAddress, amount);
        IBentLocker weBentContract = IBentLocker(webentAddress);
        weBentContract.deposit(amount);

        vlBENT vlBCVX3Contract = vlBENT(vlBENT3Address);
        vlBCVX3Contract.mintRequest(msg.sender, amount);
        uint256 userAmount = totalBalances[msg.sender];
        if (userAmount == 0) depositors = depositors + 1;
        totalBalances[msg.sender] = amount;
        totalSupply += amount;
        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice Withdraw BENT Token .
     * @param amount Amount of Bent Tokens to withdraw
     **/
    function withdrawBent(uint256 amount) external nonReentrant {
        require(amount > 0, "Zero Amount is not acceptable");
        require(
            totalBalances[msg.sender] >= amount,
            "Sender have no enough Deposit"
        );
        vlBENT vlBENTContract = vlBENT(vlBENT3Address);
        vlBENTContract.burnRequest(msg.sender, amount);
        totalBalances[msg.sender] = totalBalances[msg.sender] - (amount);
        totalSupply -= amount;
        emit userWithdraw(msg.sender, amount);
    }

    function withdrawFromWebent(uint256 amount) external onlyAdmin {
        require(amount > 0, "Zero Amount is not acceptable");
        IBentLocker weBentContract = IBentLocker(webentAddress);
        weBentContract.withdraw(amount);
        emit ownerWithdraw(msg.sender, amount);
    }

    function claim() external onlyAdmin {
        IBentLocker weBentContract = IBentLocker(webentAddress);
        uint256 reward = weBentContract.balanceOf(address(this));
        weBentContract.claimAll();
        uint256 rewardAfter = weBentContract.balanceOf(address(this)) - reward;
        totalRewardClaimed += rewardAfter;
        emit ClaimAll(msg.sender, totalRewardClaimed);
    }

    /**
     * @notice Claim Reward for your deposit of BENT Token .
     **/
    function collectUserReward() external nonReentrant {
        _updateAccPerShare(true, msg.sender);
        _claim(msg.sender);
        _updateUserRewardDebt(msg.sender);
    }

    /**
     * @notice onTransfer transfer the ownership of deposits .
     * @param user old owner of the deposit
     * @param newOwner new Owner of the deposit
     **/
    function onTransfer(address user, address newOwner) external nonReentrant {
        require(msg.sender == vlBENT3Address, "No Right To Call Transfer");
        uint256 userBalance = totalBalances[user];
        totalBalances[user] = 0;
        totalBalances[newOwner] = userBalance;
    }

    function updateReserve() external nonReentrant onlyAdmin {
        poolData.reserves = IERC20(poolData.rewardToken).balanceOf(
            address(this)
        );
    }

    /**
     * @notice Change Owner Of Contract
     * @param _address New Owner Address
     **/

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
        uint256 addedRewards = _calcAddedRewards();

        PoolData storage pool = poolData;
        if (totalSupply == 0) {
            pool.accRewardPerShare = block.number;
        } else {
            pool.accRewardPerShare += (addedRewards * (1e36)) / totalSupply;
        }

        if (withdrawReward) {
            uint256 pending = ((totalBalances[user] * pool.accRewardPerShare) /
                1e36) - userRewardDebt[user];

            if (pending > 0) {
                userPendingRewards[user] += pending;
            }
        }

        lastRewardBlock = block.number;
    }

    function onReward() public {
        _updateAccPerShare(false, address(0));
        // IBentLocker weBentContract = IBentLocker(webentAddress);

        // weBentContract.claimAll();
        bool newRewardsAvailable = false;
        PoolData storage pool = poolData;

        uint256 newRewards = IERC20(pool.rewardToken).balanceOf(address(this)) -
            pool.reserves;
        uint256 newRewardsFees = (newRewards * harvesterFee) / 10000;
        uint256 newRewardsFinal = newRewards - newRewardsFees;

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

        pool.reserves += newRewardsFinal;
        if (newRewardsFees > 0) {
            IERC20(pool.rewardToken).transfer(msg.sender, newRewardsFees);
        }

        require(newRewardsAvailable, "No Reward");
        endRewardBlock = lastRewardBlock + windowLength;
    }

    function _updateUserRewardDebt(address user) internal {
        userRewardDebt[user] =
            (totalBalances[user] * poolData.accRewardPerShare) /
            1e36;
    }

    function _claim(address user) internal returns (uint256 claimAmount) {
        if (poolData.rewardToken == address(0)) {
            return 0;
        }
        claimAmount = userPendingRewards[user];
        if (claimAmount > 0) {
            IERC20(poolData.rewardToken).transfer(user, claimAmount);
            poolData.reserves -= claimAmount;
            userPendingRewards[user] = 0;
        }
    }
}