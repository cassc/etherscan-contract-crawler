pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { MockBrandCentral } from "./MockBrandCentral.sol";

/// @notice The Brand NFT of a tokenised KNOT community
contract MockBrandNFT is ERC721Upgradeable {
    /// @notice lowercase brand ticker -> minted token ID
    mapping(string => uint256) public lowercaseBrandTickerToTokenId;
    mapping(uint256 => string) public nftDescription;
    mapping(uint256 => string) public nftImageURI;

    /// @notice total brand NFTs minted
    uint256 public totalSupply;

    MockBrandCentral public brandCentral;

    constructor() {
        brandCentral = new MockBrandCentral();
    }

    function mint(
        string calldata _ticker,
        bytes calldata,
        address _recipient
    ) external returns (uint256) {
        require(
            bytes(_ticker).length >= 3 && bytes(_ticker).length <= 5,
            "Name must be between 3 and 5 characters"
        );

        string memory lowerCaseBrandTicker = toLowerCase(_ticker);
        require(
            lowercaseBrandTickerToTokenId[lowerCaseBrandTicker] == 0,
            "Brand name already exists"
        );

        unchecked {
            // unlikely to exceed ( (2 ^ 256) - 1 )
            totalSupply += 1;
        }

        lowercaseBrandTickerToTokenId[lowerCaseBrandTicker] = totalSupply;

        _mint(_recipient, totalSupply);

        return totalSupply;
    }

    /// @notice Converts a string to its lowercase equivalent
    /// @dev Only 26 chars from the English alphabet
    /// @param _base String to convert
    /// @return string Lowercase version of string supplied
    function toLowerCase(string memory _base)
        public
        pure
        returns (string memory)
    {
        bytes memory bStr = bytes(_base);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i; i < bStr.length; ++i) {
            if ((bStr[i] >= 0x41) && (bStr[i] <= 0x5A)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            }
        }
        return string(bLower);
    }

    function setBrandMetadata(
        uint256 _tokenId,
        string memory _description,
        string memory _imageURI
    ) external {
        require(_tokenId > 0 && _tokenId <= totalSupply, "invalid token ID");
        nftDescription[_tokenId] = _description;
        nftImageURI[_tokenId] = _imageURI;
    }
}