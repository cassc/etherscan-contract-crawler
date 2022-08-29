// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

interface IAnkrProtocol {

    // tier lifecycle events
    event TierLevelCreated(uint8 level);
    event TierLevelChanged(uint8 level);
    event TierLevelRemoved(uint8 level);

    // jwt token issue
    event TierAssigned(address indexed sender, uint256 amount, uint8 tier, uint256 roles, uint64 expires, bytes32 publicKey);

    // balance management
    event FundsLocked(address indexed sender, uint256 amount);
    event FundsUnlocked(address indexed sender, uint256 amount);
    event FeeCharged(address indexed sender, uint256 fee);

    function deposit(uint256 amount, uint64 timeout, bytes32 publicKey) external;

    function withdraw(uint256 amount) external;
}

interface IRequestFormat {

    function requestWithdrawal(address sender, uint256 amount) external;
}

interface ITransportLayer {

    event ProviderRequest(
        bytes32 id,
        address sender,
        uint256 fee,
        address callback,
        bytes data,
        uint64 expires
    );

    function handleChargeFee(address[] calldata users, uint256[] calldata fees) external;

    function handleWithdraw(address[] calldata users, uint256[] calldata amounts, uint256[] calldata fees) external;
}