// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./SmartWalletStorage.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

contract SmartWalletProxy is SmartWalletStorage {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    event ImplementationUpdated(address indexed implementation);

    constructor(
        address _admin,
        address _implementation,
        address[] memory _supportedPlatformWallets,
        address[] memory _supportedSwaps,
        address[] memory _supportedLendings
    ) SmartWalletStorage(_admin) {
        _setImplementation(_implementation);
        for (uint256 i = 0; i < _supportedPlatformWallets.length; i++) {
            supportedPlatformWallets.add(_supportedPlatformWallets[i]);
        }
        for (uint256 i = 0; i < _supportedSwaps.length; i++) {
            supportedSwaps.add(_supportedSwaps[i]);
        }
        for (uint256 i = 0; i < _supportedLendings.length; i++) {
            supportedLendings.add(_supportedLendings[i]);
        }
    }

    receive() external payable {}

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    fallback() external payable {
        (bool success, ) = implementation().delegatecall(msg.data);
        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())
            switch success
                case 0 {
                    revert(free_mem_ptr, returndatasize())
                }
                default {
                    return(free_mem_ptr, returndatasize())
                }
        }
    }

    function implementation() public view returns (address impl) {
        bytes32 slot = IMPLEMENTATION;
        assembly {
            impl := sload(slot)
        }
    }

    function _setImplementation(address _implementation) internal {
        require(_implementation.isContract(), "non-contract address");

        bytes32 slot = IMPLEMENTATION;
        assembly {
            sstore(slot, _implementation)
        }
    }

    function updateNewImplementation(address _implementation) external onlyAdmin {
        _setImplementation(_implementation);
        emit ImplementationUpdated(_implementation);
    }

    function updateSupportedSwaps(address[] calldata addresses, bool isSupported)
        external onlyAdmin
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (isSupported) {
                supportedSwaps.add(addresses[i]);
            } else {
                supportedSwaps.remove(addresses[i]);
            }
        }
    }

    function getAllSupportedSwaps() external view returns (address[] memory addresses) {
        uint256 length = supportedSwaps.length();
        addresses = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            addresses[i] = supportedSwaps.at(i);
        }
    }

    function updateSupportedLendings(address[] calldata addresses, bool isSupported)
        external onlyAdmin
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (isSupported) {
                supportedLendings.add(addresses[i]);
            } else {
                supportedLendings.remove(addresses[i]);
            }
        }
    }

    function getAllSupportedLendings() external view returns (address[] memory addresses) {
        uint256 length = supportedLendings.length();
        addresses = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            addresses[i] = supportedLendings.at(i);
        }
    }

    function updateSupportedPlatformWallets(address[] calldata addresses, bool isSupported)
        external onlyAdmin
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (isSupported) {
                supportedPlatformWallets.add(addresses[i]);
            } else {
                supportedPlatformWallets.remove(addresses[i]);
            }
        }
    }

    function getAllSupportedPlatformWallets() external view returns (address[] memory addresses) {
        uint256 length = supportedPlatformWallets.length();
        addresses = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            addresses[i] = supportedPlatformWallets.at(i);
        }
    }
}