// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { CegaState } from "./CegaState.sol";
import { Deposit, FCNVaultMetadata, OptionBarrierType, OptionBarrier, VaultStatus, Withdrawal } from "./Structs.sol";
import { FCNVault } from "./FCNVault.sol";
import { Oracle } from "./Oracle.sol";
import { Calculations } from "./Calculations.sol";

error FCNProductError();

contract FCNProduct {
    using SafeERC20 for IERC20;
    using Calculations for FCNVaultMetadata;

    event VaultCreated(address vaultAddress, uint256 index);
    event VaultRemoved(address vaultAddress);
    event DepositQueued(address receiver, uint256 amount);
    event DepositQueueProcessed(address vaultAddress, uint256 totalUnderlyingAmount, uint256 processCount);
    event CollectFees(address vaultAddress, uint256 managementFee, uint256 yieldFee, uint256 totalFee);
    event WithdrawalQueued(address vaultAddress, address receiver, uint256 amountShares);
    event WithdrawalQueueProcessed(address vaultAddress, uint256 totalWithdrawnAmount, uint256 processCount);
    event RolloverVault(address vaultAddress, uint256 vaultStart);
    event FundsTransferred(address receiverAddress, uint256 totalUnderlyingAmount);

    CegaState public cegaState;

    address public immutable asset;
    string public name;
    uint256 public managementFeeBps; // basis points
    uint256 public yieldFeeBps; // basis points
    bool public isDepositQueueOpen;
    uint256 public maxDepositAmountLimit;
    uint256 public sumVaultUnderlyingAmounts;
    uint256 public queuedDepositsTotalAmount;
    uint256 public queuedDepositsCount;

    mapping(address => FCNVaultMetadata) public vaults;
    address[] public vaultAddresses;

    Deposit[] private depositQueue;
    mapping(address => Withdrawal[]) private withdrawalQueues;

    /**
     * @notice Creates a new FCNProduct
     * @param _cegaState is the address of the CegaState contract
     * @param _asset is the underlying asset this product accepts
     * @param _name is the name of the product
     * @param _managementFeeBps is the management fee in bps
     * @param _yieldFeeBps is the yield fee in bps
     * @param _maxDepositAmountLimit is the deposit limit for the product
     */
    constructor(
        address _cegaState,
        address _asset,
        string memory _name,
        uint256 _managementFeeBps,
        uint256 _yieldFeeBps,
        uint256 _maxDepositAmountLimit
    ) {
        cegaState = CegaState(_cegaState);
        asset = _asset;
        name = _name;
        managementFeeBps = _managementFeeBps;
        yieldFeeBps = _yieldFeeBps;
        maxDepositAmountLimit = _maxDepositAmountLimit;
        isDepositQueueOpen = false;
    }

    /**
     * @notice Asserts whether the sender has the DEFAULT_ADMIN_ROLE
     */
    modifier onlyDefaultAdmin() {
        require(cegaState.isDefaultAdmin(msg.sender), "403:DA");
        _;
    }

    /**
     * @notice Asserts whether the sender has the TRADER_ADMIN_ROLE
     */
    modifier onlyTraderAdmin() {
        require(cegaState.isTraderAdmin(msg.sender), "403:TA");
        _;
    }

    /**
     * @notice Asserts whether the sender has the OPERATOR_ADMIN_ROLE
     */
    modifier onlyOperatorAdmin() {
        require(cegaState.isOperatorAdmin(msg.sender), "403:OA");
        _;
    }

    /**
     * @notice Asserts that the vault has been initialized & is a Cega Vault
     * @param vaultAddress is the address of the vault
     */
    modifier validVault(address vaultAddress) {
        require(isValidVault(vaultAddress), "400:VA");
        _;
    }

    /**
     * @notice Checks whether a vault exists in the vaults mapping
     * Vault start date will never be zero if it exists
     * @param vaultAddress is the address of the vault
     */
    function isValidVault(address vaultAddress) public view returns (bool) {
        if (vaults[vaultAddress].vaultStart != 0) {
            return true;
        }
        return false;
    }

    /**
     * @notice Returns array of vault addresses associated with the product
     */
    function getVaultAddresses() public view returns (address[] memory) {
        return vaultAddresses;
    }

    /**
     * @notice Sets the management fee for the product
     * @param _managementFeeBps is the management fee in bps (100% = 10000)
     */
    function setManagementFeeBps(uint256 _managementFeeBps) public onlyOperatorAdmin {
        managementFeeBps = _managementFeeBps;
    }

    /**
     * @notice Sets the yieldfee for the product
     * @param _yieldFeeBps is the management fee in bps (100% = 10000)
     */
    function setYieldFeeBps(uint256 _yieldFeeBps) public onlyOperatorAdmin {
        yieldFeeBps = _yieldFeeBps;
    }

    /**
     * @notice Toggles whether the product is open or closed for deposits
     * @param _isDepositQueueOpen is a boolean for whether the deposit queue is accepting deposits
     */
    function setIsDepositQueueOpen(bool _isDepositQueueOpen) public onlyOperatorAdmin {
        isDepositQueueOpen = _isDepositQueueOpen;
    }

    /**
     * @notice Sets the maximum deposit limit for the product
     * @param _maxDepositAmountLimit is the deposit limit for the product
     */
    function setMaxDepositAmountLimit(uint256 _maxDepositAmountLimit) public onlyTraderAdmin {
        maxDepositAmountLimit = _maxDepositAmountLimit;
    }

    /**
     * @notice Creates a new vault for the product & maps the new vault address to the vaultMetadata
     * @param _tokenName is the name of the token for the vault
     * @param _tokenSymbol is the symbol for the vault's token
     * @param _vaultStart is the timestamp of the vault's start
     */
    function createVault(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _vaultStart
    ) public onlyTraderAdmin returns (address vaultAddress) {
        require(_vaultStart != 0, "400:VS");
        FCNVault vault = new FCNVault(asset, _tokenName, _tokenSymbol);
        address newVaultAddress = address(vault);
        vaultAddresses.push(newVaultAddress);

        // vaultMetadata & all of its fields are automatically initialized if it doesn't already exist in the mapping
        FCNVaultMetadata storage vaultMetadata = vaults[newVaultAddress];
        vaultMetadata.vaultStart = _vaultStart;
        vaultMetadata.vaultAddress = newVaultAddress;

        // Leverage is always set to 1
        vaultMetadata.leverage = 1;

        emit VaultCreated(newVaultAddress, vaultAddresses.length - 1);
        return newVaultAddress;
    }

    /**
     * @notice defaultAdmin has the ability to override & change the vaultMetadata
     * If a value is not input, it will override to the default value
     * @param vaultAddress is the address of the vault
     * @param metadata is the vault's metadata that we want to change to
     */
    function setVaultMetadata(
        address vaultAddress,
        FCNVaultMetadata calldata metadata
    ) public onlyDefaultAdmin validVault(vaultAddress) {
        require(metadata.vaultStart > 0, "400:VS");
        require(metadata.leverage == 1, "400:L");
        vaults[vaultAddress] = metadata;
    }

    /**
     * @notice defaultAdmin has the ability to remove a Vault
     * @param vaultAddress is the address of the vault
     */
    function removeVault(address vaultAddress) public onlyDefaultAdmin {
        uint256 j;
        bool isIn;

        for (j; j < vaultAddresses.length; j++) {
            if (vaultAddresses[j] == vaultAddress) {
                isIn = true;
                break;
            }
        }

        require(isIn, "400:VA");

        vaultAddresses[j] = vaultAddresses[vaultAddresses.length - 1];
        vaultAddresses.pop();
        delete vaults[vaultAddress];

        emit VaultRemoved(vaultAddress);
    }

    /**
     * @notice Trader admin sets the trade data after the auction
     * @param vaultAddress is the address of the vault
     * @param _tradeDate is the official timestamp of when the options contracts begins
     * @param _tradeExpiry is the timestamp of when the trade will expire
     * @param _aprBps is the APR in bps
     * @param _tenorInDays is the length of the options contract
     */
    function setTradeData(
        address vaultAddress,
        uint256 _tradeDate,
        uint256 _tradeExpiry,
        uint256 _aprBps,
        uint256 _tenorInDays
    ) public onlyTraderAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage metadata = vaults[vaultAddress];
        require(metadata.vaultStatus == VaultStatus.NotTraded, "500:WS");
        require(_tradeExpiry > 0, "400:TE");
        metadata.tradeDate = _tradeDate;
        metadata.tradeExpiry = _tradeExpiry;
        metadata.aprBps = _aprBps;
        metadata.tenorInDays = _tenorInDays;
    }

    /**
     * @notice Trader admin can add an option with barriers to a given vault
     * @param vaultAddress is the address of the vault
     * @param optionBarrier is the data for the option with barriers
     */
    function addOptionBarrier(
        address vaultAddress,
        OptionBarrier calldata optionBarrier
    ) public onlyTraderAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage metadata = vaults[vaultAddress];
        metadata.optionBarriers.push(optionBarrier);
        metadata.optionBarriersCount++;
    }

    /**
     * @notice Get all option barriers for a given vault
     * @param vaultAddress is the address of the vault
     */
    function getOptionBarriers(address vaultAddress) external view returns (OptionBarrier[] memory) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        return vaultMetadata.optionBarriers;
    }

    /**
     * @notice Get a single option barrier for a given vault
     * @param vaultAddress is the address of the vault
     * @param index is the index of the option barrier
     */
    function getOptionBarrier(address vaultAddress, uint256 index) public view returns (OptionBarrier memory) {
        FCNVaultMetadata storage metadata = vaults[vaultAddress];
        require(index < metadata.optionBarriersCount, "400:I");
        return metadata.optionBarriers[index];
    }

    /**
     * @notice Trader admin has ability to update price fixings & observation time.
     * @param vaultAddress is the address of the vault
     * @param index is the index of the option barrier we want to update
     * @param _asset is the ticker symbol of the asset we want to update
     * (included as a safety check since the asset name should match the option barrier at given index)
     * @param _strikeAbsoluteValue is the actual strike price of the asset
     * @param _barrierAbsoluteValue is the actual price that will cause the barrier to be triggered
     */
    function updateOptionBarrier(
        address vaultAddress,
        uint256 index,
        string calldata _asset,
        uint256 _strikeAbsoluteValue,
        uint256 _barrierAbsoluteValue
    ) public onlyTraderAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        require(index < vaultMetadata.optionBarriersCount, "400:I");

        OptionBarrier storage optionBarrier = vaultMetadata.optionBarriers[index];
        require(keccak256(abi.encodePacked(optionBarrier.asset)) == keccak256(abi.encodePacked(_asset)), "400:AS");

        optionBarrier.strikeAbsoluteValue = _strikeAbsoluteValue;
        optionBarrier.barrierAbsoluteValue = _barrierAbsoluteValue;
    }

    /**
     * @notice Operator admin has ability to update the oracle for an option barrier.
     * @param vaultAddress is the address of the vault
     * @param index is the index of the option barrier we want to update
     * @param _asset is the ticker symbol of the asset we want to update
     * (included as a safety check since the asset name should match the option barrier at given index)
     * @param newOracleName is the name of the new oracle (must also register this name in CegaState)
     */
    function updateOptionBarrierOracle(
        address vaultAddress,
        uint256 index,
        string calldata _asset,
        string memory newOracleName
    ) public onlyOperatorAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        require(index < vaultMetadata.optionBarriersCount, "400:I");

        OptionBarrier storage optionBarrier = vaultMetadata.optionBarriers[index];
        require(keccak256(abi.encodePacked(optionBarrier.asset)) == keccak256(abi.encodePacked(_asset)), "400:AS");

        require(cegaState.oracleAddresses(newOracleName) != address(0), "400:OR");
        optionBarrier.oracleName = newOracleName;
    }

    /**
     * @notice Trader admin has ability to remove an option barrier.
     * The index for all option barriers to the right of the index are shifted by one to the left.
     * @param vaultAddress is the address of the vault
     * @param index is the index of the option barrier we want to remove
     * @param _asset is the ticker symbol of the asset we want to update
     * (included as a safety check since the asset should match the option barrier at given index)
     */
    function removeOptionBarrier(
        address vaultAddress,
        uint256 index,
        string calldata _asset
    ) public onlyTraderAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        require(index < vaultMetadata.optionBarriersCount, "400:I");

        OptionBarrier[] storage optionBarriers = vaultMetadata.optionBarriers;
        require(
            keccak256(abi.encodePacked(optionBarriers[index].asset)) == keccak256(abi.encodePacked(_asset)),
            "400:AS"
        );

        // Shift all elements to the left.
        // Element at "index" becomes overwritten. Last element is now duplicated, so we can remove it.
        for (uint256 i = index; i < vaultMetadata.optionBarriersCount - 1; i++) {
            optionBarriers[i] = optionBarriers[i + 1];
        }
        optionBarriers.pop();
        vaultMetadata.optionBarriersCount -= 1;
    }

    /**
     * Operator admin has ability to override the vault's status
     * @param vaultAddress is the address of the vault
     * @param _vaultStatus is the new status for the vault
     */
    function setVaultStatus(
        address vaultAddress,
        VaultStatus _vaultStatus
    ) public onlyOperatorAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage metadata = vaults[vaultAddress];
        metadata.vaultStatus = _vaultStatus;
    }

    /**
     * Trader admin has ability to set the vault to "DepositsOpen" state
     * @param vaultAddress is the address of the vault
     */
    function openVaultDeposits(address vaultAddress) public onlyTraderAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        vaultMetadata.vaultStatus = VaultStatus.DepositsOpen;
    }

    /**
     * Trader admin has an override to set the knock in status for a vault
     * @param vaultAddress is the address of the vault
     * @param newState is the new state for isKnockedIn
     */
    function setKnockInStatus(address vaultAddress, bool newState) public onlyTraderAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        vaultMetadata.isKnockedIn = newState;
    }

    /**
     * Transfers assets from the user to the product
     * @param amount is the amount of assets being deposited
     * @param receiver is the address of the user depositing into the product
     */
    function addToDepositQueue(uint256 amount, address receiver) public {
        require(isDepositQueueOpen, "500:NotOpen");
        queuedDepositsCount += 1;
        queuedDepositsTotalAmount += amount;
        require(queuedDepositsTotalAmount + sumVaultUnderlyingAmounts <= maxDepositAmountLimit, "500:TooBig");

        IERC20(asset).safeTransferFrom(receiver, address(this), amount);
        depositQueue.push(Deposit({ amount: amount, receiver: receiver }));
        emit DepositQueued(receiver, amount);
    }

    /**
     * Processes the product's deposit queue into a specific vault
     * @param vaultAddress is the address of the vault
     * @param maxProcessCount is the number of elements in the deposit queue to be processed
     */
    function processDepositQueue(
        address vaultAddress,
        uint256 maxProcessCount
    ) public onlyTraderAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        require(vaultMetadata.vaultStatus == VaultStatus.DepositsOpen, "500:WS");

        FCNVault vault = FCNVault(vaultAddress);
        require(!(vaultMetadata.underlyingAmount == 0 && vault.totalSupply() > 0), "500:Z");

        uint256 processCount = Math.min(queuedDepositsCount, maxProcessCount);
        uint256 i;
        Deposit storage deposit;
        for (i = 0; i < processCount; i++) {
            deposit = depositQueue[i];
            queuedDepositsTotalAmount -= deposit.amount;
            vault.deposit(deposit.amount, deposit.receiver);
            vaultMetadata.underlyingAmount += deposit.amount;
            sumVaultUnderlyingAmounts += deposit.amount;
            vaultMetadata.currentAssetAmount += deposit.amount;
        }

        if (processCount >= queuedDepositsCount) {
            delete depositQueue;
        } else {
            // If partially processed the deposit queue, shift all remaining elements to the beginning
            // because we can only pop from the end of the array
            for (i = processCount; i < queuedDepositsCount; i++) {
                deposit = depositQueue[i];
                depositQueue[i - processCount] = deposit;
            }

            for (i = 0; i < processCount; i++) {
                depositQueue.pop();
            }
        }
        queuedDepositsCount -= processCount;

        if (queuedDepositsCount == 0) {
            vaultMetadata.vaultStatus = VaultStatus.NotTraded;
        }

        emit DepositQueueProcessed(vaultAddress, vaultMetadata.underlyingAmount, processCount);
    }

    /**
     * @notice Queues a withdrawal for the token holder of a specific vault token
     * @param vaultAddress is the address of the vault
     * @param amountShares is the number of vault tokens to be redeemed
     * @param receiver is the destination user's address once funds are withdrawn
     */
    function addToWithdrawalQueue(
        address vaultAddress,
        uint256 amountShares,
        address receiver
    ) public validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];

        IERC20(vaultAddress).safeTransferFrom(receiver, address(this), amountShares);
        Withdrawal[] storage withdrawalQueue = withdrawalQueues[vaultAddress];
        withdrawalQueue.push(Withdrawal({ amountShares: amountShares, receiver: receiver }));
        vaultMetadata.queuedWithdrawalsCount += 1;
        vaultMetadata.queuedWithdrawalsSharesAmount += amountShares;

        emit WithdrawalQueued(vaultAddress, receiver, amountShares);
    }

    /**
     * @notice Permissionless method that reads price from oracle contracts and checks if barrier is triggered
     * @param vaultAddress is address of the vault
     */
    function checkBarriers(address vaultAddress) public validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        vaultMetadata.checkBarriers(address(cegaState));
    }

    /**
     * @notice Calculates the final payoff for a given vault
     * @param vaultAddress is address of the vault
     */
    function calculateVaultFinalPayoff(
        address vaultAddress
    ) public validVault(vaultAddress) returns (uint256 vaultFinalPayoff) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        return vaultMetadata.calculateVaultFinalPayoff(address(cegaState));
    }

    /**
     * @notice Calculates the percentage of principal to return to users if a knock in occurs.
     * Iterates through all knock-in barriers and checks the ratio of (spot/strike) for each asset
     * Returns the minimum of the knock-in ratios.
     * @param vaultAddress is address of the vault
     */
    function calculateKnockInRatio(
        address vaultAddress
    ) public view validVault(vaultAddress) returns (uint256 knockInRatio) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        return vaultMetadata.calculateKnockInRatio(address(cegaState));
    }

    /**
     * @notice receive assets and allocate the underlying asset to the specified vault's balance
     * @param vaultAddress is the address of the vault
     * @param amount is the amount to transfer
     */
    function receiveAssetsFromCegaState(address vaultAddress, uint256 amount) public validVault(vaultAddress) {
        require(msg.sender == address(cegaState), "403:CS");
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        // // a valid vaultAddress will never have vaultStart = 0
        // require(vaultMetadata.vaultStart != 0, "400:VA");

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        vaultMetadata.currentAssetAmount += amount;
    }

    /**
     * @notice Calculates the fees that should be collected from a given vault
     * @param vaultAddress is the address of the vault
     */
    function calculateFees(
        address vaultAddress
    ) public view validVault(vaultAddress) returns (uint256 totalFee, uint256 managementFee, uint256 yieldFee) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        return vaultMetadata.calculateFees(managementFeeBps, yieldFeeBps);
    }

    /**
     * @notice Transfers the correct amount of fees to the fee recipient
     * @param vaultAddress is the address of the vault
     */
    function collectFees(address vaultAddress) public onlyTraderAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        require(vaultMetadata.vaultStatus == VaultStatus.PayoffCalculated, "500:WS");

        (uint256 totalFees, uint256 managementFee, uint256 yieldFee) = calculateFees(vaultAddress);
        totalFees = Math.min(totalFees, vaultMetadata.vaultFinalPayoff);
        IERC20(asset).safeTransfer(cegaState.feeRecipient(), totalFees);
        vaultMetadata.currentAssetAmount -= totalFees;

        vaultMetadata.vaultStatus = VaultStatus.FeesCollected;
        sumVaultUnderlyingAmounts -= vaultMetadata.underlyingAmount;
        vaultMetadata.underlyingAmount = vaultMetadata.vaultFinalPayoff - totalFees;
        sumVaultUnderlyingAmounts += vaultMetadata.underlyingAmount;

        emit CollectFees(vaultAddress, managementFee, yieldFee, totalFees);
    }

    /**
     * @notice Processes all the queued withdrawals in the withdrawal queue
     * @param vaultAddress is the address of the vault
     * @param maxProcessCount is the maximum number of withdrawals to process in the queue
     */
    function processWithdrawalQueue(
        address vaultAddress,
        uint256 maxProcessCount
    ) public onlyTraderAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        // Needs zombie state so that we can restore the vault
        require(
            vaultMetadata.vaultStatus == VaultStatus.FeesCollected || vaultMetadata.vaultStatus == VaultStatus.Zombie,
            "500:WS"
        );
        Withdrawal[] storage withdrawalQueue = withdrawalQueues[vaultAddress];

        FCNVault vault = FCNVault(vaultAddress);

        uint256 processCount = Math.min(vaultMetadata.queuedWithdrawalsCount, maxProcessCount);
        uint256 amountAssets;
        uint256 i;
        Withdrawal memory withdrawal;
        for (i = 0; i < processCount; i++) {
            withdrawal = withdrawalQueue[i];
            amountAssets = vault.redeem(withdrawal.amountShares, withdrawal.receiver);
            vaultMetadata.underlyingAmount -= amountAssets;
            sumVaultUnderlyingAmounts -= amountAssets;
            vaultMetadata.queuedWithdrawalsSharesAmount -= withdrawal.amountShares;
            IERC20(asset).safeTransfer(withdrawal.receiver, amountAssets);
            vaultMetadata.currentAssetAmount -= amountAssets;
        }

        for (i = processCount; i < vaultMetadata.queuedWithdrawalsCount; i++) {
            withdrawal = withdrawalQueue[i];
            withdrawalQueue[i - processCount] = withdrawal;
        }

        for (i = 0; i < processCount; i++) {
            withdrawalQueue.pop();
        }
        vaultMetadata.queuedWithdrawalsCount -= processCount;

        if (vaultMetadata.queuedWithdrawalsCount == 0) {
            if (vaultMetadata.underlyingAmount == 0 && vault.totalSupply() > 0) {
                vaultMetadata.vaultStatus = VaultStatus.Zombie;
            } else {
                vaultMetadata.vaultStatus = VaultStatus.WithdrawalQueueProcessed;
            }
        }

        emit WithdrawalQueueProcessed(vaultAddress, vaultMetadata.underlyingAmount, processCount);
    }

    /**
     * @notice Resets the vault to the default state after the trade is settled
     * @param vaultAddress is the address of the vault
     */
    function rolloverVault(address vaultAddress) public onlyTraderAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        require(vaultMetadata.vaultStatus == VaultStatus.WithdrawalQueueProcessed, "500:WS");
        require(vaultMetadata.tradeExpiry != 0, "400:TE");
        vaultMetadata.vaultStart = vaultMetadata.tradeExpiry;
        vaultMetadata.tradeDate = 0;
        vaultMetadata.tradeExpiry = 0;
        vaultMetadata.aprBps = 0;
        vaultMetadata.vaultStatus = VaultStatus.DepositsClosed;
        vaultMetadata.totalCouponPayoff = 0;
        vaultMetadata.vaultFinalPayoff = 0;
        vaultMetadata.isKnockedIn = false;
        emit RolloverVault(vaultAddress, vaultMetadata.vaultStart);
    }

    /**
     * @notice Trader sends assets from the product to a third party wallet address
     * @param vaultAddress is the address of the vault
     * @param receiver is the receiver of the assets
     * @param amount is the amount of the assets to be sent
     */
    function sendAssetsToTrade(
        address vaultAddress,
        address receiver,
        uint256 amount
    ) public onlyTraderAdmin validVault(vaultAddress) {
        require(cegaState.marketMakerAllowList(receiver), "400:NotAllowed");
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        require(amount <= vaultMetadata.currentAssetAmount, "400:TooBig");
        IERC20(asset).safeTransfer(receiver, amount);
        vaultMetadata.currentAssetAmount = vaultMetadata.currentAssetAmount - amount;
        vaultMetadata.vaultStatus = VaultStatus.Traded;
        emit FundsTransferred(receiver, amount);
    }

    /**
     * @notice Calculates the current yield accumulated to the current day for a given vault
     * @param vaultAddress is the address of the vault
     */
    function calculateCurrentYield(address vaultAddress) public validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        vaultMetadata.calculateCurrentYield();
    }

    function throwError() external pure {
        revert FCNProductError();
    }
}