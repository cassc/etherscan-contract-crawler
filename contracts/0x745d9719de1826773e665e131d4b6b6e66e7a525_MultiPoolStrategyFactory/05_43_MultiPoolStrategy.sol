pragma solidity ^0.8.10;

import { Initializable } from "openzeppelin-contracts/proxy/utils/Initializable.sol";
import { ERC4626Upgradeable } from "openzeppelin-contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import { IERC20Upgradeable } from "openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { OwnableUpgradeable } from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IAdapter } from "./interfaces/IAdapter.sol";
import { IERC20UpgradeableDetailed } from "./interfaces/IERC20UpgradeableDetailed.sol";
import { ERC4626UpgradeableModified } from "./ERC4626UpgradeableModified.sol";
import "solmate/utils/SafeCastLib.sol";
// TODO - implement donation attack protection

contract MultiPoolStrategy is OwnableUpgradeable, ERC4626UpgradeableModified {
    using SafeCastLib for *;

    /// @notice addresses of the adapters
    address[] public adapters;
    /// @notice Mapping for the whitelisted adapters
    mapping(address => bool) public isAdapter;
    /// @notice Address of the offchain monitor
    address public monitor;
    /// @notice Interval for adjusting in
    uint256 public adjustInInterval;
    /// @notice Interval for adjusting out
    uint256 public adjustOutInterval;
    /// @notice timestamp of the last adjust in
    uint256 public lastAdjustIn;
    /// @notice timestamp of the last adjust out
    uint256 public lastAdjustOut;
    /// @notice Minimum percentage of assets that must be in this contract
    uint256 public minPercentage; // 10000 = 100%
    /// @notice Percentage of the fee
    uint256 public feePercentage; // 10000 = 100%
    /// @notice Address of the fee recipient
    address public feeRecipient;
    /// @notice Flag for pausing the contract
    bool public paused;
    /// @notice the maximum length of a rewards cycle
    uint32 public rewardsCycleLength;
    /// @notice the effective start of the current cycle
    uint32 public lastSync;
    /// @notice the end of the current cycle. Will always be evenly divisible by `rewardsCycleLength`.
    uint32 public rewardsCycleEnd;
    /// @notice the amount of rewards distributed in a the most recent cycle.
    uint192 public lastRewardAmount;

    uint256 public storedTotalAssets;

    /// @notice Address of the LIFI diamond
    address public constant LIFI_DIAMOND = 0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE;

    //// ERRORS
    error Unauthorized();
    error AdjustmentWrong();
    error SwapFailed();
    error AdapterIsNotEmpty();
    error WithdrawTooLow();
    error AdapterNotHealthy();
    error StrategyPaused();
    error AdapterAlreadyAdded();
    /// @dev thrown when syncing before cycle ends.
    error SyncError();

    ///STRUCTS
    struct Adjust {
        address adapter;
        uint256 amount;
        uint256 minReceive;
    }

    struct SwapData {
        address token;
        uint256 amount;
        bytes callData;
    }

    /// EVENTS

    event HardWork(uint256 totalClaimed, uint256 fee);
    /// @dev emit every time a new rewards cycle starts
    event NewRewardsCycle(uint32 indexed cycleEnd, uint256 rewardAmount);

    /// @dev The contract automatically disables initializers when deployed so that nobody can highjack the
    /// implementation contract.
    constructor() {
        _disableInitializers();
    }

    /**
     *
     * @param _stakingToken address of the underlying token
     * @param _monitor  address of the monitor
     */
    function initalize(address _stakingToken, address _monitor) public initializer {
        __Ownable_init_unchained();
        __ERC20_init_unchained(
            string(abi.encodePacked(IERC20UpgradeableDetailed(_stakingToken).name(), " MultiPoolStrategy")),
            string(abi.encodePacked("mp", IERC20UpgradeableDetailed(_stakingToken).symbol()))
        );
        __ERC4626_init(IERC20Upgradeable(_stakingToken));
        monitor = _monitor;
        adjustInInterval = 6 hours;
        adjustOutInterval = 6 hours;
        minPercentage = 500; // 5%
        rewardsCycleLength = 7 days;
        feePercentage = 1500; // 15%
    }
    /// OVERRIDEN FUNCTIONS

    /**
     * @notice Fetch all the underlying balances including this contract
     */

    function totalAssets() public view override returns (uint256) {
        // cache global vars
        uint256 storedTotalAssets_ = storedTotalAssets;
        uint192 lastRewardAmount_ = lastRewardAmount;
        uint32 rewardsCycleEnd_ = rewardsCycleEnd;
        uint32 lastSync_ = lastSync;
        uint256 total = 0;
        for (uint256 i = 0; i < adapters.length; i++) {
            total += IAdapter(adapters[i]).underlyingBalance();
        }
        if (block.timestamp >= rewardsCycleEnd_) {
            // no rewards or rewards fully unlocked
            // entire reward amount is available
            return storedTotalAssets_ + lastRewardAmount_ + total;
        }

        // rewards not fully unlocked
        // add unlocked rewards to stored total
        uint256 unlockedRewards = (lastRewardAmount_ * (block.timestamp - lastSync_)) / (rewardsCycleEnd_ - lastSync_);
        return storedTotalAssets_ + unlockedRewards + total;
    }

    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        if (paused) revert StrategyPaused();
        address[] memory _adapters = adapters; // SSTORE
        for (uint256 i = 0; i < _adapters.length; i++) {
            bool isHealthy = IAdapter(_adapters[i]).isHealthy();
            if (!isHealthy) revert AdapterNotHealthy();
        }
        shares = super.deposit(assets, receiver);
        storedTotalAssets += assets;
        return shares;
    }

    /**
     * @dev See {IERC4626-withdraw}.
     */

    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256 minimumReceive
    )
        public
        override
        returns (uint256)
    {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);

        uint256 currBal = IERC20Upgradeable(asset()).balanceOf(address(this));

        // in the contract
        if (assets > currBal) {
            assets = _withdrawFromAdapter(assets, currBal, minimumReceive);
        } else {
            storedTotalAssets -= assets;
        }
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        uint256 minimumReceive
    )
        public
        override
        returns (uint256)
    {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);
        uint256 currBal = IERC20Upgradeable(asset()).balanceOf(address(this));
        if (assets > currBal) {
            assets = _withdrawFromAdapter(assets, currBal, minimumReceive);
        } else {
            storedTotalAssets -= assets;
        }
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Withdraws tokens from the adapter in the case of assets amount being greater than the current balance.
     * @param assets amount of assets to withdraw
     * @param currBal current balance of the contract
     * @param minimumReceive minimum amount of assets to receive
     */
    function _withdrawFromAdapter(uint256 assets, uint256 currBal, uint256 minimumReceive) internal returns (uint256) {
        address[] memory _adapters = adapters; // SSTORE

        Adjust[] memory _adjustOuts = new Adjust[](adapters.length); //init with worst case scenario
        uint256 _assets = assets - currBal;
        uint256 adaptersLength = adapters.length;
        for (uint256 i = adaptersLength; i > 0;) {
            uint256 _adapterAssets = IAdapter(_adapters[i - 1]).underlyingBalance();
            if (_adapterAssets > 0) {
                uint256 lpBal = IAdapter(_adapters[i - 1]).lpBalance(); // check the lpbalance of the adapter
                uint256 _amount = _assets > _adapterAssets ? _adapterAssets : _assets; // check if the underlying asset
                    // amount in adapter is greater than the assets to be withdrawn
                uint256 _lpAmount = (_amount * 10 ** decimals() / _adapterAssets) * lpBal / (10 ** decimals()); // calculate
                    // the lp amount to be withdrawn based on asset amount
                _adjustOuts[i - 1] = Adjust({ adapter: _adapters[i - 1], amount: _lpAmount, minReceive: 0 });
                _assets -= _amount;
                if (_assets == 0) break;
            }
            unchecked {
                --i;
            }
        }
        for (uint256 i = _adjustOuts.length; i > 0;) {
            if (_adjustOuts[i - 1].adapter != address(0)) {
                IAdapter(_adjustOuts[i - 1].adapter).withdraw(_adjustOuts[i - 1].amount, _adjustOuts[i - 1].minReceive);
            } else {
                break;
            }
            unchecked {
                --i;
            }
        }
        assets = IERC20Upgradeable(asset()).balanceOf(address(this));
        if (assets < minimumReceive) revert WithdrawTooLow();
        storedTotalAssets = 0; // withdraw all assets from this contract

        return assets;
    }

    /// ADMIN FUNCTIONS
    /**
     * @notice Adjust the underlying assets either out from adapters or in to adapters.Total adjust out amount must be
     * smaller/equal to storedTotalAssets - (storedTotalAssets * minPercentage / 10000)
     * @param _adjustIns List of AdjustIn structs
     * @param _adjustOuts List of AdjustOut structs
     * @param _sortedAdapters List of adapters sorted by lowest tvl to highest tvl
     */
    function adjust(
        Adjust[] calldata _adjustIns,
        Adjust[] calldata _adjustOuts,
        address[] calldata _sortedAdapters
    )
        external
    {
        if ((_msgSender() != monitor && paused) || (_msgSender() != owner() && !paused)) revert Unauthorized();
        uint256 adjustOutLength = _adjustOuts.length;

        if (adjustOutLength > 0 && block.timestamp - lastAdjustOut > adjustOutInterval) {
            uint256 balBefore = IERC20Upgradeable(asset()).balanceOf(address(this));
            for (uint256 i = 0; i < adjustOutLength; i++) {
                IAdapter(_adjustOuts[i].adapter).withdraw(_adjustOuts[i].amount, _adjustOuts[i].minReceive);
            }
            uint256 balAfter = IERC20Upgradeable(asset()).balanceOf(address(this));
            storedTotalAssets += (balAfter - balBefore); // add the assets back to the contract
            lastAdjustOut = block.timestamp;
        }
        uint256 adjustInLength = _adjustIns.length;
        if (adjustInLength > 0 && block.timestamp - lastAdjustIn > adjustInInterval) {
            uint256 totalOut;
            for (uint256 i = 0; i < adjustInLength; i++) {
                if (!isAdapter[_adjustIns[i].adapter]) revert Unauthorized();
                IERC20Upgradeable(asset()).transfer(_adjustIns[i].adapter, _adjustIns[i].amount);
                IAdapter(_adjustIns[i].adapter).deposit(_adjustIns[i].amount, _adjustIns[i].minReceive);
                totalOut += _adjustIns[i].amount;
            }

            storedTotalAssets -= totalOut; // remove the assets from the contract
            lastAdjustIn = block.timestamp;
        }

        uint256 _totalAssets = totalAssets();
        if (storedTotalAssets < _totalAssets * minPercentage / 10_000) {
            revert AdjustmentWrong();
        }
        if (_sortedAdapters.length > 0) adapters = _sortedAdapters;
    }

    /**
     * @notice Claim rewards from the adapters and swap them for the underlying asset. Only callable once per reward
     * cycle. Can be callable by monitor or owner.
     * @param _adaptersToClaim List of adapters to claim from
     * @param _swapDatas List of SwapData structs
     */
    function doHardWork(address[] calldata _adaptersToClaim, SwapData[] calldata _swapDatas) external {
        if (_msgSender() != monitor || _msgSender() != owner()) revert Unauthorized();
        for (uint256 i = 0; i < _adaptersToClaim.length; i++) {
            IAdapter(_adaptersToClaim[i]).claim();
        }
        uint256 underlyingBalanceBefore = IERC20Upgradeable(asset()).balanceOf(address(this));
        for (uint256 i = 0; i < _swapDatas.length; i++) {
            IERC20Upgradeable(_swapDatas[i].token).approve(LIFI_DIAMOND, 0);
            IERC20Upgradeable(_swapDatas[i].token).approve(LIFI_DIAMOND, _swapDatas[i].amount);
            (bool success,) = LIFI_DIAMOND.call(_swapDatas[i].callData);
            if (!success) revert SwapFailed();
            unchecked {
                ++i;
            }
        }
        uint256 underlyingBalanceAfter = IERC20Upgradeable(asset()).balanceOf(address(this));
        uint256 totalClaimed = underlyingBalanceAfter - underlyingBalanceBefore;

        uint256 fee;
        if (totalClaimed > 0) {
            fee = totalClaimed * feePercentage / 10_000;
            if (fee > 0) {
                IERC20Upgradeable(asset()).transfer(feeRecipient, fee);
            }
        }
        uint256 rewardAmount = totalClaimed - fee;
        _syncRewards(rewardAmount);
        emit HardWork(totalClaimed, fee);
    }

    /// @notice Distributes rewards to xERC4626 holders.
    /// All surplus `asset` balance of the contract over the internal balance becomes queued for the next cycle.
    function _syncRewards(uint256 nextRewards) internal {
        uint192 lastRewardAmount_ = lastRewardAmount;
        uint32 timestamp = block.timestamp.safeCastTo32();

        if (timestamp < rewardsCycleEnd) revert SyncError();

        uint256 storedTotalAssets_ = storedTotalAssets;

        storedTotalAssets = storedTotalAssets_ + lastRewardAmount_; // SSTORE

        uint32 end = ((timestamp + rewardsCycleLength) / rewardsCycleLength) * rewardsCycleLength;

        if (end - timestamp < rewardsCycleLength / 20) {
            end += rewardsCycleLength;
        }

        // Combined single SSTORE
        lastRewardAmount = nextRewards.safeCastTo192();
        lastSync = timestamp;
        rewardsCycleEnd = end;

        emit NewRewardsCycle(end, nextRewards);
    }

    /**
     * @notice Add an adapter to the list of adapters
     * @param _adapter Address of the adapter to add
     */
    function addAdapter(address _adapter) external onlyOwner {
        if (isAdapter[_adapter]) revert AdapterAlreadyAdded();
        isAdapter[_adapter] = true;
        adapters.push(_adapter);
    }

    /**
     * @notice Add multiple adapters to the list of adapters
     * @param _adapters Addresses of the adapters to add
     */
    function addAdapters(address[] calldata _adapters) external onlyOwner {
        for (uint256 i = 0; i < _adapters.length; i++) {
            if (isAdapter[_adapters[i]]) revert AdapterAlreadyAdded();
            isAdapter[_adapters[i]] = true;
            adapters.push(_adapters[i]);
        }
    }

    /**
     * @notice Remove an adapter from the list of adapters
     * @param _adapter Address of the adapter to remove
     */
    function removeAdapter(address _adapter) external onlyOwner {
        if (IAdapter(_adapter).underlyingBalance() > 0) revert AdapterIsNotEmpty();
        isAdapter[_adapter] = false;
        for (uint256 i = 0; i < adapters.length; i++) {
            if (adapters[i] == _adapter) {
                adapters[i] = adapters[adapters.length - 1];
                adapters.pop();
                break;
            }
        }
    }

    /**
     * @notice Set the minimum percentage of assets that will be in this contract as idle for cheaper withdrawals
     * @param _minPercentage 10000 = 100%
     */
    function setMinimumPercentage(uint256 _minPercentage) external onlyOwner {
        minPercentage = _minPercentage;
    }

    /**
     * @notice Set the monitor address
     * @param _monitor Address of the monitor
     */
    function setMonitor(address _monitor) external onlyOwner {
        monitor = _monitor;
    }

    /**
     * @notice Change interval for adjusting in to adapters
     * @param _adjustInInterval New interval in seconds
     */
    function changeAdjustInInterval(uint256 _adjustInInterval) external onlyOwner {
        adjustInInterval = _adjustInInterval;
    }

    /**
     * @notice Change interval for adjusting out from adapters
     * @param _adjustOutInterval New interval in seconds
     */
    function changeAdjustOutInterval(uint256 _adjustOutInterval) external onlyOwner {
        adjustOutInterval = _adjustOutInterval;
    }

    /**
     * @notice Pause the strategy
     */
    function togglePause() external onlyOwner {
        paused = !paused;
    }

    /**
     * @notice change the adapter health factor. Health factor indicates how much of the underlying pool of adapter lost
     * it's ratio
     * @param _adapter Address of the adapter
     * @param _healthFactor New health factor for the adapter. 10000 = 100%
     */
    function changeAdapterHealthFactor(address _adapter, uint256 _healthFactor) external onlyOwner {
        require(_healthFactor <= 10_000, "Health factor can't be more than 100%");
        IAdapter(_adapter).setHealthFactor(_healthFactor);
    }

    /**
     * @notice Change the fee percentage
     * @param _feePercentage New fee percentage. 10000 = 100%
     */
    function changeFeePercentage(uint256 _feePercentage) external onlyOwner {
        feePercentage = _feePercentage;
    }

    /**
     * @notice Change the fee recipient
     * @param _feeRecipient New fee recipient
     */
    function changeFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }
}