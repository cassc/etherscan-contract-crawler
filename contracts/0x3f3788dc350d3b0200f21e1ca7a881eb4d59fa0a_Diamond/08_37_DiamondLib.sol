//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IERC173 } from "../interfaces/IERC173.sol";

import "./LibDiamond.sol";
import "./LibAppStorage.sol";
import "./EventReporterLib.sol";

import "hardhat/console.sol";

library DiamondLib{

    function setupInterfaces() internal {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        // supports these interfaces
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Metadata).interfaceId] = true;

    }

    function setupEventReporting(address them, address me) internal {
        address[] memory allowed = new address[](2);
        allowed[0] = them;
        allowed[1] = me;
        // create the event reporter contract so that its ready to use
        EventReporterLib.createEventReportingContract(allowed);
        console.log("event reporting is set up");
    } 

    function setupMetadata(
        AppStorage storage appStorage, 
        address tokenAddress,
        BitGemSettings memory params) internal {

        // initialize the metadata
        appStorage.metadata[tokenAddress] = MetadataContract(
            params.name,
            params.symbol,
            params.description,
            params.imageName,
            params.externalUrl
        );
        console.log(string(abi.encodePacked("metadata storage is set up for token: ", params.symbol)));
    }

    function initialize(
        address tokenAddress,
        address _owner, 
        BitGemSettings memory params,
        IDiamondCut.FacetCut[] memory _facets,
        address diamondInit,
        bytes calldata _calldata
    ) public {

        LibDiamond.setContractOwner(_owner);
        setupInterfaces();
        AppStorage storage appStorage = LibAppStorage.diamondStorage();
        setupEventReporting(msg.sender, address(this));
        setupMetadata(appStorage, tokenAddress, params);
        LibDiamond.diamondCut(_facets, diamondInit, _calldata);
        console.log('initialized');
    }

}