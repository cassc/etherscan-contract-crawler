// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;
import "./HasRegistration.sol";

contract IsSerializedUpgradable is HasRegistration {
    bool internal serialized;
    bool internal hasSerialized;
    bool internal overloadSerial;
    uint256 serialCount;
    mapping(uint256 => uint256[]) internal tokenIdToSerials;
    mapping(uint256 => uint256) internal serialToTokenId;
    mapping(uint256 => address) internal serialToOwner;
    event TransferSerial(address indexed from, address indexed to, uint256 serial);
    
}