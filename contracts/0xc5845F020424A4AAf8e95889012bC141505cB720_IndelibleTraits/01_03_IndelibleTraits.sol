// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";
import "./interfaces/IIndelible.sol";

contract IndelibleTraits { 
    function getTrait(address contractAddress, uint8 layerIndex, uint8 traitIndex) public view returns(string memory) {
        IIndelible.Trait memory traitDetails = IIndelible(contractAddress).traitDetails(layerIndex, traitIndex);
        string memory dataType = string.concat('data:',traitDetails.mimetype,';base64,');
        return string.concat(dataType,Base64.encode(bytes(IIndelible(contractAddress).traitData(layerIndex, traitIndex))));
    }
}