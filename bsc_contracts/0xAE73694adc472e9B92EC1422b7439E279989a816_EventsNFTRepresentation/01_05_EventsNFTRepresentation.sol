// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Raise protocol ([email protected])
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../INFTRepresentation.sol";
import "../INFT.sol";

contract EventsNFTRepresentation is INFTRepresentation {

    function getContractUri(INFT _nft) external view override returns (string memory) {
        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string.concat(
                        '{"name":"', _nft.name(), '"}'
                    )
                )
            )
        );
    }

    function getTokenUri(INFT _nft, uint _tokenId) external view override returns (string memory) {
        (
            INFT.TokenInfo memory token,
            INFT.RoundInfo memory round,
            /* address owner */
        ) = _nft.getTokenInfoExtended(_tokenId);

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string.concat(
                        '{"name":"', _nft.name(), '"',
                        ',"image":"', _getImageUri(_nft.name(), _nft.symbol(), round.name, token.shareBasisPoints), '"',
                        ',"properties":',
                        '{"type":"', round.name, '"',
                        '}}'
                    )
                )
            )
        );
    }

    function _getImageUri(string memory _name, string memory, string memory _roundName, uint) internal pure returns (string memory) {
        return string.concat(
            "data:image/svg+xml;base64,",
            Base64.encode(
                bytes(
                    string.concat(
                        '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" viewBox="0 0 250 285" style="enable-background:new 0 0 250 285;">',
                        '<style type="text/css">.s0{fill:#C4D740;}.s1{fill:#FFFFFF;}.s2{fill:none;stroke:#DDF247;stroke-width:11;}.s3{font-family:Arial, sans-serif;font-weight:bold;}.s4{font-size:16px;}.s5{fill:#D1D1D1;}.s6{font-size:12px;}.s7{font-family:Arial, sans-serif;}.s8{font-size:14px;}</style>',
                        '<clipPath id="c"><rect x="35" y="35" width="180" height="215"/></clipPath>',
                        '<path class="s0" d="M250,10.9L239,0L0,273.1L11.1,285H250V10.9z"/><path class="s1" d="M5.5,5.5h228v262H5.5V5.5z"/><path class="s2" d="M5.5,5.5h228v262H5.5V5.5z"/>',
                        '<text x="35" y="59" class="s3 s4" clip-path="url(#c)">',
                        _name,
                        '</text>',
                        '<text x="35" y="145" class="s7 s6">Type</text>',
                        '<text x="35" y="168" class="s3 s8" clip-path="url(#c)">',
                        _roundName,
                        '</text>',
                        '</svg>'
                    )
                )
            )
        );
    }
}