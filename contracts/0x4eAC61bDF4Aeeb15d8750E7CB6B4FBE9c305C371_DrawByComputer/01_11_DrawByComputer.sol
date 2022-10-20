//Draw by Computer, Jonathan Chomko, 2022
// Created for the Herbert W. Franke Tribute. Released Oct 21, 2022. 
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */

contract DrawByComputer is Context, ERC721, Ownable {

    //withdrawal logic
    address payable public withdrawalAddress;

    //Token sale control logic
    uint256 public maxNumberOfPieces;
    uint256 public tokenCounter;
    uint256 public minTokenIdForSale;
    uint256 public maxTokenIdForSale;

    //Sale logic
    bool public standardSaleActive;
    uint256 public pricePerPiece;

    //Token Data
    struct tokenData {
        uint256[] startPoints;
        uint256  totalPoints;
        string[] xAnimationPoints;
        string[] yAnimationPoints;  
    }

    mapping (uint256 => tokenData) public tokenDataMap;
    event Mint(address buyer, uint256 price, uint256 tokenId);

    constructor(
        address payable givenWithdrawalAddress

    ) ERC721("Draw by Computer", "DBC") {
        withdrawalAddress = givenWithdrawalAddress;
        tokenCounter = 0;
        maxTokenIdForSale = 0;
        minTokenIdForSale = 1;
    }

    //Generate svg
    function tokenURI(uint256 tokenId) override public view returns (string memory){

            require(_exists(tokenId)  || msg.sender == owner(), "ERC721Metadata: URI query for nonexistent token");
            string[20] memory parts;
            parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidYMid meet" viewBox="0 0 1000 1000">   <rect width="1000" height="1000" fill="white"></rect>';
            uint256 index = 1;
            
            for(uint256 i = 0; i < tokenDataMap[tokenId].totalPoints; i ++){
                string [10] memory points;
                points[0] = '<circle cx="';
                points[1] = toString(tokenDataMap[tokenId].startPoints[i] );
                points[2] = '" cy="';
                points[3] = toString(tokenDataMap[tokenId].startPoints[i+1 % tokenDataMap[tokenId].startPoints.length]);
                points[4] = '" r="50"  fill="black">';
                points[5] = '<animate calcMode="paced" attributeName="cx" values="';
                points[6] = tokenDataMap[tokenId].xAnimationPoints[i];
                points[7] = '" dur="60s" repeatCount="indefinite"/> <animate calcMode="paced" attributeName="cy" values="';
                points[8] = tokenDataMap[tokenId].yAnimationPoints[i];
                points[9] = '" dur="60s" repeatCount="indefinite"/> </circle>';

                string memory pointOutput;
                pointOutput = string(abi.encodePacked(points[0], points[1], points[2], points[3], points[4], points[5], points[6], points[7], points[8], points[9]));
                
                parts[index] = pointOutput;
                index += 1;
            }

            parts[index] = '</svg>';
            index += 1;

            string memory output;
            for(uint256 i = 0; i < index; i ++){
              output = string(abi.encodePacked(output, parts[i]));
            }

            string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Draw by Computer ', toString(tokenId+1), '", "description": "Geometric primitives drawn by hand on a computer. Jonathan Chomko, 2022", "image": "data:image/svg+xml;base64,',Base64.encode(bytes(output)),'"}'))));
            output = string(abi.encodePacked('data:application/json;base64,', json));
            return output;
    }

    function setSaleActive(bool isActive) external onlyOwner {
        standardSaleActive = isActive;
    }

    function setSaleRange(uint256 givenMinTokenIdForSale, uint256 givenMaxTokenIdForSale) external onlyOwner {
         maxTokenIdForSale = givenMaxTokenIdForSale;
         minTokenIdForSale = givenMinTokenIdForSale;
    }

    function setPrice(uint256 givenPrice) external onlyOwner {
        pricePerPiece = givenPrice;
    }

    //Set data for token svgs and titles
    function setTokenData(tokenData[] memory givenData )external onlyOwner {
        for(uint256 i = 0; i < givenData.length; i ++){
                     tokenDataMap[i] = givenData[i];
        }
    }

    //Withdrawal
    function setWithdrawalAddress(address payable givenWithdrawalAddress) external onlyOwner {
        withdrawalAddress = givenWithdrawalAddress;
    }

    function withdrawEth() external onlyOwner {
        Address.sendValue(withdrawalAddress, address(this).balance);
    }

    //Owner info
    function tokenInfo(uint256 tokenId) external view returns (address) {
        return (ownerOf(tokenId));
    }

    function getOwners(uint256 start, uint256 end) public view returns (address[] memory){
        address[] memory re = new address[](end - start);
        for (uint256 i = start; i < end; i++) {
                re[i - start] = ownerOf(i);
        }
        return re;
    }

    function mintItem(uint256 givenTokenId) public payable returns (uint256) {
        require(givenTokenId <= maxTokenIdForSale || msg.sender == owner(), "given token value is greater than sale limit");
        require(givenTokenId >= minTokenIdForSale || msg.sender == owner(), "given token value is less than sale limit");
        require(standardSaleActive || msg.sender == owner(), "sale must be active");
        require(msg.value == pricePerPiece, "must send in correct amount");

        _safeMint(msg.sender, givenTokenId);

        tokenCounter += 1;
        emit Mint(msg.sender, msg.value, givenTokenId);
        return tokenCounter;
    }

    //Helpers
    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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