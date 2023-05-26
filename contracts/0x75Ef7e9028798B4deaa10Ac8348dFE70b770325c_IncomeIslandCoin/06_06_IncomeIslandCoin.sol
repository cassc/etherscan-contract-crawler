// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IncomeIslandCoin is Proxy {
    using Address for address;

    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @notice Constructor inherits ProxyAdmin
     * @param _newImplementation the implement contract address
     */
    constructor(address _newImplementation) {
        _setAdmin(msg.sender);
        _setImplementation(_newImplementation);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    function _implementation() internal view override returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(
            Address.isContract(newImplementation),
            "ERC1967: new implementation is not a contract"
        );
        StorageSlot
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
    }

    function implementation() external view returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @notice setUri
     */
    function setImplementation(address newImplementation) external ifAdmin {
        _setImplementation(newImplementation);
    }

    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) internal {
        require(
            newAdmin != address(0),
            "TradingProxy: new admin is the zero address"
        );
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    function admin() external view returns (address admin_) {
        admin_ = _getAdmin();
    }

    function changeAdmin(address newAdmin) external ifAdmin {
        _setAdmin(newAdmin);
    }
}