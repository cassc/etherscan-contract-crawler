//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import './CAIC.sol';
import './Randomize.sol';
import "./IBMP.sol";

/// @title CaicGrids
/// @author tfs128 (@trickerfs128)
contract CaicGrids is CAIC {
    using Strings for uint256;
    using Strings for uint32;
    using Randomize for Randomize.Random;

    IBMP public immutable _bmp;

    /// @notice constructor
    /// @param contractURI can be empty
    /// @param openseaProxyRegistry can be address zero
    /// @param bmp encoder address
    constructor(
        string memory contractURI,
        address openseaProxyRegistry,
        address bmp
    ) CAIC(contractURI, openseaProxyRegistry) {
        _bmp = IBMP(bmp);
    }

    /// @dev Rendering function; should be overrode
    /// @param tokenId the tokenId
    /// @param seed the seed
    /// @param isSvg true=svg, false=base64 encoded
    function _render(uint256 tokenId, bytes32 seed, bool isSvg)
        internal
        view
        override
        returns (string memory)
    {
        Randomize.Random memory random = Randomize.Random({
            seed: uint256(seed),
            offsetBit: 0
        });
        uint256 rule = random.next(1,255);
        bytes memory pixels = getCells(rule,random);
        bytes memory bmpImage = _bmp.bmp(pixels,SIZE,SIZE,_bmp.grayscale());
        if(isSvg == true) {
            string memory sizeInString = SIZE.toString();
            bytes memory image = abi.encodePacked(
                '"image":"data:image/svg+xml;utf8,',
                "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' height='",sizeInString,"' width='",sizeInString,"'>"
                "<image style='image-rendering: pixelated;' height='",sizeInString,"' width='",sizeInString,"' xlink:href='",_bmp.bmpDataURI(bmpImage),"'></image>",
                '</svg>"'
                );

            return string(abi.encodePacked(
                'data:application/json;utf8,'
                '{"name":"Grid #',tokenId.toString(),'",',
                '"description":"A grid completely generated onchain using 1D cellular automaton.",',
                '"properties":{ "Rule":"',rule.toString(),'"},',
                image,
                '}'
                ));
        }
        else {
            return string(abi.encodePacked(
                    _bmp.bmpDataURI(bmpImage)
                ));
        }
    }

    /// @notice Gas eater function, to generate cells on grid
    /// @param rule CA rule 1-255
    /// @param random to generate random initial row.
    function getCells(uint256 rule, Randomize.Random memory random) internal view returns(bytes memory) {
        unchecked {
            bytes memory pixels = new bytes(uint256(SIZE * SIZE));
            bytes memory oldRow = new bytes(SIZE);
            uint256 x;
            for(x=1; x < SIZE; x++) {
                uint256 random = random.next(1,255);
                oldRow[x] = random % 2 == 0 ? bytes1(uint8(1)) : bytes1(uint8(0));   
            }

            uint8 increment;
            if(SIZE <= 256) { increment = 3; }
            else if(SIZE <= 384) { increment = 2; }
            else { increment = 1; }

            for(uint256 y=0; y< SIZE; y+=4) {
                bytes memory newRow = new bytes(uint256(SIZE));
                uint8 gr = 0;
                for(x = 0; x < SIZE; x+=4) {
                    gr += increment;
                    bytes1 px = uint8(oldRow[x]) == 1 ? bytes1(uint8(1)) : bytes1(uint8(255-gr));
                    {
                        uint yp1 = y + 1;
                        uint yp2 = y + 2;
                        uint xp1 = x + 1;
                        uint xp2 = x + 2;

                        pixels[y * SIZE + x  ] = px;
                        pixels[y * SIZE + xp1] = px;
                        pixels[y * SIZE + xp2] = px;

                        pixels[ yp1 * SIZE + x  ] = px;
                        pixels[ yp1 * SIZE + xp1] = px;
                        pixels[ yp1 * SIZE + xp2] = px;

                        pixels[ yp2 * SIZE + x  ] = px;
                        pixels[ yp2 * SIZE + xp1] = px;
                        pixels[ yp2 * SIZE + xp2] = px;
                    }
                    uint8 combine;
                    if(x == 0) {
                        combine = (uint8(1) << 2) + (uint8(oldRow[x]) << 1) + (uint8(oldRow[x+4]) << 0);
                    }
                    else if(x == SIZE - 4) {
                        combine = (uint8(oldRow[x-4]) << 2) + (uint8(oldRow[x]) << 1) + (uint8(1) << 0);
                    }
                    else {
                        combine = (uint8(oldRow[x-4]) << 2) + (uint8(oldRow[x]) << 1) + (uint8(oldRow[x+4]) << 0);
                    }
                    uint8 nValue = ( uint8(rule) >> combine ) & 1;
                    newRow[x] = nValue == 1 ? bytes1(uint8(1)) : bytes1(uint8(0));
                }
                oldRow = newRow;
            }
            return pixels;
        }
    }

}