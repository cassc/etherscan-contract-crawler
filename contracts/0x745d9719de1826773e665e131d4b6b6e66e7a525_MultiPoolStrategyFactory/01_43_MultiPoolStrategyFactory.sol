pragma solidity ^0.8.10;

import { Clones } from "openzeppelin-contracts/proxy/Clones.sol";
import { Ownable } from "openzeppelin-contracts/access/Ownable.sol";
import { ConvexPoolAdapter } from "src/ConvexPoolAdapter.sol";
import { MultiPoolStrategy } from "src/MultiPoolStrategy.sol";
import { AuraWeightedPoolAdapter } from "src/AuraWeightedPoolAdapter.sol";
import { AuraStablePoolAdapter } from "src/AuraStablePoolAdapter.sol";
import { AuraComposableStablePoolAdapter } from "src/AuraComposableStablePoolAdapter.sol";

contract MultiPoolStrategyFactory is Ownable {
    using Clones for address;

    address public convexAdapterImplementation;
    address public auraWeightedAdapterImplementation;
    address public auraStableAdapterImplementation;
    address public multiPoolStrategyImplementation;
    address public auraComposableStablePoolAdapterImplementation;
    address public monitor;

    constructor(
        address _monitor,
        address _convexPoolAdapterImplementation,
        address _multiPoolStrategyImplementation,
        address _auraWeightedAdapterImplementation,
        address _auraStableAdapterImplementation,
        address _auraComposableStablePoolAdapterImplementation
    )
        Ownable()
    {
        convexAdapterImplementation = _convexPoolAdapterImplementation;
        multiPoolStrategyImplementation = _multiPoolStrategyImplementation;
        auraWeightedAdapterImplementation = _auraWeightedAdapterImplementation;
        auraStableAdapterImplementation = _auraStableAdapterImplementation;
        auraComposableStablePoolAdapterImplementation = _auraComposableStablePoolAdapterImplementation;
        monitor = _monitor;
    }

    function createConvexAdapter(
        address _curvePool,
        address _multiPoolStrategy,
        uint256 _convexPid,
        uint256 _tokensLength,
        address _zapper,
        bool _useEth,
        bool _indexUint,
        int128 _underlyingTokenIndex
    )
        external
        onlyOwner
        returns (address convexAdapter)
    {
        convexAdapter = convexAdapterImplementation.cloneDeterministic(
            keccak256(
                abi.encodePacked(
                    _curvePool,
                    _multiPoolStrategy,
                    _convexPid,
                    _tokensLength,
                    _zapper,
                    _useEth,
                    _indexUint,
                    _underlyingTokenIndex
                )
            )
        );
        ConvexPoolAdapter(payable(convexAdapter)).initialize(
            _curvePool,
            _multiPoolStrategy,
            _convexPid,
            _tokensLength,
            _zapper,
            _useEth,
            _indexUint,
            _underlyingTokenIndex
        );
    }

    function createAuraWeightedPoolAdapter(
        bytes32 _poolId,
        address _multiPoolStrategy,
        uint256 _auraPid
    )
        external
        onlyOwner
        returns (address auraAdapter)
    {
        auraAdapter = auraWeightedAdapterImplementation.cloneDeterministic(
            keccak256(abi.encodePacked(_poolId, _multiPoolStrategy, _auraPid))
        );
        AuraWeightedPoolAdapter(payable(auraAdapter)).initialize(_poolId, _multiPoolStrategy, _auraPid);
    }

    function createAuraStablePoolAdapter(
        bytes32 _poolId,
        address _multiPoolStrategy,
        uint256 _auraPid
    )
        external
        onlyOwner
        returns (address auraAdapter)
    {
        auraAdapter = auraStableAdapterImplementation.cloneDeterministic(
            keccak256(abi.encodePacked(_poolId, _multiPoolStrategy, _auraPid))
        );
        AuraStablePoolAdapter(payable(auraAdapter)).initialize(_poolId, _multiPoolStrategy, _auraPid);
    }

    function createAuraComposableStablePoolAdapter(
        bytes32 _poolId,
        address _multiPoolStrategy,
        uint256 _auraPid
    )
        external
        onlyOwner
        returns (address auraAdapter)
    {
        auraAdapter = auraComposableStablePoolAdapterImplementation.cloneDeterministic(
            keccak256(abi.encodePacked(_poolId, _multiPoolStrategy, _auraPid))
        );
        AuraComposableStablePoolAdapter(payable(auraAdapter)).initialize(_poolId, _multiPoolStrategy, _auraPid);
    }

    function createMultiPoolStrategy(
        address _underlyingToken,
        string calldata _strategyName
    )
        external
        onlyOwner
        returns (address multiPoolStrategy)
    {
        multiPoolStrategy = multiPoolStrategyImplementation.cloneDeterministic(
            keccak256(abi.encodePacked(_underlyingToken, monitor, _strategyName))
        );
        MultiPoolStrategy(multiPoolStrategy).initalize(_underlyingToken, monitor);
        MultiPoolStrategy(multiPoolStrategy).transferOwnership(msg.sender);
    }

    function setMonitorAddress(address _newMonitor) external onlyOwner {
        monitor = _newMonitor;
    }

    //// Setters for adapter factory addresses
    function setConvexAdapterImplementation(address _newConvexAdapterImplementation) external {
        convexAdapterImplementation = _newConvexAdapterImplementation;
    }

    function setAuraStableImplementation(address _newAuraStableImplementation) external {
        auraStableAdapterImplementation = _newAuraStableImplementation;
    }

    function setAuraWeightedImplementation(address _newAuraWeightedImplementation) external {
        auraWeightedAdapterImplementation = _newAuraWeightedImplementation;
    }

    function setAuraComposableStableImplementation(address _newAuraComposableStableImplementation) external {
        auraComposableStablePoolAdapterImplementation = _newAuraComposableStableImplementation;
    }
}