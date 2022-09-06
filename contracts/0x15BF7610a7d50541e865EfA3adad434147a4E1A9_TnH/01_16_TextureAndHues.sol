// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface i_BLONKS {
    function ownerOf(uint256 eligibleTokenId) external view returns (address);
}

/// @title Texture and Hues Contract
/// @author Matto
/// @notice This is a customized ERC-721 contract for Texture and Hues.
/// @custom:security-contact [email protected]
contract TnH is ERC721Royalty, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    string public description;
    string public website;
    string public decentralizedWebsite;
    string public externalURL;
    address public artistAddress;
    uint256 public royaltyBPS;
    address public BLONKScontract = 0x7f463b874eC264dC7BD8C780f5790b4Fc371F11f;
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => uint256) public entropyOf;
    uint8[700] public claimed;

    constructor() ERC721("Texture and Hues", "TnH") {}

    /**
     * @dev This function allows BLONKS owners to claim and mint a token.
     */
    function CLAIM(uint16 BLONKSnumber) external nonReentrant {
        require(BLONKSnumber <= 691, "Only BLONKS 0-691 are eligible");
        require(claimed[BLONKSnumber] == 0, "That BLONKS has been used.");
        require(
            msg.sender == i_BLONKS(BLONKScontract).ownerOf(BLONKSnumber),
            "Requesting account must own the BLONKS."
        );
        require(
            _tokenIdCounter.current() < 256,
            "All Texture and Hues tokens have been minted."
        );
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _assignTokenData(tokenId, BLONKSnumber);
        claimed[BLONKSnumber] = 1;
        _safeMint(msg.sender, tokenId);
    }

    /**
     * @dev This function assigns entropy to a mapping for tokens.
     */
    function _assignTokenData(uint256 _tokenId, uint256 _BLONKSnumber)
        internal
    {
        entropyOf[_tokenId] =
            uint256(
                keccak256(
                    abi.encodePacked(
                        "Texture and Hues",
                        _BLONKSnumber,
                        _tokenId,
                        block.number,
                        block.timestamp
                    )
                )
            ) /
            (10**10);
    }

    /**
     * @dev This function allows changes to the artist address and secondary
     * sale royalty amount. After setting values, _setDefaultRoyalty is called
     * in order to update EIP-2981 functions.
     */
    function setArtistPayments(address _artistAddress, uint96 _royaltyBPS)
        external
        onlyOwner
    {
        artistAddress = _artistAddress;
        royaltyBPS = _royaltyBPS;
        _setDefaultRoyalty(artistAddress, _royaltyBPS);
    }

    /**
     * @dev This function allows changes to on-chain, project specific
     * metadata.
     */
    function setProjectMeta(
        string memory _description,
        string memory _website,
        string memory _decentralizedWebsite,
        string memory _externalURL
    ) external onlyOwner {
        description = _description;
        website = _website;
        decentralizedWebsite = _decentralizedWebsite;
        externalURL = _externalURL;
    }

    /**
     * @dev This function generates the token SVG and metadata, encoding into 
     * base 64 as needed for browsers to be able to render images without 
     * a server or html page.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _tokenId < _tokenIdCounter.current(),
            "That token doesn't exist"
        );
        string memory hue = "";
        if (_tokenId < 240) {
            hue = string(
                abi.encodePacked(
                    "hsl(",
                    Strings.toString((_tokenId * 15) / 10),
                    ", 75%, 50%)"
                )
            );
        } else {
            hue = string(
                abi.encodePacked(
                    "hsl(0, 0%, ",
                    Strings.toString((_tokenId - 239) * 6),
                    "%"
                )
            );
        }
        uint256 tE = entropyOf[_tokenId];
        uint256[4] memory t;
        t[0] = (tE % 999) + 1;
        tE = tE / 1000;
        t[1] = (tE % 10) + 1;
        tE = tE / 10;
        t[2] = tE % 360;
        tE = tE / 1000;
        t[3] = (tE % 100) + 1;

        string memory svg = string(
            abi.encodePacked(
                '<?xml version="1.0" encoding="utf-8"?>',
                '<svg viewBox="0 0 1000 1000" xmlns="http://www.w3.org/2000/svg">',
                '<filter id="texture"><feTurbulence type="fractalNoise" baseFrequency="0.0',
                Strings.toString(t[0]),
                '" result="noise" numOctaves="5" /><feDiffuseLighting in="noise" lighting-color="',
                hue,
                '" surfaceScale="',
                Strings.toString(t[1]),
                '"><feDistantLight azimuth="',
                Strings.toString(t[2]),
                '" elevation="',
                Strings.toString(t[3]),
                '" /></feDiffuseLighting></filter>',
                '<rect x="0" y="0" width="1000" height="1000" style="filter:url(#texture)" /></svg>'
            )
        );

        string memory traits = string(
            abi.encodePacked(
                '"attributes":[',
                _trait("Texture", Strings.toString(t[0])),
                _trait("Hue", hue),
                _trait("Scale", Strings.toString(t[1])),
                _trait("Angle", Strings.toString(t[2])),
                _trait("Distance", Strings.toString(t[3])),
                '{"trait_type":"Token License","value":"CC BY-NC 4.0"}]'
            )
        );

        string memory b64SVG = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(svg))
            )
        );
        string memory URI = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name":"Texture and Hues #',
                                Strings.toString(_tokenId),
                                '","artist":"Matto","description":"',
                                description,
                                '","royaltyInfo":{"artistAddress":"',
                                Strings.toHexString(uint160(artistAddress), 20),
                                '","royaltyBPS":',
                                Strings.toString(royaltyBPS),
                                '},"collection_name":"Texture and Hues","website":"',
                                website,
                                '","external_url":"',
                                externalURL,
                                '","script_type":"Solidity","image_type":"Generative SVG","image":"',
                                b64SVG,
                                '",',
                                traits,
                                "}"
                            )
                        )
                    )
                )
            )
        );
        return URI;
    }

    /**
     * @dev This is a helper function for building 'attributes' (traits) 
     * strings for metadata.
     */
    function _trait(string memory _k, string memory _v)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    _k,
                    '","value":"',
                    _v,
                    '"},'
                )
            );
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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