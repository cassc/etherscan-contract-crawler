/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

interface IKeysFarming {
    function deposit(uint256 amount) external;
}

interface ILoyalKeyDatabase {
    function getLoyalKeyRank(address user) external view returns (uint256);
}

/**
 *
 * KEYS Funding Receiver
 * Will Allocate Funding To Different Sources
 *
 */
contract KEYSDistributor is Ownable {

    // KEYS
    address public constant KEYS = 0xe0a189C975e4928222978A74517442239a0b86ff;

    // LoyalKey Database
    ILoyalKeyDatabase public immutable loyalKey;

    // Max Int
    uint256 private constant MAX_INT = type(uint256).max;

    // Farming & Stake Manager
    address public farm;
    address public stake;
    
    // allocation to farm + stake
    uint256 public farmFee;
    uint256 public stakeFee;

    // farm fee + stake fee
    uint256 public feeDenom;

    // keys to distribute per second 0.385802469 => 1,000,000 keys per month (30 days)
    uint256 public keysPerSecond = 385802469;

    // last second to distribute keys
    uint256 public lastSecond;

    // minimum to distribute keys
    uint256 public distributionMinimum = 1 * 10**9;

    // tracks total rewards
    uint256 public totalRewards;
    uint256 public totalBounties;

    // Bounty Percent Out Of 1,000
    uint256 public constant Default_Bounty_Percent = 10; // 1%
    uint256 private constant Bounty_Denom = 1000;

    mapping ( uint256 => uint256 ) public loyalKeyRankToBountyPercent;
    
    constructor(uint256 stakePercent, uint256 farmPercent, address loyalKeyDB) {

        loyalKey = ILoyalKeyDatabase(loyalKeyDB);
    
        farm = 0x810487135d29f35f06f1075b48D5978F1791d743;
        stake = 0x73940d8E53b3cF00D92e3EBFfa33b4d54626306D;
    
        stakeFee = stakePercent;
        farmFee = farmPercent;
        feeDenom = stakePercent + farmPercent;

        loyalKeyRankToBountyPercent[0] = 10; // 1.0% for zero rank
        loyalKeyRankToBountyPercent[1] = 16; // 1.6% for first rank
        loyalKeyRankToBountyPercent[2] = 20; // 2.0% for second rank
        loyalKeyRankToBountyPercent[3] = 24; // 2.4% for third rank
        loyalKeyRankToBountyPercent[4] = 28; // 2.8% for forth rank
        loyalKeyRankToBountyPercent[5] = 32; // 3.2% for fifth rank
        loyalKeyRankToBountyPercent[6] = 36; // 3.6% for sixth rank
        loyalKeyRankToBountyPercent[7] = 40; // 4.0% for seventh rank

        lastSecond = block.timestamp;
        IERC20(KEYS).approve(farm, MAX_INT);
    }
    
    // Events
    event ResetRewardTimer();
    event SetFarm(address farm);
    event SetStaker(address staker);
    event TokenWithdrawal(uint256 amount);
    event SetKeysPerSecond(uint256 keysPerSec);
    event SetDistributionMinimum(uint256 minKeys);
    event SetBountyPercent(uint256 loyalKeyRank, uint256 newBounty);
    event SetFundPercents(uint256 farmPercentage, uint256 stakePercent);

    function setKeysPerSecond(uint256 keysPerSec) external onlyOwner {
        keysPerSecond = keysPerSec;
        emit SetKeysPerSecond(keysPerSec);
    }

    function setDistributionMinimum(uint256 minKeys) external onlyOwner {
        distributionMinimum = minKeys;
        emit SetDistributionMinimum(minKeys);
    }
    
    function resetRewardTimer() external onlyOwner {
        lastSecond = block.timestamp;
        emit ResetRewardTimer();
    }

    function setFarm(address _farm) external onlyOwner {
        farm = _farm;
        emit SetFarm(_farm);
    }
    
    function setStake(address _stake) external onlyOwner {
        stake = _stake;
        emit SetStaker(_stake);
    }

    function setBountyPercentForLoyalKeyRank(uint256 loyalKeyRank, uint256 newBountyPercent) external onlyOwner {
        require(
            newBountyPercent < Bounty_Denom,
            'Bounty Too High'
        );
        loyalKeyRankToBountyPercent[loyalKeyRank] = newBountyPercent;
        emit SetBountyPercent(loyalKeyRank, newBountyPercent);
    }
    
    function setFundPercents(uint256 farmPercentage, uint256 stakePercentage) external onlyOwner {
        farmFee = farmPercentage;
        stakeFee = stakePercentage;
        feeDenom = farmPercentage + stakePercentage;
        emit SetFundPercents(farmPercentage, stakePercentage);
    }
    
    function withdrawToken(address token) external onlyOwner {
        uint256 bal = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, bal);
        emit TokenWithdrawal(bal);
    }
    
    function reApprove() external onlyOwner {
        IERC20(KEYS).approve(farm, MAX_INT);
    }
    
    // ONLY APPROVED
    
    function distribute() external {
        _distribute();
    }

    receive() external payable {
        (bool s,) = payable(KEYS).call{value: address(this).balance}("");
        require(s, 'Failure on Token Purchase');
        _distribute();    
    }

    // INTERNAL
    
    function _distribute() internal {

        // pending keys for distribution
        uint pending = pendingKeys();
        require(
            pending >= distributionMinimum,
            'Min Distribution Not Met'
        );

        // keys bounty
        uint256 bounty = calculateBounty(msg.sender, pending);

        // update timer
        lastSecond = block.timestamp;

        // send bounty to msg.sender
        if (bounty > 0) {
            IERC20(KEYS).transfer(msg.sender, bounty);
            pending = pending - bounty;    
        }

        // Increment Total Rewards And Bounties
        unchecked {
            totalRewards += pending;
            totalBounties += bounty;
        }
        
        // divy up pending keys
        uint256 keysForFarming = (pending * farmFee) / feeDenom;
        uint256 keysForStaking = pending - keysForFarming;

        // deposit keys in farm as rewards - we have already pre-approved for max int
        IKeysFarming(farm).deposit(keysForFarming);

        // transfer rewards to Keys MAXI
        IERC20(KEYS).transfer(stake, keysForStaking);    
    }


    // Read Functions

    function timeSince() public view returns (uint256) {
        return lastSecond >= block.timestamp ? 0 : block.timestamp - lastSecond;
    }

    function pendingKeys() public view returns (uint256) {
        uint pending = timeSince() * keysPerSecond;
        uint bal = balanceOf();
        return pending < bal ? pending : bal;
    }

    function balanceOf() public view returns (uint256) {
        return IERC20(KEYS).balanceOf(address(this));
    }

    function minBounty() public view returns (uint256) {
        return currentBounty(address(0));
    }

    function currentBounty(address user) public view returns (uint256) {
        return ( pendingKeys() * getBountyPercent(user) ) / Bounty_Denom;
    }

    function calculateBounty(address user, uint256 pending) public view returns (uint256) {
        return ( pending * getBountyPercent(user) ) / Bounty_Denom;
    }

    function getBountyPercent(address user) public view returns (uint256) {
        uint percent = loyalKeyRankToBountyPercent[getLoyalKeyRank(user)];
        return percent == 0 ? Default_Bounty_Percent : percent;
    }

    function getLoyalKeyRank(address user) public view returns (uint256) {
        if (user == address(0)) {
            return 0;
        }
        return loyalKey.getLoyalKeyRank(user);
    }
}