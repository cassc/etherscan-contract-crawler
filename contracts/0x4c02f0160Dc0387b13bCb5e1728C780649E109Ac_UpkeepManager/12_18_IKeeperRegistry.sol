// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKeeperRegistry {
    struct Config {
        uint32 paymentPremiumPPB;
        uint32 flatFeeMicroLink;
        uint24 blockCountPerTurn;
        uint32 checkGasLimit;
        uint24 stalenessSeconds;
        uint16 gasCeilingMultiplier;
        uint96 minUpkeepSpend;
        uint32 maxPerformGas;
        uint256 fallbackGasPrice;
        uint256 fallbackLinkPrice;
        address transcoder;
        address registrar;
    }

    struct State {
        uint32 nonce;
        uint96 ownerLinkBalance;
        uint256 expectedLinkBalance;
        uint256 numUpkeeps;
    }

    function addFunds(uint256 id, uint96 amount) external;

    function cancelUpkeep(uint256 id) external;

    function getMinBalanceForUpkeep(uint256 id) external view returns (uint96 minBalance);

    function getState() external view returns (State memory state, Config memory config, address[] memory keepers);

    function getUpkeep(uint256 id)
        external
        view
        returns (
            address target,
            uint32 executeGas,
            bytes memory checkData,
            uint96 balance,
            address lastKeeper,
            address admin,
            uint64 maxValidBlocknumber,
            uint96 amountSpent
        );

    function registerUpkeep(address target, uint32 gasLimit, address admin, bytes memory checkData)
        external
        returns (uint256 id);

    function withdrawFunds(uint256 id, address to) external;
}