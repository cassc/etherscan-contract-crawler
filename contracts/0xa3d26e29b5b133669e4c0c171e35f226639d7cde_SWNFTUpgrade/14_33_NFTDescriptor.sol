// SPDX-License-Identifier: GPL-2.0-or-later
// https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/NFTDescriptor.sol

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./NFTSVG.sol";
import "./HexStrings.sol";

library NFTDescriptor {
    using HexStrings for uint256;
    using Strings for uint256;

    struct ConstructTokenURIParams {
        uint256 tokenId;
        address quoteTokenAddress;
        address baseTokenAddress;
        string quoteTokenSymbol;
        string baseTokenSymbol;
        uint256 baseTokenBalance;
        uint256 baseTokenDecimals;
        string pubKey;
        uint256 value;
    }

    function constructTokenURI(ConstructTokenURIParams memory params)
        public
        pure
        returns (string memory)
    {
        string memory name = generateName(params);
        string memory descriptionPartOne = generateDescriptionPartOne();
        string memory descriptionPartTwo = generateDescriptionPartTwo(
            params.tokenId.toString(),
            params.baseTokenSymbol,
            addressToString(params.baseTokenAddress)
        );
        string memory image = Base64.encode(bytes(generateSVGImage(params)));

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                descriptionPartOne,
                                descriptionPartTwo,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function generateDescriptionPartOne() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "This NFT represents a liquidity position in a Swell Network Validator. ",
                    "The owner of this NFT can modify or redeem the position.\\n"
                )
            );
    }

    function generateDescriptionPartTwo(
        string memory tokenId,
        string memory baseTokenSymbol,
        string memory baseTokenAddress
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    baseTokenSymbol,
                    " Address: ",
                    baseTokenAddress,
                    "\\nToken ID: ",
                    tokenId,
                    "\\n\\n",
                    unicode"⚠️ DISCLAIMER: Due diligence is imperative when assessing this NFT. Make sure token addresses match the expected tokens, as token symbols may be imitated."
                )
            );
    }

    function generateName(ConstructTokenURIParams memory params)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "Swell Network Validator - ",
                    params.baseTokenSymbol,
                    " - ",
                    params.pubKey,
                    " <> ",
                    (params.value / params.baseTokenDecimals).toString(),
                    " Ether"
                )
            );
    }

    function generateSVGImage(ConstructTokenURIParams memory params)
        internal
        pure
        returns (string memory svg)
    {
        svg = NFTSVG.generateSVG(
            NFTSVG.SVGParams({
                quoteToken: addressToString(params.quoteTokenAddress),
                baseToken: addressToString(params.baseTokenAddress),
                quoteTokenSymbol: params.quoteTokenSymbol,
                baseTokenSymbol: params.baseTokenSymbol,
                tokenId: params.tokenId,
                baseTokenBalance: params.baseTokenBalance,
                baseTokenDecimals: params.baseTokenDecimals,
                value: params.value,
                color0: tokenToColorHex(
                    uint256(uint160(params.quoteTokenAddress)),
                    136
                ),
                color1: tokenToColorHex(
                    uint256(uint160(params.baseTokenAddress)),
                    136
                ),
                color2: tokenToColorHex(
                    uint256(uint160(params.quoteTokenAddress)),
                    0
                ),
                color3: tokenToColorHex(
                    uint256(uint160(params.baseTokenAddress)),
                    0
                ),
                x1: scale(
                    getCircleCoord(
                        uint256(uint160(params.quoteTokenAddress)),
                        16,
                        params.tokenId
                    ),
                    0,
                    255,
                    16,
                    274
                ),
                y1: scale(
                    getCircleCoord(
                        uint256(uint160(params.baseTokenAddress)),
                        16,
                        params.tokenId
                    ),
                    0,
                    255,
                    100,
                    484
                ),
                x2: scale(
                    getCircleCoord(
                        uint256(uint160(params.quoteTokenAddress)),
                        32,
                        params.tokenId
                    ),
                    0,
                    255,
                    16,
                    274
                ),
                y2: scale(
                    getCircleCoord(
                        uint256(uint160(params.baseTokenAddress)),
                        32,
                        params.tokenId
                    ),
                    0,
                    255,
                    100,
                    484
                ),
                x3: scale(
                    getCircleCoord(
                        uint256(uint160(params.quoteTokenAddress)),
                        48,
                        params.tokenId
                    ),
                    0,
                    255,
                    16,
                    274
                ),
                y3: scale(
                    getCircleCoord(
                        uint256(uint160(params.baseTokenAddress)),
                        48,
                        params.tokenId
                    ),
                    0,
                    255,
                    100,
                    484
                )
            })
        );
    }

    function addressToString(address addr)
        internal
        pure
        returns (string memory)
    {
        return (uint256(uint160(addr))).toHexString(20);
    }

    function tokenToColorHex(uint256 token, uint256 offset)
        internal
        pure
        returns (string memory str)
    {
        return string((token >> offset).toHexStringNoPrefix(3));
    }

    function scale(
        uint256 n,
        uint256 inMn,
        uint256 inMx,
        uint256 outMn,
        uint256 outMx
    ) private pure returns (string memory) {
        return
            (n - (inMn * (outMx - outMn)) / (inMx - inMn) + (outMn)).toString();
    }

    function getCircleCoord(
        uint256 tokenAddress,
        uint256 offset,
        uint256 tokenId
    ) internal pure returns (uint256) {
        return (sliceTokenHex(tokenAddress, offset) * tokenId) % 255;
    }

    function sliceTokenHex(uint256 token, uint256 offset)
        internal
        pure
        returns (uint256)
    {
        return uint256(uint8(token >> offset));
    }
}