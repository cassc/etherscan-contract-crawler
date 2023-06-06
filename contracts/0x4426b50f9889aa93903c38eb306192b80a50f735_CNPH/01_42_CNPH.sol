// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./MultiPhaseERC721Drop.sol";

contract CNPH is MultiPhaseERC721Drop {
    using TWStrings for uint256;

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient
    )
        MultiPhaseERC721Drop(_name, _symbol, _royaltyRecipient, _royaltyBps, _primarySaleRecipient)
    {
        nextTokenIdToLazyMint = _startTokenId();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        (uint256 batchId, ) = _getBatchId(_tokenId);
        string memory batchUri = _getBaseURI(_tokenId);

        if (isEncryptedBatch(batchId)) {
            return string(abi.encodePacked(batchUri, "0", ".json"));
        } else {
            return string(abi.encodePacked(batchUri, _tokenId.toString(), ".json"));
        }
    }
}