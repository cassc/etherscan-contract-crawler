// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat/console.sol";
import "solady/src/utils/LibPRNG.sol";
import "solady/src/utils/DynamicBufferLib.sol";
import "solady/src/utils/Base64.sol";
import "solady/src/utils/LibString.sol";
import {LibSort} from "solady/src/utils/LibSort.sol";
import {SSTORE2} from "solady/src/utils/SSTORE2.sol";
import "@solidstate/contracts/utils/Multicall.sol";
import { ERC721D } from "./ERC721D/ERC721D.sol";
import {BookDataFacetPosterExt} from "./BookDataFacetPosterExt.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {ReentrancyGuard} from "@solidstate/contracts/utils/ReentrancyGuard.sol";

import "./PosterInternalFacet.sol";

contract PosterMainFacet is PosterInternalFacet, ReentrancyGuard {
    using LibString for *;
    using LibSort for *;
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;
    using LibBitmap for LibBitmap.Bitmap;
    using LibPRNG for LibPRNG.PRNG;

    error ContractsCannotMint();
    error AlreadyMintedInExhibition(uint16 exhibitionNumber);
    
    function mintPoster(address to, uint16 exhibitionNumber) external nonReentrant {
        if (msg.sender != tx.origin) revert ContractsCannotMint();
        
        require(
            s().exhibitions[exhibitionNumber].number == exhibitionNumber &&
            s().activeExhibition == exhibitionNumber,
        "Invalid exhibition");
        
        LibBitmap.Bitmap storage userToMintedInExhibition = s().userToMintedInExhibition[msg.sender];
        
        if (block.chainid == 1) {
            if (userToMintedInExhibition.get(exhibitionNumber)) revert AlreadyMintedInExhibition(exhibitionNumber);
        }
        
        userToMintedInExhibition.set(exhibitionNumber);
        
        unchecked {++s().nextTokenId;}
        
        uint64 tokenId = s().nextTokenId;
        
        _mint(to, tokenId);
        
        _setTokenExtraData(tokenId, exhibitionNumber);
    }
    
    function getQrCodeForExhibition(uint16 exhibitionNumber) public view returns (string memory) {
        address candidate = s().exhibitions[exhibitionNumber].qrCodePointer;
        
        string memory candidateValue = string(SSTORE2.read(candidate));
        
        if (bytes(candidateValue).length == 0) {
            return string(SSTORE2.read(s().defaultQrCodePointer));
        } else {
            return candidateValue;
        }
    }
    
    function getExhibitionExternalLink(uint16 exhibitionNumber) public view returns (string memory) {
        string memory candidate = s().exhibitions[exhibitionNumber].externalLink;
        
        return bytes(candidate).length > 0 ? candidate : s().defaultExternalLink;
    }
    
    function tokenImageAndAttributesJSON(uint64 id) public view returns (string memory image, string memory json) {
        LibPRNG.PRNG memory prng = LibPRNG.PRNG(id);
        DynamicBufferLib.DynamicBuffer memory svgBytes;
        
        Exhibition memory exhibition = s().exhibitions[uint16(_getTokenExtraData(id))];
        
        bytes memory idsBytes = SSTORE2.read(exhibition.representativeBooksPointer);
        uint totalBooks = idsBytes.length / 10;
        
        uint[] memory bookIds = new uint[](totalBooks);
        
        for (uint i = 0; i < totalBooks; ) {
            bookIds[i] = get80BitNumberInBytesAtIndex(idsBytes, i);
            unchecked {++i;}
        }
        
        prng.shuffle(bookIds);
        
        uint numberOfBooksToRender = min(s().maxBooksPerPoster, totalBooks);
        
        if (block.chainid == 31337) numberOfBooksToRender = 5;
        
        uint[] memory attributes = new uint[](numberOfBooksToRender * 10);
        
        svgBytes.append('<svg width="2112" height="2976" xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 2112 2976" style="background: ');
        
        // uint scale = 8;
        uint bgSize = (24 * 8);
        for (uint i; i < numberOfBooksToRender; ) {
            uint80 assets = uint80(bookIds[i]);
            
            uint8[10] memory assetsAry = unpackAssets(assets);
            
            for (uint8 slot = 0; slot < 10; ) {
                if (assetsAry[slot] > 0) {
                    string memory name = assetsAry[slot] < 12 ?
                        BookDataFacetPosterExt(s().dataContract).getAssetName(assetsAry[slot]).split(' ')[0] :
                        BookDataFacetPosterExt(s().dataContract).getAssetName(assetsAry[slot]);
                    
                    string memory traitType;
                    
                    if (slot == 1) {
                        if (assetsAry[slot] == 108 || assetsAry[slot] == 131 || assetsAry[slot] == 77) {
                            traitType = "Lips";
                        } else {
                            traitType = "Mouth";
                        }
                    } else {
                        traitType = BookDataFacetPosterExt(s().dataContract).assetSlotToTraitType(slot);
                    }
                    
                    attributes[i * 10 + slot] = uint(bytes32(bytes(name.concat("|").concat(traitType))));
                }
                
                unchecked {++slot;}
            }
            
            uint xVal = 8 * ((i % 9 * 24) + 24);
            uint yVal = 8 * ((i / 9 * 24) + 24);
            
            svgBytes.append(abi.encodePacked(
                'url(data:image/bmp;base64,', BookDataFacetPosterExt(s().dataContract).renderBmpMinimal(assets, 6522262), ') ', xVal.toString(), 'px ', yVal.toString(),'px / ',
                bgSize.toString(), 'px ', bgSize.toString(), 'px'
            ));
            
            if (i + 1 < numberOfBooksToRender) {
                svgBytes.append(', ');
            }
            
            unchecked {++i;}
        }
        
        attributes.sort();
        attributes.uniquifySorted();
        
        json = attributesAsJSON(attributes);
        
        svgBytes.append(abi.encodePacked(
            '; image-rendering: pixelated; background-repeat: no-repeat; background-color: #638596">'
        ));
        
        svgBytes.append(abi.encodePacked('<style>', SSTORE2.read(s().fontDeclarationPointer),'</style>'));
        
        svgBytes.append(abi.encodePacked('<g><image x="192" y="2592" height="288" href="', SSTORE2.read(s().wordmarkPointer),'" />'));
        
        svgBytes.append(abi.encodePacked('<image x="1728" y="2592" height="192" width="192" href="',
            getQrCodeForExhibition(exhibition.number),'" />'));
        
        svgBytes.append(abi.encodePacked(
            '<text x="1920" y="2880" font-family="lores" text-anchor="end" font-size="46" fill="white">', 
            exhibition.name.escapeHTML(),
            '</text></g>'));
        
        svgBytes.append("</svg>");
        
        image = string.concat(
                "data:image/svg+xml;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '<svg width="100%" height="100%" viewBox="0 0 2112 2976" version="1.2" xmlns="http://www.w3.org/2000/svg"><image width="2112" height="2976" href="data:image/svg+xml;base64,',
                        Base64.encode(svgBytes.data),
                        '"></image></svg>'
                    )
                )
            );
    }
    
    function attributesAsJSON(uint[] memory attributeIds) internal pure returns (string memory) {
        DynamicBufferLib.DynamicBuffer memory buffer;
        
        for (uint j; j < attributeIds.length; ) {
            uint packed = attributeIds[j];
            
            if (packed == 0) {
                unchecked {++j;}
                continue;
            }
            
            string memory combined = string(abi.encodePacked(bytes32(packed)));
            
            string[] memory split = combined.split("|");
            
            string memory name = split[0];
            
            string memory traitType = split[1].replace("\x00", '');
            
            buffer.append(abi.encodePacked('{"trait_type":"', traitType, '","value":"'));
            buffer.append(bytes(name));
            buffer.append(bytes('"}'));
                
            if (j + 1 < attributeIds.length) {
                buffer.append(bytes(','));
            }
            
            unchecked {++j;}
        }
        
        return string(buffer.data);
    }
    
    function constructTokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        
        uint64 id = uint64(tokenId);
        
        uint16 exhibitionNumber = uint16(_getTokenExtraData(id));
        Exhibition memory exhibition = s().exhibitions[exhibitionNumber];
        
        (string memory outerSvg, string memory attributes) = tokenImageAndAttributesJSON(id);
        
        string memory name = string.concat(s().nameSingular, " #", id.toString());
        
        string memory description = string.concat(
            "A commemorative poster from the Babylon Library Exhibition: ", exhibition.name
        );
        
        string memory finalAttributes = string.concat(
            "[", attributes, ",",
            '{"trait_type":"Exhibition No.","value":"', exhibitionNumber.toString(), '"}',
            ']'
        );
        
        return string(
            abi.encodePacked(
                'data:application/json;utf-8,{',
                '"name":"', name, '",'
                '"description":"', description.escapeJSON(), '",'
                '"external_url":"', getExhibitionExternalLink(exhibitionNumber), '",'
                '"attributes":', finalAttributes, ','
                '"image_data":"', outerSvg,'"'
                '}'
            )
        );
    }
}