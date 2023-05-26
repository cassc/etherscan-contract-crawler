//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

abstract contract BaseERC721A is Ownable, ERC721A {
    using SafeMath for uint256;

    function _baseMint(uint256 quantity) internal {
        // mint the token
        _baseMint(msg.sender, quantity);
    }

    function _baseMint(address _address, uint256 quantity) internal {
        // mint the token to target address
        if ( quantity > 4) {
            for (uint256 i = 0; i < quantity; i++) {
                _safeMint(_address, 1);
            }
        } else {
             _safeMint(_address, quantity);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }
}