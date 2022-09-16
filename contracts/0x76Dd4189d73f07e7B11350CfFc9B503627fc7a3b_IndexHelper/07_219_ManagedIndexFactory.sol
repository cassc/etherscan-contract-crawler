// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Create2.sol";

import "./interfaces/IManagedIndexFactory.sol";

import "./ManagedIndex.sol";
import "./BaseIndexFactory.sol";

/// @title Managed index factory
/// @notice Contains logic for managed index creation
contract ManagedIndexFactory is IManagedIndexFactory, BaseIndexFactory {
    using ERC165Checker for address;

    constructor(
        address _registry,
        address _vTokenFactory,
        address _reweightingLogic,
        uint16 _defaultMintingFeeInBP,
        uint16 _defaultBurningFeeInBP,
        uint _defaultAUMScaledPerSecondsRate
    )
        BaseIndexFactory(
            _registry,
            _vTokenFactory,
            _reweightingLogic,
            _defaultMintingFeeInBP,
            _defaultBurningFeeInBP,
            _defaultAUMScaledPerSecondsRate
        )
    {
        require(
            _reweightingLogic.supportsInterface(type(IManagedIndexReweightingLogic).interfaceId),
            "ManagedIndexFactory: INTERFACE"
        );
    }

    /// @inheritdoc IIndexFactory
    function setReweightingLogic(address _reweightingLogic) external override onlyRole(INDEX_MANAGER_ROLE) {
        require(
            _reweightingLogic.supportsInterface(type(IManagedIndexReweightingLogic).interfaceId),
            "ManagedIndexFactory: INTERFACE"
        );

        reweightingLogic = _reweightingLogic;
    }

    /// @inheritdoc IManagedIndexFactory
    function createIndex(
        address[] calldata _assets,
        uint8[] calldata _weights,
        NameDetails calldata _nameDetails
    ) external override onlyRole(INDEX_CREATOR_ROLE) returns (address index) {
        uint assetsCount = _assets.length;
        require(assetsCount > 1 && assetsCount == _weights.length, "ManagedIndexFactory: LENGTH");
        require(assetsCount <= IIndexRegistry(registry).maxComponents(), "ManagedIndexFactory: COMPONENTS");

        uint _totalWeight;

        for (uint i; i < assetsCount; ) {
            address asset = _assets[i];
            if (i != 0) {
                // makes sure that there are no duplicate assets
                require(_assets[i - 1] < asset, "ManagedIndexFactory: SORT");
            }

            uint8 weight = _weights[i];
            require(weight != 0, "ManagedIndexFactory: INVALID");

            require(IAccessControl(registry).hasRole(ASSET_ROLE, asset), "ManagedIndexFactory: INVALID");

            _totalWeight += weight;

            unchecked {
                i = i + 1;
            }
        }

        require(_totalWeight == IndexLibrary.MAX_WEIGHT, "ManagedIndexFactory: MAX");

        bytes32 salt = keccak256(abi.encodePacked(_nameDetails.name, _nameDetails.symbol));
        index = Create2.computeAddress(salt, keccak256(type(ManagedIndex).creationCode));
        IIndexRegistry(registry).registerIndex(index, _nameDetails);
        Create2.deploy(0, salt, type(ManagedIndex).creationCode);

        IFeePool.MintBurnInfo[] memory mintInfo = new IFeePool.MintBurnInfo[](1);
        mintInfo[0] = IFeePool.MintBurnInfo(index, BP.DECIMAL_FACTOR);

        IFeePool(IIndexRegistry(registry).feePool()).initializeIndex(
            index,
            defaultMintingFeeInBP,
            defaultBurningFeeInBP,
            defaultAUMScaledPerSecondsRate,
            mintInfo
        );

        ManagedIndex(index).initialize(_assets, _weights);

        emit ManagedIndexCreated(index, _assets, _weights);
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IManagedIndexFactory).interfaceId || super.supportsInterface(_interfaceId);
    }
}