// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IRegistery {
    struct Transaction {
        uint256 chainId;
        address assetAddress;
        uint256 amount;
        address receiver;
        uint256 nounce;
        bool isCompleted;
    }

    function getUserNonce(address user) external returns (uint256);

    function isSendTransaction(bytes32 transactionID) external returns (bool);

    function isClaimTransaction(bytes32 transactionID) external returns (bool);

    function isMintTransaction(bytes32 transactionID) external returns (bool);

    function isburnTransactio(bytes32 transactionID) external returns (bool);

    function transactionValidated(bytes32 transactionID)
        external
        returns (bool);

    function assetChainBalance(address asset, uint256 chainid)
        external
        returns (uint256);

    function sendTransactions(bytes32 transactionID)
        external
        returns (Transaction memory);

    function claimTransactions(bytes32 transactionID)
        external
        returns (Transaction memory);

    function burnTransactions(bytes32 transactionID)
        external
        returns (Transaction memory);

    function mintTransactions(bytes32 transactionID)
        external
        returns (Transaction memory);

    function completeSendTransaction(bytes32 transactionID) external;

    function completeBurnTransaction(bytes32 transactionID) external;

    function completeMintTransaction(bytes32 transactionID) external;

    function completeClaimTransaction(bytes32 transactionID) external;

    function transferOwnership(address newOwner) external;

    function registerTransaction(
        uint256 chainTo,
        address assetAddress,
        uint256 amount,
        address receiver,
        uint8 _transactionType
    ) external returns (bytes32 transactionID, uint256 _nounce);
}