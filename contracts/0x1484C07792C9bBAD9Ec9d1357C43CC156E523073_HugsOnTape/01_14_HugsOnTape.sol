// SPDX-License-Identifier: MIT

 /*/////////////////////////////////////////////////////////////////////////////////////////////////////////////
 __  __     __  __     ______     ______        ______     __   __        ______   ______     ______   ______    
/\ \_\ \   /\ \/\ \   /\  ___\   /\  ___\      /\  __ \   /\ "-.\ \      /\__  _\ /\  __ \   /\  == \ /\  ___\   
\ \  __ \  \ \ \_\ \  \ \ \__ \  \ \___  \     \ \ \/\ \  \ \ \-.  \     \/_/\ \/ \ \  __ \  \ \  _-/ \ \  __\   
 \ \_\ \_\  \ \_____\  \ \_____\  \/\_____\     \ \_____\  \ \_\\"\_\       \ \_\  \ \_\ \_\  \ \_\    \ \_____\ 
  \/_/\/_/   \/_____/   \/_____/   \/_____/      \/_____/   \/_/ \/_/        \/_/   \/_/\/_/   \/_/     \/_____/ 
*//////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                                                                                 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract HugsOnTape is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Hugs on Tape by LoVid", "HOT") {}

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function changeTokenURI(uint256 _tokenId, string memory uri) public onlyOwner {
        require(_exists(_tokenId), 'ERC721Metadata: nonexistent token');
        _setTokenURI(_tokenId, uri);
    }
}