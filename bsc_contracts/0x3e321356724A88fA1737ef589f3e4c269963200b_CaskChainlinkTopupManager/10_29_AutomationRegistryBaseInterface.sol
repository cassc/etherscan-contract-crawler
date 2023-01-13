// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationRegistryBaseInterface {
    function registerUpkeep(
        address target,
        uint32 gasLimit,
        address admin,
        bytes calldata checkData
    ) external returns (
        uint256 id
    );
    function performUpkeep(
        uint256 id,
        bytes calldata performData
    ) external returns (
        bool success
    );
    function cancelUpkeep(
        uint256 id
    ) external;
    function addFunds(
        uint256 id,
        uint96 amount
    ) external;

    function getUpkeep(uint256 id)
    external view returns (
        address target,
        uint32 executeGas,
        bytes memory checkData,
        uint96 balance,
        address lastKeeper,
        address admin,
        uint64 maxValidBlocknumber
    );
    function getUpkeepCount()
    external view returns (uint256);
    function getCanceledUpkeepList()
    external view returns (uint256[] memory);
    function getKeeperList()
    external view returns (address[] memory);
    function getKeeperInfo(address query)
    external view returns (
        address payee,
        bool active,
        uint96 balance
    );
    function getConfig()
    external view returns (
        uint32 paymentPremiumPPB,
        uint24 checkFrequencyBlocks,
        uint32 checkGasLimit,
        uint24 stalenessSeconds,
        uint16 gasCeilingMultiplier,
        uint256 fallbackGasPrice,
        uint256 fallbackLinkPrice
    );
}