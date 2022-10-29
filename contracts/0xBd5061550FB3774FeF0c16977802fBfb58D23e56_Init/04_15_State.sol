//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./Structs.sol";

/// @title Base state contract
/// @notice This is a base contract for storing state. It has to be upgrade-safe so it uses an assignable slot for state storage.
/// Based on https://medium.com/1milliondevs/new-storage-layout-for-proxy-contracts-and-diamonds-98d01d0eadb.
/// @author Piotr "pibu" Buda
contract State is PausableUpgradeable, OwnableUpgradeable {
    uint256 constant DEFAULT_TOKEN_BASE_TYPE = 0;

    //bytes32 is used as ids for collections and base types
    struct BridgeState {
        //keccak256(tokenClassKey) => TokenBridge
        mapping(bytes32 => Structs.TokenBridge) bridges;
        //token contract => TokenType
        mapping(address => TokenType) tokenTypes;
        //token contract => base type => keccak256(tokenClassKey)
        mapping(address => mapping(uint256 => bytes32)) reverseBridges;
        //keccak256(VSM) => bool
        mapping(bytes32 => bool) usedGovernanceMessages;
        //keccak256(VSM) => bool
        mapping(bytes32 => bool) usedBridgeMessages;
        //this bridge's chain id
        uint16 chainId;
        //chain id of the hub
        uint16 hubChainId;
        //id of the governance contract
        bytes32 governanceContract;
        //sequence number for BridgeMessage to use
        uint64 sequence;
        //current set of signing authority
        address[] authorities;
    }

    /// @notice This method allows to retrieve the Bridge's state by using an assignable storage slot.
    /// @return ms the Bridge's state represented by the BridgeState struct
    function getState() internal pure returns (BridgeState storage ms) {
        assembly {
            //keccak256("gala.bridge.storage")
            ms.slot := 0x07b26557da28ba49062e0328822024c4af75c9bcd1fcb0d96f1702cfe37e7d70
        }
    }
}