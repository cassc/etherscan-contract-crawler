// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./LibStorage.sol";
import "hardhat/console.sol";

import "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "hardhat-deploy/solc_0.8/diamond/interfaces/IDiamondLoupe.sol";

import "hardhat-deploy/solc_0.8/diamond/UsingDiamondOwner.sol";

import { IERC173 } from "hardhat-deploy/solc_0.8/diamond/interfaces/IERC173.sol";

import { ERC721DInternal } from "./ERC721D/ERC721DInternal.sol";

import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

import {BookInternalFacet} from "./BookInternalFacet.sol";
import {ERC2981} from "@solidstate/contracts/token/common/ERC2981/ERC2981.sol";
import {IERC2981} from "@solidstate/contracts/interfaces/IERC2981.sol";

import {ERC2981Storage} from "@solidstate/contracts/token/common/ERC2981/ERC2981Storage.sol";

import "@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol";
import "./PosterInternalFacet.sol";
import {BookDataFacet} from "./BookDataFacet.sol";
import "solady/src/utils/SSTORE2.sol";

contract PosterInitFacet is PosterInternalFacet, OperatorFilterer {
    function init(
        address dataContract,
        string calldata _wordmarkPointer,
        string calldata _fontDeclarationPointer
    ) external onlyOwner {
        if (block.chainid != 31337 && s().isInitialized) return;
        
        _grantRole(ADMIN, msg.sender);
        _grantRole(ADMIN, 0xC2172a6315c1D7f6855768F843c420EbB36eDa97);
        
        setMetadata(
            "Babylon Exhibition Posters",
            "POSTER",
            "Babylon Exhibition Poster",
            "https://babylon.game/"
        );
        
        s().maxBooksPerPoster = 9 * 12;
        
        s().dataContract = dataContract;
        
        s().wordmarkPointer = SSTORE2.write(bytes(_wordmarkPointer));
        s().fontDeclarationPointer = SSTORE2.write(bytes(_fontDeclarationPointer));
        
        s().withdrawAddress = block.chainid == 1 ?
                0x542430459de4A821C32DaA89b00dE3f2A8Cf43b9 :
                0xC2172a6315c1D7f6855768F843c420EbB36eDa97;
        
        ERC2981Storage.layout().defaultRoyaltyBPS = 500;
        ERC2981Storage.layout().defaultRoyaltyReceiver = s().withdrawAddress;
        
        s().operatorFilteringEnabled = true;
        
        ds().supportedInterfaces[type(IERC165).interfaceId] = true;
        ds().supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds().supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds().supportedInterfaces[type(IERC173).interfaceId] = true;
        
        ds().supportedInterfaces[type(IERC721).interfaceId] = true;
        ds().supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
        
        ds().supportedInterfaces[type(IERC2981).interfaceId] = true;
        
        _registerForOperatorFiltering();
        
        s().isInitialized = true;
    }
    
    function setMetadata(
        string memory name,
        string memory symbol,
        string memory nameSingular,
        string memory externalLink
    ) public onlyRole(ADMIN) {
        _setName(name);
        _setSymbol(symbol);
        s().nameSingular = nameSingular;
        s().defaultExternalLink = externalLink;
    }
    
    function setExhibitionInfo(
        uint16 exhibitionNumber,
        string calldata name,
        string calldata qrCode,
        string calldata externalLink,
        bytes calldata bookIds,
        bool markActive
    ) external onlyRole(ADMIN) {
        require(exhibitionNumber > 0);
        
        Exhibition memory newExhibition = Exhibition({
            number: exhibitionNumber,
            qrCodePointer: SSTORE2.write(bytes(qrCode)),
            representativeBooksPointer: SSTORE2.write(bookIds),
            name: name,
            externalLink: externalLink
        });
        
        s().exhibitions[exhibitionNumber] = newExhibition;
        
        if (markActive) s().activeExhibition = exhibitionNumber;
    }
    
    function getExhibition(uint16 exhibitionNumber) external view returns (Exhibition memory) {
        return s().exhibitions[exhibitionNumber];
    }
    
    function setExhibitionTextInfo(
        uint16 exhibitionNumber,
        string calldata name,
        string calldata externalLink
    ) public onlyRole(ADMIN) {
        require(exhibitionNumber > 0);
        
        Exhibition storage existingExhibition = s().exhibitions[exhibitionNumber];
        
        existingExhibition.name = name;
        existingExhibition.externalLink = externalLink;
    }
    
    function markExhibitionActive(uint16 exhibitionNumber) external onlyRole(ADMIN) {
        // require(exhibitionNumber > 0);
        // require(s().exhibitions[exhibitionNumber].number == exhibitionNumber);
        
        s().activeExhibition = exhibitionNumber;
    }
    
    function setWordmarkPointer(string calldata _wordmarkPointer) external onlyRole(ADMIN) {
        s().wordmarkPointer = SSTORE2.write(bytes(_wordmarkPointer));
    }

    function setFontDeclarationPointer(string calldata _fontDeclarationPointer) external onlyRole(ADMIN) {
        s().fontDeclarationPointer = SSTORE2.write(bytes(_fontDeclarationPointer));
    }
    
    function setDefaultQrCodePointer(string calldata _defaultQrCodePointer) external onlyRole(ADMIN) {
        s().defaultQrCodePointer = SSTORE2.write(bytes(_defaultQrCodePointer));
    }
}