// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721Drop.sol";

contract Contract is ERC721Drop {
    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient
    )
        ERC721Drop(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _primarySaleRecipient
        )
    {}
    
    function awakening(uint256 _tokenId, string memory updateURI) public virtual returns (string memory) {
        require(_canReveal(), "Not authorized");
        string memory tokenURI = tokenURI(_tokenId);
        uint256 batchId = getBatchIdAtIndex(_tokenId);
        _setBaseURI(batchId, updateURI);
        return tokenURI;
    }
}