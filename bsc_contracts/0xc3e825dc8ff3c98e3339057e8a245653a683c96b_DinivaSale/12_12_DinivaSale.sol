// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract DinivaSale is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeMath for uint256;

    enum TransactionType {
        BUY,
        CLAIM
    }

    event RewardsTransferred(address holder, uint256 amount);
    event BuyToken(
        address indexed holder,
        address indexed referral,
        uint256 amount,
        uint256 timestamp
    );
    event Referral(
        address indexed user,
        address indexed referral,
        uint256 timestamp
    );

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

    struct TotalDeposit {
        uint256 from;
        uint256 to;
        uint256 amount;
    }

    // token contract address
    address private tokenAddress;
    IERC20 public dotsToken;

    uint256 public lastDistributionTime;

    uint256 public totalClaimedRewards;

    uint256 public totalStakedToken;

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
    TotalDeposit[] public totalDeposit;
    uint256[] public referrals;
    address public depositToken;
    address[] public stakingContract;

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // @update Initialize NFT contract

    function initialize() public initializer {
        tokenAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        dotsToken = IERC20(0x18Ca55403b99ab07479302e7DA5FeE7D82c879F5);
        lastDistributionTime = 1676678400;
        referrals = [500, 300, 200, 100, 100, 100, 100, 100, 100, 50];
        minAmount = 55 ether;
        purchaseTokenAmount = 19140 ether;
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    // All constant value view function

    /**
     * @notice Token address
     * @return tokenAddress of erc20 token address which is stake in this contract
     */
    function getTokenAddress() public view returns (address) {
        return tokenAddress;
    }

    function getTransactionHistory(
        address _holder
    ) public view returns (TransactionHistory memory) {
        return transactionHistory[_holder];
    }

    function getLastDistributionTime() public view returns (uint256, uint256) {
        require(block.timestamp > lastDistributionTime, "Invalid time");
        uint256 times = block.timestamp.sub(lastDistributionTime).div(
            uint256(86400)
        );
        if (times == 0) {
            return (0, lastDistributionTime);
        }
        uint256 currentTime = lastDistributionTime.add(
            uint256(86400).mul(times)
        );
        return (times, currentTime);
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
    function updateAccount(
        address account,
        TransactionType _transactionType
    ) private {
        uint256 pendingDivs = 0; //getUnLockedPendingDivs(account);
        uint256 referralIncome = availableReferralIncome[account];
        if (_transactionType != TransactionType.BUY) {
            if (referralIncome > 0) {
                totalEarnedTokens[account] += (referralIncome);
                availableReferralIncome[account] = 0;
                totalReferralIncome[account] += referralIncome;
                totalClaimedRewards = totalClaimedRewards.add(pendingDivs);

                // uint256 diff = totalEarnedTokens[account] -
                //     depositedTokens[account].mul(maxReturn).div(1e4);
                // pendingDivs = pendingDivs.sub(diff);
                // userMatured[account] = true;
                // require(
                //     totalEarnedTokens[account] <=
                //         depositedTokens[account].mul(maxReturn).div(1e4),
                //     "Earning limit reached"
                // );
                transactionHistory[account].timestamp.push(block.timestamp);
                transactionHistory[account].amount.push(
                    pendingDivs + referralIncome
                );
                transactionHistory[account].transactionType.push(
                    TransactionType.CLAIM
                );
                // uint256 fee = pendingDivs
                //     .add(referralIncome)
                //     .mul(unstakingFeeRate)
                //     .div(1e4);
                uint256 amountToTransfer = (referralIncome);
                totalClaimedRewards += (referralIncome);
                // require(
                //     IERC20(tokenAddress).transfer(owner(), fee),
                //     "Could not transfer tokens."
                // );
                require(
                    IERC20(tokenAddress).transfer(account, amountToTransfer),
                    "Could not transfer tokens."
                );
                if (account != owner()) {
                    // require(
                    //     payReferral(account, account, 0, pendingDivs),
                    //     "Can't pay referral"
                    // );
                }

                emit RewardsTransferred(account, pendingDivs);
            }
            // if (block.timestamp > cliffTime.add(lastDistributionTime)) {
            //     //check condition
            //     //for loop to determine gloal time from start time
            //     lastDistributionTime += cliffTime;
            // }
            (, uint256 time) = getLastDistributionTime();
            lastClaimedTime[account] = time;
        }
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
     * @notice Buy Token
     * @notice A transfer is used to bring tokens into the staking contract so pre-approval is required
     * @param _referral refferral address for user
     */
    function buyToken(address _referral) public {
        require(!isDepositPaused, "Deposit is paused");
        require(depositedTokens[msg.sender] == 0, "Already deposited");

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
                minAmount
            ),
            "Insufficient Token Allowance"
        );

        require(
            dotsToken.transfer(msg.sender, purchaseTokenAmount),
            "Transfer failed"
        );

        transactionHistory[msg.sender].timestamp.push(block.timestamp);
        transactionHistory[msg.sender].amount.push(minAmount);
        transactionHistory[msg.sender].transactionType.push(
            TransactionType.BUY
        );
        depositedTokens[msg.sender] += minAmount;
        stakingTime[msg.sender] = block.timestamp;
        totalStakedToken += minAmount;
        // (, uint256 time) = getLastDistributionTime();
        // if (totalDeposit[totalDeposit.length - 1].to == time + 86400) {
        //     totalDeposit[totalDeposit.length - 1].amount += minAmount;
        // } else {
        //     totalDeposit.push(TotalDeposit(time, time + 86400, minAmount));
        // }

        if (
            _referral != address(0) &&
            _referral != msg.sender &&
            depositedTokens[_referral] > 0
        ) {
            alreadyReferral[msg.sender] = true;
            myReferralAddresses[msg.sender] = _referral;
            if (userLevel[_referral] < 10) {
                userLevel[_referral] += 1;
            }

            require(
                setUserReferral(msg.sender, _referral),
                "Can't set user referral"
            );

            require(
                setReferralAddressesOfUsers(msg.sender, _referral),
                "Can't update referral list"
            );

            require(
                payReferral(msg.sender, msg.sender, 0, minAmount),
                "Can't pay referral"
            );
            emit Referral(msg.sender, _referral, block.timestamp);
        }
        // lastClaimedTime[msg.sender] = block.timestamp;
        if (!onlyHolder()) {
            holders.push(msg.sender);
            stakingTime[msg.sender] = block.timestamp;
        }
        emit BuyToken(msg.sender, _referral, minAmount, block.timestamp);
    }

    /**
     * @notice Claim reward tokens call by directly from user
     */
    function claimDivs() public pure returns (bool) {
        // require(!isClaimPaused, "Claim is paused");
        // require(!userMatured[msg.sender], "User earning limit reached");
        // updateAccount(msg.sender, TransactionType.CLAIM);
        return true;
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
    function getBuyersList(
        uint256 startIndex,
        uint256 endIndex
    )
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
    function getUserReferralInformation(
        address userAddress
    )
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

    function updateExistingLevel(
        uint256 index,
        uint256 levelRate
    ) public onlyOwner {
        referrals[index] = levelRate;
    }

    function setUserReferral(
        address beneficiary,
        address referral
    ) internal returns (bool) {
        userReferral[beneficiary] = referral;
        return true;
    }

    function setReferralAddressesOfUsers(
        address beneficiary,
        address referral
    ) internal returns (bool) {
        userReferrales[referral].push(beneficiary);
        return true;
    }

    function getUserReferral(address user) public view returns (address) {
        return userReferral[user];
    }

    function getReferralAddressOfUsers(
        address user
    ) public view returns (address[] memory) {
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
                // if (!userMatured[userReferral[_userAddress]]) {
                if (_index < userLevel[userReferral[_userAddress]]) {
                    setReferralIncome(
                        userReferral[_userAddress],
                        transferAmount
                    );

                    require(
                        IERC20(tokenAddress).transfer(
                            userReferral[_userAddress],
                            transferAmount
                        ),
                        "Could not transfer tokens."
                    );
                }
                // }
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

    /** Admin functions for income distribution */
    uint256 public purchaseTokenAmount;
    event DistributeIncomePerUser(
        address indexed _userAddress,
        uint256 _amount,
        uint256 indexed _type
    );
    event DistributeIncome(
        address[] indexed _userAddress,
        uint256[] _amount,
        uint256 indexed _type
    );
    mapping(address => bool) public admin;
    mapping(address => uint256) public userLevel;

    function grantAdminRole(address _userAddress) external onlyOwner {
        admin[_userAddress] = true;
    }

    function distributeIncome(
        address[] memory _userAddress,
        uint256[] memory _amount,
        uint256 _type
    ) external returns (bool) {
        require(admin[msg.sender], "No access");
        for (uint256 i = 0; i < _userAddress.length; i++) {
            availableReferralIncome[_userAddress[i]] += _amount[i];
            require(
                IERC20(tokenAddress).transfer(_userAddress[i], _amount[i]),
                "Could not transfer tokens."
            );
            emit DistributeIncomePerUser(_userAddress[i], _amount[i], _type);
        }
        emit DistributeIncome(_userAddress, _amount, _type);
        return true;
    }

    function setTokenAmountForSale(uint256 _amount) external onlyOwner {
        purchaseTokenAmount = _amount;
    }

    function withdrawToken(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.transfer(msg.sender, _amount);
    }
}