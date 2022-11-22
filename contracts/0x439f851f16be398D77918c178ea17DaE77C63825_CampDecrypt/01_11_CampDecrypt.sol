// SPDX-License-Identifier: MIT

// This contract is used for the Camp Decrypt NFT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CampDecrypt is ERC721, Ownable {
    /*///////////////////////////////////////////////////////////////
                            TOKEN STORAGE
    //////////////////////////////////////////////////////////////*/
    uint256 public totalSupply;
    string public _tokenUri;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    /*///////////////////////////////////////////////////////////////
                            TOKEN LOGIC
    //////////////////////////////////////////////////////////////*/

    function mint(address to) external onlyOwner {
        unchecked {
            ++totalSupply;
        }
        _safeMint(_msgSender(), totalSupply);
    }

    /*///////////////////////////////////////////////////////////////
                             UTILS
    //////////////////////////////////////////////////////////////*/

    function setTokenURI(string calldata newTokenUri) external onlyOwner {
        _tokenUri = newTokenUri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return _tokenUri;
    }
}