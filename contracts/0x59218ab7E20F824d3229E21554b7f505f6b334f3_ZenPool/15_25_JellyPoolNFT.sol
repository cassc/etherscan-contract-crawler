pragma solidity 0.8.6;

import "ERC721SemiNumerable.sol";
import "Counters.sol";


contract JellyPoolNFT is ERC721SemiNumerable {
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIdTracker;

    constructor() ERC721("JellyPool NFT","JPOOL") {

    }

    function _safeMint(address _user) internal returns (uint256){
        uint256 _tokenId = _tokenIdTracker.current();
        _safeMint(_user, _tokenId);
        _tokenIdTracker.increment();
        return _tokenId;
    }

}