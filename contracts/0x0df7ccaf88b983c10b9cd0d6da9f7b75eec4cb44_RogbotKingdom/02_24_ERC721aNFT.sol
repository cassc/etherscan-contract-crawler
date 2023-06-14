//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../erc721aV3/ERC721A.sol";
import "../erc721aV3/extensions/ERC721ABurnable.sol";
import "../erc721aV3/extensions/ERC721AQueryable.sol";

abstract contract ERC721aNFT is Ownable, ERC721A, ERC721ABurnable, ERC721AQueryable {
    using SafeMath for uint256;
    string internal _baseTokenURI;

    function _baseMint(uint256 quantity) internal {
        // mint the token
        _baseMint(msg.sender, quantity);
    }

    function _baseMint(address _address, uint256 quantity) internal {
        _safeMint(_address, quantity);
    }
     
    function tokenURI(uint256 tokenId)
        public
        view
        override (ERC721A, IERC721Metadata)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

         
        return
            bytes(_baseTokenURI).length > 0
                ? string(
                    abi.encodePacked(
                        _baseTokenURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function updateTokenURI(string memory _tokenURI) external onlyOwner {
        _baseTokenURI = _tokenURI;
    }


}