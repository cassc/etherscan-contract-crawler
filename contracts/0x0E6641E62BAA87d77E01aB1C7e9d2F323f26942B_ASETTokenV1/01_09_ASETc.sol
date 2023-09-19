//    217 131 217 135 217 138 216 185 216 181 32 216 173 217 133 216 185 216 179 217 130 
//          █████  ███████ ███████ ███████ ████████ ██      ██ ███    ██ ██   ██
//         ██   ██ ██      ██      ██         ██    ██      ██ ████   ██ ██  ██
//         ███████ ███████ ███████ █████      ██    ██      ██ ██ ██  ██ █████
//         ██   ██      ██      ██ ██         ██    ██      ██ ██  ██ ██ ██  ██
//         ██   ██ ███████ ███████ ███████    ██    ███████ ██ ██   ████ ██   ██
//    217 131 217 135 217 138 216 185 216 181 32 216 173 217 133 216 185 216 179 217 130 
/**
 * @title AssetLink Token (ASET)
 * @version 1.0.2
 * @date 2023-08-26
 * @license MIT
 * @author Tech Department, AssetLink
 * 
 * @dev Official smart contract for the AssetLink Token (ASET) and its presale.
 * Designed for a transparent, secure, and efficient token sale process.
 *
 * ## Key Features & Notes
 *
 * - **Initial & Max Supply**: 100 Million ASET, capped at 10 Billion ASET.
 * - **Presale Mechanism**: Adjustable min/max contributions, bonus rate, and price.
 * - **Staking**: Users can stake their tokens to earn rewards over time.
 * - **Staking of Vested**: Users can stake their vested tokens to earn rewards as they wait for release.
 * - **Investors**: Buy $ASET tokens to participate and benefit from utilities.
 * - **Funds**: Developer will withdraw all funds and use them as necessary in preparation for Q1 2024 launch.
 * - **Refund Mechanism**: Full refunds if minimum funding goal is not met.
 * - **Token Vesting**: Gradual distribution to contributors and team.
 * - **Rate Adjustments**: Dynamic token rate against ETH.
 * - **Pause & Resume**: Halt or resume functionalities.
 * - **Important**: Deployed after the achievement of the soft cap on the AssetLink platform. Refer to the official announcement for details.
 *
 * ## Tokenomics & Allocation
 *
 * - **Sale**: 20M ASET offered for sale. More details on the website.
 * - **Initial Supply**: Allocated to the contract owner upon deployment.
 * - **Team & Advisors**: 2 years of locking, cliff, and vesting.
 *
 * ## Security
 *
 * - Built with OpenZeppelin contracts, including ReentrancyGuard and Pausable.
 *
 * ## Official Links & Contact
 *
 * - **Website**: [https://assetlink.io](https://assetlink.io)
 * - **Note**: Conduct due diligence and consult professionals before participating.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

contract ASETTokenV1 is
    IERC20,
    Ownable,
    Pausable,
    ReentrancyGuard,
    AutomationCompatibleInterface
{
    // ------------------------
    // TOKEN PROPERTIES
    // ------------------------
    string private _NAME = "AssetLink Token";
    string private _SYMBOL = "ASET";
    uint8 private constant _DECIMALS = 18;
    uint256 private _totalSupply = 100000000 * (10**18);
    uint256 private constant _maxSupply = 10000000000 * (10**18);
    uint256 private lastMintTimestamp;
    uint256 private constant ONE_ETHER_IN_WEI = 10**18;
    uint256 private constant SIX_MONTHS_IN_SECONDS = 15768000;
    uint256 private constant TOTAL_PRESALE_TOKENS =
        20_000_000 * ONE_ETHER_IN_WEI;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // ------------------------
    // PRESALE PROPERTIES
    // ------------------------
    bool public presaleEnded = false;
    bool public minGoalReached = false;
    bool private hasSentTeamTokens = false;

    uint256 public minByWallet = 0.06 ether;
    uint256 public maxByWallet = 5 ether;
    uint256 public rate = 6313; // Tokens / ETH. Changes every week until presale ends.
    uint256 public minimumFundingGoal = 1 ether;
    uint256 public totalContributions = 0;
    uint256 public totalTokensPurchased = 0;
    uint256 public totalBonusGiven = 0;
    uint256 public bonusAmount = 0.06 ether; // Per each 1 ETH contributed
    uint256 public lastPriceIncrementTimestamp;
    address public lockContract; // The contract handling locked team tokens.
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public tokensPurchased;
    mapping(address => uint256) public bonusTokens;

    // ------------------------
    // VESTING PROPERTIES
    // ------------------------
    bool public claimAllowed = false;
    mapping(address => uint256) public vestedTokens;
    uint256 public vestingStart;
    uint256 public VESTING_DURATION = 365 days;
    uint256 public CLIFF_DURATION = 90 days;
    mapping(address => uint256) public claimed;

    // ------------------------
    // ALLOCATIONS
    // ------------------------
    // Token allocations (in terms of tokens, not wei)
    uint256 public developmentAllocation = 10000000 * 10**18;
    uint256 public marketingAllocation = 15000000 * 10**18;
    uint256 public teamAdvisorsAllocation = 10000000 * 10**18; // Locked for 2 years
    uint256 public reservesAllocation = 7000000 * 10**18;
    uint256 public liquidityAllocation = 20000000 * 10**18;
    uint256 public partnershipsAllocation = 13000000 * 10**18;
    uint256 public communityAllocation = 5000000 * 10**18;
    // icoAllocation (in the owner's wallet) = 20 * 10**6 * 10**18;

    // Wallet addresses for each allocation
    address public developmentWallet =
        0x8f899E8911f67918ADAe0b19Bb229AFB51141154;
    address public reservesWallet = 0x5A1627154858BE203aF31A4f2547e55d4D4Ba177;
    address public liquidityWallet = 0x0E13c1a88CdAf4f36Fe9bEcd43C58B20DdFB5d19;
    address public partnershipsWallet =
        0xE2937d8A2b68159CF7134eBc6Ab74ae7BD5688Aa;
    address public communityWallet = 0x91eedb8a3339c2829765834E087b18043F4bd889;
    // ico and marketing are in the owner's wallet;
    // teamAdvisorsWallet is the lock contract's address

    // ------------------------
    // EVENTS
    // ------------------------
    event TokensLocked(
        address indexed locker,
        address indexed lockContract,
        uint256 value
    );
    event Mint(address indexed minter, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event FundsReceived(address indexed _from, uint256 _amount);
    event FundsWithdrawn(address indexed _to, uint256 _amount);
    event VestingDurationChanged(uint256 newDuration);
    event CliffDurationChanged(uint256 newDuration);
    event TokensClaimed(address indexed claimer, uint256 amount);
    event BonusAmountChanged(uint256 newBonusAmount);
    event RateChanged(uint256 newRate);
    event PresaleEnded(bool minGoalReached);
    event MinGoalReached(uint256 totalContributions);
    event TokensReleasedFromLockContract(address indexed from, uint256 amount);
    event RewardPaid(address indexed recipient, uint256 amount);

    // ------------------------
    // STAKING PROPERTIES
    // ------------------------
    bool public stakingAllowed = false; // By default, it's set to false.
    uint256 public APY = 22; // Default value of 22%
    uint256 public stakingDuration = 365 days; // default to 365 days
    uint256 public stakingRewardPool;
    uint256 public unstakingCooldown = 7 days;
    mapping(address => uint256) public lastUnstakingTime; // Store the last unstaking time for each user
    mapping(address => uint256) public stakingBalances;
    mapping(address => uint256) public lastStakingTime;

    event Staked(address indexed user, uint256 amount, uint256 totalAmount);
    event Unstaked(address indexed user, uint256 amount, uint256 totalAmount);
    event RewardClaimed(address indexed user, uint256 reward);
    event APRUpdated(uint256 newAPR);
    event APYUpdated(uint256 newAPY);
    event StakingDurationUpdated(uint256 newDuration);
    event RewardsAddedToPool(address indexed owner, uint256 amount);
    event UnstakingCooldownUpdated(uint256 newCooldown);

    // ------------------------
    // MARKETING PARTNERS
    // ------------------------

    address payable public marketingPartner;
    uint256 public marketingFeesToBeRouted; // Amount to be routed in wei.
    uint256 public totalMarketingPaid = 0; // Cumulative amount paid to marketing partner.
    bool public routePaymentToMarketingPartner = false;
    event NewMarketingPartnerSet(address indexed partner, uint256 amount);

    // AUTOMATION
    uint256 public immutable rateIncreaseIv = 7 days;

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded =
            (block.timestamp - lastPriceIncrementTimestamp) >= rateIncreaseIv;
        return (upkeepNeeded, "");
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        if ((block.timestamp - lastPriceIncrementTimestamp) >= rateIncreaseIv) {
            incrementPrice();
        }
    }

    /**
     * @dev Constructs the ASETTokenV1 contract and initiates token allocation and other properties.
     */
    constructor() {
        //MINT THE 100M TOKENS TO INITIATE THE PROCESS
        _balances[owner()] = _totalSupply;
        emit Mint(address(0), owner(), _totalSupply);

        //MARK LAST MINT DATE: IMPORTANT FOR MINTING PROTECTION
        lastMintTimestamp = block.timestamp;

        //MARK THE FIRST PRICE POINT: IMPORTANT FOR PRESALE PRICE INCREASE
        lastPriceIncrementTimestamp = block.timestamp;

        //ALLOCATE TOKENS ACCORDING TO ASSETLINK TOKENOMICS
        address[] memory allocationAddresses = new address[](5);
        uint256[] memory allocationAmounts = new uint256[](5);

        allocationAddresses[0] = developmentWallet;
        allocationAmounts[0] = developmentAllocation;

        allocationAddresses[1] = reservesWallet;
        allocationAmounts[1] = reservesAllocation;

        allocationAddresses[2] = liquidityWallet;
        allocationAmounts[2] = liquidityAllocation;

        allocationAddresses[3] = partnershipsWallet;
        allocationAmounts[3] = partnershipsAllocation;

        allocationAddresses[4] = communityWallet;
        allocationAmounts[4] = communityAllocation;

        // Call batch transfer function to handle allocations
        _batchTransfer(owner(), allocationAddresses, allocationAmounts);
    }

    // ------------------------
    // TOKEN FUNCTIONS
    // ------------------------
    /**
     * @dev Sends team tokens to a specified lock contract.
     * The team allocation is locked for 2 years with vesting.
     * @param teamLockAddress The address of the lock contract.
     */
    function sendTeamTokensToLockContract(address teamLockAddress)
        external
        nonReentrant
        onlyOwner
    {
        require(!hasSentTeamTokens, "Team tokens already sent");
        require(teamLockAddress != address(0), "Invalid lock address");

        uint256 teamAllocation = teamAdvisorsAllocation;

        //SET THE CA
        lockContract = teamLockAddress;

        hasSentTeamTokens = true;

        _transfer(owner(), teamLockAddress, teamAllocation);

        //EMIT EVENTS
        emit TokensLocked(owner(), teamLockAddress, teamAllocation);
        emit Transfer(owner(), teamLockAddress, teamAllocation);
    }

    /**
     * @dev Mints new tokens, abiding by certain conditions such as time and amount limits.
     * Can only be called by the owner. Can only happen once every 6 months. Can only be 5% of total supply.
     * @param to The address receiving the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function _mint(address to, uint256 amount) internal onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Mint amount should be greater than zero");

        // Can only mint every 6 months.
        require(
            block.timestamp - lastMintTimestamp >= SIX_MONTHS_IN_SECONDS,
            "Cannot mint until 6 months have passed since the last minting"
        );

        uint256 mintLimit = (_totalSupply * 5) / 100; // Only 5% of total supply can be minted at once

        require(amount <= mintLimit, "Exceeds weekly mint limit");
        require(_totalSupply + amount <= _maxSupply, "Exceeds max supply");

        _totalSupply += amount;
        _balances[to] += amount;

        emit Mint(msg.sender, to, amount);
        emit Transfer(address(0), to, amount);

        // Update the lastMintTimestamp to the current time
        lastMintTimestamp = block.timestamp;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Mint amount should be greater than zero");

        _mint(to, amount);
    }

    /**
     * @dev Burns tokens from the caller's address.
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        _balances[msg.sender] -= amount;
        _totalSupply -= amount;

        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    /**
     * @dev Allows the owner to pay a reward to a specific address.
     * Can only be called by the owner.
     * @param _to The address to which the reward will be sent.
     * @param _amount The amount of the reward.
     */
    function payReward(address _to, uint256 _amount)
        external
        onlyOwner
        nonReentrant
    {
        require(_to != address(0), "Invalid recipient address");
        require(_amount > 0, "Reward amount should be greater than zero");
        require(
            _balances[owner()] >= _amount,
            "Insufficient balance to pay reward"
        );

        _transfer(owner(), _to, _amount);
        emit RewardPaid(_to, _amount);
    }

    /**
     * @dev Returns the maximum supply of the token.
     * @return The maximum token supply.
     */
    function maxSupply() external pure returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * @return The total supply of tokens.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the name of the token.
     * @return The token name.
     */
    function name() external view returns (string memory) {
        return _NAME;
    }

    /**
     * @dev Returns the symbol of the token.
     * @return The token symbol.
     */
    function symbol() external view returns (string memory) {
        return _SYMBOL;
    }

    /**
     * @dev Returns the number of decimals used to get the token's smallest unit.
     * @return The number of decimals used by the token.
     */
    function decimals() external pure returns (uint8) {
        return _DECIMALS;
    }

    /**
     * @dev Returns the amount of tokens owned by the specified address.
     * @param account The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Moves the specified amount of tokens to the specified address.
     * @param recipient The address to receive the tokens.
     * @param amount The amount of tokens to send.
     * @return A boolean indicating whether the operation succeeded.
     */
    function transfer(address recipient, uint256 amount)
        external
        whenNotPaused
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that the spender can spend on behalf of the owner.
     * @param _owner The address of the token owner.
     * @param spender The address of the spender.
     * @return The remaining number of tokens that the spender can spend.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    /**
     * @dev Sets the allowance for the spender over the caller's tokens.
     * @param spender The address of the spender.
     * @param amount The number of tokens to allow.
     * @return A boolean indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount)
        external
        whenNotPaused
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Moves tokens from one address to another using the allowance mechanism.
     * @param sender The address to send tokens from.
     * @param recipient The address to send tokens to.
     * @param amount The amount of tokens to send.
     * @return A boolean indicating whether the operation succeeded.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    /**
     * @dev Returns the Ether balance of the contract.
     * @return The Ether balance of the contract.
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Pauses all token transfers, approvals, and other operations. Can only be called by the contract owner.
     */
    function pause() external nonReentrant onlyOwner {
        _pause();
    }

    /**
     * @dev Resumes all token transfers, approvals, and other paused operations. Can only be called by the contract owner.
     */
    function unpause() external nonReentrant onlyOwner {
        _unpause();
    }

    /**
     * @dev Internal function to transfer tokens between addresses.
     * @param sender The address sending the tokens.
     * @param recipient The address receiving the tokens.
     * @param amount The amount of tokens to transfer.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(recipient != address(0), "Invalid recipient address");
        if (sender != address(0)) {
            require(_balances[sender] >= amount, "Insufficient balance");
            _balances[sender] -= amount;
        }

        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Internal function to batch transfer tokens to multiple recipients.
     * @param from The address from which the tokens will be sent.
     * @param recipients An array of addresses that will receive the tokens.
     * @param amounts An array of amounts to send to each recipient.
     */
    function _batchTransfer(
        address from,
        address[] memory recipients,
        uint256[] memory amounts
    ) internal {
        require(
            recipients.length == amounts.length,
            "Recipients and amounts array length must match"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            require(
                recipients[i] != address(0),
                "Recipient address cannot be 0"
            );
            require(amounts[i] > 0, "Amount must be greater than 0");

            _transfer(from, recipients[i], amounts[i]);
        }
    }

    /**
     * @dev Transfers tokens from the contract's balance to the specified address.
     * Can only be called by the contract owner.
     * @param recipient The address to receive the tokens.
     * @param amount The amount of tokens to send.
     */
    function sendTokensFromContract(address recipient, uint256 amount)
        external
        nonReentrant
        onlyOwner
    {
        require(recipient != address(0), "Cannot transfer to the zero address");
        require(
            amount <= _balances[address(this)],
            "transfer amount exceeds balance"
        );

        _transfer(address(this), recipient, amount);
    }

    /**
     * @dev Internal function to set allowance for a spender over the caller's tokens.
     * @param _owner The owner of the tokens.
     * @param spender The address getting the allowance.
     * @param amount The amount of tokens allowed.
     */

    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) internal {
        require(_owner != address(0), "Invalid owner address");
        require(spender != address(0), "Invalid spender address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    // ------------------------
    // VESTING FUNCTIONS
    // ------------------------

    /**
     * @dev Sets the duration of the token vesting period.
     * Can only be set by the owner.
     * @param _durationInDays The new vesting duration, in days.
     */

    function setVestingDuration(uint256 _durationInDays) external onlyOwner {
        require(_durationInDays > 0, "Duration should be greater than zero");
        require(
            _durationInDays * 1 days > CLIFF_DURATION,
            "Vesting duration should be greater than the cliff duration"
        );
        VESTING_DURATION = _durationInDays * 1 days;
        emit VestingDurationChanged(VESTING_DURATION);
    }

    /**
     * @dev Sets the duration of the cliff in the vesting schedule.
     * Can only be set by the owner.
     * @param _durationInDays The new cliff duration, in days.
     */

    function setCliffDuration(uint256 _durationInDays) external onlyOwner {
        require(_durationInDays > 0, "Duration should be greater than zero");
        require(
            VESTING_DURATION > _durationInDays * 1 days,
            "Cliff duration should be less than the vesting duration"
        );
        CLIFF_DURATION = _durationInDays * 1 days;
        emit CliffDurationChanged(CLIFF_DURATION);
    }

    /**
     * @dev Returns the amount of tokens that can be claimed by an address.
     * @param user The address of the user.
     * @return The amount of tokens that can be claimed.
     */

    function getClaimableAmount(address user) public view returns (uint256) {
        if (block.timestamp < vestingStart + CLIFF_DURATION) {
            return 0;
        }
        if (block.timestamp >= vestingStart + VESTING_DURATION) {
            return vestedTokens[user] - claimed[user]; // Claim whatever is left after vesting duration
        }

        uint256 elapsedTimeAfterCliff = block.timestamp -
            (vestingStart + CLIFF_DURATION);

        uint256 effectiveVestingDuration = VESTING_DURATION - CLIFF_DURATION;

        uint256 claimablePercentage = (elapsedTimeAfterCliff * 100) /
            effectiveVestingDuration;

        uint256 totalVestedAmount = vestedTokens[user];

        uint256 totalClaimableAmount = (totalVestedAmount *
            claimablePercentage) / 100;

        return totalClaimableAmount - claimed[user];
    }

    // ------------------------
    // PRESALE FUNCTIONS
    // ------------------------

    /**
     * @dev Sets the minimum funding goal for the presale.
     * @param _minimumFundingGoalInEther The new minimum funding goal, in Ether.
     */

    function setMinimumFundingGoalInEther(uint256 _minimumFundingGoalInEther)
        external
        nonReentrant
        onlyOwner
    {
        require(
            _minimumFundingGoalInEther > 0,
            "Minimum funding goal should be greater than zero"
        );
        minimumFundingGoal = _minimumFundingGoalInEther * (ONE_ETHER_IN_WEI);
    }

    /**
     * @dev Sets the bonus amount for the presale.
     * @param newBonusAmountInEther The new bonus amount, in Ether.
     */

    function setBonusAmount(uint256 newBonusAmountInEther) external onlyOwner {
        bonusAmount = newBonusAmountInEther * (ONE_ETHER_IN_WEI);
    }

    /**
     * @dev Internal function to mark the end of the presale.
     * Updates state variables and starts the vesting period.
     */

    function _endPresale() private {
        require(!presaleEnded, "Presale already ended");
        presaleEnded = true;
        minGoalReached = totalContributions >= minimumFundingGoal;
        vestingStart = block.timestamp;
        claimAllowed = true;
        emit PresaleEnded(minGoalReached);
    }

    /**
     * @dev Manually ends the presale. Can only be called by the owner.
     */

    function endPresaleManually() external onlyOwner {
        _endPresale();
    }

    /**
     * @dev Allows or disallows token claiming.
     * @param _status The new status for token claiming.
     */

    function setClaimAllowed(bool _status) external onlyOwner {
        claimAllowed = _status;
    }

    /**
     * @dev Allows users to claim vested tokens.
     * Can only be called after the presale has ended and the minimum goal is reached.
     */

    function claimTokens() external canClaim nonReentrant {
        require(presaleEnded, "Presale not ended");
        require(minGoalReached, "Funding goal not reached");

        uint256 claimableAmount = getClaimableAmount(msg.sender);
        require(claimableAmount > 0, "Nothing to claim or it is not time yet");

        require(
            claimed[msg.sender] + claimableAmount <= vestedTokens[msg.sender],
            "Claim exceeds allowed amount"
        );

        claimed[msg.sender] += claimableAmount;
        _transfer(owner(), msg.sender, claimableAmount);

        emit TokensClaimed(msg.sender, claimableAmount);
    }

    /**
     * @dev Refunds contributions for users if the presale did not reach the minimum goal.
     */

    function refundContributions() external nonReentrant {
        require(presaleEnded, "Presale not ended");
        require(!minGoalReached, "Funding goal reached");
        require(
            claimed[msg.sender] == 0,
            "Tokens already claimed, refund not possible"
        );

        uint256 etherSent = contributions[msg.sender];
        require(etherSent > 0, "No contributions found");

        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(etherSent);
    }

    /**
     * @dev Checks the current worth in Ether of the user's tokens.
     * @return The worth of the user's tokens in Ether.
     */

    function checkTokenWorth() external view returns (uint256) {
        require(vestedTokens[msg.sender] > 0, "You have no allocated tokens");

        // Calculate worth in Ether according to the current rate
        uint256 tokenWorthInEther = (vestedTokens[msg.sender] *
            ONE_ETHER_IN_WEI) / rate;

        return tokenWorthInEther;
    }

    /**
     * @dev Receives Ether sent to the contract, calculates the amount of tokens to be bought based on the current rate,
     * and handles bonuses if applicable. Tokens are vested for the buyer. If the total contributions reach the minimum funding goal,
     * an event is emitted. If the total tokens purchased hit the presale limit, the presale ends.
     * Additionally, handles the routing of payments to the marketing partner.
     * ك ه ي ع ص ح م ع س ق
     */

    receive() external payable whenNotPaused nonReentrant {
        require(msg.value >= minByWallet, "Below minimum limit");
        require(msg.value <= maxByWallet, "Above maximum limit");
        require(
            contributions[msg.sender] + msg.value <= maxByWallet,
            "Total contributions exceed maximum limit per wallet"
        );

        // CALCULATES THE AMOUNT OF TOKENS BASED ON THE CURRENT RATE (TOKEN PRICE)
        uint256 tokensBought = (msg.value * rate) / (ONE_ETHER_IN_WEI);
        uint256 totalBonus = 0;

        if (bonusAmount > 0) {
            uint256 bonusForEther = (bonusAmount * rate) / (ONE_ETHER_IN_WEI);
            totalBonus = (msg.value / 1 ether) * bonusForEther;
            totalBonusGiven += totalBonus;
        }
        require(
            _balances[owner()] >= tokensBought + totalBonus,
            "Insufficient tokens in reserve"
        );

        // STORE ETH VALUE (MIGHT BE USED FOR REFUNDS)
        contributions[msg.sender] += msg.value;

        // LOG HOW MANY TOKENS PURCHASED
        tokensPurchased[msg.sender] += tokensBought;

        // ADD BONUS IF APPLICABLE
        bonusTokens[msg.sender] += totalBonus;

        // TAKE TOKENS FROM OWNER WALLET
        _balances[owner()] -= (tokensBought + totalBonus);

        // VEST THE TOKENS FOR THE BUYER
        vestedTokens[msg.sender] += (tokensBought + totalBonus);

        totalContributions += msg.value;
        totalTokensPurchased += tokensBought;

        if (totalContributions >= minimumFundingGoal && !minGoalReached) {
            minGoalReached = true;
            emit MinGoalReached(totalContributions); // Emit the event
        }

        emit FundsReceived(msg.sender, msg.value);

        // MARKETING PARTNER HANDLING
        // IF ENABLED, 50% OF EACH RECEIVED PAYMENT WILL BE ROUTED TO MARKETING PROVIDER UNTIL AMOUNT IS DELIVERED
        if (routePaymentToMarketingPartner && marketingPartner != address(0)) {
            uint256 halfOfReceived = msg.value / 2; // Calculate half of the received value
            uint256 amountToRoute = marketingFeesToBeRouted -
                totalMarketingPaid; // Amount left to be routed
            if (halfOfReceived > amountToRoute) {
                // If half of the amount received exceeds the amount left to be routed
                marketingPartner.transfer(amountToRoute);
                totalMarketingPaid += amountToRoute;
            } else {
                // If half of the amount received is less than or equal to the amount left to be routed
                marketingPartner.transfer(halfOfReceived);
                totalMarketingPaid += halfOfReceived;
            }

            if (totalMarketingPaid >= marketingFeesToBeRouted)
                routePaymentToMarketingPartner = false;
        }

        // END THE PRESALE WHEN TOTAL BUYS HIT 20M TOKENS
        if (totalTokensPurchased >= TOTAL_PRESALE_TOKENS) {
            _endPresale();
        }
    }

    /**
     * @dev Allows the owner to adjust the token sale price upward.
     *
     * Constraints:
     * - Can only be invoked once per week.
     *
     * Rationale:
     * - Designed to incentivize early participation in the presale.
     * - Rewards early investors by gradually increasing the token cost.
     *
     * Implementation Details:
     * - Increases the token price by reducing the 'rate' variable.
     * - The price inflates approximately by 5% each week.
     */
    function incrementPrice() public nonReentrant {
        require(
            block.timestamp - lastPriceIncrementTimestamp >= rateIncreaseIv,
            "Increment too frequently"
        );

        // Reduce the 'rate' to effectively increase the token price by ~5%
        rate = (rate * 1000) / 1055;
        lastPriceIncrementTimestamp = block.timestamp;
        emit RateChanged(rate);
    }

    /**
     * @dev Sets the minimum contribution limit per wallet in Ether.
     * @param newMinInEther The new minimum contribution limit in Ether.
     */

    function setMinByWalletInEther(uint256 newMinInEther) external onlyOwner {
        minByWallet = newMinInEther * (ONE_ETHER_IN_WEI);
    }

    /**
     * @dev Sets the maximum contribution limit per wallet in Ether.
     * @param newMaxInEther The new maximum contribution limit in Ether.
     */

    function setMaxByWalletInEther(uint256 newMaxInEther) external onlyOwner {
        maxByWallet = newMaxInEther * (ONE_ETHER_IN_WEI);
    }

    /**
     * @dev Sets the bonus amount in Ether.
     * @param newBonusAmountInEther The new bonus amount in Ether.
     */

    function setBonusAmountInEther(uint256 newBonusAmountInEther)
        external
        onlyOwner
    {
        bonusAmount = newBonusAmountInEther * (ONE_ETHER_IN_WEI);
        // You can also emit an event here to log the change
        emit BonusAmountChanged(bonusAmount);
    }

    // ------------------------
    // WITHDRAWAL FUNCTIONS
    // ------------------------

    // ALLOW THE OWNER TO WITHDRAW RECEIVED FUNDS TO A DEFINED WALLET
    // OWNER CANNOT WITHDRAW FUNDS IF THE MINIMUM PRESALE GOAL IS NOT MET
    // FUNDS WITHDRAWN ARE USED IN DEV, MARKETING, PARNTERSHIPS AND MORE

    /**
     * @dev Allows the owner to withdraw the contract balance.
     * Can only be called if the minimum funding goal is reached.
     * @param _to The address to send the withdrawn funds to.
     */

    function withdrawBalance(address payable _to)
        external
        onlyOwner
        nonReentrant
    {
        require(minGoalReached, "Funding goal not reached");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        require(_to != address(0), "Invalid address");

        _to.transfer(balance);
        emit FundsWithdrawn(_to, balance);
    }

    /**
     * @dev Allows the owner to withdraw a specific amount from the contract.
     * Can only be called if the minimum funding goal is reached.
     * @param _to The address to send the withdrawn funds to.
     * @param amountInEther The amount to withdraw, in Ether.
     */

    function withdrawSome(address payable _to, uint256 amountInEther)
        external
        onlyOwner
        nonReentrant
    {
        require(minGoalReached, "Funding goal not reached");
        require(
            amountInEther > 0,
            "Withdrawal amount should be greater than zero"
        );
        uint256 amountToWithdraw = amountInEther * (ONE_ETHER_IN_WEI);
        require(
            amountToWithdraw <= address(this).balance,
            "Amount exceeds balance"
        );
        require(_to != address(0), "Invalid address");

        _to.transfer(amountToWithdraw);
        emit FundsWithdrawn(_to, amountToWithdraw);
    }

    // ------------------------
    // MODIFIERS
    // ------------------------
    modifier canClaim() {
        require(claimAllowed, "Claim not allowed");
        _;
    }

    // ------------------------
    // STAKING
    // ------------------------

    /**
     * @dev Sets the staking duration in days.
     * @param _durationInDays The duration in days for staking.
     */
    function setStakingDuration(uint256 _durationInDays) external onlyOwner {
        require(_durationInDays > 0, "Duration should be greater than 0 days");
        stakingDuration = _durationInDays * 1 days;
        emit StakingDurationUpdated(stakingDuration);
    }

    /**
     * @dev Sets the APY (Annual Percentage Yield) for staking.
     * @param _apyInPercentage The APY value in percentage.
     */
    function setAPY(uint256 _apyInPercentage) external nonReentrant onlyOwner {
        require(_apyInPercentage > 0, "APR should be greater than 0");
        APY = _apyInPercentage;
        emit APYUpdated(APY);
    }

    /**
     * @dev Returns the number of vested tokens for the caller.
     */
    function getVestedTokens() public view returns (uint256) {
        return stakingBalances[msg.sender];
    }

    /**
     * @dev Allows users to stake a specified amount of tokens.
     * @param amount The amount of tokens to stake.
     */
    function stakeTokens(uint256 amount) external nonReentrant whenNotPaused {
        require(stakingAllowed, "Staking is currently not allowed");
        require(
            block.timestamp >=
                lastUnstakingTime[msg.sender] + unstakingCooldown,
            "You are still within the unstaking cooldown period"
        );
        require(amount > 0, "Staking amount must be greater than zero");
        require(
            _balances[msg.sender] >= amount,
            "Insufficient balance for staking"
        );
        _transfer(msg.sender, address(this), amount);
        stakingBalances[msg.sender] += amount;
        lastStakingTime[msg.sender] = block.timestamp;
        emit Staked(msg.sender, amount, stakingBalances[msg.sender]);
    }

    /**
     * @dev Allows users to stake a specified amount of their vested tokens.
     * @param amount The amount of vested tokens to stake.
     */
    function stakeVestedTokens(uint256 amount)
        external
        nonReentrant
        whenNotPaused
    {
        require(stakingAllowed, "Staking is currently not allowed");
        require(
            block.timestamp >=
                lastUnstakingTime[msg.sender] + unstakingCooldown,
            "You are still within the unstaking cooldown period"
        );
        require(amount > 0, "Staking amount must be greater than zero");
        uint256 vestedAmount = vestedTokens[msg.sender];
        require(
            vestedAmount >= amount,
            "Insufficient vested tokens for staking"
        );
        vestedTokens[msg.sender] -= amount;
        stakingBalances[msg.sender] += amount;
        lastStakingTime[msg.sender] = block.timestamp;
        emit Staked(msg.sender, amount, stakingBalances[msg.sender]);
    }

    /**
     * @notice Allows users to unstake their tokens and claim rewards.
     * @dev The function first checks if the user has staked tokens and if the staking duration has passed.
     * It then transfers the staked tokens back to the user and resets their staking balance.
     * After that, it calculates the reward for the user, checks if the reward is available, and transfers it.
     * Finally, it updates the last unstaking time for the user and emits relevant events.
     */

    function unstakeAndReward() external nonReentrant whenNotPaused {
        uint256 amount = stakingBalances[msg.sender];
        require(amount > 0, "No staked tokens to unstake");
        require(
            block.timestamp >= lastStakingTime[msg.sender] + stakingDuration,
            "Cannot unstake within staking duration"
        );

        _transfer(address(this), msg.sender, amount);

        stakingBalances[msg.sender] = 0;

        uint256 reward = calculateReward(msg.sender);

        require(reward > 0, "No rewards available");
        require(stakingRewardPool >= reward, "Not enough rewards in the pool");

        stakingRewardPool -= reward;
        _transfer(address(this), msg.sender, reward);

        lastUnstakingTime[msg.sender] = block.timestamp;

        emit Unstaked(msg.sender, amount, stakingBalances[msg.sender]);
        emit RewardClaimed(msg.sender, reward);
    }

    /**
     * @dev Calculates the reward for a given user based on their staking balance and time.
     * @param user The address of the user.
     * @return The calculated reward amount.
     */
    function calculateReward(address user) public view returns (uint256) {
        uint256 stakingTimeInDays = (block.timestamp - lastStakingTime[user]) /
            1 days;
        uint256 reward = stakingBalances[user] *
            ((1 + APY / 100)**stakingTimeInDays - 1);
        return reward;
    }

    /**
     * @dev Adds a specified amount of tokens to the staking reward pool.
     * @param _amount The amount of tokens to add to the reward pool.
     */
    function addRewardsToPool(uint256 _amount) external onlyOwner {
        require(
            _balances[msg.sender] >= _amount,
            "Not enough balance to add to the pool"
        );
        _transfer(msg.sender, address(this), _amount);
        stakingRewardPool += _amount;
        emit RewardsAddedToPool(msg.sender, _amount);
    }

    /**
     * @dev Sets the unstaking cooldown period in days.
     * @param _cooldownInDays The cooldown period in days.
     */
    function setUnstakingCooldown(uint256 _cooldownInDays) external onlyOwner {
        require(_cooldownInDays >= 0, "Cooldown should be non-negative");
        unstakingCooldown = _cooldownInDays * 1 days;
        emit UnstakingCooldownUpdated(unstakingCooldown);
    }

    /**
     * @dev Enables staking functionality.
     */
    function enableStaking() external onlyOwner {
        stakingAllowed = true;
    }

    /**
     * @dev Disables staking functionality.
     */
    function disableStaking() external onlyOwner {
        stakingAllowed = false;
    }

    /**
     * @dev Sets a marketing partner and the amount to be routed in Ether.
     * @param _marketingPartner The address of the marketing partner.
     * @param _amountInEther The amount in Ether to be routed.
     */
    function setMarketingPartner(
        address payable _marketingPartner,
        uint256 _amountInEther
    ) external nonReentrant onlyOwner {
        marketingPartner = _marketingPartner;
        marketingFeesToBeRouted = _amountInEther * 10**18;
        totalMarketingPaid = 0;
        routePaymentToMarketingPartner = true;
        emit NewMarketingPartnerSet(_marketingPartner, _amountInEther);
    }

    /**
     * @dev Toggles the payment routing to the marketing partner.
     * @param _status The status to set for payment routing (true/false).
     */
    function togglePaymentRouting(bool _status) external onlyOwner {
        routePaymentToMarketingPartner = _status;
    }
}