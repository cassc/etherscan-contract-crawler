// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {DynamicBuffer} from "@divergencetech/ethier/contracts/utils/DynamicBuffer.sol";
import {Base64} from "./Base64.sol";

import {ILostPetsStore} from "./interfaces/ILostPetsStore.sol";
import {ILostPetsRenderer} from "./interfaces/ILostPetsRenderer.sol";
import {IExquisiteGraphics} from "./interfaces/IExquisiteGraphics.sol";

contract LostPetsRenderer is ILostPetsRenderer, Ownable {
    using Strings for uint256;
    using DynamicBuffer for bytes;

    ILostPetsStore public dataStore;
    IExquisiteGraphics public xqstgfx;

    constructor(
        address inLostPetsStore,
        address inxqstgfx
    ) {
        dataStore = ILostPetsStore(inLostPetsStore);
        xqstgfx = IExquisiteGraphics(inxqstgfx);
    }

    function setXqstGfx(IExquisiteGraphics newXqstgfx) external onlyOwner
    {
        xqstgfx = newXqstgfx;
    }
    
    function setDataStore(ILostPetsStore newDataStore) external onlyOwner
    {
        dataStore = newDataStore;
    }

    function SVGToString(bytes memory data) public view returns (string memory) {
        return string(SVGToBytes(data));
    }

    function SVGToBytes(bytes memory data) public view returns (bytes memory) {
        string memory rects = xqstgfx.drawPixelsUnsafe(data);
        bytes memory svg = DynamicBuffer.allocate(2**19);

        svg.appendSafe(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" width="100%" height="100%" version="1.1" viewBox="0 0 32 32" fill="#fff"><rect width="32" height="32" fill="#fff" /><g>',
                rects,
                "</g></svg>"
            )
        );

        return svg;
    }

    function getLostPetSVG(uint256 id) external view returns (string memory) {
        bytes memory data = dataStore.getRawPetData(id);
        return SVGToString(data);
    }

    function getLostPetBase64SVG(uint256 id) external view returns (string memory) {
        bytes memory data = dataStore.getRawPetData(id);
        if(data.length <= 0) {
            return "";
        }

        bytes memory svg = SVGToBytes(data);
        bytes memory svgB64 = DynamicBuffer.allocate(2**19);

        svgB64.appendSafe("data:image/svg+xml;base64,");
        svgB64.appendSafe(bytes(Base64.encode(svg)));

        return string(svgB64);
    }

    function tokenURI(uint256 id) external view returns (string memory) {
        string memory imageString = "";


        bytes memory data = dataStore.getRawPetData(id);
        if(data.length > 0) {
            bytes memory svgB64 = DynamicBuffer.allocate(2**19);
            bytes memory svg = SVGToBytes(data);

            svgB64.appendSafe("data:image/svg+xml;base64,");
            svgB64.appendSafe(bytes(Base64.encode(svg)));
            imageString = string(svgB64);
        }

        bytes memory json = DynamicBuffer.allocate(2**19);
        bytes memory jsonB64 = DynamicBuffer.allocate(2**19);


        json.appendSafe(
            abi.encodePacked(
                '{"symbol":"LOSTPETS","name":"', dataStore.getPetName((uint8)(id)),
                '","description":"200 fully on-chain lost pet portraits. LostPets.NYC"',
                ',"image":"', imageString, '"',
                ',"attributes":[{"trait_type":"Pet Type","value":"', dataStore.getPetType((uint8)(id)), '"}',
                ',{"trait_type":"Breed","value":"', dataStore.getPetBreed((uint8)(id)), '"}',
                ',{"trait_type":"Neighborhood","value":"', dataStore.getPetHood((uint8)(id)), '"}'
            )
        );

        json.appendSafe(
            abi.encodePacked(
                ',{"trait_type":"Status","value":"', dataStore.getPetState((uint8)(id)), '"}',
                ',{"trait_type":"Borough","value":"', dataStore.getPetBorough((uint8)(id)), '"}',
                ',{"trait_type":"Reward","value":"', dataStore.getPetHasReward((uint8)(id)), '"}',
                ',{"trait_type":"Colors","value":"', dataStore.getPetColors((uint8)(id)), '"}',
                ',{"trait_type":"Palette","value":"', dataStore.getPetPallete((uint8)(id)), '"}]}'
            )
        );

        jsonB64.appendSafe("data:application/json;base64,");
        jsonB64.appendSafe(bytes(Base64.encode(json)));

        return string(jsonB64);
    }
}