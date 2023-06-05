/**
 *Submitted for verification at Etherscan.io on 2020-12-06
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not the owner");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner address is invalid");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
      * @dev Multiplies two numbers, throws on overflow.
      */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @dev A staking contract that pays interest if users and the owner (on behalf of users) stake
 * tokens
 */
contract AINStake is Ownable {
    using SafeMath for uint256;

    ERC20 public token;
    uint256 public closingTime;
    uint256 public interestRate = 1020000; // 1.02 (2%, monthly)
    uint256 public divider = 1000000;
    uint256 public maxStakingAmountPerUser = 20000 ether; // 20,000 AIN (~1,000,000 KRW)
    uint256 public maxUnstakingAmountPerUser = 40000 ether; // 40,000 AIN
    uint256 public maxStakingAmountPerContract = 2000000 ether; // 2,000,000 AIN (~100,000,000 KRW)
    uint256 constant public MONTH = 30 days; // ~1 month in seconds

    bool public stakingClosed = false;
    bool public contractClosed = false;
    bool public reEntrancyMutex = false;

    mapping(address => UserStake) public userStakeMap; // userAddress => { index, [{ amount, startTime }, ...] }
    // sum of all stakes from the user (only the principal amounts, stakes from the owner don't count)
    mapping(address => uint256) public singleStakeSum; // userAddress => sum
    uint256 public contractSingleStakeSum;
    address[] public userList;

    struct StakeItem {
        uint256 amount; // amount of tokens staked
        uint256 startTime; // timestamp when tokens are staked
    }

    struct UserStake {
        uint256 index; // index of the user within userList
        StakeItem[] stakes; // stakes from the user
    }

    event MultiStake(address[] users, uint256[] amounts, uint256 startTime);
    event Stake(address user, uint256 amount, uint256 startTime);
    event Unstake(address user, uint256 amount);

    constructor(ERC20 _token, uint256 _closingTime) public {
        token = _token;
        closingTime = _closingTime;
    }

    function userExists(address user) public view returns (bool) {
        return userStakeMap[user].index > 0 || (userList.length > 0 && userList[0] == user);
    }

    function getUserListLength() public view returns (uint256) {
        return userList.length;
    }

    function getUserStakeCount(address user) public view returns (uint256) {
        return userStakeMap[user].stakes.length;
    }

    /**
     * @return staking information of a user
     */
    function getUserStake(address user, uint256 index) public view returns (uint256, uint256) {
        if (index >= getUserStakeCount(user)) {
            return (0, 0);
        }
        StakeItem memory item = userStakeMap[user].stakes[index];
        return (item.amount, item.startTime);
    }

    /**
     * @dev Closes contract, return staked tokens to users, and transfer contract's tokens to the owner
     */
    function closeContract() onlyOwner public returns (bool) {
        require(contractClosed == false, "contract is closed");

        // unstake all users
        for (uint256 i = 0; i < userList.length; i++) {
            if (userStakeMap[userList[i]].stakes.length > 0) {
                _unstake(userList[i]);
            }
        }

        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            require(token.transfer(owner, balance), "token transfer to owner failed");
        }
        stakingClosed = true;
        contractClosed = true;
        return true;
    }

    /**
     * @dev Opens staking (users can start staking after calling this function)
     */
    function openStaking() onlyOwner public returns (bool) {
        require(stakingClosed == true, "staking is open");
        require(contractClosed == false, "contract is closed");
        stakingClosed = false;
        return true;
    }

    /**
     * @dev Closes staking (users can only unstake after calling this function)
     */
    function closeStaking() onlyOwner public returns (bool) {
        require(stakingClosed == false, "staking is closed");
        stakingClosed = true;
        return true;
    }

    function setMaxStakingAmountPerUser(uint256 max) onlyOwner public {
        maxStakingAmountPerUser = max;
    }

    function setMaxUnstakingAmountPerUser(uint256 max) onlyOwner public {
        maxUnstakingAmountPerUser = max;
    }

    function setMaxStakingAmountPerContract(uint256 max) onlyOwner public {
        maxStakingAmountPerContract = max;
    }

    function extendContract(uint256 rate, uint256 time) onlyOwner public {
        require(contractClosed == false, "contract is closed");
        require(block.timestamp >= closingTime,
            "cannot extend contract before the current closingTime");
        if (interestRate != rate) {
            for (uint256 i = 0; i < userList.length; i++) {
                address user = userList[i];
                uint256 total = calcUserStakeAndInterest(user, closingTime);
                resetUserStakes(user);
                _stake(user, total, block.timestamp);
            }
            interestRate = rate;
        }
        closingTime = time;
    }

    /**
     * @return sum of stakes from an address as well as stakes from the owner
     */
    function getUserTotalStakeSum(address user) public view returns (uint256) {
        uint256 sum = 0;
        StakeItem[] memory stakes = userStakeMap[user].stakes;
        for (uint256 i = 0; i < stakes.length; i++) {
            sum = sum.add(stakes[i].amount);
        }
        return sum;
    }

    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @return min(total stakes + interest earned from the stakes, maxUnstakingAmountPerUser) of an address
     */
    function calcUserStakeAndInterest(address user, uint256 _endTime) public view returns (uint256) {
        uint256 endTime = min(_endTime, closingTime);
        uint256 total = 0;
        uint256 multiplier = 1000000;
        uint256 currentMonthsPassed = 0;
        uint256 currentMonthSum = 0;
        StakeItem[] memory stakes = userStakeMap[user].stakes;
        for (uint256 i = stakes.length; i > 0; i--) { // start with the most recent stakes
            uint256 amount = stakes[i.sub(1)].amount;
            uint256 startTime = stakes[i.sub(1)].startTime;
            if (startTime > endTime) { // should not happen
                total = total.add(amount);
            } else {
                uint256 monthsPassed = (endTime.sub(startTime)).div(MONTH);
                if (monthsPassed == currentMonthsPassed) {
                    currentMonthSum = currentMonthSum.add(amount);
                } else {
                    total = total.add(currentMonthSum.mul(multiplier).div(divider));
                    currentMonthSum = amount;
                    while (currentMonthsPassed < monthsPassed) {
                        multiplier = multiplier.mul(interestRate).div(divider);
                        currentMonthsPassed = currentMonthsPassed.add(1);
                    }
                }
            }
        }
        total = total.add(currentMonthSum.mul(multiplier).div(divider));
        require(total <= maxUnstakingAmountPerUser, "maxUnstakingAmountPerUser exceeded");
        return total;
    }

    /**
     * @return the total staked amount + interest in this contract
     */
    function calcContractStakeAndInterest(uint256 endTime) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < userList.length; i++) {
            total = total.add(calcUserStakeAndInterest(userList[i], endTime));
        }
        return total;
    }

    function addUser(address user) private {
        userList.push(user);
        userStakeMap[user].index = userList.length.sub(1);
    }

    /**
     * @dev Deletes user's stakes from userStakeMap (keeps the user in userList)
     */
    function resetUserStakes(address user) private {
        // NOTE: decreasing array length will automatically clean up the storage slots occupied by 
        // the out-of-bounds elements
        userStakeMap[user].stakes.length = 0;
        contractSingleStakeSum = contractSingleStakeSum.sub(singleStakeSum[user]);
        delete singleStakeSum[user];
    }

    function addMultiStakeWhitelist(address[] users) onlyOwner public {
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (!userExists(user)) {
                addUser(user);
            }
        }
    }

    function _stake(address user, uint256 amount, uint256 startTime) private {
        userStakeMap[user].stakes.push(StakeItem(amount, startTime));
    }

    /**
     * @dev Airdrops tokens, in the form of stakes, to multiple users. Note that before calling this
     * fucntion, the owner should call token.approve() for the transferFrom() to work, as well as
     * addMultiStakeWhitelist() to register users.
     */
    function multiStake(address[] users, uint256[] amounts) onlyOwner public returns (bool) {
        require(contractClosed == false, "contract closed");
        require(users.length == amounts.length, "array length mismatch");

        address emptyAddr = address(0);
        uint256 amountTotal = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            require(users[i] != emptyAddr, "invalid address");
            amountTotal = amountTotal.add(amounts[i]);
        }
        require(token.transferFrom(msg.sender, address(this), amountTotal), "transferFrom failed");

        uint256 startTime = block.timestamp;
        for (uint256 j = 0; j < users.length; j++) {
            _stake(users[j], amounts[j], startTime);
        }

        emit MultiStake(users, amounts, startTime);

        return true;
    }

    /**
     * @dev Stakes tokens and earn interest. User must first approve this contract for transferring
     * her tokens.
     */
    function stake(uint256 amount) public returns (bool) {
        require(!reEntrancyMutex, "re-entrancy occurred");
        require(stakingClosed == false, "staking closed");
        require(contractClosed == false, "contract closed");
        require(block.timestamp < closingTime, "past closing time");
        require(amount > 0, "invalid amount");
        require(amount.add(singleStakeSum[msg.sender]) <= maxStakingAmountPerUser,
            "max user staking amount exceeded");
        require(amount.add(contractSingleStakeSum) <= maxStakingAmountPerContract,
            "max contract staking amount exceeded");
        
        reEntrancyMutex = true;
        require(token.transferFrom(msg.sender, address(this), amount), "transferFrom failed");

        if (!userExists(msg.sender)) {
            addUser(msg.sender);
        }
        
        _stake(msg.sender, amount, block.timestamp);
        singleStakeSum[msg.sender] = singleStakeSum[msg.sender].add(amount);
        contractSingleStakeSum = contractSingleStakeSum.add(amount);
        reEntrancyMutex = false;

        emit Stake(msg.sender, amount, block.timestamp);

        return true;
    }

    function _unstake(address user) private returns (uint256) {
        require(!reEntrancyMutex, "re-entrancy occurred");
        reEntrancyMutex = true;
        uint256 amount = calcUserStakeAndInterest(user, block.timestamp);
        require(amount > 0 && amount <= maxUnstakingAmountPerUser, "invalid unstaking amount");
        resetUserStakes(user);
        require(token.transfer(user, amount), "transfer failed");
        reEntrancyMutex = false;
        return amount;
    }

    /**
     * @dev Unstakes a user's stakes and interest all at once
     */
    function unstake() public returns (bool) {
        require(contractClosed == false, "contract closed");
        require(userStakeMap[msg.sender].stakes.length > 0, "no stakes");
        uint256 amount = _unstake(msg.sender);
        emit Unstake(msg.sender, amount);
        return true;
    }
}