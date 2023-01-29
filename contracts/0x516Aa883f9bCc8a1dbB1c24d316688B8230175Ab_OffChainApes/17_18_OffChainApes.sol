// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Verifier.sol";
import "./Base64.sol";

pragma solidity ^0.8.17;

error OffChainApes__TransferFailed();

contract OffChainApes is ERC721, ERC2981, Verifier {
    using Strings for uint256;

    uint256 internal constant MAX_SUPPLY = 10000;

    constructor(bytes32 _root) ERC721("OffChainApes", "OFFCA") Verifier(_root) {
        _setDefaultRoyalty(msg.sender, 1000);
    }

    mapping(address => uint256) internal amountMinted;
    mapping(uint256 => string) internal idToIpfs;
    mapping(uint256 => string) internal idToColor;

    bool internal isMintOpen = false;
    uint256 internal currentSupply = 0;

    function mint(
        bytes32[] memory proof,
        string memory imageIpfs,
        uint256 tokenId,
        string memory color
    ) external {
        require(currentSupply < MAX_SUPPLY, "All tokens have been minted");
        // Make sure mint is open
        require(isMintOpen, "Mint is not open");
        // Make sure the tokenId + imageIpfs + color are valid
        verify(proof, imageIpfs, tokenId, color);
        // Make sure the minter has not minted 10 tokens already
        require(amountMinted[msg.sender] < 10, "User has already minted the maximum amount");
        // Make sure the minter is not a contract
        require(msg.sender == tx.origin, "No contracts allowed");

        // Increase amount minted by sender
        amountMinted[msg.sender] += 1;
        // Update the IPFS string for the minted tokenId
        idToIpfs[tokenId] = imageIpfs;
        // Update the Color string for the minted tokenId
        idToColor[tokenId] = color;
        // Update current supply
        currentSupply++;
        // Mint the token
        _mint(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        string[6] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: black; font-family: monospace; font-size: 10px; }</style><rect width="100%" height="100%" fill="#';

        parts[1] = idToColor[tokenId];

        parts[2] = '" /><text text-anchor="end" x="347" y="347" class="base">';

        parts[3] = "ipfs://";

        parts[4] = idToIpfs[tokenId];

        parts[5] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5])
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "OffChainApe #',
                        tokenId.toString(),
                        '", "description": "This NFT is part of a collection of 10,000 created by Verdomi. The collection serves as an artistic expression on the lack of on-chain storage for most NFT artwork. There is a 10% royalty on the collection.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

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

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function toggleMint() external onlyOwner {
        isMintOpen = !isMintOpen;
    }

    function totalSupply() external view returns (uint256) {
        return currentSupply;
    }

    function isMinted(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function getImageIpfs(uint256 tokenId) external view returns (string memory) {
        return idToIpfs[tokenId];
    }

    function getBackgroundColor(uint256 tokenId) external view returns (string memory) {
        return idToColor[tokenId];
    }

    function getAmountMinted(address wallet) external view returns (uint256) {
        return amountMinted[wallet];
    }

    function maxSupply() external pure returns (uint256) {
        return MAX_SUPPLY;
    }

    function findUnminted() external view returns (uint256) {
        for (uint256 i = 0; i < MAX_SUPPLY; i++) {
            if (!isMinted(i)) {
                return i;
            }
        }
        return 0;
    }
}