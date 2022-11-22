// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "../lib/interfaces/IDepositContract.sol";
import "../SystemParameters.sol";
import "../lib/Lockable.sol";
import "../lib/interfaces/IAETH.sol";
import "../lib/interfaces/IFETH.sol";
import "../lib/interfaces/IConfig.sol";
import "../lib/interfaces/IStaking.sol";
import "../lib/interfaces/IDepositContract.sol";
import "../lib/Pausable.sol";

contract GlobalPool_R39 is Lockable, Pausable {

    using SafeMath for uint256;
    using Math for uint256;

    /* change events */
    event AETHContractChanged(address prevValue, address newValue);
    event FETHContractChanged(address prevValue, address newValue);
    event ConfigContractChanged(address prevValue, address newValue);
    event StakingContractChanged(address prevValue, address newValue);
    event OperatorChanged(address prevValue, address newValue);
    event CrossChainBridgeChanged(address prevValue, address newValue);

    /* staker events */
    event StakePending(address indexed staker, uint256 amount);
    event StakeConfirmed(address indexed staker, uint256 amount);
    event StakeRemoved(address indexed staker, uint256 amount);

    /* pool events */
    event PoolOnGoing(bytes pool);
    event PoolCompleted(bytes pool);

    /* provider events */
    event ProviderSlashedAnkr(address indexed provider, uint256 ankrAmount, uint256 etherEquivalence);
    event ProviderSlashedEth(address indexed provider, uint256 amount);
    event ProviderToppedUpEth(address indexed provider, uint256 amount);
    event ProviderToppedUpAnkr(address indexed provider, uint256 amount);
    event ProviderExited(address indexed provider);

    /* rewards (AETH) */
    event RewardClaimed(address indexed staker, uint256 amount, bool isAETH);

    // deleted fields
    mapping(address => uint256) private _pendingUserStakes; // deleted

    mapping(address => uint256) private _userStakes;
    mapping(address => uint256) private _rewards;
    mapping(address => uint256) private _claims;

    // deleted fields
    mapping(address => uint256) private _etherBalances; // deleted
    mapping(address => uint256) private _slashings; // deleted

    mapping(address => uint256) private _exits;

    // deleted fields
    address[] private _pendingStakers; // deleted
    uint256 private _pendingAmount; // deleted
    uint256 private _totalStakes; // deleted
    uint256 private _totalRewards; // deleted

    IAETH private _aethContract;
    IStaking private _stakingContract;
    SystemParameters private _systemParameters;
    address private _depositContract;

    // deleted fields
    address[] private _pendingTemp; // deleted
    uint256[50] private __gap; // deleted
    uint256 private _lastPendingStakerPointer; // deleted

    IConfig private _configContract;

    // deleted fields
    mapping(address => uint256) private _pendingEtherBalances; // deleted

    address private _operator; // slot:322

    // deleted fields
    mapping(address => uint256[2]) private _fETHRewards; // deleted

    mapping(address => uint256) private _aETHRewards;
    IFETH private _fethContract;

    // deleted fields
    uint256 private _fethMintBase; // deleted

    /**
     * @dev deprecated variable with old cross-chain bridge
     */
    address private _crossChainBridge; // slot:327
    mapping(address => uint256) private _aETHProviderRewards; // slot:323
    uint256 private _totalSlashedETH;

    modifier notExitRecently(address provider) {
        require(block.number > _exits[provider].add(_configContract.getConfig("EXIT_BLOCKS")), "Recently exited");
        delete _exits[msg.sender];
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == _operator, "Operator: not allowed");
        _;
    }

    function initialize(IAETH aethContract, SystemParameters parameters, address depositContract) public initializer {
        __Ownable_init();

        _depositContract = depositContract;
        _aethContract = aethContract;
        _systemParameters = parameters;

        _paused["topUpETH"] = true;
        _paused["topUpANKR"] = true;
    }

    function pushToBeacon(bytes calldata pubkey, bytes calldata withdrawal_credentials, bytes calldata signature, bytes32 deposit_data_root) public onlyOperator {
        require(address(this).balance >= 32 ether, "pending ethers not enough");
        IDepositContract(_depositContract).deposit{value : 32 ether}(pubkey, withdrawal_credentials, signature, deposit_data_root);
        emit PoolOnGoing(pubkey);
    }

    function stake() public whenNotPaused("stake") unlocked(msg.sender) payable {
        _stake(msg.sender, msg.value, LockStrategy.Claimable);
    }

    function stakeAndClaimAethC() public whenNotPaused("stake") unlocked(msg.sender) payable {
        _stake(msg.sender, msg.value, LockStrategy.Claimable);
        claimAETH();
    }

    function stakeAndClaimAethB() public whenNotPaused("stake") unlocked(msg.sender) payable {
        _stake(msg.sender, msg.value, LockStrategy.Claimable);
        claimFETH();
    }

    // This function don't have to be protected because there is no reason for someone
    // to call it manually. In this case "attacker" can just delegate his stake to someone else
    // and lock his funds on cross chain contract that doesn't make sense. But on the other
    // hand it brings tiny gas optimization to our backend.
    function crossChainStake(address[] memory addresses, uint256[] memory amounts) public payable {
        require(addresses.length == amounts.length, "Addresses and amounts length must be equal");
        uint256 totalSent = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalSent = totalSent.add(amounts[i]);
            _stake(addresses[i], amounts[i], LockStrategy.CrossChain);
        }
        require(msg.value == totalSent, "Total value must be same with sent");
    }

    enum LockStrategy {
        Claimable, CrossChain, Provider
    }

    function _stake(address staker, uint256 value, LockStrategy lockStrategy) internal {
        // check minimum staking amount (don't allow remainders also)
        uint256 minimumStaking = _configContract.getConfig("REQUESTER_MINIMUM_POOL_STAKING");
        require(value >= minimumStaking, "Value must be greater than zero");
        require(value % minimumStaking == 0, "Value must be multiple of minimum staking amount");
        // lets calc how many ethers every user staked
        _userStakes[staker] = _userStakes[staker].add(value);
        // calculate amount of shares to be minted to the user
        uint256 shares = value.mul(_aethContract.ratio()).div(1e18);
        // mint rewards based on lock strategy
        if (lockStrategy == LockStrategy.Claimable) {
            // allow staker to claim aETH or fETH tokens
            _aethContract.mint(address(this), shares);
            _aETHRewards[staker] = _aETHRewards[staker].add(shares);
        } else if (lockStrategy == LockStrategy.CrossChain) {
            // lock rewards on cross chain bridge
            require(_crossChainBridge != address(0x00), "Cross chain bridge is not initialized");
            _aethContract.mint(address(_crossChainBridge), shares);
        } else if (lockStrategy == LockStrategy.Provider) {
            // lock rewards because staker is provider
            _aethContract.mint(address(this), shares);
            _aETHProviderRewards[staker] = _aETHProviderRewards[staker].add(shares);
        } else {
            revert("Not supported lock strategy type");
        }
        // mint event that this stake is confirmed
        emit StakeConfirmed(staker, value);
    }

    function claimableAETHRewardOf(address staker) public view returns (uint256) {
        // this is super legacy and super strange reward calculation scheme, lets keep it here
        uint256 blocked = _etherBalances[staker].add(_aETHProviderRewards[staker]);
        uint256 legacyRewards = _rewards[staker].sub(_claims[staker]);
        if (blocked >= legacyRewards) {
            legacyRewards = 0;
        } else {
            legacyRewards = legacyRewards.sub(blocked);
        }
        // return claimable aETH rewards for token
        return _aETHRewards[staker].add(legacyRewards);
    }

    function claimableFETHRewardOf(address staker) public view returns (uint256) {
        return claimableAETHRewardOf(staker).mul(1e18).div(_aethContract.ratio());
    }

    function claimableAETHFRewardOf(address staker) public view returns (uint256) {
        return claimableFETHRewardOf(staker);
    }

    function claimAETH() /*whenNotPaused("claim")*/ notExitRecently(msg.sender) public {
        address staker = msg.sender;
        uint256 claimableShares = claimableAETHRewardOf(staker);
        require(claimableShares > 0, "claimable reward zero");
        _aETHRewards[staker] = 0;
        uint256 oldReward = _rewards[staker].sub(_claims[staker]);
        if (oldReward > 0) {
            _claims[staker] = _claims[staker].add(oldReward);
        }
        require(_aethContract.transfer(address(staker), claimableShares), "can't transfer shares");
        emit RewardClaimed(staker, claimableShares, true);
    }

    function claimFETH() whenNotPaused("claim") notExitRecently(msg.sender) public {
        address staker = msg.sender;
        uint256 claimableShares = claimableAETHRewardOf(staker);
        require(claimableShares > 0, "claimable reward zero");
        _aETHRewards[staker] = 0;
        uint256 oldReward = _rewards[staker].sub(_claims[staker]);
        if (oldReward > 0) {
            _claims[staker] = _claims[staker].add(oldReward);
        }
        uint256 allowance = _aethContract.allowance(address(this), address(_fethContract));
        if (allowance < claimableShares) {
            require(_aethContract.approve(address(_fethContract), 2 ** 256 - 1), "can't approve");
        }
        _fethContract.lockSharesFor(address(this), staker, claimableShares);
        emit RewardClaimed(staker, claimableShares, false);
    }

    function availableEtherBalanceOf(address provider) public view returns (uint256) {
        return _aETHProviderRewards[provider];
    }

    function etherBalanceOf(address provider) public view returns (uint256) {
        return _etherBalances[provider];
    }

    function slashingsOf(address provider) public view returns (uint256) {
        return 0;
    }

    function topUpETH() public whenNotPaused("topUpETH") payable {
        require(_configContract.getConfig("PROVIDER_MINIMUM_ETH_STAKING") <= msg.value, "Value must be greater than minimum amount");
        _stake(msg.sender, msg.value, LockStrategy.Provider);
        emit ProviderToppedUpEth(msg.sender, msg.value);
    }

    function topUpANKR(uint256 amount) public whenNotPaused("topUpANKR") {
        require(_configContract.getConfig("PROVIDER_MINIMUM_ANKR_STAKING") <= amount, "Value must be greater than minimum amount");
        require(_stakingContract.freeze(msg.sender, amount), "Not enough allowance or balance");
        emit ProviderToppedUpAnkr(msg.sender, amount);
    }

    function forceAdminProviderExit(address[] calldata providers) public onlyOperator {
        for (uint256 i = 0; i < providers.length; i++) {
            _forceProviderExitFor(providers[i]);
        }
    }

    event ProviderLockedEthReset(address provider, uint256 amount, uint256 legacy);

    function resetLockedEthForProviders(address[] calldata providers) external onlyOperator {
        for (uint256 i = 0; i < providers.length; i++) {
            address provider = providers[i];
            uint256 legacyBalance = _etherBalances[provider];
            uint256 newBalance = _aETHProviderRewards[provider];
            _etherBalances[provider] = 0;
            _aETHProviderRewards[provider] = 0;
            emit ProviderLockedEthReset(provider, newBalance, legacyBalance);
        }
    }

    function _forceProviderExitFor(address provider) internal {
        uint256 claimableRewards = _aETHProviderRewards[provider];
        if (claimableRewards > 0) {
            _aETHProviderRewards[provider] = _aETHProviderRewards[provider].sub(claimableRewards);
            _aETHRewards[provider] = _aETHRewards[provider].add(claimableRewards);
        }
        uint256 frozenDeposits = _stakingContract.frozenDepositsOf(provider);
        uint256 lockedDeposits = _stakingContract.lockedDepositsOf(provider);
        uint256 ankrDepositBalance = frozenDeposits.sub(lockedDeposits);
        if (ankrDepositBalance > 0) {
            require(_stakingContract.unfreeze(provider, ankrDepositBalance), "Failed to unfreeze");
        }
        emit ProviderExited(provider);
    }

    function softLockBlockNumber(address provider) public view returns (uint256) {
        uint256 exitedAt = _exits[provider];
        if (exitedAt == 0) {
            return 0;
        }
        uint256 waitFor = _configContract.getConfig("EXIT_BLOCKS");
        return exitedAt.add(waitFor);
    }

    /**
        @dev Slash eth, returns remaining needs to be slashed
    */
    function slashETH(address provider, uint256 amount) public onlyOperator {
        require(amount <= _aETHProviderRewards[provider], "Not enough rewards for slashing");
        // deduct slashed amount from provider
        _aETHProviderRewards[provider] = _aETHProviderRewards[provider].sub(amount);
        _totalSlashedETH = _totalSlashedETH.add(amount);
        // emit event indicating provider slash
        emit ProviderSlashedEth(provider, amount);
    }

    function totalSlashedETH() public view returns (uint256) {
        return _totalSlashedETH;
    }

    function updateAETHContract(address payable aEthContract) external onlyOwner {
        address prevValue = address(_aethContract);
        _aethContract = IAETH(aEthContract);
        emit AETHContractChanged(prevValue, aEthContract);
    }

    function updateFETHContract(address payable fEthContract) external onlyOwner {
        address prevValue = address(_fethContract);
        _fethContract = IFETH(fEthContract);
        emit FETHContractChanged(prevValue, fEthContract);
    }

    function updateConfigContract(address configContract) external onlyOwner {
        address prevValue = address(_configContract);
        _configContract = IConfig(configContract);
        emit ConfigContractChanged(prevValue, configContract);
    }

    function updateStakingContract(address stakingContract) external onlyOwner {
        address prevValue = address(_stakingContract);
        _stakingContract = IStaking(stakingContract);
        emit StakingContractChanged(prevValue, stakingContract);
    }

    function changeOperator(address operator) public onlyOwner {
        address prevValue = _operator;
        _operator = operator;
        emit OperatorChanged(prevValue, operator);
    }

    function depositContractAddress() public view returns (address) {
        return _depositContract;
    }

    /**
     * @dev deprecated
     */
    function crossChainBridge() public view returns (address) {
        return _crossChainBridge;
    }
}