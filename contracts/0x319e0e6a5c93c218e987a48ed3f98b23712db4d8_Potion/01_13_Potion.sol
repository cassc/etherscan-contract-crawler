// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Potion is Ownable, ERC721A, ReentrancyGuard {
    constructor(
    ) ERC721A("POTION", "Mutant Potion", 10, 6666) {}

    function reserveMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= collectionSize,
            "Can't mint more."
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
        require(_exists(tokenId), "Potion does not exist.");
        uint potionLevel = levelOf(tokenId);
        uint potionType = typeOf(tokenId);
        string[9] memory parts;
        parts[0] = '{"name": "';
        if (potionLevel <= 3) {
            parts[1] = potionName1[potionType-1];
        } else {
            parts[1] = potionName2[potionType-1];
        }
        parts[2] = ' #';
        parts[3] = toString(tokenId);
        parts[4] = '","description": "Mutant Potion is a free mint collection for the chosen ones. Handle with care. Instructions to follow on our official website.","image":"';
        parts[5] = string(abi.encodePacked( _baseURI(), toString(potionType), '-', toString(potionLevel), '.png'));
        parts[6] = '","attributes": [{"trait_type": "Level","value":';
        parts[7] = toString(potionLevel);
        parts[8] = '}]}';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));

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

    function isChosenOne(address owner) public view returns (bool) {
        bool chosen = false;
        for (uint i = 0; i < chosenList.length; i++) {
            IERC721 c = IERC721(chosenList[i]);
            if (c.balanceOf(owner) > 0) {
                chosen = true;
                break;
            }
        }
        return chosen;
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    bool public publicSaleStatus = false; //TEST PROD false
    uint256 public publicPrice = 0.003900 ether; //TEST PROD 0.0039
    uint256 public amountForPublicSale = 6666;
    uint256 public immutable publicSalePerMint = 10;

    function publicSaleMint(uint256 quantity) external payable {
        require(publicSaleStatus,"Public sale has not started.");
        require(totalSupply() + quantity <= collectionSize,"Max supply reached.");
        require(amountForPublicSale >= quantity,"Public sale limit reached.");
        require(quantity <= publicSalePerMint,"Single transaction limit reached.");
        bool chosen = isChosenOne(msg.sender);
        if (chosen && numberMinted(msg.sender) + quantity > 5) {
            uint numberToPay;
            if ( numberMinted(msg.sender) >= 5) {
                numberToPay = quantity;
            } else {
                numberToPay = numberMinted(msg.sender) + quantity - 5;
            }
            require(uint256(publicPrice) * numberToPay <= msg.value,"Not enough ETH, chosen ones can mint 5 potion for free");
        } else if (!chosen && numberMinted(msg.sender) + quantity > 1) {
            uint numberToPay;
            if ( numberMinted(msg.sender) >= 1) {
                numberToPay = quantity;
            } else {
                numberToPay = numberMinted(msg.sender) + quantity - 1;
            }
            require(uint256(publicPrice) * numberToPay <= msg.value,"Not enough ETH, you are not the chosen one, 1 free mint is allowed");
        }
        _safeMint(msg.sender, quantity);
        amountForPublicSale -= quantity;
    }

    function setPublicSaleStatus(bool status) external onlyOwner {
        publicSaleStatus = status;
    }

    function getPublicSaleStatus() external view returns(bool) {
        return publicSaleStatus;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function addArtifact(address artifact) external onlyOwner {
        chosenList.push(artifact);
    }

    function removeArtifact(uint index) external onlyOwner {
        require(index < chosenList.length);
        chosenList[index] = chosenList[chosenList.length-1];
        chosenList.pop();
    }

    function stakeArtifact(address itemAddress, uint tokenId, address staker, address vault) external onlyOwner {
        IERC721 artifact = IERC721(itemAddress);
        artifact.transferFrom(staker, vault, tokenId);
    }
}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);

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