// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./interfaces/IBlitmap.sol";
import "./MetadataBuilder.sol";
import "./MetadataJSONKeys.sol";
import "./utils/StringsBytes32.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IBlitkinRenderV3} from "./interfaces/IBlitkinRenderV3.sol";

contract BlitkinRenderV3 is OwnableUpgradeable, UUPSUpgradeable, IBlitkinRenderV3 {

    event InscriptionsAdded();

    mapping (uint256 => Inscription) inscriptions;
    
    uint256 inscriptionsCount;
    /// @notice Stores address => string base, string postfix, string contractURI for urls
    ContractInfo private contractInfo;

    mapping(bytes32 => bool) private tokenPairs;

    IBlitmap public blitmap;

    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }
    
    // Setters
    function setBaseURIs(ContractInfo memory info)
        external
        onlyOwner
    {
        contractInfo = info;
        blitmap = IBlitmap(info.blitmapAddress);
    }

    function getContractInfo() external view returns(string memory){
        //   from opensea: https://docs.opensea.io/docs/contract-level-metadata
        //         {
        //   "name": "OpenSea Creatures",
        //   "description": "OpenSea Creatures are adorable aquatic beings primarily for demonstrating what can be done using the OpenSea platform. Adopt one today to try out all the OpenSea buying, selling, and bidding feature set.",
        //   "image": "external-link-url/image.png",
        //   "external_link": "external-link-url",
        //   "seller_fee_basis_points": 100, # Indicates a 1% seller fee.
        //   "fee_recipient": "0xA97F337c39cccE66adfeCB2BF99C1DdC54C2D721" # Where seller fees will be paid to.
        // }
        MetadataBuilder.JSONItem[] memory items = new MetadataBuilder.JSONItem[](5);
        items[0].key = "name";
        items[0].value = contractInfo.title;
        items[0].quote = true;

        items[1].key = "description";
        items[1].value = contractInfo.description;
        items[1].quote = true;

        items[2].key = "external_link";
        items[2].value = contractInfo.contractURI;
        items[2].quote = true;

        items[3].key = "seller_fee_basis_points";
        items[3].value = Strings.toString(contractInfo.royaltyFee);
        items[3].quote = false;

        items[4].key = "fee_recipient";
        items[4].value = Strings.toHexString(uint256(uint160(contractInfo.royaltyReciever)), 20);
        items[4].quote = true;

        return MetadataBuilder.generateEncodedJSON(items);
    } 

    function addInscriptions(
        Inscription[] calldata newInscriptions
    ) external onlyOwner {
        unchecked {
            // get count
            //uint256 count = inscriptionsCount;
            for (uint256 i = 0; i < newInscriptions.length; ++i) {
                inscriptions[i] = newInscriptions[i];
            }
            // update count
            inscriptionsCount = newInscriptions.length;
        }
        emit InscriptionsAdded();
    }
    
    function getInscription(uint256 inscriptionId) public view returns (Inscription memory){
        return inscriptions[inscriptionId];
    }

    function getInscriptionsCount() public view returns (uint256){
        return inscriptionsCount;
    }

    function getScramble(uint256 inscriptionId, uint256 blitmapPaletteId) public view returns (string memory,string memory, string memory) {
        Inscription memory inscription = getInscription(inscriptionId);
        bytes memory data = blitmap.tokenDataOf(blitmapPaletteId);
        string memory palette = blitmap.tokenNameOf(blitmapPaletteId);
        
        string[4] memory colors = [
            string(abi.encodePacked("%23", byteToHexString(data[0]), byteToHexString(data[1]), byteToHexString(data[2]))),
            string(abi.encodePacked("%23", byteToHexString(data[3]), byteToHexString(data[4]), byteToHexString(data[5]))),
            string(abi.encodePacked("%23", byteToHexString(data[6]), byteToHexString(data[7]), byteToHexString(data[8]))),
            string(abi.encodePacked("%23", byteToHexString(data[9]), byteToHexString(data[10]), byteToHexString(data[11])))       
        ];

        string memory animationURI = string.concat(
            contractInfo.animationBase,
            StringsBytes32.toHexString(inscription.btc_txn),
            contractInfo.animationPostfix,
            "?fill1=",
            colors[0],
            "&fill2=",
            colors[1],
            "&fill3=",
            colors[2],
            "&fill4=",
            colors[3]
        );

        string memory btcHash = StringsBytes32.toHexString(inscription.btc_txn);

        string memory imageURI = string.concat(
            contractInfo.imageBase,
            btcHash,
            contractInfo.imagePostfix,
            "%3Ffill1%3D",
            colors[0],
            "%26fill2%3D",
            colors[1],
            "%26fill3%3D",
            colors[2],
            "%26fill4%3D",
            colors[3]
        );

        return(string.concat(inscription.composition, " ", palette), animationURI, imageURI);
    }

    function tokenURI(uint256 tokenId, uint256 inscriptionId, uint256 blitmapPaletteId) public view returns (string memory) {
        Inscription memory inscription = getInscription(inscriptionId);
        string memory palette = blitmap.tokenNameOf(blitmapPaletteId);
        string memory btcHash = StringsBytes32.toHexString(inscription.btc_txn);

        (, string memory animationURI, string memory imageURI ) = getScramble(inscriptionId,  blitmapPaletteId);

        string memory htmlWrapper = string.concat(
           
            '<!DOCTYPE html><html><style> html,body { margin: 0; padding: 0; height: 100%; } #svg-container { position: absolute; width: 100%; height: 100%; overflow: hidden; } svg, object { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); width: 100%; max-height: 100%;}</style>',
            '<body><div id="svg-container"><object type="image/svg+xml" width="100%" height="100%" data="',
            animationURI,
            '"></object></div></body></html>'
        );

        MetadataBuilder.JSONItem[]
        memory items = new MetadataBuilder.JSONItem[](6);
        items[0].key = MetadataJSONKeys.keyName;
        items[0].value = string.concat(
            "#",
            Strings.toString(tokenId),
            " ",
            inscription.composition,
            " ",
            palette
        );

        items[0].quote = true;

        items[1].key = MetadataJSONKeys.keyDescription;
        items[1].value = string.concat(contractInfo.description, " \\n ", animationURI);
        items[1].quote = true;

        items[2].key = MetadataJSONKeys.keyImage;
        items[2].value = imageURI;
        items[2].quote = true;

        items[3].key = MetadataJSONKeys.keyAnimationURL;
        items[3].value = string.concat(
            'data:text/html;base64,',
            string(Base64.encode(bytes(htmlWrapper)))
        );
        items[3].quote = true;

        items[4].key = "external_url";
        items[4].value = animationURI;
        items[4].quote = true;

        MetadataBuilder.JSONItem[]
            memory properties = new MetadataBuilder.JSONItem[](4);
        properties[0].key = "BTC tx Hash";
        properties[0].value = btcHash;
        properties[0].quote = true;

        properties[1].key = "Composition";
        properties[1].value = inscription.composition;
        properties[1].quote = true;

        properties[2].key = "Palette";
        properties[2].value = palette;
        properties[2].quote = true;

        properties[3].key = "Artist";
        properties[3].value = inscription.artist;
        properties[3].quote = true;

        items[5].key = MetadataJSONKeys.keyProperties;
        items[5].quote = false;
        items[5].value = MetadataBuilder.generateJSON(properties);

        return MetadataBuilder.generateEncodedJSON(items);
    }

    function uintToHexString(uint a) internal pure returns (string memory) {
        uint count = 0;
        uint b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint i=0; i<count; ++i) {
            b = a % 16;
            res[count - i - 1] = uintToHexDigit(uint8(b));
            a /= 16;
        }
        
        string memory str = string(res);
        if (bytes(str).length == 0) {
            return "00";
        } else if (bytes(str).length == 1) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }
    
    function byteToUint(bytes1 b) internal pure returns (uint) {
        return uint(uint8(b));
    }
    
    function byteToHexString(bytes1 b) internal pure returns (string memory) {
        return uintToHexString(byteToUint(b));
    }

    function uintToHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1('0')) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1('a')) + d - 10);
        }
        revert();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}