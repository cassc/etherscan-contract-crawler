// contracts/TeaVaultV2Deployer.sol
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./TeaVaultV2.sol";

contract TeaVaultV2Deployer {

    event TeaVaultV2Deployed(address indexed sender, address contractAddr, bytes32 salt);

    function deploy(bytes32 salt) external returns (address) {
        TeaVaultV2 teavault = new TeaVaultV2{salt: salt}(msg.sender);
        emit TeaVaultV2Deployed(msg.sender, address(teavault), salt);
        return address(teavault);
    }

    function predictedAddress(bytes32 salt) external view returns (address) {
        address result = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(type(TeaVaultV2).creationCode, abi.encode(msg.sender)))
        )))));
        return result;
    }
}