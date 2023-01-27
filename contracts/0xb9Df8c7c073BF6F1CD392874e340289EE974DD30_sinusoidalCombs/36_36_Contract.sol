// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721Drop.sol";

contract sinusoidalCombs is ERC721Drop {
    // Store the script that generates the art from a hash
	  string public script;

    function setScript(string calldata _script) onlyOwner public {
        script = _script;
    }

    // mapping from tokenId to associated hash value
    mapping(uint256 => bytes32) public tokenToHash;

    // mapping of hash to tokenId
    mapping(bytes32 => uint256) public hashToToken;

    // Generative NFT logic
    function _mintGenerative(address _to, uint256 _startTokenId, uint256 _qty) internal virtual {
      for(uint256 i = 0; i < _qty; i += 1) {
          uint256 _id = _startTokenId + i;
	  			// generate hash
          bytes32 mintHash = keccak256(abi.encodePacked(_id, blockhash(block.number - 1), _to));
	  			// save hash in mappings
          tokenToHash[_id] = mintHash;
          hashToToken[mintHash] = _id;
      }
    }

    function _transferTokensOnClaim(address _to, uint256 _quantityBeingClaimed)
      internal
      virtual
      override
      returns (uint256 startTokenId)
    {
        startTokenId = _currentIndex;
	      // Call our mintGenerative function here!
        _mintGenerative(_to, startTokenId, _quantityBeingClaimed);
        _safeMint(_to, _quantityBeingClaimed);
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient,
				string memory _script
    )
      ERC721Drop(
        _name,
        _symbol,
        _royaltyRecipient,
        _royaltyBps,
        _primarySaleRecipient
      )
    {
				script = _script;
		}
}