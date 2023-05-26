//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./utils/ECDSA.sol";
import "./ChainIdValidators.sol";

contract Validators is ChainIdValidators {
    using ECDSA for bytes32;

    address[] public bridgeValidators;

    function addBridgeValidator(address _validator) external onlyOwner {
        (bool found,) = indexOfBridgeValidator(_validator);
        require(!found, 'Validator already added');
        bridgeValidators.push(_validator);
    }

    function removeBridgeValidator(address _validator) external onlyOwner {
        (bool found, uint index) = indexOfBridgeValidator(_validator);
        require(found, 'Validator not found');
        if (bridgeValidators.length > 1) {
            bridgeValidators[index] = bridgeValidators[bridgeValidators.length - 1];
        }
        bridgeValidators.pop();
    }

    function getListBridgeValidators() public view returns (address[] memory) {
        return bridgeValidators;
    }

    function indexOfBridgeValidator(address _validator) public view returns (bool found, uint index) {
        for (uint i = 0; i < bridgeValidators.length; i++) {
            if (bridgeValidators[i] == _validator) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function checkSignatures(bytes32 _messageHash, bytes[] memory _signatures) public view returns (bool) {
        require(bridgeValidators.length > 0, 'Validators not added');
        require(_signatures.length == bridgeValidators.length, 'The number of signatures does not match the number of validators');
        bool[] memory markedValidators = new bool[](bridgeValidators.length);
        for (uint i = 0; i < _signatures.length; i++) {
            address extractedAddress = _messageHash.toEthSignedMessageHash().recover(_signatures[i]);
            (bool found, uint index) = indexOfBridgeValidator(extractedAddress);
            if (found && !markedValidators[index]) {
                markedValidators[index] = true;
            } else {
                return false;
            }
        }
        return true;
    }
}