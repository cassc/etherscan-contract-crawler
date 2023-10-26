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
import "../lib/interfaces/IGlobalPool.sol";
import "../lib/interfaces/IWithdrawalPool.sol";

contract GlobalPool_R46 is IGlobalPool, Lockable, Pausable {

    using SafeMath for uint256;
    using Math for uint256;

    /* change events */
    event AETHContractChanged(address prevValue, address newValue);
    event FETHContractChanged(address prevValue, address newValue);
    event ConfigContractChanged(address prevValue, address newValue);
    event StakingContractChanged(address prevValue, address newValue);
    event OperatorChanged(address prevValue, address newValue);
    event CrossChainBridgeChanged(address prevValue, address newValue);
    event DistributeGasLimitChanged(uint256 prevValue, uint256 newValue);
    event WithdrawalPoolChanged(address prevValue, address newValue);
    event TreasuryChanged(address prevValue, address newValue);
    event VaultAllowed(address vault);
    event VaultDisallowed(address vault);

    /* staker events */
    event StakePending(address indexed staker, uint256 amount);
    event StakeConfirmed(address indexed staker, uint256 amount);
    event StakeRemoved(address indexed staker, uint256 amount);
    event PendingUnstake(
        address indexed ownerAddress,
        address indexed receiverAddress,
        uint256 amount,
        bool isAETH
    );
    event RewardsDistributed(address[] claimers, uint256[] amounts);
    event RewardsClaimed(
        address indexed receiverAddress,
        address claimer,
        uint256 amount
    );

    event ManualClaimExpected(
        address indexed claimer,
        uint256 amount
    );

    /* deprecated staker events */
    event PendingUnstakeRemoved(address claimer, uint256 amount);

    /* pool events */
    event PoolOnGoing(bytes pool);
    event PoolCompleted(bytes pool);
    event PushedToVault(address vault, uint256 count);

    /* deprecated provider events */
    event ProviderSlashedAnkr(address indexed provider, uint256 ankrAmount, uint256 etherEquivalence);
    event ProviderToppedUpEth(address indexed provider, uint256 amount);
    event ProviderToppedUpAnkr(address indexed provider, uint256 amount);
    event ProviderExited(address indexed provider);
    event ProviderSlashedEth(address indexed provider, uint256 amount);
    event ProviderLockedEthReset(address provider, uint256 amount, uint256 legacy);

    /* rewards (AETH) */
    event RewardsRestaked(address indexed sender, uint256 amount);
    event RewardClaimed(address indexed staker, uint256 amount, bool isAETH);

    /// @dev deprecated variable
    mapping(address => uint256) private _pendingUserStakes; // deleted

    /// @dev total user stake
    mapping(address => uint256) private _userStakes;

    /* @dev deprecated variables */
    mapping(address => uint256) private _rewards; // deleted
    mapping(address => uint256) private _claims; // deleted
    mapping(address => uint256) private _etherBalances; // deleted
    mapping(address => uint256) private _slashings; // deleted
    mapping(address => uint256) private _exits;
    address[] private _pendingStakers; // deleted
    uint256 private _pendingAmount; // deleted
    uint256 private _totalStakes; // deleted
    uint256 private _totalRewards; // deleted

    /// @dev ankrETH contract
    IAETH private _aethContract;

    /* @dev deprecated variables */
    IStaking private _stakingContract;
    SystemParameters private _systemParameters;

    /// @dev ETH2 Staking contract
    address private _depositContract;

    /* @dev deprecated variables */
    address[] private _pendingTemp; // deleted
    uint256[50] private __gap; // deleted
    uint256 private _lastPendingStakerPointer; // deleted

    /// @dev Governance contract
    IConfig private _configContract;

    /// @dev deprecated variable
    mapping(address => uint256) private _pendingEtherBalances; // deleted

    /// @dev operator of contract
    address private _operator; // slot:322

    /* @dev deprecated variables */
    mapping(address => uint256[2]) private _fETHRewards; // deleted
    mapping(address => uint256) private _aETHRewards; // slot:324

    /// @dev aETHb contract
    IFETH private _fethContract;

    /* @dev deprecated variables */
    uint256 private _fethMintBase; // deleted
    address private _crossChainBridge; // slot:327
    mapping(address => uint256) private _aETHProviderRewards; // slot:328
    uint256 private _totalSlashedETH;

    /// @notice Ankr Treasury wallet
    address public treasury;

    // unstakes
    uint256 public _DISTRIBUTE_GAS_LIMIT;
    IWithdrawalPool internal _withdrawalPool;
    uint256 internal _pendingUnstakeGap;
    uint256 internal _pendingTotalUnstakes;
    address[] internal _pendingUnstakeClaimers;
    mapping(address => uint256) internal _pendingClaimerUnstakes;
    uint256[] internal _pendingUnstakeRequests;

    // reentrancy guard
    // @dev inverse @openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol
    bool private _entered;

    // manual claim
    uint256 internal _stashedForManualClaims;
    mapping(address => uint256) internal _manualClaims; // address => amount

    // Vaults
    mapping(address => bool) internal _allowedVaults; // address => bool

    // claimable shares (after stake)
    mapping(address => uint256) internal _claimableShares;

    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == _operator, "Operator: not allowed");
        _;
    }

    modifier notMarkedForManualClaim() virtual {
        require(
            _manualClaims[msg.sender] == 0,
            "GlobalPool: sender is marked for manual claim"
        );
        _;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _entered will be false
        require(!_entered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _entered = true;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _entered = false;
    }

    function initialize(IAETH aethContract, SystemParameters parameters, address depositContract) public initializer {
        __Ownable_init();

        _depositContract = depositContract;
        _aethContract = aethContract;
        _systemParameters = parameters;

        _paused["topUpETH"] = true;
        _paused["topUpANKR"] = true;
    }

    // @notice Push 32 ETH x count to allowed vault, where ETH going to Deposit Contract
    function pushToVault(address vault, uint256 count) external nonReentrant onlyOperator {
        require(_allowedVaults[vault], "GlobalPool: vault not allowed");
        require(count > 0, "GlobalPool: count is zero");
        uint256 amount = count.mul(32 ether);
        require(address(this).balance >= amount, "GlobalPool: pending ethers not enough");
        require(_unsafeTransfer(vault, amount, false), "GlobalPool: transfer failed");
        emit PushedToVault(vault, count);
    }

    function pushToBeacon(bytes calldata pubkey, bytes calldata withdrawal_credentials, bytes calldata signature, bytes32 deposit_data_root) public onlyOperator {
        require(address(this).balance >= 32 ether, "pending ethers not enough");
        IDepositContract(_depositContract).deposit{value : 32 ether}(pubkey, withdrawal_credentials, signature, deposit_data_root);
        emit PoolOnGoing(pubkey);
    }

    /*
     * @notice add an amount as stakeable reward of pull
     */
    function restake() external payable override {
        emit StakeConfirmed(msg.sender, msg.value);
    }

    /*
     * @notice same as stakeAndClaimAethC
     * @dev deprecated
     */
    function stake() external payable {
        stakeAndClaimAethC();
    }

    function stakeAndClaimAethC() public whenNotPaused("stake") nonReentrant payable {
        _stake(msg.sender, msg.value, LockStrategy.Claimable);
        claimAETH();
    }

    function stakeAndClaimAethB() external whenNotPaused("stake") nonReentrant payable {
        _stake(msg.sender, msg.value, LockStrategy.Claimable);
        claimFETH();
    }

    enum LockStrategy {
        Claimable, CrossChain, Provider
    }

    function _stake(address staker, uint256 value, LockStrategy lockStrategy) internal {
        require(value > 0, "Value must be greater than zero");
        // lets calc how many ethers every user staked
        _userStakes[staker] = _userStakes[staker].add(value);
        // calculate amount of shares to be minted to the user
        uint256 shares = _aethContract.bondsToShares(value);
        // mint rewards based on lock strategy
        if (lockStrategy == LockStrategy.Claimable) {
            // allow staker to claim aETH or fETH tokens
            _aethContract.mint(address(this), shares);
            _claimableShares[staker] = _claimableShares[staker].add(shares);
        } else if (lockStrategy == LockStrategy.CrossChain) {
            // lock rewards on cross chain bridge
            require(_crossChainBridge != address(0x00), "Cross chain bridge is not initialized");
            _aethContract.mint(address(_crossChainBridge), shares);
        } else {
            revert("Not supported lock strategy type");
        }
        // mint event that this stake is confirmed
        emit StakeConfirmed(staker, value);
    }

    function claimableAETHRewardOf(address staker) public view returns (uint256) {
        return _claimableShares[staker];
    }

    function claimableFETHRewardOf(address staker) public view returns (uint256) {
        return _aethContract.sharesToBonds(claimableAETHRewardOf(staker));
    }

    function claimableAETHFRewardOf(address staker) public view returns (uint256) {
        return claimableFETHRewardOf(staker);
    }

    function claimAETH() whenNotPaused("claim") public {
        address staker = msg.sender;
        uint256 claimableShares = claimableAETHRewardOf(staker);
        require(claimableShares > 0, "claimable reward zero");
        _claimableShares[staker] = 0;
        require(_aethContract.transfer(address(staker), claimableShares), "can't transfer shares");
        emit RewardClaimed(staker, claimableShares, true);
    }

    function claimFETH() whenNotPaused("claim") public {
        address staker = msg.sender;
        uint256 claimableShares = claimableAETHRewardOf(staker);
        require(claimableShares > 0, "claimable reward zero");
        _claimableShares[staker] = 0;
        uint256 allowance = _aethContract.allowance(address(this), address(_fethContract));
        if (allowance < claimableShares) {
            require(_aethContract.approve(address(_fethContract), 2 ** 256 - 1), "can't approve");
        }
        _fethContract.lockSharesFor(address(this), staker, claimableShares);
        emit RewardClaimed(staker, claimableShares, false);
    }

    function unstakeFETH(uint256 amount) external whenNotPaused("unstake") nonReentrant {
        uint256 shares = _fethContract.bondsToShares(amount);
        // swap fETH into aETH (it also burns fETH)
        _fethContract.unlockSharesFor(msg.sender, shares);
        _unstake(msg.sender, msg.sender, shares, amount, false);
    }

    function unstakeFETHFor(uint256 amount, address recipient) external whenNotPaused("unstake") nonReentrant {
        uint256 shares = _fethContract.bondsToShares(amount);
        // swap fETH into aETH (it also burns fETH)
        _fethContract.unlockSharesFor(msg.sender, shares);
        _unstake(msg.sender, recipient, shares, amount, false);
    }

    function unstakeAETH(uint256 shares) external whenNotPaused("unstake") nonReentrant {
        uint256 amount = _fethContract.sharesToBonds(shares);
        _unstake(msg.sender, msg.sender, shares, amount, true);
    }

    function unstakeAETHFor(uint256 shares, address recipient) external whenNotPaused("unstake") nonReentrant {
        uint256 amount = _fethContract.sharesToBonds(shares);
        _unstake(msg.sender, recipient, shares, amount, true);
    }

    /*
     * @param staker - address where we must burn aETH
     * @param recipient - future support for unstakeFor
     * @param shares - aETH to burn
     * @param amount - ETH amount to unstake
     */
    function _unstake(address staker, address recipient, uint256 shares, uint256 amount, bool isAETH) internal {
        require(amount >= _configContract.getConfig("UNSTAKE_MIN_AMOUNT"), "Value must be not less than minimum amount");
        // no need to check balance, because ERC20UpgradeSafe is checking it before burn
        _aethContract.burn(staker, shares);
        _addIntoQueue(staker, recipient, amount);
        emit PendingUnstake(staker, recipient, amount, isAETH);
    }

    /*
     * @dev queue is released by distributeRewards()
     */
    function _addIntoQueue(address staker, address recipient, uint256 amount) internal {
        require(
            amount != 0 && recipient != address(0),
            "GlobalPool: zero input values"
        );
        _pendingTotalUnstakes = _pendingTotalUnstakes.add(amount);
        _pendingUnstakeClaimers.push(recipient);
        _pendingUnstakeRequests.push(amount);

        _pendingClaimerUnstakes[recipient] = _pendingClaimerUnstakes[recipient].add(amount);
    }

    function getUnstakeRequestsOf(
        address claimer
    ) external view returns (uint256[] memory) {
        uint256 j;
        uint256 gap = _pendingUnstakeGap;

        uint256[] memory unstakes = new uint256[](
            _pendingUnstakeClaimers.length - gap
        );
        for (; gap < _pendingUnstakeClaimers.length; gap++) {
            if (_pendingUnstakeClaimers[gap] == claimer) {
                unstakes[j] = _pendingUnstakeRequests[gap];
                ++j;
            }
        }
        uint256 removeCells = unstakes.length - j;
        if (removeCells > 0) {
            assembly {
                mstore(unstakes, j)
            }
        }
        return unstakes;
    }

    function getPendingUnstakesOf(
        address claimer
    ) public view returns (uint256) {
        return _pendingClaimerUnstakes[claimer];
    }

    function getTotalPendingUnstakes() public view returns (uint256) {
        return _pendingTotalUnstakes;
    }

    /*
     * @notice take fee from rewards, pay unstakes, restake the rest of rewards
     * @dev control fee from backend
     * @param fee - ANKR's fee that should be deducted from rewards
     */
    function distributeRewards(uint256 feeAmount) external nonReentrant onlyOperator {
        require(
            _DISTRIBUTE_GAS_LIMIT > 0,
            "GlobalPool: DISTRIBUTE_GAS_LIMIT is not set"
        );
        _withdrawalPool.claim();
        uint256 poolBalance = address(this).balance.sub(_stashedForManualClaims);
        // withdraw ANKR fee to treasury
        require(poolBalance >= feeAmount, "GlobalPool: not enough ETH to withdraw fee");
        poolBalance = poolBalance.sub(feeAmount);
        require(_unsafeTransfer(treasury, feeAmount, false), "GlobalPool: failed to send fee");

        address[] memory claimers = new address[](
            _pendingUnstakeClaimers.length - _pendingUnstakeGap
        );
        uint256[] memory amounts = new uint256[](
            _pendingUnstakeClaimers.length - _pendingUnstakeGap
        );
        uint256 j = 0;
        uint256 i = _pendingUnstakeGap;

        while (
            i < _pendingUnstakeClaimers.length &&
            poolBalance > 0 &&
            gasleft() > _DISTRIBUTE_GAS_LIMIT
        ) {
            address claimer = _pendingUnstakeClaimers[i];
            uint256 toDistribute = _pendingUnstakeRequests[i];
            // empty unstake
            if (claimer == address(0) || toDistribute == 0) {
                i++;
                continue;
            }

            if (poolBalance < toDistribute) {
                break;
            }

            _pendingClaimerUnstakes[claimer] = _pendingClaimerUnstakes[claimer].sub(toDistribute);
            _pendingTotalUnstakes = _pendingTotalUnstakes.sub(toDistribute);
            poolBalance = poolBalance.sub(toDistribute);
            delete _pendingUnstakeClaimers[i];
            delete _pendingUnstakeRequests[i];
            i++;

            if (isMarkedForManualClaim(claimer)) {
                _setForManualClaim(claimer, toDistribute);
                continue;
            }

            bool success = _unsafeTransfer(claimer, toDistribute, true);
            if (!success) {
                _setForManualClaim(claimer, toDistribute);
                continue;
            }

            claimers[j] = claimer;
            amounts[j] = toDistribute;
            j++;
        }
        _pendingUnstakeGap = i;
        /* decrease arrays */
        uint256 removeCells = claimers.length - j;
        if (removeCells > 0) {
            assembly {
                mstore(claimers, j)
            }
            assembly {
                mstore(amounts, j)
            }
        }
        emit RewardsDistributed(claimers, amounts);
    }

    function _setForManualClaim(
        address claimer,
        uint256 amount
    ) internal {
        _stashedForManualClaims = _stashedForManualClaims.add(amount);
        _manualClaims[claimer] = _manualClaims[claimer].add(amount);

        emit ManualClaimExpected(claimer, amount);
    }

    function claimManually(address receiverAddress) external nonReentrant {
        require(
            receiverAddress != address(0),
            "GlobalPool: zero address"
        );
        uint256 amount = _manualClaims[receiverAddress];
        require(
            amount > 0,
            "GlobalPool: not marked for manual claim"
        );
        require(_stashedForManualClaims <= address(this).balance, "GlobalPool: not enough balance");
        _stashedForManualClaims = _stashedForManualClaims.sub(amount);
        delete _manualClaims[receiverAddress];

        require(
            _unsafeTransfer(receiverAddress, amount, false),
            "GlobalPool: failed to send rewards"
        );
        emit RewardsClaimed(receiverAddress, msg.sender, amount);
    }

    function isMarkedForManualClaim(address claimer)
    public
    view
    returns (bool)
    {
        return _manualClaims[claimer] != uint256(0);
    }

    function getForManualClaimOf(address claimer)
    public
    view
    returns (uint256)
    {
        return _manualClaims[claimer];
    }

    function getStashedForManualClaims() public view returns (uint256) {
        return _stashedForManualClaims;
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

    function changeOperator(address operator) public onlyOwner {
        address prevValue = _operator;
        _operator = operator;
        emit OperatorChanged(prevValue, operator);
    }

    function updateDistributeGasLimit(uint256 newValue) external onlyOwner {
        require(newValue > 0, "GlobalPool: cannot be zero");
        emit DistributeGasLimitChanged(_DISTRIBUTE_GAS_LIMIT, newValue);
        _DISTRIBUTE_GAS_LIMIT = newValue;
    }

    function updateWithdrawalPool(address newValue) external onlyOwner {
        require(newValue != address(0), "GlobalPool: zero address");
        emit WithdrawalPoolChanged(address(_withdrawalPool), newValue);
        _withdrawalPool = IWithdrawalPool(newValue);
    }

    function updateTreasury(address newValue) external onlyOwner {
        require(newValue != address(0), "GlobalPool: zero address");
        emit TreasuryChanged(address(treasury), newValue);
        treasury = newValue;
    }

    function allowVault(address vault) external onlyOwner {
        require(vault != address(0), "GlobalPool: zero address");
        require(!_allowedVaults[vault], "GlobalPool: already allowed");
        _allowedVaults[vault] = true;
        emit VaultAllowed(vault);
    }

    function disallowVault(address vault) external onlyOwner {
        require(vault != address(0), "GlobalPool: zero address");
        require(_allowedVaults[vault], "GlobalPool: not allowed");
        _allowedVaults[vault] = false;
        emit VaultDisallowed(vault);
    }

    event ClaimableSharesUpdated(address[] accounts, uint256[] amounts);

    function updateClaimableShares(address[] calldata accounts, uint256[] calldata amounts) external onlyOwner {
        require(accounts.length == amounts.length, "GlobalPool: wrong length");
        for (uint i; i < accounts.length; i++) {
            _claimableShares[accounts[i]] = amounts[i];
        }
        emit ClaimableSharesUpdated(accounts, amounts);
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

    function _unsafeTransfer (
        address receiverAddress,
        uint256 amount,
        bool limit
    ) internal virtual returns (bool) {
        address payable wallet = payable(receiverAddress);
        bool success;
        if (limit) {
            assembly {
                success := call(10000, wallet, amount, 0, 0, 0, 0)
            }
            return success;
        }
        (success, ) = wallet.call{value: amount}("");
        return success;
    }

    receive() external payable virtual {
        require(msg.sender == address(_withdrawalPool), "sender not allowed");
    }
}