// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@violetprotocol/extendable/extensions/Extension.sol";
import { HumanboundPermissionState, HumanboundPermissionStorage } from "../../storage/HumanboundPermissionStorage.sol";
import { EthereumAccessTokenState, EthereumAccessTokenStorage } from "../../storage/EthereumAccessTokenStorage.sol";
import "./IEATVerifierConnector.sol";

contract EATVerifierConnector is EATVerifierConnectorExtension {
    modifier onlyOperatorOrSelf() virtual {
        HumanboundPermissionState storage state = HumanboundPermissionStorage._getState();
        require(
            _lastExternalCaller() == state.operator ||
                _lastCaller() == state.operator ||
                _lastCaller() == address(this),
            "EATVerifierConnector: unauthorised"
        );
        _;
    }

    function setVerifier(address verifier) external override onlyOperatorOrSelf {
        EthereumAccessTokenState storage state = EthereumAccessTokenStorage._getState();
        state.verifier = verifier;
    }

    function getVerifier() public view override returns (address) {
        EthereumAccessTokenState storage state = EthereumAccessTokenStorage._getState();
        return state.verifier;
    }
}