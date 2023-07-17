// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { ICegaState } from "./interfaces/ICegaState.sol";
import {
    Deposit,
    FCNVaultMetadata,
    OptionBarrierType,
    OptionBarrier,
    VaultStatus,
    Withdrawal,
    LeverageMetadata
} from "./Structs.sol";
import { FCNVault } from "./FCNVault.sol";
import { LOVCalculations } from "./LOVCalculations.sol";

contract LOVProduct is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using LOVCalculations for FCNVaultMetadata;

    event LOVProductCreated(
        address indexed cegaState,
        address indexed asset,
        string name,
        uint256 managementFeeBps,
        uint256 yieldFeeBps,
        uint256 maxDepositAmountLimit,
        uint256 minDepositAmount,
        uint256 minWithdrawalAmount,
        uint256[] initialLeverages
    );

    event ManagementFeeBpsUpdated(uint256 managementFeeBps);
    event YieldFeeBpsUpdated(uint256 yieldFeeBps);
    event MinDepositAmountUpdated(uint256 minDepositAmount);
    event MinWithdrawalAmountUpdated(uint256 minWithdrawalAmount);
    event IsDepositQueueOpenUpdated(uint256 leverage, bool isDepositQueueOpen);
    event MaxDepositAmountLimitUpdated(uint256 leverage, uint256 maxDepositAmountLimit);
    event LeverageUpdated(uint256 leverage, bool isAllowed);

    event VaultCreated(
        address indexed vaultAddress,
        string _tokenSymbol,
        string _tokenName,
        uint256 _vaultStart,
        uint256 _leverage
    );
    event VaultMetadataUpdated(address indexed vaultAddress);
    event VaultRemoved(address indexed vaultAddress);

    event TradeDataSet(
        address indexed vaultAddress,
        uint256 _tradeDate,
        uint256 _tradeExpiry,
        uint256 _aprBps,
        uint256 _tenorInDays
    );

    event OptionBarrierAdded(
        address indexed vaultAddress,
        uint256 barrierBps,
        uint256 barrierAbsoluteValue,
        uint256 strikeBps,
        uint256 strikeAbsoluteValue,
        string asset,
        string oracleName,
        OptionBarrierType barrierType
    );
    event OptionBarrierUpated(
        address indexed vaultAddress,
        uint256 index,
        string _asset,
        uint256 _strikeAbsoluteValue,
        uint256 _barrierAbsoluteValue
    );
    event OptionBarrierOracleUpdated(address indexed vaultAddress, uint256 index, string _asset, string _oracleName);
    event OptionBarrierRemoved(address indexed vaultAddress, uint256 index, string asset);

    event VaultStatusUpdated(address indexed vaultAddress, VaultStatus vaultStatus);

    event DepositQueued(address indexed receiver, uint256 leverage, uint256 amount);
    event DepositProcessed(address indexed vaultAddress, address indexed receiver, uint256 amount);

    event KnockInStatusUpdated(address indexed vaultAddress, bool isKnockIn);

    event FeesCollected(
        address indexed vaultAddress,
        uint256 managementFee,
        uint256 yieldFee,
        uint256 totalFee,
        VaultStatus vaultStatus
    );

    event WithdrawalQueued(address indexed vaultAddress, address indexed receiver, uint256 amountShares);

    event WithdrawalProcessed(
        address indexed vaultAddress,
        address indexed receiver,
        uint256 amountShares,
        uint256 amountAssets
    );

    event VaultRollover(address indexed vaultAddress, uint256 vaultStart, VaultStatus vaultStatus);

    event VaultFinalPayoffCalculated(address indexed vaultAddress, uint256 finalPayoffAmount, VaultStatus vaultStatus);

    event BarriersChecked(address indexed vaultAddress, bool isKnockedIn);

    event AssetsReceivedFromCegaState(address indexed vaultAddress, uint256 amount);

    event AssetsSentToTrade(
        address indexed vaultAddress,
        address indexed receiver,
        uint256 amount,
        VaultStatus vaultStatus
    );

    ICegaState public cegaState;

    address public immutable asset;
    string public name;
    uint256 public managementFeeBps; // basis points
    uint256 public yieldFeeBps; // basis points
    uint256 public minDepositAmount;
    uint256 public minWithdrawalAmount;

    mapping(uint256 => LeverageMetadata) public leverages;
    mapping(uint256 => Deposit[]) public depositQueues;

    mapping(address => FCNVaultMetadata) public vaults;
    mapping(address => Withdrawal[]) public withdrawalQueues;

    /**
     * @notice Creates a new LOVProduct
     * @param _cegaState is the address of the CegaState contract
     * @param _asset is the underlying asset this product accepts
     * @param _name is the name of the product
     * @param _managementFeeBps is the management fee in bps
     * @param _yieldFeeBps is the yield fee in bps
     * @param _maxDepositAmountLimit is the deposit limit for each leverage of the product
     * @param _minDepositAmount is the minimum units of underlying for a user to deposit
     * @param _minWithdrawalAmount is the minimum units of vault shares for a user to withdraw
     * @param _initialLeverages is the initial leverages for the product
     */
    constructor(
        address _cegaState,
        address _asset,
        string memory _name,
        uint256 _managementFeeBps,
        uint256 _yieldFeeBps,
        uint256 _maxDepositAmountLimit,
        uint256 _minDepositAmount,
        uint256 _minWithdrawalAmount,
        uint256[] memory _initialLeverages
    ) {
        require(_managementFeeBps < 1e4, "400:IB");
        require(_yieldFeeBps < 1e4, "400:IB");
        require(_minDepositAmount > 0, "400:IU");
        require(_minWithdrawalAmount > 0, "400:IU");

        cegaState = ICegaState(_cegaState);
        asset = _asset;
        name = _name;
        managementFeeBps = _managementFeeBps;
        yieldFeeBps = _yieldFeeBps;

        minDepositAmount = _minDepositAmount;
        minWithdrawalAmount = _minWithdrawalAmount;

        for (uint256 i = 0; i < _initialLeverages.length; i++) {
            leverages[_initialLeverages[i]].isAllowed = true;
            leverages[_initialLeverages[i]].maxDepositAmountLimit = _maxDepositAmountLimit;
        }

        emit LOVProductCreated(
            _cegaState,
            _asset,
            _name,
            _managementFeeBps,
            _yieldFeeBps,
            _maxDepositAmountLimit,
            _minDepositAmount,
            _minWithdrawalAmount,
            _initialLeverages
        );
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
    modifier onlyValidVault(address vaultAddress) {
        require(vaults[vaultAddress].vaultStart != 0, "400:VA");
        _;
    }

    /**
     * @notice Returns array of vault addresses associated with the product
     * @param leverage is the leverage of the vaults
     */
    function getVaultAddresses(uint256 leverage) public view returns (address[] memory) {
        return leverages[leverage].vaultAddresses;
    }

    /**
     * @notice Returns vault metadata for a given vault address, includes OptionBarrier array in output
     * @param vaultAddress is the address of the vault
     */
    function getVaultMetadata(address vaultAddress) public view returns (FCNVaultMetadata memory) {
        return vaults[vaultAddress];
    }

    /**
     * @notice Returns the length of the deposit queue for a given leverage
     * @param leverage is the leverage of the deposit queue
     */
    function getDepositQueueCount(uint256 leverage) public view returns (uint256) {
        return depositQueues[leverage].length;
    }

    /**
     * @notice Sets the management fee for the product
     * @param _managementFeeBps is the management fee in bps (100% = 10000)
     */
    function setManagementFeeBps(uint256 _managementFeeBps) public onlyOperatorAdmin {
        require(_managementFeeBps < 1e4, "400:IB");
        managementFeeBps = _managementFeeBps;
        emit ManagementFeeBpsUpdated(_managementFeeBps);
    }

    /**
     * @notice Sets the yieldfee for the product
     * @param _yieldFeeBps is the management fee in bps (100% = 10000)
     */
    function setYieldFeeBps(uint256 _yieldFeeBps) public onlyOperatorAdmin {
        require(_yieldFeeBps < 1e4, "400:IB");
        yieldFeeBps = _yieldFeeBps;
        emit YieldFeeBpsUpdated(_yieldFeeBps);
    }

    /**
     * @notice Sets the min deposit amount for the product
     * @param _minDepositAmount is the minimum units of underlying for a user to deposit
     */
    function setMinDepositAmount(uint256 _minDepositAmount) public onlyOperatorAdmin {
        require(_minDepositAmount > 0, "400:IU");
        minDepositAmount = _minDepositAmount;
        emit MinDepositAmountUpdated(_minDepositAmount);
    }

    /**
     * @notice Updates the allowed leverage status for the product
     * @param _leverage is the leverage to be updated
     * @param _isAllowed is the allowed status of the leverage
     */
    function updateAllowedLeverage(uint256 _leverage, bool _isAllowed) public onlyOperatorAdmin {
        require(_leverage > 0, "400:L");
        require(leverages[_leverage].isAllowed != _isAllowed, "400:L");
        require(depositQueues[_leverage].length == 0);
        leverages[_leverage].isAllowed = _isAllowed;
        emit LeverageUpdated(_leverage, _isAllowed);
    }

    /**
     * @notice Sets the min withdrawal amount for the product
     * @param _minWithdrawalAmount is the minimum units of vault shares for a user to withdraw
     */
    function setMinWithdrawalAmount(uint256 _minWithdrawalAmount) public onlyOperatorAdmin {
        require(_minWithdrawalAmount > 0, "400:IU");
        minWithdrawalAmount = _minWithdrawalAmount;
        emit MinWithdrawalAmountUpdated(_minWithdrawalAmount);
    }

    /**
     * @notice Toggles whether the product is open or closed for deposits
     * @param _leverage is the leverage of the product
     * @param _isDepositQueueOpen is a boolean for whether the deposit queue is accepting deposits
     */
    function setIsDepositQueueOpen(uint256 _leverage, bool _isDepositQueueOpen) public onlyOperatorAdmin {
        leverages[_leverage].isDepositQueueOpen = _isDepositQueueOpen;
        emit IsDepositQueueOpenUpdated(_leverage, _isDepositQueueOpen);
    }

    /**
     * @notice Sets the maximum deposit limit for the product leverage
     * @param _leverage is the leverage of the product
     * @param _maxDepositAmountLimit is the deposit limit for the product
     */
    function setMaxDepositAmountLimit(uint256 _leverage, uint256 _maxDepositAmountLimit) public onlyTraderAdmin {
        require(
            leverages[_leverage].queuedDepositsTotalAmount + leverages[_leverage].sumVaultUnderlyingAmounts <=
                _maxDepositAmountLimit,
            "400:TooSmall"
        );
        leverages[_leverage].maxDepositAmountLimit = _maxDepositAmountLimit;
        emit MaxDepositAmountLimitUpdated(_leverage, _maxDepositAmountLimit);
    }

    /**
     * @notice Creates a new vault for the product & maps the new vault address to the vaultMetadata
     * @param _tokenName is the name of the token for the vault
     * @param _tokenSymbol is the symbol for the vault's token
     * @param _vaultStart is the timestamp of the vault's start
     * @param _leverage is the leverage of the vault
     */
    function createVault(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _vaultStart,
        uint256 _leverage
    ) public onlyTraderAdmin returns (address vaultAddress) {
        require(_vaultStart != 0, "400:VS");
        require(leverages[_leverage].isAllowed, "400:L");

        FCNVault vault = new FCNVault(asset, _tokenName, _tokenSymbol);
        address newVaultAddress = address(vault);
        leverages[_leverage].vaultAddresses.push(newVaultAddress);

        // vaultMetadata & all of its fields are automatically initialized if it doesn't already exist in the mapping
        FCNVaultMetadata storage vaultMetadata = vaults[newVaultAddress];
        vaultMetadata.vaultStart = _vaultStart;
        vaultMetadata.vaultAddress = newVaultAddress;
        vaultMetadata.leverage = _leverage;

        emit VaultCreated(newVaultAddress, _tokenSymbol, _tokenName, _vaultStart, _leverage);
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
    ) public onlyDefaultAdmin onlyValidVault(vaultAddress) {
        require(metadata.vaultStart > 0, "400:VS");
        require(leverages[metadata.leverage].isAllowed, "400:L");
        vaults[vaultAddress] = metadata;
        emit VaultMetadataUpdated(vaultAddress);
    }

    /**
     * @notice defaultAdmin has the ability to remove a Vault
     * @param leverage is the leverage of the vault
     * @param i is the index of the vault in the vaultAddresses array
     */
    function removeVault(uint256 leverage, uint256 i) public onlyDefaultAdmin {
        address vaultAddress = leverages[leverage].vaultAddresses[i];
        require(withdrawalQueues[vaultAddress].length == 0);
        uint256 lastIndex = leverages[leverage].vaultAddresses.length - 1;
        leverages[leverage].vaultAddresses[i] = leverages[leverage].vaultAddresses[lastIndex];
        leverages[leverage].vaultAddresses.pop();
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
    ) public onlyTraderAdmin onlyValidVault(vaultAddress) {
        FCNVaultMetadata storage metadata = vaults[vaultAddress];
        require(metadata.vaultStatus == VaultStatus.NotTraded, "500:WS");
        require(_tradeDate >= metadata.vaultStart, "400:TD");
        require(_tradeExpiry > _tradeDate, "400:TE");

        // allow for a 1 day difference in input tenor and derived tenor
        uint256 derivedDays = (_tradeExpiry - _tradeDate) / 1 days;
        if (derivedDays < _tenorInDays) {
            require(_tenorInDays - derivedDays <= 1, "400:TN");
        } else {
            require(derivedDays - _tenorInDays <= 1, "400:TN");
        }

        metadata.tradeDate = _tradeDate;
        metadata.tradeExpiry = _tradeExpiry;
        metadata.aprBps = _aprBps;
        metadata.tenorInDays = _tenorInDays;

        emit TradeDataSet(vaultAddress, _tradeDate, _tradeExpiry, _aprBps, _tenorInDays);
    }

    /**
     * @notice Trader admin can add an option with barriers to a given vault
     * @param vaultAddress is the address of the vault
     * @param optionBarrier is the data for the option with barriers
     */
    function addOptionBarrier(
        address vaultAddress,
        OptionBarrier calldata optionBarrier
    ) public onlyTraderAdmin onlyValidVault(vaultAddress) {
        FCNVaultMetadata storage metadata = vaults[vaultAddress];
        require(
            metadata.vaultStatus == VaultStatus.DepositsClosed || metadata.vaultStatus == VaultStatus.NotTraded,
            "500:WS"
        );
        metadata.optionBarriers.push(optionBarrier);
        metadata.optionBarriersCount++;

        emit OptionBarrierAdded(
            vaultAddress,
            optionBarrier.barrierBps,
            optionBarrier.barrierAbsoluteValue,
            optionBarrier.strikeBps,
            optionBarrier.strikeAbsoluteValue,
            optionBarrier.asset,
            optionBarrier.oracleName,
            optionBarrier.barrierType
        );
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
    ) public onlyTraderAdmin onlyValidVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];

        require(_strikeAbsoluteValue > 0, "400:SV");
        require(_barrierAbsoluteValue > 0, "400:BV");

        OptionBarrier storage optionBarrier = vaultMetadata.optionBarriers[index];
        require(keccak256(abi.encodePacked(optionBarrier.asset)) == keccak256(abi.encodePacked(_asset)), "400:AS");

        optionBarrier.strikeAbsoluteValue = _strikeAbsoluteValue;
        optionBarrier.barrierAbsoluteValue = _barrierAbsoluteValue;

        emit OptionBarrierUpated(vaultAddress, index, _asset, _strikeAbsoluteValue, _barrierAbsoluteValue);
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
    ) public onlyOperatorAdmin onlyValidVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        require(
            vaultMetadata.vaultStatus == VaultStatus.DepositsClosed ||
                vaultMetadata.vaultStatus == VaultStatus.NotTraded,
            "500:WS"
        );

        OptionBarrier storage optionBarrier = vaultMetadata.optionBarriers[index];
        require(keccak256(abi.encodePacked(optionBarrier.asset)) == keccak256(abi.encodePacked(_asset)), "400:AS");

        require(cegaState.oracleAddresses(newOracleName) != address(0), "400:OR");
        optionBarrier.oracleName = newOracleName;

        emit OptionBarrierOracleUpdated(vaultAddress, index, _asset, newOracleName);
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
    ) public onlyTraderAdmin onlyValidVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        require(
            vaultMetadata.vaultStatus == VaultStatus.DepositsClosed ||
                vaultMetadata.vaultStatus == VaultStatus.NotTraded,
            "500:WS"
        );

        OptionBarrier[] storage optionBarriers = vaultMetadata.optionBarriers;
        require(
            keccak256(abi.encodePacked(optionBarriers[index].asset)) == keccak256(abi.encodePacked(_asset)),
            "400:AS"
        );

        // swap and pop
        optionBarriers[index] = optionBarriers[optionBarriers.length - 1];
        optionBarriers.pop();
        vaultMetadata.optionBarriersCount -= 1;

        emit OptionBarrierRemoved(vaultAddress, index, _asset);
    }

    /**
     * Operator admin has ability to override the vault's status
     * @param vaultAddress is the address of the vault
     * @param _vaultStatus is the new status for the vault
     */
    function setVaultStatus(
        address vaultAddress,
        VaultStatus _vaultStatus
    ) public onlyOperatorAdmin onlyValidVault(vaultAddress) {
        FCNVaultMetadata storage metadata = vaults[vaultAddress];
        metadata.vaultStatus = _vaultStatus;
        emit VaultStatusUpdated(vaultAddress, _vaultStatus);
    }

    /**
     * Trader admin has ability to set the vault to "DepositsOpen" state
     * @param vaultAddress is the address of the vault
     */
    function openVaultDeposits(address vaultAddress) public onlyTraderAdmin onlyValidVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        require(vaultMetadata.vaultStatus == VaultStatus.DepositsClosed, "500:WS");
        vaultMetadata.vaultStatus = VaultStatus.DepositsOpen;
        emit VaultStatusUpdated(vaultAddress, VaultStatus.DepositsOpen);
    }

    /**
     * Default admin has an override to set the knock in status for a vault
     * @param vaultAddress is the address of the vault
     * @param newState is the new state for isKnockedIn
     */
    function setKnockInStatus(
        address vaultAddress,
        bool newState
    ) public onlyDefaultAdmin onlyValidVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        vaultMetadata.isKnockedIn = newState;
        emit KnockInStatusUpdated(vaultAddress, newState);
    }

    /**
     * Transfers assets from the user to the product for a specific vault deposit
     * @param leverage is desired leverage of the deposit
     * @param amount is the amount of assets being deposited
     */
    function addToDepositQueue(uint256 leverage, uint256 amount) public nonReentrant {
        require(leverages[leverage].isAllowed, "400:L");
        require(leverages[leverage].isDepositQueueOpen, "500:NotOpen");
        require(amount >= minDepositAmount, "400:DA");

        leverages[leverage].queuedDepositsTotalAmount += amount;
        require(
            leverages[leverage].queuedDepositsTotalAmount + leverages[leverage].sumVaultUnderlyingAmounts <=
                leverages[leverage].maxDepositAmountLimit,
            "500:TooBig"
        );

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        depositQueues[leverage].push(Deposit({ amount: amount, receiver: msg.sender }));
        emit DepositQueued(msg.sender, leverage, amount);
    }

    /**
     * Processes the product's deposit queue into a specific vault
     * @param vaultAddress is the address of the vault
     * @param maxProcessCount is the number of elements in the deposit queue to be processed
     */
    function processDepositQueue(
        address vaultAddress,
        uint256 maxProcessCount
    ) public nonReentrant onlyTraderAdmin onlyValidVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        require(vaultMetadata.vaultStatus == VaultStatus.DepositsOpen, "500:WS");

        FCNVault vault = FCNVault(vaultAddress);
        require(!(vaultMetadata.underlyingAmount == 0 && vault.totalSupply() > 0));

        uint256 processCount = Math.min(depositQueues[vaultMetadata.leverage].length, maxProcessCount);
        Deposit storage deposit;

        while (processCount > 0) {
            deposit = depositQueues[vaultMetadata.leverage][depositQueues[vaultMetadata.leverage].length - 1];

            leverages[vaultMetadata.leverage].queuedDepositsTotalAmount -= deposit.amount;
            vault.deposit(deposit.amount, deposit.receiver);
            vaultMetadata.underlyingAmount += deposit.amount;
            leverages[vaultMetadata.leverage].sumVaultUnderlyingAmounts += deposit.amount;
            vaultMetadata.currentAssetAmount += deposit.amount;

            emit DepositProcessed(vaultAddress, deposit.receiver, deposit.amount);

            depositQueues[vaultMetadata.leverage].pop();
            processCount -= 1;
        }

        if (depositQueues[vaultMetadata.leverage].length == 0) {
            vaultMetadata.vaultStatus = VaultStatus.NotTraded;
            emit VaultStatusUpdated(vaultAddress, VaultStatus.NotTraded);
        }
    }

    /**
     * @notice Queues a withdrawal for the token holder of a specific vault token
     * @param vaultAddress is the address of the vault
     * @param amountShares is the number of vault tokens to be redeemed
     */
    function addToWithdrawalQueue(
        address vaultAddress,
        uint256 amountShares
    ) public nonReentrant onlyValidVault(vaultAddress) {
        require(amountShares >= minWithdrawalAmount, "400:WA");

        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];

        IERC20(vaultAddress).safeTransferFrom(msg.sender, address(this), amountShares);
        Withdrawal[] storage withdrawalQueue = withdrawalQueues[vaultAddress];
        withdrawalQueue.push(Withdrawal({ amountShares: amountShares, receiver: msg.sender }));
        vaultMetadata.queuedWithdrawalsCount += 1;
        vaultMetadata.queuedWithdrawalsSharesAmount += amountShares;

        emit WithdrawalQueued(vaultAddress, msg.sender, amountShares);
    }

    /**
     * @notice Permissionless method that reads price from oracle contracts and checks if barrier is triggered
     * @param vaultAddress is address of the vault
     */
    function checkBarriers(address vaultAddress) public onlyValidVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        vaultMetadata.checkBarriers(address(cegaState));
        emit BarriersChecked(vaultAddress, vaultMetadata.isKnockedIn);
    }

    /**
     * @notice Calculates the final payoff for a given vault
     * @param vaultAddress is address of the vault
     */
    function calculateVaultFinalPayoff(
        address vaultAddress
    ) public onlyValidVault(vaultAddress) returns (uint256 vaultFinalPayoff) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        vaultFinalPayoff = vaultMetadata.calculateVaultFinalPayoff(address(cegaState));
        emit VaultFinalPayoffCalculated(vaultAddress, vaultFinalPayoff, VaultStatus.PayoffCalculated);
    }

    /**
     * @notice receive assets and allocate the underlying asset to the specified vault's balance
     * @param vaultAddress is the address of the vault
     * @param amount is the amount to transfer
     */
    function receiveAssetsFromCegaState(
        address vaultAddress,
        uint256 amount
    ) public nonReentrant onlyValidVault(vaultAddress) {
        require(msg.sender == address(cegaState), "403:CS");
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        vaultMetadata.currentAssetAmount += amount;

        emit AssetsReceivedFromCegaState(vaultAddress, amount);
    }

    /**
     * @notice Transfers the correct amount of fees to the fee recipient
     * @param vaultAddress is the address of the vault
     */
    function collectFees(address vaultAddress) public nonReentrant onlyTraderAdmin onlyValidVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        require(vaultMetadata.vaultStatus == VaultStatus.PayoffCalculated, "500:WS");

        (uint256 totalFees, uint256 managementFee, uint256 yieldFee) = vaultMetadata.calculateFees(
            managementFeeBps,
            yieldFeeBps
        );
        totalFees = Math.min(totalFees, vaultMetadata.vaultFinalPayoff);
        IERC20(asset).safeTransfer(cegaState.feeRecipient(), totalFees);
        vaultMetadata.currentAssetAmount -= totalFees;

        vaultMetadata.vaultStatus = VaultStatus.FeesCollected;
        leverages[vaultMetadata.leverage].sumVaultUnderlyingAmounts -= vaultMetadata.underlyingAmount;
        vaultMetadata.underlyingAmount = vaultMetadata.vaultFinalPayoff - totalFees;
        leverages[vaultMetadata.leverage].sumVaultUnderlyingAmounts += vaultMetadata.underlyingAmount;

        emit FeesCollected(vaultAddress, managementFee, yieldFee, totalFees, VaultStatus.FeesCollected);
    }

    /**
     * @notice Processes all the queued withdrawals in the withdrawal queue
     * @param vaultAddress is the address of the vault
     * @param maxProcessCount is the maximum number of withdrawals to process in the queue
     */
    function processWithdrawalQueue(
        address vaultAddress,
        uint256 maxProcessCount
    ) public nonReentrant onlyTraderAdmin onlyValidVault(vaultAddress) {
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
        Withdrawal memory withdrawal;
        while (processCount > 0) {
            withdrawal = withdrawalQueue[vaultMetadata.queuedWithdrawalsCount - 1];

            amountAssets = vault.redeem(withdrawal.amountShares);
            vaultMetadata.underlyingAmount -= amountAssets;
            leverages[vaultMetadata.leverage].sumVaultUnderlyingAmounts -= amountAssets;
            vaultMetadata.queuedWithdrawalsSharesAmount -= withdrawal.amountShares;
            IERC20(asset).safeTransfer(withdrawal.receiver, amountAssets);
            vaultMetadata.currentAssetAmount -= amountAssets;

            emit WithdrawalProcessed(vaultAddress, withdrawal.receiver, withdrawal.amountShares, amountAssets);

            withdrawalQueue.pop();
            vaultMetadata.queuedWithdrawalsCount -= 1;
            processCount -= 1;
        }

        if (vaultMetadata.queuedWithdrawalsCount == 0) {
            if (vaultMetadata.underlyingAmount == 0 && vault.totalSupply() > 0) {
                vaultMetadata.vaultStatus = VaultStatus.Zombie;
                emit VaultStatusUpdated(vaultAddress, VaultStatus.Zombie);
            } else {
                vaultMetadata.vaultStatus = VaultStatus.WithdrawalQueueProcessed;
                emit VaultStatusUpdated(vaultAddress, VaultStatus.WithdrawalQueueProcessed);
            }
        }
    }

    /**
     * @notice Resets the vault to the default state after the trade is settled
     * @param vaultAddress is the address of the vault
     */
    function rolloverVault(address vaultAddress) public onlyTraderAdmin onlyValidVault(vaultAddress) {
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

        emit VaultRollover(vaultAddress, vaultMetadata.vaultStart, VaultStatus.DepositsClosed);
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
    ) public nonReentrant onlyTraderAdmin onlyValidVault(vaultAddress) {
        require(cegaState.marketMakerAllowList(receiver), "400:NotAllowed");
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        require(amount <= vaultMetadata.currentAssetAmount, "400:TooBig");
        IERC20(asset).safeTransfer(receiver, amount);
        vaultMetadata.currentAssetAmount = vaultMetadata.currentAssetAmount - amount;
        vaultMetadata.vaultStatus = VaultStatus.Traded;

        emit AssetsSentToTrade(vaultAddress, receiver, amount, VaultStatus.Traded);
    }

    /**
     * @notice Calculates the current yield accumulated to the current day for a given vault
     * @param vaultAddress is the address of the vault
     */
    function calculateCurrentYield(address vaultAddress) public onlyValidVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        vaultMetadata.calculateCurrentYield();
    }
}