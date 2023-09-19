// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CustomNFT is ERC721, Ownable {
    uint256 public constant MAX_TOKENS = 8888;
    uint256 public constant MAX_TOKENS_GRANDMASTER = 9999;
    uint256 public currentTokenId = 0;
    string public grandmasterIpfs;
    string public baseIpfs;
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant TABLE_DECODE =
        hex"0000000000000000000000000000000000000000000000000000000000000000"
        hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
        hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
        hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    struct TokenMetadata {
        bool useCustomMetadata;
        string customSVG;
        string metadata;
        uint256 step;
    }


    mapping(uint256 => TokenMetadata) private tokenMetadata;

    constructor() ERC721("Braindead Buddies m1", "BDB") {
        baseIpfs = "QmSutM8kqCxcNkvP8xQsgvjrfoFe87D6WWtZtG1ELnhtbt/";
        _transferOwnership(0xA7D1f2A9C0D09a5493886f715F137A19331b3fa8);
    }

    function mintBatch(uint256 batchSize) external onlyOwner {
        require((currentTokenId + batchSize) <= MAX_TOKENS_GRANDMASTER, "Minting would exceed max token limit.");
        require(!(currentTokenId == MAX_TOKENS && bytes(grandmasterIpfs).length == 0), "Max regular tokens reached, should switch to Grandmaster.");

        if (bytes(grandmasterIpfs).length > 0 && currentTokenId >= MAX_TOKENS) {
            for (uint256 i = 0; i < batchSize; i++) {
                if (currentTokenId < MAX_TOKENS_GRANDMASTER) {
                    _mint(msg.sender, currentTokenId);
                    currentTokenId++;
                } else {
                    break;
                }
            }
        } else {
            for (uint256 i = 0; i < batchSize; i++) {
                if (currentTokenId < MAX_TOKENS) {
                    _mint(msg.sender, currentTokenId);
                    currentTokenId++;
                } else {
                    break;
                }
            }
        }
    }

    function setGrandmasterHash(string memory _hash) external onlyOwner {
        require(bytes(grandmasterIpfs).length == 0, "Grandmaster hash can only be set once.");
        grandmasterIpfs = string(abi.encodePacked(_hash, "/"));
    }

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {} {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
                case 1 {
                    mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
                }
                case 2 {
                    mstore(sub(resultPtr, 1), shl(248, 0x3d))
                }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {} {
                // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                        shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFFFF))
                    ),
                    add(
                        shl(6, and(mload(add(tablePtr, and(shr(8, input), 0xFF))), 0xFF)),
                        and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token.");

        if (tokenMetadata[_tokenId].useCustomMetadata) {
            string memory json = encode(bytes(string(abi.encodePacked(
                tokenMetadata[_tokenId].metadata,
                ', "image_data": "',
                getSvg(_tokenId),
                '"}'
            ))));
            return string(abi.encodePacked("data:application/json;base64,", json));
        }

        string memory tokenIdString = uint256ToString(_tokenId);

        if (bytes(grandmasterIpfs).length > 0 && _tokenId >= MAX_TOKENS) {
            return string(abi.encodePacked("ipfs://", grandmasterIpfs, tokenIdString, ".json"));
        }

        return string(abi.encodePacked("ipfs://", baseIpfs, tokenIdString, ".json"));
    }

    function getSvg(uint256 _tokenId) private view returns (string memory) {
        return tokenMetadata[_tokenId].customSVG;
    }

    function checkTokenStatus(uint256 _tokenId) public view returns (
        bool isMetadataSet,
        bool isToggled,
        uint256 svgStep
    ) {
        require(_exists(_tokenId), "Token has not been minted yet.");
        TokenMetadata storage tm = tokenMetadata[_tokenId];

        isMetadataSet = bytes(tm.metadata).length > 0;
        isToggled = tm.useCustomMetadata;
        svgStep = tm.step;

        return (isMetadataSet, isToggled, svgStep);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        if (currentTokenId < MAX_TOKENS) {
            return string(abi.encodePacked('https://ipfs.io/ipfs/', baseIpfs));
        } else {
            return string(abi.encodePacked('https://ipfs.io/ipfs/', grandmasterIpfs));
        }
    }

    function _concatenate(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function uint256ToString(uint256 number) internal pure returns (string memory) {
        if (number == 0) {
            return "0";
        }
        uint256 temp = number;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (number != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(number % 10)));
            number /= 10;
        }
        return string(buffer);
    }

    function getCustomMetadata(uint256 _tokenId) public view returns (string memory) {
        return tokenMetadata[_tokenId].metadata;
    }

    function setCustomSVG(uint256 _tokenId, string memory _svg, uint256 _step) public {
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the owner of the token");
    
        TokenMetadata storage tm = tokenMetadata[_tokenId];

        require(_step == tm.step, string(abi.encodePacked("Incorrect step. Current step is ", uint256ToString(tm.step), ".")));
        require(_step < 5, "Custom SVG is fully uploaded.");

        if(_step == 0){
            tm.customSVG = _svg;
        } else {
            tm.customSVG = _concatenate(tm.customSVG, _svg);
        }

        tm.step++;
    }

    function setCustomMetadata(uint256 _tokenId, string memory _metadata) public {
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the owner of the token.");
        tokenMetadata[_tokenId].metadata = _metadata;
    }

    function toggleCustomMetadata(uint256 _tokenId) public {
        require(_exists(_tokenId), "Token has not been minted yet.");
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the owner of the token.");

        TokenMetadata storage tm = tokenMetadata[_tokenId];

        if (tm.useCustomMetadata) {
            tm.useCustomMetadata = false;
        } else {
            require(bytes(tokenMetadata[_tokenId].metadata).length > 0, string(abi.encodePacked("Please load custom metadata first for token ", uint256ToString(_tokenId), ".")));
            require(tm.step == 5, string(abi.encodePacked("SVG upload currently on step ", uint256ToString(tm.step), "! Please upload to 5 before switching.")));
            tm.useCustomMetadata = true;
        }
    }
}