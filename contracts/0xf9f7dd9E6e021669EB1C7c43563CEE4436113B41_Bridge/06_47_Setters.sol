//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./State.sol";

/// @title State mutators.
/// @notice This contract encapsulates access to the State.getState() method. It's not enforced, since that method is internal.
/// It is a good practice though, to keep the getState() usage limited to this, and the Getter contracts.
/// @author Piotr "pibu" Buda
contract Setters is State {
    /// @notice use this method to change authorities of the contract
    /// @param newAuthorities authorities to set
    function setAuthorities(address[] memory newAuthorities) internal {
        getState().authorities = newAuthorities;
    }

    ///@notice marks a governance message as used so that it cannot be reused
    /// @param digest the keccak256 of the Structs.VSM message
    function useGovernanceMessage(bytes32 digest) internal {
        getState().usedGovernanceMessages[digest] = true;
    }

    ///@notice marks a bridge message as used so that it cannot be reused
    /// @param digest the keccak256 of the Structs.VSM message
    function useBridgeMessage(bytes32 digest) internal {
        getState().usedBridgeMessages[digest] = true;
    }

    /// @notice provides a sequence number for the next message. After returning it, the sequence number is updated.
    /// @return seq the current value of the sequence number
    function useSequence() internal returns (uint64 seq) {
        seq = getState().sequence;
        getState().sequence += 1;
    }

    function setChainId(uint16 chainId) internal {
        getState().chainId = chainId;
    }

    function setHubChainId(uint16 hubChainId) internal {
        getState().hubChainId = hubChainId;
    }

    function setGovernanceContract(bytes32 governanceContract) internal {
        getState().governanceContract = governanceContract;
    }

    function setTokenBridge(Structs.TokenBridge memory tokenBridge, TokenType tokenType) internal {
        bytes32 collectionId = keccak256(tokenBridge.tokenClassKey);
        getState().bridges[collectionId] = tokenBridge;
        getState().tokenTypes[tokenBridge.token] = tokenType;
        getState().reverseBridges[tokenBridge.token][tokenBridge.baseType] = collectionId;
    }

    function setConversionFunnel(
        address token,
        uint256 baseType,
        bytes memory tokenClassKey,
        TokenType tokenType
    ) internal {
        getState().reverseBridges[token][baseType] = keccak256(tokenClassKey);
        getState().tokenTypes[token] = tokenType;
    }

    function setEnabled(bytes memory tokenClassKey, bool enabled) internal {
        getState().bridges[keccak256(tokenClassKey)].enabled = enabled;
    }
}