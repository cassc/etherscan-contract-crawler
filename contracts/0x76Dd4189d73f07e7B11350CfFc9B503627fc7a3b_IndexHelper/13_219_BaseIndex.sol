// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./libraries/IndexLibrary.sol";

import "./interfaces/IIndex.sol";
import "./interfaces/IIndexLogic.sol";
import "./interfaces/IIndexFactory.sol";

import "./PhutureIndex.sol";

/// @title Base index
/// @notice Contains common logic for all indices
abstract contract BaseIndex is PhutureIndex, ReentrancyGuard, IIndex {
    using ERC165Checker for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Role allows configure index related data/components
    bytes32 internal immutable INDEX_MANAGER_ROLE;

    /// @notice Checks if msg.sender has the given role's permission
    modifier onlyRole(bytes32 role) {
        require(IAccessControl(registry).hasRole(role, msg.sender), "Index: FORBIDDEN");
        _;
    }

    constructor(address _factory) {
        require(_factory.supportsInterface(type(IIndexFactory).interfaceId), "Index: INTERFACE");

        INDEX_MANAGER_ROLE = keccak256("INDEX_MANAGER_ROLE");

        factory = _factory;
        lastTransferTime = uint96(block.timestamp);
        registry = IIndexFactory(_factory).registry();
        vTokenFactory = IIndexFactory(_factory).vTokenFactory();
    }

    /// @inheritdoc IIndex
    function mint(address _recipient) external override nonReentrant {
        (bool success, bytes memory data) = IIndexRegistry(registry).indexLogic().delegatecall(
            abi.encodeWithSelector(IIndexLogic.mint.selector, _recipient)
        );
        if (!success) {
            if (data.length == 0) {
                revert("Index: MINT_FAILED");
            } else {
                assembly {
                    revert(add(32, data), mload(data))
                }
            }
        }
    }

    /// @inheritdoc IIndex
    function burn(address _recipient) external override nonReentrant {
        (bool success, bytes memory data) = IIndexRegistry(registry).indexLogic().delegatecall(
            abi.encodeWithSelector(IIndexLogic.burn.selector, _recipient)
        );
        if (!success) {
            if (data.length == 0) {
                revert("Index: BURN_FAILED");
            } else {
                assembly {
                    revert(add(32, data), mload(data))
                }
            }
        }
    }

    /// @inheritdoc IIndex
    function anatomy() external view override returns (address[] memory _assets, uint8[] memory _weights) {
        _assets = assets.values();
        uint assetsCount = _assets.length;
        _weights = new uint8[](assetsCount);

        for (uint i; i < assetsCount; ) {
            _weights[i] = weightOf[_assets[i]];

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc IIndex
    function inactiveAnatomy() external view override returns (address[] memory) {
        return inactiveAssets.values();
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IIndex).interfaceId || super.supportsInterface(_interfaceId);
    }
}