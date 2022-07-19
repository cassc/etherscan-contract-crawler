// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IIIDepositManager {
    function globalWithdrawalDelay()
        external
        view
        returns (uint256 withdrawalDelay);

    function accStaked(address layer2, address account)
        external
        view
        returns (uint256 wtonAmount);

    function accStakedLayer2(address layer2)
        external
        view
        returns (uint256 wtonAmount);

    function accStakedAccount(address account)
        external
        view
        returns (uint256 wtonAmount);

    function pendingUnstaked(address layer2, address account)
        external
        view
        returns (uint256 wtonAmount);

    function pendingUnstakedLayer2(address layer2)
        external
        view
        returns (uint256 wtonAmount);

    function pendingUnstakedAccount(address account)
        external
        view
        returns (uint256 wtonAmount);

    function accUnstaked(address layer2, address account)
        external
        view
        returns (uint256 wtonAmount);

    function accUnstakedLayer2(address layer2)
        external
        view
        returns (uint256 wtonAmount);

    function accUnstakedAccount(address account)
        external
        view
        returns (uint256 wtonAmount);

    function withdrawalRequestIndex(address layer2, address account)
        external
        view
        returns (uint256 index);

    // solhint-disable-next-line max-line-length
    function withdrawalRequest(
        address layer2,
        address account,
        uint256 index
    )
        external
        view
        returns (
            uint128 withdrawableBlockNumber,
            uint128 amount,
            bool processed
        );

    function WITHDRAWAL_DELAY() external view returns (uint256);

    function deposit(address layer2, uint256 amount) external returns (bool);

    function requestWithdrawal(address layer2, uint256 amount)
        external
        returns (bool);

    function processRequest(address layer2, bool receiveTON)
        external
        returns (bool);

    function requestWithdrawalAll(address layer2) external returns (bool);

    function processRequests(
        address layer2,
        uint256 n,
        bool receiveTON
    ) external returns (bool);

    function numRequests(address layer2, address account)
        external
        view
        returns (uint256);

    function numPendingRequests(address layer2, address account)
        external
        view
        returns (uint256);
}