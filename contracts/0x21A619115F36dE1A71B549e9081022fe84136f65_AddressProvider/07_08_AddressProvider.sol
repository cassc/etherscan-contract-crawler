// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IAddressProvider.sol";

contract AddressProvider is AccessControl, IAddressProvider {
    mapping(bytes32 => address) private _addresses;
    event AddressUpdated(bytes32 id, address oldAddress, address newAddress);

    constructor(address _admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function getLenderNote() external view override returns (address) {
        return getAddress(ADDR_LENDER_NOTE);
    }

    function getBorrowerNote() external view override returns (address) {
        return getAddress(ADDR_BORROWER_NOTE);
    }

    function getFlashExecPermits() external view override returns (address) {
        return getAddress(ADDR_FLASH_EXEC_PERMITS);
    }

    function getTransferDelegate() external view override returns (address) {
        return getAddress(ADDR_TRANSFER_DELEGATE);
    }

    function getServiceFee() external view override returns (address) {
        return getAddress(ADDR_SERVICE_FEE);
    }

    function getAddress(bytes32 id) public view override returns (address) {
        return _addresses[id];
    }

    function setAddress(
        bytes32 id,
        address newAddress
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldAddress = _addresses[id];
        _addresses[id] = newAddress;
        emit AddressUpdated(id, oldAddress, newAddress);
    }

    function getXY3() external view override returns (address) {
        return getAddress(ADDR_XY3);
    }
}