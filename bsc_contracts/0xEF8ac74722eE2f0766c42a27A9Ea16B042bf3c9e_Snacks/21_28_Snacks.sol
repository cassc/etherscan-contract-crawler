// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./base/SnacksBaseV2.sol";
import "./interfaces/ISnacks.sol";
import "./interfaces/IMultipleRewardPool.sol";
import "./interfaces/ISnacksPool.sol";
import "./interfaces/ILunchBox.sol";

contract Snacks is ISnacks, SnacksBaseV2 {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Arrays for uint256[];
    using Counters for Counters.Counter;
    using PRBMathUD60x18 for uint256;

    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    uint256 private constant STEP = 0.000001 * 1e18;
    uint256 private constant CORRELATION_FACTOR = 1e24;
    uint256 private constant TOTAL_SUPPLY_FACTOR = 1e6;
    uint256 private constant PULSE_FEE_PERCENT = 3500;
    uint256 private constant POOL_REWARD_DISTRIBUTOR_FEE_PERCENT = 4500;
    uint256 private constant SENIORAGE_FEE_PERCENT = 500;
    
    address public btcSnacks;
    address public ethSnacks;
    address public snacksPool;
    address public lunchBox;
    uint256 private _btcSnacksFeeAmountStored;
    uint256 private _ethSnacksFeeAmountStored;
    Counters.Counter private _currentSnapshotId;
    
    mapping(uint256 => uint256) public snapshotIdToBtcSnacksFeeAmount;
    mapping(uint256 => uint256) public snapshotIdToEthSnacksFeeAmount;
    mapping(address => uint256) private _btcSnacksStartIndexPerAccount;
    mapping(address => uint256) private _ethSnacksStartIndexPerAccount;
    mapping(address => Snapshots) private _accountBalanceAndDepositSnapshots;
    uint256[] private _btcSnacksFeeSnapshots;
    uint256[] private _ethSnacksFeeSnapshots;
    Snapshots private _holderSupplySnapshots;
    
    event Snapshot(uint256 id);
    event BtcSnacksFeeAdded(uint256 feeAmount);
    event EthSnacksFeeAdded(uint256 feeAmount);
    
    modifier onlyBtcSnacks {
        require(
            msg.sender == btcSnacks,
            "Snacks: caller is not the BtcSnacks contract"
        );
        _;
    }
    
    modifier onlyEthSnacks {
        require(
            msg.sender == ethSnacks,
            "Snacks: caller is not the EthSnacks contract"
        );
        _;
    }
    
    constructor()
        SnacksBaseV2(
            STEP,
            CORRELATION_FACTOR,
            TOTAL_SUPPLY_FACTOR,
            PULSE_FEE_PERCENT,
            POOL_REWARD_DISTRIBUTOR_FEE_PERCENT,
            SENIORAGE_FEE_PERCENT,
            "Snacks",
            "SNACK"
        )
    {}
    
    /**
    * @notice Configures the contract.
    * @dev Could be called by the owner in case of resetting addresses.
    * @param zoinks_ Zoinks token address.
    * @param pulse_ Pulse contract address.
    * @param poolRewardDistributor_ PoolRewardDistributor contract address.
    * @param seniorage_ Seniorage contract address.
    * @param snacksPool_ SnacksPool contract address.
    * @param pancakeSwapPool_ PancakeSwapPool contract address.
    * @param lunchBox_ LunchBox contract address.
    * @param authority_ Authorised address.
    * @param btcSnacks_ BtcSnacks token address.
    * @param ethSnacks_ EthSnacks token address.
    */
    function configure(
        address zoinks_,
        address pulse_,
        address poolRewardDistributor_,
        address seniorage_,
        address snacksPool_,
        address pancakeSwapPool_,
        address lunchBox_,
        address authority_,
        address btcSnacks_,
        address ethSnacks_
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _configure(
            zoinks_,
            pulse_,
            poolRewardDistributor_,
            seniorage_,
            snacksPool_,
            pancakeSwapPool_,
            lunchBox_,
            authority_
        );
        snacksPool = snacksPool_;
        lunchBox = lunchBox_;
        btcSnacks = btcSnacks_;
        ethSnacks = ethSnacks_;
        _excludedHolders.add(btcSnacks_);
        _excludedHolders.add(ethSnacks_);
    }
    
    /**
    * @notice Notifies the contract about the incoming fee in BtcSnacks token.
    * @dev The `distributeFee()` function in the BtcSnacks contract must be called before
    * the `distributeFee()` function in the Snacks contract.
    * @param feeAmount_ Fee amount.
    */
    function notifyBtcSnacksFeeAmount(uint256 feeAmount_) external onlyBtcSnacks {
        _btcSnacksFeeAmountStored += feeAmount_;
        emit BtcSnacksFeeAdded(feeAmount_);
    }
    
    /**
    * @notice Notifies the contract about the incoming fee in EthSnacks token.
    * @dev The `distributeFee()` function in the EthSnacks contract must be called before
    * the `distributeFee()` function in the Snacks contract.
    * @param feeAmount_ Fee amount.
    */
    function notifyEthSnacksFeeAmount(uint256 feeAmount_) external onlyEthSnacks {
        _ethSnacksFeeAmountStored += feeAmount_;
        emit EthSnacksFeeAdded(feeAmount_);
    }
    
    /**
    * @notice Withdraws all the fee earned by the holder in BtcSnacks token.
    * @dev Theoretically, there may not be enough gas to execute this function 
    * if the holder has not withdrawn his fee for a long time. 
    * In this case, he needs to use the `withdrawBtcSnacks(offset)` function.
    */
    function withdrawBtcSnacks() external whenNotPaused nonReentrant {
        (uint256 newStartIndex, uint256 feeAmount) = getPendingBtcSnacks();
        _withdrawBtcSnacks(newStartIndex, feeAmount);
    }
    
    /**
    * @notice Withdraws the fee earned by the holder in BtcSnacks token in parts.
    * @dev Used when there is not enough gas to execute the `withdrawBtcSnacks()` function.
    * @param offset_ Number of unused withdrawals of the earned fee.
    */
    function withdrawBtcSnacks(uint256 offset_) external whenNotPaused nonReentrant {
        (uint256 newStartIndex, uint256 feeAmount) = getPendingBtcSnacks(offset_);
        _withdrawBtcSnacks(newStartIndex, feeAmount);
    }
    
    /**
    * @notice Withdraws all the fee earned by the holder in EthSnacks token.
    * @dev Theoretically, there may not be enough gas to perform this function 
    * if the holder has not withdrawn his fee for a long time. 
    * In this case, he needs to use the `withdrawEthSnacks(offset)` function.
    */
    function withdrawEthSnacks() external whenNotPaused nonReentrant {
        (uint256 newStartIndex, uint256 feeAmount) = getPendingEthSnacks();
        _withdrawEthSnacks(newStartIndex, feeAmount);
    }
    
    /**
    * @notice Withdraws the fee earned by the holder in EthSnacks token in parts.
    * @dev Used when there is not enough gas to execute the `withdrawEthSnacks()` function.
    * @param offset_ Number of unused withdrawals of the earned fee.
    */
    function withdrawEthSnacks(uint256 offset_) external whenNotPaused nonReentrant {
        (uint256 newStartIndex, uint256 feeAmount) = getPendingEthSnacks(offset_);
        _withdrawEthSnacks(newStartIndex, feeAmount);
    }
    
    /**
    * @notice Retrieves all the fee earned by the holder in BtcSnacks token.
    * @dev Executed inside the `withdrawBtcSnacks()` function, since the upper limit 
    * of the count is equal to the total number of fee distributions.
    * @return New start index (if it makes sense) and all the fee earned by the holder
    * in BtcSnacks token.
    */
    function getPendingBtcSnacks() public view returns (uint256, uint256) {
        uint256 startIndex = _btcSnacksStartIndexPerAccount[msg.sender];
        return _calculatePending(startIndex, _btcSnacksFeeSnapshots.length, true);
    }
    
    /**
    * @notice Retrieves the fee earned by the holder in BtcSnacks token for some number
    * of unused withdrawals.
    * @dev Executed inside the `withdrawBtcSnacks(offset)` function, since the upper limit 
    * of the count is equal to `starting index + offset`.
    * @param offset_ Number of unused withdrawals of the earned fee.
    * @return New start index (if it makes sense) and the fee earned by the holder 
    * in BtcSnacks token for some number of unused withdrawals.
    */
    function getPendingBtcSnacks(
        uint256 offset_
    )
        public
        view
        returns (uint256, uint256)
    {
        require(
            offset_ <= getAvailableBtcSnacksOffsetByAccount(msg.sender),
            "Snacks: invalid offset"
        );
        uint256 startIndex = _btcSnacksStartIndexPerAccount[msg.sender];
        return _calculatePending(startIndex, startIndex + offset_, true);
    }
    
    /**
    * @notice Retrieves all the fee earned by the holder in EthSnacks token.
    * @dev Executed inside the `withdrawEthSnacks()` function, since the upper limit 
    * of the count is equal to the total number of fee distributions.
    * @return New start index (if it makes sense) and all the fee earned by the holder
    * in EthSnacks token.
    */
    function getPendingEthSnacks() public view returns (uint256, uint256) {
        uint256 startIndex = _ethSnacksStartIndexPerAccount[msg.sender];
        return _calculatePending(startIndex, _ethSnacksFeeSnapshots.length, false);
    }
    
    /**
    * @notice Retrieves the fee earned by the holder in EthSnacks token for some number
    * of unused withdrawals.
    * @dev Executed inside the `withdrawEthSnacks(offset)` function, since the upper limit 
    * of the count is equal to `starting index + offset`.
    * @param offset_ Number of unused withdrawals of the earned fee.
    * @return New start index (if it makes sense) and the fee earned by the holder 
    * in EthSnacks token for some number of unused withdrawals.
    */
    function getPendingEthSnacks(
        uint256 offset_
    )
        public
        view
        returns (uint256, uint256)
    {
        require(
            offset_ <= getAvailableEthSnacksOffsetByAccount(msg.sender),
            "Snacks: invalid offset"
        );
        uint256 startIndex = _ethSnacksStartIndexPerAccount[msg.sender];
        return _calculatePending(startIndex, startIndex + offset_, false);
    }
    
    /**
    * @notice Retrieves a number of unused withdrawals of the earned fee in BtcSnacks token.
    * @dev Used as a check inside the `getPendingBtcSnacks(offset)` function.
    * @param account_ Account address.
    * @return Number of unused withdrawals of the earned fee.
    */
    function getAvailableBtcSnacksOffsetByAccount(
        address account_
    )
        public
        view
        returns (uint256)
    {
        uint256 startIndex = _btcSnacksStartIndexPerAccount[account_];
        uint256 endIndex = _btcSnacksFeeSnapshots.length;
        return endIndex - startIndex;
    }
    
    /**
    * @notice Retrieves a number of unused withdrawals of the earned fee in EthSnacks token.
    * @dev Used as a check inside the `getPendingEthSnacks(offset)` function.
    * @param account_ Account address.
    * @return Number of unused withdrawals of the earned fee.
    */
    function getAvailableEthSnacksOffsetByAccount(
        address account_
    )
        public
        view
        returns (uint256)
    {
        uint256 startIndex = _ethSnacksStartIndexPerAccount[account_];
        uint256 endIndex = _ethSnacksFeeSnapshots.length;
        return endIndex - startIndex;
    }
    
    /** 
    * @notice Retrieves summed up the balance and deposit of an account.
    * @dev The function is utilized in order to take into account the deposit 
    * of users in SnacksPool contract in the calculation of earned fees.
    * @param account_ Account address.
    * @return Account balance and deposit amount.
    */
    function balanceAndDepositOf(address account_) public view returns (uint256) {
        return IMultipleRewardPool(snacksPool).getBalance(account_) + balanceOf(account_);
    }

    /**
    * @notice Retrieves summed up the balance and deposit of an account at the time `snapshotId_` was created.
    * @dev The function is utilized for the correct calculation of fees each holder belongs to.
    * @param account_ Account address.
    * @param snapshotId_ Snapshot ID.
    * @return Accounts sum of balance and deposit amount at the time `snapshotId_` was created.
    */
    function balanceAndDepositOfAt(
        address account_, 
        uint256 snapshotId_
    ) 
        public 
        view  
        returns (uint256) 
    {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId_, _accountBalanceAndDepositSnapshots[account_]);
        return snapshotted ? value : balanceAndDepositOf(account_);
    }

    /**
    * @notice Retrieves the holder supply at the time `snapshotId_` was created.
    * @dev The function is utilized for the correct calculation of fees each holder belongs to.
    * @param snapshotId_ Snapshot ID.
    * @return Holder supply at the time `snapshotId_` was created.
    */
    function holderSupplyAt(
        uint256 snapshotId_
    ) 
        public 
        view 
        returns (uint256) 
    {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId_, _holderSupplySnapshots);
        return snapshotted ? value : _totalSupply - getExcludedBalance();
    }

    /**
    * @notice Gets total balance and deposit amount of all excluded holders.
    * @dev Overriden for taking into account not excluded holders deposits.
    * @return Total balance and deposit amount of all excluded holders.
    */
    function getExcludedBalance() public view returns (uint256) {
        uint256 excludedBalance;
        for (uint256 i = 0; i < _excludedHolders.length(); i++) {
            excludedBalance += balanceOf(_excludedHolders.at(i));
        }
        excludedBalance -= ISnacksPool(snacksPool).getNotExcludedHoldersSupply();
        return excludedBalance;
    }

    /**
    * @notice Retrieves the current snapshot ID.
    * @dev Utilized to properly update and retrieve data.
    * @return Current snapshot ID.
    */
    function getCurrentSnapshotId() public view returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
    * @notice Hook that is called inside `distributeFee()` function.
    * @dev No implementation.
    */
    function _beforeDistributeFee(uint256) internal pure override {}
    
    /**
    * @notice Hook that is called inside `distributeFee()` function.
    * @dev In addition to the standard behavior, the function updates the information about the 
    * received fee in the BtcSnacks tokens and EthSnacks tokens and takes a snapshot.
    * @param undistributedFee_ Amount of undistributed fee left.
    */
    function _afterDistributeFee(uint256 undistributedFee_) internal override {
        uint256 excludedBalance = getExcludedBalance();
        uint256 holdersBalance = _totalSupply - excludedBalance;
        if (undistributedFee_ != 0) {
            uint256 seniorageFeeAmount = undistributedFee_ / 10;
            _transfer(address(this), seniorage, seniorageFeeAmount);
            if (holdersBalance != 0) {
                address snacksPoolAddress = snacksPool;
                undistributedFee_ -= seniorageFeeAmount;
                uint256 notExcludedHoldersSupplyBefore = ISnacksPool(snacksPoolAddress).getNotExcludedHoldersSupply();
                uint256 totalSupplyBefore = ISnacksPool(snacksPoolAddress).getTotalSupply();
                uint256 lunchBoxParticipantsTotalSupplyBefore = ISnacksPool(snacksPoolAddress).getLunchBoxParticipantsTotalSupply();
                adjustmentFactor = adjustmentFactor.mul((holdersBalance + undistributedFee_).div(holdersBalance));
                uint256 difference = ISnacksPool(snacksPoolAddress).getNotExcludedHoldersSupply() - notExcludedHoldersSupplyBefore;
                _adjustedBalances[snacksPoolAddress] += difference;
                ISnacksPool(snacksPoolAddress).updateTotalSupplyFactor(totalSupplyBefore);
                ILunchBox(lunchBox).updateTotalSupplyFactor(lunchBoxParticipantsTotalSupplyBefore);
                _adjustedBalances[address(this)] = 0;
                emit RewardForHolders(undistributedFee_);
            }
        }
        uint256 currentId = _snapshot();
        if (_btcSnacksFeeAmountStored != 0) {
            _btcSnacksFeeSnapshots.push(currentId);
            snapshotIdToBtcSnacksFeeAmount[currentId] = _btcSnacksFeeAmountStored;
            _btcSnacksFeeAmountStored = 0;
        }
        if (_ethSnacksFeeAmountStored != 0) {
            _ethSnacksFeeSnapshots.push(currentId);
            snapshotIdToEthSnacksFeeAmount[currentId] = _ethSnacksFeeAmountStored;
            _ethSnacksFeeAmountStored = 0;
        }
    }
    
    /**
    * @notice Updates snapshots before the values are modified. 
    * @dev Executed for `_mint()`, `_burn()`, and `_transfer()` functions.
    * @param from_ Address from which tokens are sent.
    * @param to_ Address to which tokens are sent.
    */
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256
    )
        internal
        override
    {
        if (from_ == address(0)) {
            _updateAccountBalanceAndDeposit(to_);
            _updateHolderSupply();
        } else if (to_ == address(0)) {
            _updateAccountBalanceAndDeposit(from_);
            _updateHolderSupply();
        } else {
            _updateAccountBalanceAndDeposit(from_);
            _updateAccountBalanceAndDeposit(to_);
        }
    }

    /**
    * @notice Hook that is called right after any 
    * transfer of tokens. This includes minting and burning.
    * @dev No implementation.
    */
    function _afterTokenTransfer(address, address, uint256) internal pure override {}
    
    /**
    * @notice Sends the calculated amount of fee earned in BtcSnacks token to the holder 
    * and updates the starting index.
    * @dev Implemented to allow modularity in the contract.
    * @param newStartIndex_ New start index.
    * @param feeAmount_ Fee earned by the holder in BtcSnacks token.
    */
    function _withdrawBtcSnacks(
        uint256 newStartIndex_,
        uint256 feeAmount_
    )
        private
    {
        if (newStartIndex_ != _btcSnacksStartIndexPerAccount[msg.sender]) {
            _btcSnacksStartIndexPerAccount[msg.sender] = newStartIndex_;
        }
        if (feeAmount_ != 0) {
            IERC20(btcSnacks).safeTransfer(msg.sender, feeAmount_);
        }
    }
    
    /**
    * @notice Sends the calculated amount of fee earned in EthSnacks token to the holder 
    * and updates the starting index.
    * @dev Implemented to allow modularity in the contract.
    * @param newStartIndex_ New start index.
    * @param feeAmount_ Fee earned by the holder in EthSnacks token.
    */
    function _withdrawEthSnacks(
        uint256 newStartIndex_,
        uint256 feeAmount_
    )
        private
    {
        if (newStartIndex_ != _ethSnacksStartIndexPerAccount[msg.sender]) {
            _ethSnacksStartIndexPerAccount[msg.sender] = newStartIndex_;
        }
        if (feeAmount_ != 0) {
            IERC20(ethSnacks).safeTransfer(msg.sender, feeAmount_);
        }
    }
    
    /**
    * @notice Creates a new snapshot and returns its ID.
    * @dev A snapshot is taken once every 12 hours when the `distributeFee()` function is called.
    * @return New snapshot ID.
    */
    function _snapshot() private returns (uint256) {
        _currentSnapshotId.increment();
        uint256 currentId = getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }
    
    /**
    * @notice Updates the balance and deposit, and then it's taking a snapshot for the `account_`.
    * @dev Called inside `_afterTokenTransfer()` callback.
    * @param account_ Account address.
    */
    function _updateAccountBalanceAndDeposit(address account_) private {
        _updateSnapshot(_accountBalanceAndDepositSnapshots[account_], balanceAndDepositOf(account_));
    }
    
    /**
    * @notice Updates holder supply snapshot.
    * @dev Called inside `_afterTokenTransfer()` callback.
    */
    function _updateHolderSupply() private {
        _updateSnapshot(_holderSupplySnapshots, _totalSupply - getExcludedBalance());
    }

    /**
    * @notice Updates snapshot.
    * @dev If information about the amount of the balance and deposit or holder supply 
    * has already been updated in the current snapshot, then it is re-updated.
    * @param snapshots_ Snapshot history.
    * @param currentValue_ Current value.
    */
    function _updateSnapshot(Snapshots storage snapshots_, uint256 currentValue_) private {
        uint256 currentId = getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots_.ids) < currentId) {
            snapshots_.ids.push(currentId);
            snapshots_.values.push(currentValue_);
        }
    }

    /**
    * @notice Retrieves the last snapshot ID. 
    * @dev Called inside `_updateSnapshot()` function.
    * @param ids_ Snapshot ids array.
    * @return Last snapshot ID.
    */
    function _lastSnapshotId(uint256[] storage ids_) private view returns (uint256) {
        if (ids_.length == 0) {
            return 0;
        } else {
            return ids_[ids_.length - 1];
        }
    }

    /**
    * @notice Retrieves the value at the time `snapshotId_` was created.
    * @dev Called inside `balanceAndDepositOfAt()` and `holderSupplyAt()` functions.
    * @param snapshotId_ Snapshot ID.
    * @param snapshots_ Snapshot history.
    * @return Boolean value indicating whether snapshot was taken or not
    * and the value at the time `snapshotId_` was created (0 if snapshot wasn't taken).
    */
    function _valueAt(
        uint256 snapshotId_, 
        Snapshots storage snapshots_
    ) 
        private 
        view 
        returns (bool, uint256) 
    {
        require(snapshotId_ > 0, "Snacks: id is 0");
        require(snapshotId_ <= getCurrentSnapshotId(), "Snacks: nonexistent id");
        // When a valid snapshot is queried, there are three possibilities:
        // 1. The queried value was not modified after the snapshot was taken. 
        // Therefore, a snapshot entry was never created for this ID, and all stored snapshot ids 
        // are smaller than the requested one. The value that corresponds to this ID is the current one.
        // 2. The queried value was modified after the snapshot was taken. 
        // Therefore, there will be an entry with the requested ID, and its value is the one to return.
        // 3. More snapshots were created after the requested one, and the queried value was later modified. 
        // There will be no entry for the requested ID: the value that corresponds to it is that 
        // of the smallest snapshot ID that is larger than the requested one.
        // In summary, we need to find an element in an array, returning the index of the smallest value that 
        // is larger if it is not found, unless said value doesn't exist (e.g. when all values are smaller). 
        // Arrays.findUpperBound does exactly this.
        uint256 index = snapshots_.ids.findUpperBound(snapshotId_);
        if (index == snapshots_.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots_.values[index]);
        }
    }

    /**
    * @notice Calculates pending amount of the earned fee.
    * @dev The calculation uses cumulative values, as the holder 
    * may not withdraw his fee for a long time.
    * @param startIndex_ Starting index.
    * @param endIndex_ Ending index.
    * @param flag_ Flag that determines for which token to calculate.
    * @return New start index (if it makes sense) and the fee earned by the holder.
    */
    function _calculatePending(
        uint256 startIndex_,
        uint256 endIndex_,
        bool flag_
    )
        private
        view
        returns (uint256, uint256)
    {
        uint256 feeSnapshotId;
        uint256 cumulativeBalanceAndDeposit;
        uint256 cumulativeHolderSupply;
        uint256 cumulativeFeeAmount;
        uint256 i;
        if (flag_) {
            uint256[] memory btcSnacksFeeSnapshots = _btcSnacksFeeSnapshots;
            for (i = startIndex_; i < endIndex_; i++) {
                feeSnapshotId = btcSnacksFeeSnapshots[i];
                cumulativeBalanceAndDeposit += balanceAndDepositOfAt(msg.sender, feeSnapshotId);
                cumulativeHolderSupply += holderSupplyAt(feeSnapshotId);
                cumulativeFeeAmount += snapshotIdToBtcSnacksFeeAmount[feeSnapshotId];
            }
        } else {
            uint256[] memory ethSnacksFeeSnapshots = _ethSnacksFeeSnapshots;
            for (i = startIndex_; i < endIndex_; i++) {
                feeSnapshotId = ethSnacksFeeSnapshots[i];
                cumulativeBalanceAndDeposit += balanceAndDepositOfAt(msg.sender, feeSnapshotId);
                cumulativeHolderSupply += holderSupplyAt(feeSnapshotId);
                cumulativeFeeAmount += snapshotIdToEthSnacksFeeAmount[feeSnapshotId];
            }
        }
        if (i == startIndex_) {
            return (startIndex_, 0);
        } else {
            return (i, cumulativeFeeAmount.mul(cumulativeBalanceAndDeposit).div(cumulativeHolderSupply));
        }
    }
}