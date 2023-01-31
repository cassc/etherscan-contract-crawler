// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;
bytes32 constant ADDR_LENDER_NOTE = "LENDER_NOTE";
bytes32 constant ADDR_BORROWER_NOTE = "BORROWER_NOTE";
bytes32 constant ADDR_FLASH_EXEC_PERMITS = "FLASH_EXEC_PERMITS";
bytes32 constant ADDR_TRANSFER_DELEGATE = "TRANSFER_DELEGATE";
bytes32 constant ADDR_SERVICE_FEE = "SERVICE_FEE";
bytes32 constant ADDR_XY3 = "XY3";
interface IAddressProvider {
    function getAddress(bytes32 id) external view returns (address);

    function getXY3() external view returns (address);

    function getLenderNote() external view returns (address);

    function getBorrowerNote() external view returns (address);

    function getFlashExecPermits() external view returns (address);

    function getTransferDelegate() external view returns (address);

    function getServiceFee() external view returns (address);

    function setAddress(bytes32 id, address newAddress) external;
}