// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {IProtectionPlanFactory} from "./interfaces/IProtectionPlanFactory.sol";
import {IProtocolRegistry} from "./interfaces/IProtocolRegistry.sol";
import {IProtectionPlan} from "./interfaces/IProtectionPlan.sol";


import "./ProtectionPlanFactoryStorage.sol";

contract ProtectionPlanFactory is ProtectionPlanFactoryStorage, IProtectionPlanFactory, Ownable {
    using ECDSA for bytes32;

    event ProtectionPlanCreated (
        address walletAddress,
        address protectionPlanAddress,
        uint256 dateCreated
    );

    constructor(address _protocolDirectoryAddr) {
      protocolDirectoryAddr = _protocolDirectoryAddr;
    }

    function setProtocolDirectory(address _protocolDirectoryAddr) external onlyOwner {
         protocolDirectoryAddr = _protocolDirectoryAddr;
    }

    function createNewProtectionPlan(uint256 _nonce, uint256 _deadline, bytes memory _signature) external {
        if(userProtectionPlan[msg.sender] != address(0)) revert ProtectionPlanExistsForUser();
        address signer = IProtocolRegistry(protocolDirectoryAddr).getSignerAddress();
        bytes32 messageHash = keccak256(abi.encode(msg.sender, _nonce, _deadline)).toEthSignedMessageHash();
        if(!SignatureChecker.isValidSignatureNow(signer, messageHash, _signature)) revert InvalidSignature();
        if(_nonces[msg.sender][_nonce]) revert NonceAlreadyUsed();
        if(block.timestamp > _deadline) revert DeadlineExceeded();
        _nonces[msg.sender][_nonce] = true;

        BeaconProxy beaconProxy = new BeaconProxy(IProtocolRegistry(protocolDirectoryAddr).getUpgradeableAddress(), abi.encodeWithSelector(IProtectionPlan.initialize.selector, msg.sender, protocolDirectoryAddr));
        userProtectionPlan[msg.sender] = address(beaconProxy);
        emit ProtectionPlanCreated(msg.sender, address(beaconProxy), block.timestamp);
    }



}