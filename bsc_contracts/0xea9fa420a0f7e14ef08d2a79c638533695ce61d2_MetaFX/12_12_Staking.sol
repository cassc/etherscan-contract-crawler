/**
    ##  ###  #######  #######   ######           #######  ###  ##            ######  ####### 
    #######  ##         ###     ##  ##           ##       ###  ##            ##  ##    ###   
    #######  ##         ###     ##  ##           ##       ###  ##            ##  ##    ###   
    ### ###  #######    ###    #######           #######   #####            #######    ###   
    ##  ###  ###        ###    ###  ##           ###      ##  ###           ###  ##    ###   
    ##  ###  ###        ###    ###  ##           ###      ##  ###           ###  ##    ###   
    ##  ###  #######    ###    ###  ##           ###      ##  ###           ###  ##  #######                                                                                     
 */
// https://metafxai.money/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MetaFX is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeMath for uint256;

    enum TransactionType {
        DEPOSIT,
        CLAIM,
        COMPOUND
    }

    event RewardsTransferred(address holder, uint256 amount);
    event Deposit(
        address indexed holder,
        address indexed referral,
        uint256 amount,
        uint256 time
    );
    event Reinvest(address indexed holder, uint256 amount, uint256 time);

    struct ReferralEarning {
        address[] stakingAddress;
        address[] user;
        uint256[] amount;
        uint256[] timestamp;
    }

    struct TransactionHistory {
        uint256[] timestamp;
        uint256[] amount;
        TransactionType[] transactionType;
    }

    // token contract address
    address private tokenAddress;
    address public fundWallet;

    uint256 private rewardInterval;

    // unstaking fee 5 percent
    uint256 private unstakingFeeRate;

    // calaim possible after each clifftime interval - value in seconds
    uint256 public cliffTime;

    uint256 public lastDistributionTime;

    uint256 public totalClaimedRewards;

    uint256 public totalStakedToken;

    uint256 public maxReturn;
    uint256 public minAmount;
    bool public isDepositPaused;
    bool public isClaimPaused;

    //  array of holders;
    address[] public holders;

    mapping(address => uint256) public depositedTokens;
    mapping(address => uint256) public stakingTime;
    mapping(address => uint256) public lastClaimedTime;
    mapping(address => uint256) public totalEarnedTokens;
    mapping(address => uint256) public availableReferralIncome;
    mapping(address => uint256) public totalReferralIncome;
    mapping(address => address) public myReferralAddresses; // get my referal address that i refer
    mapping(address => bool) public alreadyReferral;
    mapping(address => TransactionHistory) private transactionHistory;
    mapping(address => bool) public userMatured;

    //Referral
    mapping(address => address) userReferral; // which refer user used
    mapping(address => address[]) userReferrales; // referral address which use users address
    mapping(address => uint256) public totalReferalAmount; // get my total referal amount
    mapping(address => ReferralEarning) referralEarning;
    uint256[] public referrals;
    address public depositToken;
    address[] public stakingContract;

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // @update Initialize NFT contract

    function initialize() public initializer {
        tokenAddress = 0x55d398326f99059fF775485246999027B3197955;
        fundWallet = 0x70df79E9dE9c1bd221E442e027Dee9E3C2FDD9B0;
        rewardInterval = 86400;
        unstakingFeeRate = 500;
        cliffTime = 604800;
        lastDistributionTime = 1676678400;
        referrals = [
            1000,
            500,
            400,
            300,
            300,
            300,
            200,
            200,
            200,
            100,
            100,
            100,
            100,
            100,
            100,
            200,
            200,
            200,
            200,
            200
        ];
        maxReturn = 20000;
        minAmount = 100 ether;
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    // All constant value view function

    /**
     * @notice Reward interval
     * @return rewardInterval of staking
     */
    function getRewardInterval() public view returns (uint256) {
        return rewardInterval;
    }

    /**
     * @notice Staking Fee Rate
     * @return unstakingFeeRate will be send to owner at unstaking time
     */
    function getUnstakingFeeRate() public view returns (uint256) {
        return unstakingFeeRate;
    }

    /**
     * @notice Cliff time
     * @return cliffTime after which time user can wwithdraw their stake
     */
    function getCliffTime() public view returns (uint256) {
        return cliffTime;
    }

    /**
     * @notice Token address
     * @return tokenAddress of erc20 token address which is stake in this contract
     */
    function getTokenAddress() public view returns (address) {
        return tokenAddress;
    }

    function getTransactionHistory(address _holder)
        public
        view
        returns (TransactionHistory memory)
    {
        return transactionHistory[_holder];
    }

    function getLastDistributionTime() public view returns (uint256) {
        require(block.timestamp > lastDistributionTime, "Invalid time");
        uint256 times = block.timestamp.sub(lastDistributionTime).div(
            cliffTime
        );
        if (times == 0) {
            return lastDistributionTime;
        }
        uint256 currentTime = lastDistributionTime.add(cliffTime.mul(times));
        return currentTime;
    }

    /**
     * @notice Change Unstaking fee rate
     */
    function setUnstakingFeeRate(uint256 _rate) public onlyOwner {
        unstakingFeeRate = _rate;
    }

    /**
     * @notice Change deposit flag
     */
    function setDepositFlag(bool _isDepositPaused) public onlyOwner {
        isDepositPaused = _isDepositPaused;
    }

    /**
     * @notice Change claim flag
     */
    function setClaimFlag(bool _isClaimPaused) public onlyOwner {
        isClaimPaused = _isClaimPaused;
    }

    /**
     * @notice Change funding wallet address
     */
    function setFundWalletAddress(address _fundWallet) public onlyOwner {
        fundWallet = _fundWallet;
    }

    /**
     * @notice Change Cliff Time
     */
    function setCliffTime(uint256 _cliffTime) public onlyOwner {
        cliffTime = _cliffTime;
    }

    /**
     * @notice Change Minimum amount
     */
    function setMinimumAmount(uint256 _minAmount) public onlyOwner {
        minAmount = _minAmount;
    }

    function setReferralIncome(address _userAddress, uint256 _amount) internal {
        availableReferralIncome[_userAddress] += _amount;
    }

    /**
     * @notice Only Holder - check holder is exists in our contract or not
     * @return bool value
     */
    function onlyHolder() public view returns (bool) {
        bool condition = false;
        for (uint256 i = 0; i < holders.length; i++) {
            if (holders[i] == msg.sender) {
                condition = true;
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Update Account
     * @param account account address of the user
     */
    function updateAccount(address account, TransactionType _transactionType)
        private
    {
        uint256 pendingDivs = getUnLockedPendingDivs(account);
        uint256 referralIncome = availableReferralIncome[account];
        if (_transactionType != TransactionType.DEPOSIT) {
            if (pendingDivs > 0) {
                totalEarnedTokens[account] += pendingDivs.add(referralIncome);
                availableReferralIncome[account] = 0;
                totalReferralIncome[account] += referralIncome;
                totalClaimedRewards = totalClaimedRewards.add(pendingDivs);
                if (
                    totalEarnedTokens[account] >=
                    depositedTokens[account].mul(maxReturn).div(1e4)
                ) {
                    uint256 diff = totalEarnedTokens[account] -
                        depositedTokens[account].mul(maxReturn).div(1e4);
                    pendingDivs = pendingDivs.sub(diff);
                    userMatured[account] = true;
                }
                // require(
                //     totalEarnedTokens[account] <=
                //         depositedTokens[account].mul(maxReturn).div(1e4),
                //     "Earning limit reached"
                // );
                transactionHistory[account].timestamp.push(block.timestamp);
                transactionHistory[account].amount.push(
                    pendingDivs + referralIncome
                );
                if (_transactionType == TransactionType.COMPOUND) {
                    depositedTokens[account] += pendingDivs.add(referralIncome);
                    transactionHistory[account].transactionType.push(
                        TransactionType.COMPOUND
                    );
                    emit Reinvest(
                        account,
                        pendingDivs.add(referralIncome),
                        block.timestamp
                    );
                } else {
                    transactionHistory[account].transactionType.push(
                        TransactionType.CLAIM
                    );
                    uint256 fee = pendingDivs
                        .add(referralIncome)
                        .mul(unstakingFeeRate)
                        .div(1e4);
                    uint256 amountToTransfer = pendingDivs
                        .add(referralIncome)
                        .sub(fee);
                    totalClaimedRewards += pendingDivs.add(referralIncome);
                    require(
                        IERC20(tokenAddress).transfer(owner(), fee),
                        "Could not transfer tokens."
                    );
                    require(
                        IERC20(tokenAddress).transfer(
                            account,
                            amountToTransfer
                        ),
                        "Could not transfer tokens."
                    );
                    if (account != owner()) {
                        require(
                            payReferral(account, account, 0, pendingDivs),
                            "Can't pay referral"
                        );
                    }
                }

                emit RewardsTransferred(account, pendingDivs);
            }
            // if (block.timestamp > cliffTime.add(lastDistributionTime)) {
            //     //check condition
            //     //for loop to determine gloal time from start time
            //     lastDistributionTime += cliffTime;
            // }
            lastClaimedTime[account] = getLastDistributionTime();
        }
    }

    /**
     * @notice Get Pending divs
     * @param _holder account address of the user
     * @return pendingDivs;
     */
    function getLockedPendingDivs(address _holder)
        public
        view
        returns (uint256)
    {
        uint256 timeDiff;
        uint256 _lastInteractionTime; //1676138759
        if (lastClaimedTime[_holder] == 0) {
            _lastInteractionTime = stakingTime[_holder];
        } else {
            _lastInteractionTime = lastClaimedTime[_holder];
        }
        timeDiff = block.timestamp.sub(_lastInteractionTime);
        // if (block.timestamp < _lastDistributionTime.add(cliffTime)) {
        //     if (_lastInteractionTime >= _lastDistributionTime) {
        //         timeDiff = block.timestamp.sub(_lastInteractionTime);
        //     } else {
        //         timeDiff = block.timestamp.sub(lastDistributionTime);
        //     }
        // }
        uint256 stakedAmount = depositedTokens[_holder];
        uint256 rewardRate;
        if (stakedAmount <= 1000 ether) {
            rewardRate = 50;
        } else if (stakedAmount > 1000 ether && stakedAmount <= 3000 ether) {
            rewardRate = 60;
        } else if (stakedAmount > 3000 ether && stakedAmount <= 5000 ether) {
            rewardRate = 75;
        } else if (stakedAmount > 5000 ether && stakedAmount <= 10000 ether) {
            rewardRate = 90;
        } else if (stakedAmount > 10000 ether) {
            rewardRate = 100;
        }
        uint256 pendingDivs = stakedAmount
            .mul(rewardRate)
            .mul(timeDiff)
            .div(rewardInterval)
            .div(1e4);

        return uint256(pendingDivs);
    }

    function getUnLockedPendingDivs(address _holder)
        public
        view
        returns (uint256)
    {
        uint256 _lastDistributionTime = getLastDistributionTime();
        uint256 _lastInteractionTime;
        if (lastClaimedTime[_holder] == 0) {
            _lastInteractionTime = stakingTime[_holder];
        } else {
            _lastInteractionTime = lastClaimedTime[_holder];
        }

        if (_lastDistributionTime < _lastInteractionTime) {
            return 0;
        }
        uint256 timeDiff = _lastDistributionTime.sub(_lastInteractionTime); //125641

        //currentgolabal - userlast = timediff
        // if (block.timestamp > lastDistributionTime.add(cliffTime)) {
        //     timeDiff = block.timestamp.sub(lastClaimedTime[_holder]);
        // }
        uint256 stakedAmount = depositedTokens[_holder];
        uint256 rewardRate;
        if (stakedAmount <= 1000 ether) {
            rewardRate = 50;
        } else if (stakedAmount > 1000 ether && stakedAmount <= 3000 ether) {
            rewardRate = 60;
        } else if (stakedAmount > 3000 ether && stakedAmount <= 5000 ether) {
            rewardRate = 75;
        } else if (stakedAmount > 5000 ether && stakedAmount <= 10000 ether) {
            rewardRate = 90;
        } else if (stakedAmount > 10000 ether) {
            rewardRate = 100;
        }
        uint256 pendingDivs = stakedAmount
            .mul(rewardRate)
            .mul(timeDiff)
            .div(rewardInterval)
            .div(1e4);

        return uint256(pendingDivs);
    }

    /**
     * @notice Get number of holders
     * @notice will return length of holders array
     * @return holders;
     */
    function getNumberOfHolders() public view returns (uint256) {
        return holders.length;
    }

    /**
     * @notice Deposit
     * @notice A transfer is used to bring tokens into the staking contract so pre-approval is required
     * @param amountToStake amount of total tokens user staking and get NFT basis on that
     */
    function deposit(uint256 amountToStake, address _referral) public {
        require(!isDepositPaused, "Deposit is paused");
        require(
            amountToStake >= minAmount,
            "Cannot deposit less than Minimum Tokens"
        );
        if (msg.sender != owner()) {
            require(
                _referral != address(0) &&
                    _referral != msg.sender &&
                    _referral != address(this) &&
                    depositedTokens[_referral] > 0,
                "Invalid Referral Address"
            );
        }
        if (alreadyReferral[msg.sender]) {
            _referral = myReferralAddresses[msg.sender];
        }
        require(
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                amountToStake
            ),
            "Insufficient Token Allowance"
        );

        require(
            IERC20(tokenAddress).transfer(fundWallet, amountToStake),
            "Deposit Failed"
        );
        updateAccount(msg.sender, TransactionType.DEPOSIT);

        transactionHistory[msg.sender].timestamp.push(block.timestamp);
        transactionHistory[msg.sender].amount.push(amountToStake);
        transactionHistory[msg.sender].transactionType.push(
            TransactionType.DEPOSIT
        );
        depositedTokens[msg.sender] += amountToStake;
        stakingTime[msg.sender] = block.timestamp;
        totalStakedToken += amountToStake;
        userMatured[msg.sender] = false;

        if (
            amountToStake > 0 &&
            _referral != address(0) &&
            _referral != msg.sender &&
            depositedTokens[_referral] > 0
        ) {
            alreadyReferral[msg.sender] = true;
            myReferralAddresses[msg.sender] = _referral;

            require(
                setUserReferral(msg.sender, _referral),
                "Can't set user referral"
            );

            require(
                setReferralAddressesOfUsers(msg.sender, _referral),
                "Can't update referral list"
            );

            // require(
            //     payReferral(
            //         msg.sender,
            //         msg.sender,
            //         0,
            //         amountToStake
            //     ),
            //     "Can't pay referral"
            // );
        }
        // lastClaimedTime[msg.sender] = block.timestamp;
        if (!onlyHolder()) {
            holders.push(msg.sender);
            stakingTime[msg.sender] = block.timestamp;
        }
        emit Deposit(msg.sender, _referral, amountToStake, block.timestamp);
    }

    /**
     * @notice Claim reward tokens call by directly from user
     */
    function claimDivs() public {
        require(!isClaimPaused, "Claim is paused");
        require(!userMatured[msg.sender], "User earning limit reached");
        updateAccount(msg.sender, TransactionType.CLAIM);
    }

    function compound() public {
        require(!userMatured[msg.sender], "User earning limit reached");
        updateAccount(msg.sender, TransactionType.COMPOUND);
    }

    /**
     * @notice Get stakers list
     * @param startIndex index of array from point
     * @param endIndex index of array end point
     * @return stakers
     * @return stakingTimestamps
     * @return lastClaimedTimeStamps
     * @return stakedTokens
     */
    function getStakersList(uint256 startIndex, uint256 endIndex)
        public
        view
        returns (
            address[] memory stakers,
            uint256[] memory stakingTimestamps,
            uint256[] memory lastClaimedTimeStamps,
            uint256[] memory stakedTokens
        )
    {
        require(startIndex < endIndex);

        uint256 length = endIndex.sub(startIndex);
        address[] memory _stakers = new address[](length);
        uint256[] memory _stakingTimestamps = new uint256[](length);
        uint256[] memory _lastClaimedTimeStamps = new uint256[](length);
        uint256[] memory _stakedTokens = new uint256[](length);

        for (uint256 i = startIndex; i < endIndex; i = i.add(1)) {
            // address staker = holders.at(i);
            address staker = holders[i];
            uint256 listIndex = i.sub(startIndex);
            _stakers[listIndex] = staker;
            _stakingTimestamps[listIndex] = stakingTime[staker];
            _lastClaimedTimeStamps[listIndex] = lastClaimedTime[staker];
            _stakedTokens[listIndex] = depositedTokens[staker];
        }

        return (
            _stakers,
            _stakingTimestamps,
            _lastClaimedTimeStamps,
            _stakedTokens
        );
    }

    // function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    // Admin cannot transfer out Staking Token from this smart contract
    function transferAnyERC20Tokens(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        require(
            _tokenAddr != tokenAddress,
            "Cannot Transfer Out Staking Token!"
        );
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    //Referral
    function getUserReferralInformation(address userAddress)
        public
        view
        returns (
            address[] memory,
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        return (
            referralEarning[userAddress].stakingAddress,
            referralEarning[userAddress].user,
            referralEarning[userAddress].amount,
            referralEarning[userAddress].timestamp
        );
    }

    function addNewLevel(uint256 levelRate) public onlyOwner {
        referrals.push(levelRate);
    }

    function updateExistingLevel(uint256 index, uint256 levelRate)
        public
        onlyOwner
    {
        referrals[index] = levelRate;
    }

    function setUserReferral(address beneficiary, address referral)
        internal
        returns (bool)
    {
        userReferral[beneficiary] = referral;
        return true;
    }

    function setReferralAddressesOfUsers(address beneficiary, address referral)
        internal
        returns (bool)
    {
        userReferrales[referral].push(beneficiary);
        return true;
    }

    function getUserReferral(address user) public view returns (address) {
        return userReferral[user];
    }

    function getReferralAddressOfUsers(address user)
        public
        view
        returns (address[] memory)
    {
        return userReferrales[user];
    }

    function payReferral(
        address _userAddress,
        address _secondaryAddress,
        uint256 _index,
        uint256 _mainAmount
    ) internal returns (bool) {
        if (_index >= referrals.length) {
            return true;
        } else {
            if (userReferral[_userAddress] != address(0)) {
                uint256 transferAmount = (_mainAmount * referrals[_index]) /
                    10000;
                referralEarning[userReferral[_userAddress]].stakingAddress.push(
                        msg.sender
                    );
                referralEarning[userReferral[_userAddress]].user.push(
                    _secondaryAddress
                );
                referralEarning[userReferral[_userAddress]].amount.push(
                    transferAmount
                );
                referralEarning[userReferral[_userAddress]].timestamp.push(
                    block.timestamp
                );
                // if(!Staking(msg.sender).isBlackListForRefer(userReferral[_userAddress])){
                // require(
                //     Token(depositToken).transfer(
                //         userReferral[_userAddress],
                //         transferAmount
                //     ),
                //     "Could not transfer referral amount"
                // );
                if (!userMatured[userReferral[_userAddress]]) {
                    setReferralIncome(
                        userReferral[_userAddress],
                        transferAmount
                    );
                }
                totalReferalAmount[userReferral[_userAddress]] =
                    totalReferalAmount[userReferral[_userAddress]] +
                    (transferAmount);
                // }
                payReferral(
                    userReferral[_userAddress],
                    _secondaryAddress,
                    _index + 1,
                    _mainAmount
                );
                return true;
            } else {
                return false;
            }
        }
    }
}