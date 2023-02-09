// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title InitializedProxy
 * @author Anna Carroll
 */
contract GameErc20Proxy {
    using Address for address;

    struct AddressSlot {
        address value;
    }

    bytes32 internal constant _LOGIC_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    // ======== Constructor =========

    constructor(
        address _logic,
        bytes memory _initializationCalldata
    ) {
        assert(_LOGIC_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        require(Address.isContract(_logic), "ERC1967: new implementation is not a contract");

        getAddressSlot(_LOGIC_SLOT).value = _logic;
        // Delegatecall into the logic contract, supplying initialization calldata
        (bool _ok, bytes memory returnData) =
            _logic.delegatecall(_initializationCalldata);
        // Revert if delegatecall to implementation reverts
        require(_ok, string(returnData));
    }

    // ======== logic =========

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function logic() public view returns (address) {
        return getAddressSlot(_LOGIC_SLOT).value;
    }

    // ======== Fallback =========

    fallback() external payable {
        address _impl = getAddressSlot(_LOGIC_SLOT).value;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
    }

    // ======== Receive =========

    receive() external payable {} // solhint-disable-line no-empty-blocks
}