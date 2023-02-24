// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

interface IMultiTransactorV1 {
    event SetAdmin(address indexed admin, address account, bool value);
    event SetTransactor(address indexed transactor, address account, bool value);

    event SendTransaction(address indexed to, bytes data, bytes result);
    event SendTransactionBatch(address[] indexed to, bytes[] data, bytes[] result);

    function setAdmin(address target, bool value) external returns (bool success);

    function setTransactor(address target, bool value) external returns (bool success);

    function isAdmin(address target) external view returns (bool);

    function isTransactor(address target) external view returns (bool);

    function getAdminList(uint256 cursor, uint256 count)
        external
        view
        returns (address[] memory result, uint256 newCursor);

    function getTransactorList(uint256 cursor, uint256 count)
        external
        view
        returns (address[] memory result, uint256 newCursor);

    function sendTx(address to, bytes memory data) external returns (bytes memory);

    function sendTxBatch(address[] calldata to, bytes[] calldata data) external returns (bytes[] memory);

    function version() external pure returns (string memory);
}