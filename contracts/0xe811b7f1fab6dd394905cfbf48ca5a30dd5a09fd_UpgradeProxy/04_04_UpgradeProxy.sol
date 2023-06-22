// SPDX-License-Identifier: GPL-3.0   

pragma solidity ^0.8.7;
import "./ERC1967Proxy.sol";

contract UpgradeProxy is ERC1967Proxy {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _PROXY_ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6104;
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(address _logic) payable ERC1967Proxy(_logic, bytes("")) {
        _setProxyAdmin(msg.sender);
    }

    function upgradeTo(address newImplementation) public {
        require(_getProxyAdmin() == msg.sender, "No Proxy Admin");
        _upgradeTo(newImplementation);
    }


    function implementation() public view returns (address) {
        return _implementation();
    }

        /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setProxyAdmin(address newAdmin) private {
        // require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        getAddressSlot(_PROXY_ADMIN_SLOT).value = newAdmin;
    }

        /**
     * @dev Returns the current implementation address.
     */
    function _getProxyAdmin() internal view returns (address) {
        return getAddressSlot(_PROXY_ADMIN_SLOT).value;
    }
}