//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./State.sol";

/// @title Getters for the state.
/// @notice This contract is used to encapsulate the calls to State.getState() method and to expose helper functions
/// that allow both contracts and off-chain apps to query the state of the Bridge.
/// @author Piotr "pibu" Buda
contract Getters is State {
    
    function getTokenAndBaseType(bytes memory tokenClassKey) public view returns (address token, uint256 baseType) {
        Structs.TokenBridge memory bridge = getState().bridges[keccak256(tokenClassKey)];
        require(bridge.initialized, "NOT_INITIALIZED");
        require(bridge.enabled, "DISABLED");
        require(bridge.token != address(0), "TOKEN_NOT_CONFIGURED");
        token = bridge.token;
        baseType = bridge.baseType;
    }

    /// @dev this method does not perform the check of the enabled flag of the token bridge
    function getToken(bytes memory tokenClassKey) internal view returns (address token) {
        Structs.TokenBridge memory bridge = getState().bridges[keccak256(tokenClassKey)];
        require(bridge.initialized, "NOT_INITIALIZED");
        require(bridge.token != address(0), "TOKEN_NOT_CONFIGURED");
        token = bridge.token;
    }

    /// @dev this method does not perform the check of the enabled flag of the token bridge
    function getBaseType(bytes memory tokenClassKey) internal view returns (uint256 baseType) {
        Structs.TokenBridge memory bridge = getState().bridges[keccak256(tokenClassKey)];
        require(bridge.initialized, "NOT_INITIALIZED");
        require(bridge.token != address(0), "TOKEN_NOT_CONFIGURED");
        baseType = bridge.baseType;
    }

    function isEnabled(address token, uint256 baseType) public view returns (bool enabled) {
        enabled = getState().bridges[getState().reverseBridges[token][baseType]].enabled;
    }

    function getTokenClassKey(address token, uint256 baseType) public view returns (bytes memory tokenClassKey) {
        Structs.TokenBridge memory bridge = getState().bridges[getState().reverseBridges[token][baseType]];
        require(bridge.initialized, "NOT_INITIALIZED");
        require(bridge.token != address(0), "TOKEN_NOT_CONFIGURED");
        tokenClassKey = bridge.tokenClassKey;
    }

    function isInitialized(bytes memory tokenClassKey) public view returns (bool initialized) {
        initialized = getState().bridges[keccak256(tokenClassKey)].initialized;
    }

    function isBurningBridge(address token, uint256 baseType) public view returns (bool) {
        return getState().bridges[getState().reverseBridges[token][baseType]].burning;
    }

    function getTokenType(address token) public view returns (TokenType) {
        return getState().tokenTypes[token];
    }

    function chainId() public view returns (uint16) {
        return getState().chainId;
    }

    function isGovernanceMessageUsed(bytes32 digest) public view returns (bool) {
        return getState().usedGovernanceMessages[digest];
    }

    function isBridgeMessageUsed(bytes32 digest) public view returns (bool) {
        return getState().usedBridgeMessages[digest];
    }

    function sequence() external view returns (uint64) {
        return getState().sequence;
    }

    function hubChainId() public view returns (uint16) {
        return getState().hubChainId;
    }

    function authoritiesLength() public view returns (uint256) {
        return getState().authorities.length;
    }

    function getAuthority(uint256 index) public view returns (address) {
        return getState().authorities[index];
    }

    function governanceContract() public view returns (bytes32) {
        return getState().governanceContract;
    }
}