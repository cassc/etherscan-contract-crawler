//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

// Contract by @backseats_eth

contract ContractReaderLiveValues {

    function tokenURI(uint256 _tokenId) public pure returns (string memory) {
        return string.concat(
            'data:application/json;base64,',
            Base64.encode(
                bytes(
                    string.concat(
                        '{"name": "Contract Reader Live Values #',
                            Strings.toString(_tokenId),
                        '",',
                        '"description": "The second feature-release NFT minted from the team at ContractReader.io (but the first one fully onchain). Contract Reader is the better way to read and understand smart contracts. This NFT commemorates the launch of the Live Onchain Values feature, where storage variabels and read-only functions are readable right inline next to the code!",',
                        '"image":"data:image/svg+xml;base64,',
                            Base64.encode(bytes(generateLiveValuesNFT())),
                        '",',
                        '"attributes": "[',
                            '{"trait_type": "Release Date", "value": "February 24, 2023"}',
                        ']" }'
                    )
                )
            )
        );
    }

    function generateLiveValuesNFT() internal pure returns (string memory) {
        return string.concat(
            '<svg width="1660" height="1300" viewBox="0 0 1660 1300" fill="none" xmlns="http://www.w3.org/2000/svg">',
                '<rect width="1660" height="1300" fill="black"/>',
                '<rect x="505" y="182" width="650" height="936" rx="6" fill="white" fill-opacity="0.1"/>',
                '<rect x="502" y="179" width="656" height="942" rx="9" stroke="white" stroke-opacity="0.25" stroke-width="6"/>',
                '<path d="M505 188C505 184.686 507.686 182 511 182H1149C1152.31 182 1155 184.686 1155 188V266H505V188Z" fill="url(#paint0_linear_260_2)"/>',
                '<path d="M505 266H1155V1112C1155 1115.31 1152.31 1118 1149 1118H511C507.686 1118 505 1115.31 505 1112V266Z" fill="black"/>',
                '<path d="M505 387H1155V1118H511C507.686 1118 505 1115.31 505 1112V387Z" fill="#0F172A"/>',
                '<rect x="505" y="387" width="650" height="77" fill="#1E3B8B"/>',
                '<rect x="517" y="403" width="126" height="8" fill="white" fill-opacity="0.7"/>',
                '<rect x="517" y="487" width="126" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="505" width="380" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="523" width="361" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="541" width="253" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="559" width="269" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="577" width="211" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="637" width="211" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="655" width="269" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="673" width="282" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="691" width="273" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="709" width="207" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="727" width="253" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="745" width="122" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="805" width="297" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="823" width="186" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="841" width="186" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="859" width="163" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="877" width="49" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="937" width="245" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="955" width="245" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="973" width="158" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="991" width="207" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="1009" width="97" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="527" y="293" width="126" height="13" fill="white" fill-opacity="0.7"/>',
                '<circle cx="666" cy="300" r="5" fill="#2363ED"/>',
                '<path d="M665 300.5L664 299L663 300L665 302.5L669.5 299L668.5 298L665 300.5Z" fill="white"/>',
                '<rect x="526" y="316" width="144" height="17" rx="2" fill="#1E3B8B"/>',
                '<rect x="989" y="215" width="144" height="17" rx="2" fill="white" fill-opacity="0.4"/>',

                '<path d="M886 522C886 520.895 886.895 520 888 520H905V529H888C886.895 529 886 528.105 886 527V522Z" fill="#1D43D8">',
                    '<animate attributename="opacity" values="0;1;0" dur="3s" repeatcount="indefinite" fill="freeze" />',
                '</path>',
                '<rect x="905" y="520" width="19" height="9" fill="white">',
                    '<animate attributename="opacity" values="0;1;0" dur="3s" repeatcount="indefinite" fill="freeze" />',
                '</rect>',

                '<path d="M778 540C778 538.895 778.895 538 780 538H797V547H780C778.895 547 778 546.105 778 545V540Z" fill="#1D43D8">',
                    '<animate attributename="opacity" values="0;1;0" dur="3s" repeatcount="indefinite" fill="freeze" />',
                '</path>',
                '<rect x="797" y="538" width="19" height="9" fill="white">',
                    '<animate attributename="opacity" values="0;1;0" dur="3s" repeatcount="indefinite" fill="freeze" />',
                '</rect>',

                '<path d="M822 804C822 802.895 822.895 802 824 802H841V811H824C822.895 811 822 810.105 822 809V804Z" fill="#1D43D8">',
                    '<animate attributename="opacity" values="0;1;0" dur="3s" repeatcount="indefinite" fill="freeze" />',
                '</path>',
                '<rect x="841" y="802" width="19" height="9" fill="white">',
                    '<animate attributename="opacity" values="0;1;0" dur="3s" repeatcount="indefinite" fill="freeze" />',
                '</rect>',

                '<path d="M770 936C770 934.895 770.895 934 772 934H789V943H772C770.895 943 770 942.105 770 941V936Z" fill="#1D43D8">',
                    '<animate attributename="opacity" values="0;1;0" dur="3s" repeatcount="indefinite" fill="freeze" />',
                '</path>',
                '<rect x="789" y="934" width="19" height="9" fill="white">',
                    '<animate attributename="opacity" values="0;1;0" dur="3s" repeatcount="indefinite" fill="freeze" />',
                '</rect>',

                '<defs>',
                    '<linearGradient id="paint0_linear_260_2" x1="830" y1="182" x2="830" y2="266" gradientUnits="userSpaceOnUse">',
                        '<stop stop-color="#BE00F2"/>',
                        '<stop offset="0.72619" stop-color="#7403F9"/>',
                    '</linearGradient>',
                '</defs>',
            '</svg>'
        );
    }
}