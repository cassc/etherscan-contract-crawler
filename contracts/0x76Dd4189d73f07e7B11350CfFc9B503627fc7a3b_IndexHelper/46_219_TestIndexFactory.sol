// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./TestIndex.sol";
import "../BaseIndexFactory.sol";

contract TestIndexFactory is BaseIndexFactory {
    event TestIndexCreated(address index, address[] assets, uint8[] weights);

    using EnumerableSet for EnumerableSet.AddressSet;

    uint8 internal constant MAX_WEIGHT = type(uint8).max;

    constructor(
        address _registry,
        address _vTokenFactory,
        uint16 _defaultMintingFeeInBP,
        uint16 _defaultBurningFeeInBP,
        uint _defaultAUMScaledPerSecondsRate
    )
        BaseIndexFactory(
            _registry,
            _vTokenFactory,
            address(0),
            _defaultMintingFeeInBP,
            _defaultBurningFeeInBP,
            _defaultAUMScaledPerSecondsRate
        )
    {}

    function createIndex(
        address[] calldata _assets,
        uint8[] calldata _weights,
        NameDetails calldata _nameDetails
    ) external onlyRole(INDEX_CREATOR_ROLE) returns (address index) {
        require(
            _assets.length > 1 &&
                _assets.length <= IIndexRegistry(registry).maxComponents() &&
                _weights.length == _assets.length,
            "TestIndexFactory: INVALID"
        );
        {
            // stack too deep: start scope
            uint totalWeight;
            for (uint i; i < _assets.length; ) {
                require(_assets[i] != address(0) && _weights[i] != 0, "TestIndexFactory: ZERO");
                if (i > 0) {
                    // makes sure that there are no duplicate assets
                    require(_assets[i - 1] < _assets[i], "TestIndexFactory: SORT");
                }
                totalWeight += _weights[i];

                unchecked {
                    i = i + 1;
                }
            }
            require(totalWeight == MAX_WEIGHT, "TestIndexFactory: MAX");
            bytes32 salt = keccak256(abi.encodePacked(_assets, _weights));
            index = Create2.computeAddress(salt, keccak256(type(TestIndex).creationCode));
            IIndexRegistry(registry).registerIndex(index, _nameDetails);
            Create2.deploy(0, salt, type(TestIndex).creationCode);
        }
        // stack too deep: end scope

        IFeePool.MintBurnInfo[] memory mintInfo = new IFeePool.MintBurnInfo[](1);
        mintInfo[0] = IFeePool.MintBurnInfo(index, BP.DECIMAL_FACTOR);

        IFeePool(IIndexRegistry(registry).feePool()).initializeIndex(
            index,
            defaultMintingFeeInBP,
            defaultBurningFeeInBP,
            defaultAUMScaledPerSecondsRate,
            mintInfo
        );

        TestIndex(index).initialize(_assets, _weights);
        emit TestIndexCreated(index, _assets, _weights);
    }

    /// @inheritdoc IIndexFactory
    function setReweightingLogic(address _reweightingLogic) external override onlyRole(INDEX_MANAGER_ROLE) {
        reweightingLogic = _reweightingLogic;
    }
}