// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAddressRelay, Implementation} from "./interfaces/IAddressRelay.sol";
import {IERC165} from "./interfaces/IERC165.sol";
import {IERC173} from "./interfaces/IERC173.sol";

/**
 * @author Created by HeyMint Launchpad https://join.heymint.xyz
 * @notice This contract contains the base logic for ERC-721A tokens deployed with HeyMint
 */
contract AddressRelay is IAddressRelay, Ownable {
    mapping(bytes4 => address) public selectorToImplAddress;
    mapping(bytes4 => bool) public supportedInterfaces;
    bytes4[] selectors;
    address[] implAddresses;
    address public fallbackImplAddress;
    bool public relayFrozen;

    constructor() {
        supportedInterfaces[0x01ffc9a7] = true; // IERC165
        supportedInterfaces[0x7f5828d0] = true; // IERC173
        supportedInterfaces[0xd9b67a26] = true; // ERC-1155
        supportedInterfaces[0x0e89341c] = true; // ERC1155MetadataURI
        supportedInterfaces[0x2a55205a] = true; // IERC2981
    }

    /**
     * @notice Permanently freezes the relay so no more selectors can be added or removed
     */
    function freezeRelay() external onlyOwner {
        relayFrozen = true;
    }

    /**
     * @notice Adds or updates selectors and their implementation addresses
     * @param _selectors The selectors to add or update
     * @param _implAddress The implementation address the selectors will point to
     */
    function addOrUpdateSelectors(
        bytes4[] memory _selectors,
        address _implAddress
    ) external onlyOwner {
        require(!relayFrozen, "RELAY_FROZEN");
        for (uint256 i = 0; i < _selectors.length; i++) {
            bytes4 selector = _selectors[i];
            selectorToImplAddress[selector] = _implAddress;
            selectors.push(selector);
        }
        bool implAddressExists = false;
        for (uint256 i = 0; i < implAddresses.length; i++) {
            if (implAddresses[i] == _implAddress) {
                implAddressExists = true;
                break;
            }
        }
        if (!implAddressExists) {
            implAddresses.push(_implAddress);
        }
    }

    /**
     * @notice Removes selectors
     * @param _selectors The selectors to remove
     */
    function removeSelectors(bytes4[] memory _selectors) external onlyOwner {
        require(!relayFrozen, "RELAY_FROZEN");
        for (uint256 i = 0; i < _selectors.length; i++) {
            bytes4 selector = _selectors[i];
            delete selectorToImplAddress[selector];
            uint256 selectorsLen = selectors.length;
            for (uint256 j = 0; j < selectorsLen; j++) {
                if (selectors[j] == selector) {
                    if (j != selectorsLen - 1) {
                        // if not last element, copy last to deleted element's slot
                        selectors[j] = selectors[selectorsLen - 1];
                    }
                    // pop last element
                    selectors.pop();
                    break;
                }
            }
        }
    }

    /**
     * @notice Removes an implementation address and all the selectors that point to it
     * @param _implAddress The implementation address to remove
     */
    function removeImplAddressAndAllSelectors(
        address _implAddress
    ) external onlyOwner {
        require(!relayFrozen, "RELAY_FROZEN");
        for (uint256 i = 0; i < implAddresses.length; i++) {
            if (implAddresses[i] == _implAddress) {
                // this just sets the value to 0, but doesn't remove it from the array
                delete implAddresses[i];
                break;
            }
        }
        for (uint256 i = 0; i < selectors.length; i++) {
            if (selectorToImplAddress[selectors[i]] == _implAddress) {
                delete selectorToImplAddress[selectors[i]];
                delete selectors[i];
            }
        }
    }

    /**
     * @notice Returns the implementation address for a given function selector
     * @param _functionSelector The function selector to get the implementation address for
     */
    function getImplAddress(
        bytes4 _functionSelector
    ) external view returns (address) {
        address implAddress = selectorToImplAddress[_functionSelector];
        if (implAddress == address(0)) {
            implAddress = fallbackImplAddress;
        }
        require(implAddress != address(0), "Function does not exist");
        return implAddress;
    }

    /**
     * @notice Returns the implementation address for a given function selector. Throws an error if function does not exist.
     * @param _functionSelector The function selector to get the implementation address for
     */
    function getImplAddressNoFallback(
        bytes4 _functionSelector
    ) external view returns (address) {
        address implAddress = selectorToImplAddress[_functionSelector];
        require(implAddress != address(0), "Function does not exist");
        return implAddress;
    }

    /**
     * @notice Returns all the implementation addresses and the selectors they support
     * @return impls_ An array of Implementation structs
     */
    function getAllImplAddressesAndSelectors()
        external
        view
        returns (Implementation[] memory)
    {
        uint256 trueImplAddressCount = 0;
        uint256 implAddressesLength = implAddresses.length;
        for (uint256 i = 0; i < implAddressesLength; i++) {
            if (implAddresses[i] != address(0)) {
                trueImplAddressCount++;
            }
        }
        Implementation[] memory impls = new Implementation[](
            trueImplAddressCount
        );
        for (uint256 i = 0; i < implAddressesLength; i++) {
            if (implAddresses[i] == address(0)) {
                continue;
            }
            address implAddress = implAddresses[i];
            bytes4[] memory selectors_;
            uint256 selectorCount = 0;
            uint256 selectorsLength = selectors.length;
            for (uint256 j = 0; j < selectorsLength; j++) {
                if (selectorToImplAddress[selectors[j]] == implAddress) {
                    selectorCount++;
                }
            }
            selectors_ = new bytes4[](selectorCount);
            uint256 selectorIndex = 0;
            for (uint256 j = 0; j < selectorsLength; j++) {
                if (selectorToImplAddress[selectors[j]] == implAddress) {
                    selectors_[selectorIndex] = selectors[j];
                    selectorIndex++;
                }
            }
            impls[i] = Implementation(implAddress, selectors_);
        }
        return impls;
    }

    /**
     * @notice Return all the function selectors associated with an implementation address
     * @param _implAddress The implementation address to get the selectors for
     */
    function getSelectorsForImplAddress(
        address _implAddress
    ) external view returns (bytes4[] memory) {
        uint256 selectorCount = 0;
        uint256 selectorsLength = selectors.length;
        for (uint256 i = 0; i < selectorsLength; i++) {
            if (selectorToImplAddress[selectors[i]] == _implAddress) {
                selectorCount++;
            }
        }
        bytes4[] memory selectorArr = new bytes4[](selectorCount);
        uint256 selectorIndex = 0;
        for (uint256 i = 0; i < selectorsLength; i++) {
            if (selectorToImplAddress[selectors[i]] == _implAddress) {
                selectorArr[selectorIndex] = selectors[i];
                selectorIndex++;
            }
        }
        return selectorArr;
    }

    /**
     * @notice Sets the fallback implementation address to use when a function selector is not found
     * @param _fallbackAddress The fallback implementation address
     */
    function setFallbackImplAddress(
        address _fallbackAddress
    ) external onlyOwner {
        require(!relayFrozen, "RELAY_FROZEN");
        fallbackImplAddress = _fallbackAddress;
    }

    /**
     * @notice Updates the supported interfaces
     * @param _interfaceId The interface ID to update
     * @param _supported Whether the interface is supported or not
     */
    function updateSupportedInterfaces(
        bytes4 _interfaceId,
        bool _supported
    ) external onlyOwner {
        supportedInterfaces[_interfaceId] = _supported;
    }

    /**
     * @notice Returns whether the interface is supported or not
     * @param _interfaceId The interface ID to check
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) external view returns (bool) {
        return supportedInterfaces[_interfaceId];
    }
}