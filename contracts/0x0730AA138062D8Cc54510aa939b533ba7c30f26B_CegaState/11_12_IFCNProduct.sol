// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Deposit, FCNVaultMetadata, OptionBarrier, VaultStatus, Withdrawal } from "../Structs.sol";

interface IFCNProduct {
    function cegaState() external view returns (address);

    function asset() external view returns (address);

    function name() external view returns (string memory);

    function managementFeeBps() external view returns (uint256);

    function yieldFeeBps() external view returns (uint256);

    function isDepositQueueOpen() external view returns (bool);

    function maxDepositAmountLimit() external view returns (uint256);

    function sumVaultUnderlyingAmounts() external view returns (uint256);

    function queuedDepositsTotalAmount() external view returns (uint256);

    function queuedDepositsCount() external view returns (uint256);

    function vaults(
        address vaultAddress
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            VaultStatus,
            bool
        );

    function vaultAddresses() external view returns (address[] memory);

    function depositQueue() external view returns (Deposit[] memory);

    function withdrawalQueues(address vaultAddress) external view returns (Withdrawal[] memory);

    function isValidVault(address vaultAddress) external view returns (bool);

    function getVaultAddresses() external view returns (address[] memory);

    function setManagementFeeBps(uint256 _managementFeeBps) external;

    function setYieldFeeBps(uint256 _yieldFeeBps) external;

    function setMaxDepositAmountLimit(uint256 _maxDepositAmountLimit) external;

    function createVault(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _vaultStart
    ) external returns (address vaultAddress);

    function setVaultMetadata(address vaultAddress, FCNVaultMetadata calldata metadata) external;

    function removeVault(address vaultAddress) external;

    function setTradeData(
        address vaultAddress,
        uint256 _tradeDate,
        uint256 _tradeExpiry,
        uint256 _aprBps,
        uint256 _tenorInDays
    ) external;

    function addOptionBarrier(address vaultAddress, OptionBarrier calldata optionBarrier) external;

    function getOptionBarriers(address vaultAddress) external view returns (OptionBarrier[] memory);

    function getOptionBarrier(address vaultAddress, uint256 index) external view returns (OptionBarrier memory);

    function updateOptionBarrier(
        address vaultAddress,
        uint256 index,
        string calldata _asset,
        uint256 _strikeAbsoluteValue,
        uint256 _barrierAbsoluteValue
    ) external;

    function updateOptionBarrierOracle(
        address vaultAddress,
        uint256 index,
        string calldata _asset,
        string memory newOracleName
    ) external;

    function removeOptionBarrier(address vaultAddress, uint256 index, string calldata _asset) external;

    function setVaultStatus(address vaultAddress, VaultStatus _vaultStatus) external;

    function openVaultDeposits(address vaultAddress) external;

    function setKnockInStatus(address vaultAddress, bool newState) external;

    function addToDepositQueue(uint256 amount, address receiver) external;

    function processDepositQueue(address vaultAddress, uint256 maxProcessCount) external;

    function addToWithdrawalQueue(address vaultAddress, uint256 amountShares, address receiver) external;

    function checkBarriers(address vaultAddress) external;

    function calculateVaultFinalPayoff(address vaultAddress) external returns (uint256 vaultFinalPayoff);

    function calculateKnockInRatio(address vaultAddress) external view returns (uint256 knockInRatio);

    function receiveAssetsFromCegaState(address vaultAddress, uint256 amount) external;

    function calculateFees(
        address vaultAddress
    ) external view returns (uint256 totalFee, uint256 managementFee, uint256 yieldFee);

    function collectFees(address vaultAddress) external;

    function processWithdrawalQueue(address vaultAddress, uint256 maxProcessCount) external;

    function rolloverVault(address vaultAddress) external;

    function sendAssetsToTrade(address vaultAddress, address receiver, uint256 amount) external;

    function calculateCurrentYield(address vaultAddress) external;

    function getVaultMetadata(address vaultAddress) external view returns (FCNVaultMetadata memory);
}