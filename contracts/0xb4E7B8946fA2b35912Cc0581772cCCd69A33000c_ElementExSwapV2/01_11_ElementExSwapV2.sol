// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./storage/LibFeatureStorage.sol";
import "./Aggregator.sol";
import "./libs/Ownable.sol";


contract ElementExSwapV2 is Aggregator, Ownable {

    struct Method {
        bytes4 methodID;
        string methodName;
    }

    struct Feature {
        address feature;
        string name;
        Method[] methods;
    }

    event FeatureFunctionUpdated(
        bytes4 indexed methodID,
        address oldFeature,
        address newFeature
    );

    function registerFeatures(Feature[] calldata features) external onlyOwner {
        unchecked {
            for (uint256 i = 0; i < features.length; ++i) {
                registerFeature(features[i]);
            }
        }
    }

    function registerFeature(Feature calldata feature) public onlyOwner {
        unchecked {
            address impl = feature.feature;
            require(impl != address(0), "registerFeature: invalid feature address.");

            LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();
            stor.featureNames[impl] = feature.name;

            Method[] calldata methods = feature.methods;
            for (uint256 i = 0; i < methods.length; ++i) {
                bytes4 methodID = methods[i].methodID;
                address oldFeature = stor.featureImpls[methodID];
                if (oldFeature == address(0)) {
                    stor.methodIDs.push(methodID);
                }
                stor.featureImpls[methodID] = impl;
                stor.methodNames[methodID] = methods[i].methodName;
                emit FeatureFunctionUpdated(methodID, oldFeature, impl);
            }
        }
    }

    function unregister(bytes4[] calldata methodIDs) external onlyOwner {
        unchecked {
            uint256 removedFeatureCount;
            LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();

            // Update storage.featureImpls
            for (uint256 i = 0; i < methodIDs.length; ++i) {
                bytes4 methodID = methodIDs[i];
                address impl = stor.featureImpls[methodID];
                if (impl != address(0)) {
                    removedFeatureCount++;
                    stor.featureImpls[methodID] = address(0);
                }
                emit FeatureFunctionUpdated(methodID, impl, address(0));
            }
            if (removedFeatureCount == 0) {
                return;
            }

            // Remove methodIDs from storage.methodIDs
            bytes4[] storage storMethodIDs = stor.methodIDs;
            for (uint256 i = storMethodIDs.length; i > 0; --i) {
                bytes4 methodID = storMethodIDs[i - 1];
                if (stor.featureImpls[methodID] == address(0)) {
                    if (i != storMethodIDs.length) {
                        storMethodIDs[i - 1] = storMethodIDs[storMethodIDs.length - 1];
                    }
                    delete storMethodIDs[storMethodIDs.length - 1];
                    storMethodIDs.pop();

                    if (removedFeatureCount == 1) { // Finished
                        return;
                    }
                    --removedFeatureCount;
                }
            }
        }
    }

    /// @dev Fallback for just receiving ether.
    receive() external payable {}

    /// @dev Forwards calls to the appropriate implementation contract.
    uint256 private constant STORAGE_ID_FEATURE = 1 << 128;
    fallback() external payable {
        assembly {
            // Copy methodID to memory 0x00~0x04
            calldatacopy(0, 0, 4)

            // Store LibFeatureStorage.slot to memory 0x20~0x3F
            mstore(0x20, STORAGE_ID_FEATURE)

            // Calculate impl.slot and load impl from storage
            let impl := sload(keccak256(0, 0x40))
            if iszero(impl) {
                // revert("Not implemented method.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x000000174e6f7420696d706c656d656e746564206d6574686f642e0000000000)
                mstore(0x60, 0)
                revert(0, 0x64)
            }

            calldatacopy(0, 0, calldatasize())
            if iszero(delegatecall(gas(), impl, 0, calldatasize(), 0, 0)) {
                // Failed, copy the returned data and revert.
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            // Success, copy the returned data and return.
            returndatacopy(0, 0, returndatasize())
            return(0, returndatasize())
        }
    }

    function approveERC20(IERC20 token, address operator, uint256 amount) external onlyOwner {
        token.approve(operator, amount);
    }

    function rescueETH(address recipient) external onlyOwner {
        address to = (recipient != address(0)) ? recipient : msg.sender;
        _transferEth(to, address(this).balance);
    }

    function rescueERC20(address asset, address recipient) external onlyOwner {
        address to = (recipient != address(0)) ? recipient : msg.sender;
        _transferERC20(asset, to, IERC20(asset).balanceOf(address(this)));
    }

    function rescueERC721(address asset, uint256[] calldata ids , address recipient) external onlyOwner {
        assembly {
            // selector for transferFrom(address,address,uint256)
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(0x4, address())

            switch recipient
            case 0 { mstore(0x24, caller()) }
            default { mstore(0x24, recipient) }

            for { let offset := ids.offset } lt(offset, calldatasize()) { offset := add(offset, 0x20) } {
                // tokenID
                mstore(0x44, calldataload(offset))
                if iszero(call(gas(), asset, 0, 0, 0x64, 0, 0)) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    function onERC721Received(address, uint256, bytes calldata) external virtual returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function supportsInterface(bytes4 interfaceId) external virtual returns (bool) {
        return interfaceId == this.supportsInterface.selector;
    }
}