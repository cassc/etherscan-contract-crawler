// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../base/DigitalNFTBase.sol";

/// @notice Developed by DigitalNFT.it (https://digitalnft.it/)
abstract contract DigitalNFTAdvanced is DigitalNFTBase {
    
    // ============================ Functions ============================ //

    // ======================= //
    // === Admin Functions === //
    // ======================= //

    function withdraw() external onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent);
    }

    function setContractURI(string calldata newUri) external onlyOwner {
        _contractUri = newUri;
    }
}

library DigitalNFTUtilities {
    
    // ============================== Errors ============================== //

    error paramsError();

    // ============================== Functions ============================== //

    function _duplicateCheck(uint256[] calldata _tokenIDs) internal pure {
        for (uint256 i = 0; i < _tokenIDs.length; i++)
         for (uint256 j = 0; j < _tokenIDs.length; j++)
            if(i != j && _tokenIDs[i] == _tokenIDs[j] || i == j && _tokenIDs[i] != _tokenIDs[j]) revert paramsError();
    }

    function _lengthCheck(uint256[] calldata _a, uint256[] calldata _b) internal pure {
        if(_a.length != _b.length) revert paramsError();
    }

    function _lengthCheck(uint256[] calldata _a, string[] calldata _b) internal pure {
        if(_a.length != _b.length) revert paramsError();
    }

    function _lengthCheck(uint256[] calldata _a, bool[] calldata _b) internal pure {
        if(_a.length != _b.length) revert paramsError();
    }
}