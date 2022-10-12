// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Planet is Ownable, ERC721A, ReentrancyGuard {
    uint public maxSupply = 3666;
    constructor(
    ) ERC721A("PLANET", "Merging Galaxy", 1, maxSupply) {}

    function reserveMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= collectionSize,
            "too many already minted before dev mint"
        );
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
        if (quantity % maxBatchSize != 0){
            _safeMint(msg.sender, quantity % maxBatchSize);
        }
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "This planet does not exist.");

        string[7] memory parts;
        if (bytes(nameOf(tokenId)).length == 0) {
            parts[0] = '{"name": "Planet #';
        } else {
            parts[0] = string(abi.encodePacked( '{"name": "', nameOf(tokenId) ,' #' ));
        }
        parts[1] = toString(tokenId);
        parts[2] = '","description": "Merging Galaxy is a space of extinction.","image":"';
        if (levelOf(tokenId) == 0){
            parts[3] = string(abi.encodePacked( _baseURI(), toString(typeOf(tokenId)),'-', toString(levelOf(tokenId)), '-', toString(tokenId%3+1), '.gif'));
        } else {
            parts[3] = string(abi.encodePacked( _baseURI(), toString(typeOf(tokenId)),'-', toString(levelOf(tokenId)), '.gif'));
        }
        parts[4] = '","attributes": [{"display_type": "number","trait_type": "Level","value":';
        parts[5] = toString(levelOf(tokenId));
        parts[6] = string(abi.encodePacked('},{"display_type": "number", "trait_type": "Mass", "value": ',toString(sizeOf(tokenId)),'}]}'));

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));

        string memory json = Base64.encode(bytes(output));
    
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    //PUBLIC SALE
    bool public publicSaleStatus = false;
    // uint256 public publicPrice = 0.003000 ether;
    uint256 public amountForPublicSale = maxSupply;
    // per mint public sale limitation
    uint256 public immutable publicSalePerMint = 1;

    function publicSaleMint(uint256 quantity) external payable {
        require(
        publicSaleStatus,
        "Public sale has not started."
        );
        require(
        totalSupply() + quantity <= collectionSize,
        "Max supply reached."
        );
        require(
        amountForPublicSale >= quantity,
        "Public sale limit reached."
        );

        require(
        quantity <= publicSalePerMint,
        "Single transaction limit reached."
        );

        _safeMint(msg.sender, quantity);
        amountForPublicSale -= quantity;
    }

    function togglePublicSaleStatus() external onlyOwner {
        publicSaleStatus = !publicSaleStatus;
    }

    function getPublicSaleStatus() external view returns(bool) {
        return publicSaleStatus;
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}