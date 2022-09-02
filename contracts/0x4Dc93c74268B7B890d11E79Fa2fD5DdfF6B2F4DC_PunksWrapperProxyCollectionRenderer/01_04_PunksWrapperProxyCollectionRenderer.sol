// SPDX-License-Identifier: UNLICENSED
/// @title PunksWrapperProxyCollectionRenderer
/// @notice Renders PunksWrapperProxyCollection
/// @author CyberPnk <[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     

pragma solidity ^0.8.16;

import "@cyberpnk/solidity-library/contracts/IStringUtilsV3.sol";
import "./ICryptoPunksData.sol";
// import "hardhat/console.sol";

contract PunksWrapperProxyCollectionRenderer {
    IStringUtilsV3 stringUtils;
    ICryptoPunksData cryptoPunksData;

    constructor(address stringUtilsContract, address cryptoPunksDataContract) {
        stringUtils = IStringUtilsV3(stringUtilsContract);
        cryptoPunksData = ICryptoPunksData(cryptoPunksDataContract);
    }

    function getEmptyWrapperImage(uint16) public pure returns(bytes memory) {
        return abi.encodePacked('<svg width="640" height="640" version="1.1" viewBox="0 0 640 640" xmlns="http://www.w3.org/2000/svg">'
            '<rect y="0" height="640" x="0" width="640" fill="#696969"/>'
        '</svg>');
    }

    function getImage(uint16 punkId) public view returns(bytes memory) {
        bytes memory imageBytes = bytes(cryptoPunksData.punkImageSvg(punkId));
        string memory imageBytesNoHeader = stringUtils.substr(imageBytes, 24, imageBytes.length);

        return abi.encodePacked('<svg width="640" height="640" version="1.1" viewBox="0 0 640 640" xmlns="http://www.w3.org/2000/svg">'
            '<rect y="0" height="640" x="0" width="640" fill="#696969"/>',
            imageBytesNoHeader, 
        '</svg>');
    }

    function getTraitsJsonValue(uint256 tokenId, bool isEmptyWrapper) internal view returns(string memory) {
        string memory traitsBytes = cryptoPunksData.punkAttributes(uint16(tokenId));

        string[] memory traits = stringUtils.split(traitsBytes, ",");
        bytes memory traitsStr = "";
        uint len = traits.length;
        string memory wrapperTrait = isEmptyWrapper ? '{"trait_type":"Wrapper","value":"Empty"},' : '{"trait_type":"Wrapper","value":"Full"},';
        for (uint i = 0; i < len; i++) {
            bytes memory trait = bytes(traits[i]);
             string memory traitToUse = i == 0 ? string(trait) : stringUtils.substr(trait, 1, trait.length);
            traitsStr = abi.encodePacked(traitsStr, 
                '{'
                    '"trait_type":"', traitToUse, '",'
                    '"value":"', traitToUse, '"'
                '}', 
                i == len - 1 ? '' : ','
            );
        }

        return string(abi.encodePacked('[', wrapperTrait, traitsStr, ']'));
    }


    function getTokenURI(uint256 punkId, bool isEmptyWrapper) public view returns (string memory) {
        string memory strTokenId = stringUtils.numberToString(punkId);

        bytes memory imageBytes = isEmptyWrapper ? getEmptyWrapperImage(uint16(punkId)) : getImage(uint16(punkId));
        string memory image = stringUtils.base64EncodeSvg(abi.encodePacked(imageBytes));

        string memory traitsJsonValue = getTraitsJsonValue(punkId, isEmptyWrapper);

        string memory emptyWrapperText = isEmptyWrapper ? " (Empty wrapper, cannot transfer)" : "";

        string memory emptyWrapperDescription = isEmptyWrapper ? " Empty wrappers are created when the underlying punk is sold separately from the wrapper. Empty wrappers can be safely discarded or rewrapped again." : "";

        bytes memory description = abi.encodePacked('"Wrapped Punk #',
            strTokenId, 
            emptyWrapperText,
            '. that proxies calls to the CryptoPunksMarket contract.', 
            emptyWrapperDescription, 
            '"');

        bytes memory json = abi.encodePacked(string(abi.encodePacked(
            '{'
                '"title": "PWP #', strTokenId, emptyWrapperText, '",'
                '"name": "Proxying Wrapped Punk #', strTokenId, emptyWrapperText, '",'
                '"external_url": "https://pwp.cyberpnk.win/manage-punk/', strTokenId, '",'
                '"image": "', image, '",'
                '"traits":', traitsJsonValue, ','
                '"description": ', description, 
            '}'
        )));

        return stringUtils.base64EncodeJson(json);
    }

    function getContractURI() public view returns(string memory) {
        return stringUtils.base64EncodeJson(abi.encodePacked(
        '{'
            '"name": "Proxying Wrapped Punks",'
            '"description": "Wrapped Punks that proxy calls to the CryptoPunksMarket contract.  This allows you to offer for sale the same punk in the punks market at the same time as in any other ERC721 market.  Empty wrappers are created when the underlying punk is sold separately from the wrapper. Empty wrappers can be safely discarded or rewrapped.",'
            '"image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYBAMAAAASWSDLAAAAFVBMVEVpaWkAAADbsYCmbizFIRDSnWD/2SazLrR0AAAAY0lEQVQY063NwRGAMAgEQOiAY0b/Oa1AW7ACO7D/JowJ8tDx572yuQHklyhg8YSgRtC/xwtHK5FpUJDFOkydpGmACRWfFq4mfbuXnUMeYs0NfcC/mnlLiJNFEjEShyCZWrxxAsZQCuiq327OAAAAAElFTkSuQmCC",'
            '"seller_fee_basis_points": 0,'
            '"external_link": "https://pwp.cyberpnk.win"'
        '}'));
    }
}