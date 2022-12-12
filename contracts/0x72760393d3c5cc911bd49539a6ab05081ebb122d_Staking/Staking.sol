/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

error NotOwner();
error NullAddress();
error TransferFail();
error InvalidAmount();
error InvalidCaller();
error EthTransferFail();
error NoClaimableRewards();
error ExceedsMaxPenalty();

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

library TransferHelper {

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper::safeTransfer: transfer failed');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper::transferFrom: transferFrom failed');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

contract Eggs is IERC20 {
    uint256 public totalSupply_ = 0;
    string constant public NAME = "EGGS";
    string constant public SYMBOL = "EGGS";
    uint8 constant public DECIMALS = 18;
    address public stakingAddress;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    event MintEggs(address to, uint amount);
    event BurnEggs(uint amount);

    constructor() {
        stakingAddress = msg.sender;
    }

    function mint(address to, uint amount) external {
        require(stakingAddress == msg.sender, "Not allowed");
        require(to != address(0), "Zero address");
        require(amount > 0, "Null");
        totalSupply_ += amount;
        balances[to] += amount;
        emit MintEggs(to, amount);
    }

    function burn(address from, uint amount) external {
        require(from != address(0), "Zero address");
        require(amount > 0, "Null");
        require(amount <= balances[from]);
        if (from != msg.sender) {
            uint256 all = allowed[from][msg.sender];
            require(all >= amount, "allowance");
            allowed[from][msg.sender] = all - amount;
        }
        totalSupply_ -= amount;
        balances[from] -= amount;
        emit BurnEggs(amount);
    }

    function approve(address spender, uint256 amount) external override returns (bool){
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function totalSupply() external override view returns (uint256){
        return totalSupply_;
    }

    function balanceOf(address account) external override view returns (uint256){
        return balances[account];
    }

    function transfer(address to, uint256 amount) external override returns (bool){
        return _transfer(msg.sender, to, amount);
    }

    function allowance(address owner, address spender) external override view returns (uint256){
        return allowed[owner][spender];
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool){
        uint256 all = allowed[from][msg.sender];
        if (all < amount) {
            return false;
        }
        allowed[from][msg.sender] = all - amount;
        return _transfer(from, to, amount);
    }

    function _transfer(address from, address to, uint amount) private returns (bool){
        if (balances[from] < amount) {
            return false;
        }
        balances[to] += amount;
        balances[from] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
}

contract Staking is ReentrancyGuard {

    struct Stake {
        uint256 weight;
        uint256 stakedAmount;
        uint256 claimedRewards;
        uint256 minStakeTime;
    }

    // State Variables
    uint256 private s_trueRewards;
    uint256 private s_scaledRewards;
    uint256 private s_totalWeight;
    uint256 private s_totalETHRewards;
    uint256 private s_totalETHWeight;
    uint256[4] private s_tierWeights;
    uint256[4] private s_tierPeriods;
    uint256[4] private s_stakePerTier;
    address private s_penaltyAddress;
    uint256 private s_penaltyTax;
    address private s_eggs;
    address immutable public BASAN;
    address private immutable i_owner;
    uint256 constant public TOP_TIER_IDX = 3;
    uint256 constant public MAX_PENALTY_TAX = 250; // 25%

    mapping(address => mapping(uint256 => Stake)) public stakes;
    mapping(address => uint256) public claimedETHRewards; // only for top tier

    constructor() {
        s_tierWeights = [1, 2, 3, 4]; 
        s_tierPeriods = [0 , 30 days, 60 days, 90 days]; 
        s_penaltyTax = 200; // 20%
        s_penaltyAddress = 0x000000000000000000000000000000000000dEaD;
        BASAN = 0x970cf867Ca0530a989f222bE01FdD67C1ab5b2bF;
        i_owner = msg.sender;
        s_eggs = address(new Eggs());
    }

    // Events
    event IncomingBasanRewards(uint256 amount);
    event IncomingETHRewards(uint256 amount);
    event BasanStaked(address staker, uint256 amount, uint256 tier);
    event BasanRewardsClaimed(address staker, uint256 amount, uint256 tier);
    event BasanUnstaked(address staker, uint256 amount, uint256 tier);
    event EthRewardsClaimed(address staker, uint256 ethAmount);
    event RewardTokenChanged(address rewardTokenAddress);
    event PenaltyStateToggled(bool penaltyEnabled);
    event PenaltyTaxChanged(uint256 penaltyTax);
    event PenaltyAddressChanged(address penaltyAddress);

    function sync(uint256 amount) external {
        // add incoming rewards
        if (msg.sender != BASAN) revert InvalidCaller();
        s_scaledRewards += amount;
        s_trueRewards += amount;
        emit IncomingBasanRewards(amount);
    }

    function stake(uint256 amount, uint256 tier) external nonReentrant {
        // receive amount to stake
        if (amount == 0) revert InvalidAmount();
        TransferHelper.safeTransferFrom(BASAN, msg.sender, address(this), amount);

        uint256 newWeight = s_tierWeights[tier] * amount;
        uint256 claimedOffset = 0;

        if (s_totalWeight > 0) {
            claimedOffset = (s_scaledRewards * newWeight) / s_totalWeight;
            s_scaledRewards = (s_scaledRewards * (s_totalWeight + newWeight)) / s_totalWeight;
        }

        s_totalWeight += newWeight;

        // add stake
        Stake memory s = stakes[msg.sender][tier];
        stakes[msg.sender][tier] = Stake(
            s.weight + newWeight,
            s.stakedAmount + amount,
            s.claimedRewards + claimedOffset,
            tier > 0 ? block.timestamp + s_tierPeriods[tier] : 0
        );

        // For tracking ETH distribution to top tier (index 3?)
        if (tier == TOP_TIER_IDX) {
            if (s_totalETHWeight > 0) {
                claimedETHRewards[msg.sender] += (s_totalETHRewards * amount) / s_totalETHWeight;
                s_totalETHRewards = (s_totalETHRewards * (s_totalETHWeight + amount)) / s_totalETHWeight;
            }
            s_totalETHWeight += amount;
        }

        // only used for frontend query
        s_stakePerTier[tier] += amount;

        emit BasanStaked(msg.sender, amount, tier);
    }

    function unstake(uint256 amount, uint256 tier) external nonReentrant {
        Stake memory s = stakes[msg.sender][tier];
        if (amount == 0 || amount > s.stakedAmount) revert InvalidAmount();

        // get claimable rewards
        uint256 claimableRewards = getClaimableRewards(tier, msg.sender);
        if (claimableRewards > 0) s_trueRewards -= claimableRewards;
        uint256 unstakedWeight = amount * s_tierWeights[tier];

        // For EGG & ETH rewards if top tier
        if (tier == TOP_TIER_IDX) {
            if (claimableRewards > 0) {
                Eggs(s_eggs).mint(msg.sender, claimableRewards);
            }
            uint256 claimableETHRewards = getClaimableETHRewards(msg.sender);
            claimedETHRewards[msg.sender] = (s_totalETHRewards * (s.stakedAmount - amount)) / s_totalETHWeight;
            s_totalETHRewards = (s_totalETHRewards * (s_totalETHWeight - amount)) / s_totalETHWeight;
            s_totalETHWeight -= amount;
            TransferHelper.safeTransferETH(msg.sender, claimableETHRewards);
            emit EthRewardsClaimed(msg.sender, claimableETHRewards);
        }

        // update stake
        if (s.stakedAmount == amount) {
            delete stakes[msg.sender][tier];
        } else {
            uint256 updatedStakeWeight = s.weight - unstakedWeight;
            stakes[msg.sender][tier] = Stake(
                updatedStakeWeight,
                s.stakedAmount - amount,
                (s_scaledRewards * updatedStakeWeight) / s_totalWeight,
                tier > 0 ? block.timestamp + s_tierPeriods[tier] : 0
            );
        }

        // scale total rewards and update total weight
        s_scaledRewards = (s_scaledRewards * (s_totalWeight - unstakedWeight)) / s_totalWeight;
        s_totalWeight -= unstakedWeight;

        // Remove % of amount to be transferred if unstaked prematurely
        uint256 transferAmount = amount;
        if (tier > 0 && s_penaltyTax > 0 && block.timestamp < s.minStakeTime) {
            uint256 penalty = (transferAmount * s_penaltyTax) / 1000;
            transferAmount = transferAmount - penalty;
            TransferHelper.safeTransfer(BASAN, s_penaltyAddress, penalty);
        }

        // only used for frontend query
        s_stakePerTier[tier] -= amount;

        // transfer unstaked amount + claimed rewards (- penalty)
        TransferHelper.safeTransfer(BASAN, msg.sender, transferAmount + claimableRewards);
        emit BasanUnstaked(msg.sender, amount, tier);
    }

    function claimAllRewards() external {
        for (uint i = 0; i <= TOP_TIER_IDX; i++) {
            uint256 claimableRewards = getClaimableRewards(i, msg.sender);
            if (claimableRewards > 0) claimRewards(i, msg.sender);
        }
        uint256 claimableETHRewards = getClaimableETHRewards(msg.sender);
        if (claimableETHRewards > 0) claimETHRewards(msg.sender);
    }

    function claimRewards(uint256 tier, address from) public nonReentrant {
        if (msg.sender != from && msg.sender != address(this)) revert InvalidCaller();
        uint256 claimableRewards = getClaimableRewards(tier, msg.sender);
        if (claimableRewards == 0) revert NoClaimableRewards();
        s_trueRewards -= claimableRewards;

        // update claimedRewards
        uint256 weight = stakes[from][tier].weight;
        stakes[from][tier].claimedRewards = (s_scaledRewards * weight) / s_totalWeight;

        // transfer claimed amount
        TransferHelper.safeTransfer(BASAN, from, claimableRewards);
        if (tier == TOP_TIER_IDX) {
            Eggs(s_eggs).mint(from, claimableRewards);
        }
        emit BasanRewardsClaimed(from, claimableRewards, tier);
    }

    function claimETHRewards(address from) public nonReentrant {
        if (msg.sender != from && msg.sender != address(this)) revert InvalidCaller();
        uint256 claimableETHRewards = getClaimableETHRewards(from);
        if (claimableETHRewards == 0) revert NoClaimableRewards();

        // update claimedRewards
        uint256 amount = stakes[from][TOP_TIER_IDX].stakedAmount;
        claimedETHRewards[from] = (s_totalETHRewards * amount) / s_totalETHWeight;

        // transfer claimed amount
        TransferHelper.safeTransferETH(from, claimableETHRewards);
        emit EthRewardsClaimed(from, claimableETHRewards);
    }

    function getClaimableRewards(uint256 tier, address from) public view returns (uint256) {
        if (s_totalWeight == 0) return 0;
        Stake memory s = stakes[from][tier];
        uint256 rewardAmount = (s_scaledRewards * s.weight) / s_totalWeight;
        uint256 claimableRewards = 0;
        if (s.claimedRewards < rewardAmount) {
            claimableRewards = rewardAmount - s.claimedRewards;
        }
        return min(claimableRewards, s_trueRewards);
    }

    function getClaimableETHRewards(address from) public view returns (uint256) {
        uint256 amount = stakes[from][TOP_TIER_IDX].stakedAmount;
        if (amount == 0) return 0;
        uint256 claimedETH = claimedETHRewards[from];
        uint256 rewardAmountETH = (s_totalETHRewards * amount) / s_totalETHWeight;
        uint256 claimableETH = 0;
        if (claimedETH < rewardAmountETH) {
            claimableETH = rewardAmountETH - claimedETH;
        }
        return claimableETH;
    }

    function getTierWeights() external view returns (uint256[4] memory) {
        return s_tierWeights;
    }

    function getTierPeriods() external view returns (uint256[4] memory) {
        return s_tierPeriods;
    }

    function getStakePerTier() external view returns (uint256[4] memory) {
        return s_stakePerTier;
    }

    function getTotalRewards() external view returns (uint256) {
        return s_trueRewards;
    }

    function getTotalWeight() external view returns (uint256) {
        return s_totalWeight;
    }

    function getTotalETHRewards() external view returns (uint256) {
        return s_totalETHRewards;
    }

    function getTotalETHWeight() external view returns (uint256) {
        return s_totalETHWeight;
    }

    function getStake(address staker, uint256 tier) external view returns (Stake memory) {
        return stakes[staker][tier];
    }

    function getRewardTokenAddress() external view returns (address) {
        return s_eggs;
    }

    function getPenaltyTax() external view returns (uint256) {
        return s_penaltyTax;
    }

    function getPenaltyAddress() external view returns (address) {
        return s_penaltyAddress;
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function setRewardTokenAddress(address rewardTokenAddress) onlyOwner external {
        if (rewardTokenAddress == address(0)) revert NullAddress();
        s_eggs = rewardTokenAddress;
        emit RewardTokenChanged(rewardTokenAddress);
    }

    function setPenaltyTax(uint256 penaltyTax) onlyOwner external {
        if (penaltyTax > MAX_PENALTY_TAX) revert ExceedsMaxPenalty();
        s_penaltyTax = penaltyTax;
        emit PenaltyTaxChanged(penaltyTax);
    }

    function setPenaltyAddress(address penaltyAddress) onlyOwner external {
        if (penaltyAddress == address(0)) revert NullAddress();
        s_penaltyAddress = penaltyAddress;
        emit PenaltyAddressChanged(penaltyAddress);
    }

    modifier onlyOwner {
        if (msg.sender != i_owner) {revert NotOwner();}
        _;
    }

    // Fallback function to receive Ether when msg.data is empty
    receive() external payable {
        // add incoming ETH rewards
        s_totalETHRewards += msg.value;
        emit IncomingETHRewards(msg.value);
    }

    // Fallback function to receive Ether when msg.data is NOT empty
    fallback() external payable {
        // add incoming ETH rewards
        s_totalETHRewards += msg.value;
        emit IncomingETHRewards(msg.value);
    }
}