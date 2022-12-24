// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LibAsset} from "../libraries/LibAsset.sol";
import {LibPausable} from "../libraries/LibPausable.sol";
import {LibUtil} from "../libraries/LibUtil.sol";
import {GenericErrors} from "../libraries/GenericErrors.sol";
import {IMiraidon} from "../interfaces/IMiraidon.sol";

contract Validatable {
    modifier validateBridgeData(IMiraidon.BridgeData memory _bridgeData) {
        require(
            !LibUtil.isZeroAddress(_bridgeData.receiver),
            GenericErrors.E16
        );
        require(_bridgeData.minAmount != 0, GenericErrors.E12);
        _;
    }

    modifier noNativeAsset(IMiraidon.BridgeData memory _bridgeData) {
        require(
            !LibAsset.isNativeAsset(_bridgeData.sendingAssetId),
            GenericErrors.E27
        );
        _;
    }

    modifier onlyAllowSourceToken(
        IMiraidon.BridgeData memory _bridgeData,
        address _token
    ) {
        require(_bridgeData.sendingAssetId == _token, GenericErrors.E18);
        _;
    }

    modifier onlyAllowDestinationChain(
        IMiraidon.BridgeData memory _bridgeData,
        uint256 _chainId
    ) {
        require(_bridgeData.destinationChainId == _chainId, GenericErrors.E17);
        _;
    }

    modifier containsSourceSwaps(IMiraidon.BridgeData memory _bridgeData) {
        require(_bridgeData.hasSourceSwaps, GenericErrors.E35);
        _;
    }

    modifier doesNotContainSourceSwaps(
        IMiraidon.BridgeData memory _bridgeData
    ) {
        require(!_bridgeData.hasSourceSwaps, GenericErrors.E35);
        _;
    }

    modifier doesNotContainDestinationCalls(
        IMiraidon.BridgeData memory _bridgeData
    ) {
        require(!_bridgeData.hasDestinationCall, GenericErrors.E35);
        _;
    }

    modifier whenNotPaused() {
        LibPausable.enforceNotPaused();
        _;
    }
}