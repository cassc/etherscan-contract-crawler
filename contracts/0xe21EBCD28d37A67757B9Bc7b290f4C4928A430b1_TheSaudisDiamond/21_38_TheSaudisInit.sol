// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import { LibDiamond } from "./libraries/LibDiamond.sol";
import { IDiamondLoupe } from "./interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "./interfaces/IDiamondCut.sol";
import { IERC173 } from "./interfaces/IERC173.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";
import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import { IERC721A } from "erc721a/contracts/IERC721A.sol";
import "./libraries/Constants.sol";
import "./libraries/BaseContract.sol";
import "./libraries/AppStorage.sol";
import "./libraries/Hex.sol";
import "hardhat/console.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

contract DiamondInit is
	BaseContract
{    
	// You can add parameters to this function in order to pass in 
    // data to set your own state variables
    function init()
		external onlyOwner
	{	
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
		ds.supportedInterfaces[type(IERC721A).interfaceId] = true;
		ds.supportedInterfaces[type(IERC721).interfaceId] = true;
		ds.supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
		ds.supportedInterfaces[type(IERC2981).interfaceId] = true;

		AppStorage.State storage s = AppStorage.getState();
		s.name = Constants.NAME;
		s.symbol = Constants.SYMBOL;
		s.version = Constants.VERSION;
		s.description = Constants.DESCRIPTION;

		s.paused = true;

		s.tokenBaseExternalUrl = "https://token.thesaudisnft.com/";
		s.contractLevelImageUrl = "https://assets.thesaudisnft.com/logo.png";
		s.contractLevelExternalUrl = "https://www.thesaudisnft.com";
		s.wlMinting = false;
		s.royaltyWalletAddress = 0x7C114bfb123cE75196c4fCb3dF84856cDf04c394;
		s.royaltyBasisPoints = 750;

		// _setDefaultRoyalty(royaltyWalletAddress, royaltyBasisPoints);

		s.attributeTypes[0].name = "Head";
		s.attributeTypes[0].description = "Head of the NFT";
		s.attributeTypes[0].zIndex = 0;
	
		s.attributeTypes[0].selections[0].name = "head-dark-1";
		s.attributeTypes[0].selections[0].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAtklEQVRIiWNgGAXDHjASoeY/JfoJKfi/rjsRp2RQ6XyCZjARYziHiCJWBVB5fD7EawHc8B9v7hNSRr4FlBhOlAWUAhZiFJ04f4eBgYGBwcJQBUOMEMDlA5TU07XsMIOmPB+KAmxi2ABRPsCWVPElX2SAMw6gaZxigMsCnJknqHQ+SZYTFUTIgNiggYHBkUxhADloiPUJSRaQGjwMDBQGETGlKdE+wJFyCNYHpKYiYiooFEDzVAQAUHYtbfcz0SIAAAAASUVORK5CYII=";
		s.attributeTypes[0].selections[1].name = "head-dark-2";
		s.attributeTypes[0].selections[1].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAtUlEQVRIiWNgGAXDHjASoeY/JfoJKfi/rjsRp2RQ6XyCZjARYziHiCJWBVB5fD7EawHc8B9v7hNSRr4FlBhOlAWUAhZiFC3efJKBgYGBIdbXHEOMEMDlA5TUs/7QNQY/a9SIxiaGDRDlA2xJFV/yRQY44wCaxikGuCzAmXmCSueTZDlRQYQMiA0aGBgcyRQGkIOGWJ+QZAGpwcPAQGEQEVOaEu0DHCmHYH1AaioipoJCATRPRQB5rC5p549cPAAAAABJRU5ErkJggg==";
		s.attributeTypes[0].selections[2].name = "head-darker-1";
		s.attributeTypes[0].selections[2].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAtUlEQVRIiWNgGAXDHjASoeY/JfoJKfhfaC+LU7L/4GOCZjARY7iUCD9WBVB5fD7EawHc8GdvPhJSRr4FlBhOlAWUAhZiFD19/piBgYGBQVpSFkOMEMDlA5TUs+oWA4OMICeKAmxi2ACuJIY3eSIDQkkVZxxANVIMcFmA00X9Bx+TZDlRkYwMiA06GBgcyRQGkIOGWJ+QZAGpwcPAQGEQEVOaEu0DHCmHYH1AaioipoJCATRPRQBLiy1Uef9tkwAAAABJRU5ErkJggg==";
		s.attributeTypes[0].selections[3].name = "head-darker-2";
		s.attributeTypes[0].selections[3].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAtUlEQVRIiWNgGAXDHjASoeY/JfoJKfhfaC+LU7L/4GOCZjARY7iUCD9WBVB5fD7EawHc8GdvPhJSRr4FlBhOlAWUAhZiFJ26/ZiBgYGBwUxVFkOMEMDlA5TUc/QZA4O5LCeKAmxi2ACuJIY3eSIDQkkVZxxANVIMcFmA00X9Bx+TZDlRkYwMiA06GBgcyRQGkIOGWJ+QZAGpwcPAQGEQEVOaEu0DHCmHYH1AaioipoJCATRPRQA6VS3JBLgqewAAAABJRU5ErkJggg==";
		s.attributeTypes[0].selections[4].name = "head-light-1";
		s.attributeTypes[0].selections[4].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAtklEQVRIiWNgGAXDHjASoeY/JfoJKfh/e2MDTklV/waCZjARYziPlCZWBVB5fD7EawHc8C/PrhNSRr4FlBhOlAWUAhZiFK3fdYqBgYGBIdDNDEOMEMDlA5TUUzZ1G4OHkRiKAmxi2ABRPsCWVPElX2SAMw6gaZxigMsCnJlH1b+BJMuJCiJkQGzQwMDgSKYwgBw0xPqEJAtIDR4GBgqDiJjSlGgf4Eg5BOsDUlMRMRUUCqB5KgIAHCwuITa/cDMAAAAASUVORK5CYII=";
		s.attributeTypes[0].selections[5].name = "head-light-2";
		s.attributeTypes[0].selections[5].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAtklEQVRIiWNgGAXDHjASoeY/JfoJKfh/e2MDTklV/waCZjARYziPlCZWBVB5fD7EawHc8C/PrhNSRr4FlBhOlAWUAhZiFLXM2MzAwMDAUJPhiyFGCODyAUrqWbj9LENxiC6KAmxi2ABRPsCWVPElX2SAMw6gaZxigMsCnJlH1b+BJMuJCiJkQGzQwMDgSKYwgBw0xPqEJAtIDR4GBgqDiJjSlGgf4Eg5BOsDUlMRMRUUCqB5KgIAEEcvTXc8NnAAAAAASUVORK5CYII=";
		
		s.attributeTypes[1].name = "Hair";
		s.attributeTypes[1].description = "Hair of the NFT";
		s.attributeTypes[1].zIndex = 1;
		s.attributeTypes[1].selections[0].name = "buzzcut";
		s.attributeTypes[1].selections[0].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAcElEQVRIiWP8//8/Ay0BE01NH7Vg1IJRC0YtGCkWsOCTZGRk/M/AwMBIyBB8RT4xPvgPxaTKMTAwEPABFsNIBqRYwJCpzwFnT7/4gyg9jPjCDxoHBMH///9xxhOhOCAYwYTUDIp8gM+FBH2INw6oAQAdSRkqe15k+wAAAABJRU5ErkJggg==";
		s.attributeTypes[1].selections[1].name = "long";
		s.attributeTypes[1].selections[1].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAf0lEQVRIiWP8//8/Ay0BE01NH7Vg1IJRC0YtGCkWsOCTDDMQ+8/AwMC4+uJrnGoIFffE+OB/qL4oVolQfVGClQleHyBbQqQ6ki1ghBkeqi/KcPnNF7iErggPVSxAAcQaigzwxgE0chnxKMEnR9gCNIPQDSNoOAMDAwPjkG9VAAACRBiyHxhQkwAAAABJRU5ErkJggg==";
		s.attributeTypes[1].selections[2].name = "messy";
		s.attributeTypes[1].selections[2].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAcElEQVRIie2VwQ2AMAwDbcQczMUsDNBZmItFzIfydCJEH4j4VampT07UlpIwUtNQ9wIUoAAF+AtgdpskBYCuJnruMwlkTMLPxCboupI8UgrQ1dblXm/7kTpD10OSQNAGSXZGmRk4A2sOBAne0Pcv2gmCKRoq7plQsAAAAABJRU5ErkJggg==";
		s.attributeTypes[1].selections[3].name = "widowspeak";
		s.attributeTypes[1].selections[3].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAbUlEQVRIie2WwQqAMAxDUxHy/5/bU3dxgsNunbKD2BwbyGvoDhMzw0ptS9MTkIAEJOAvgL1nqqoBEAAgCVW9+HVG0s2INLADdrfA6XvqNmghTxQFVMksdASQJmi6SeQG8saPPlMvZASHfP5XUQDRNBwHkyo/CAAAAABJRU5ErkJggg==";

		s.attributeTypes[2].name = "Facial Hair";
		s.attributeTypes[2].description = "Facial hair of the NFT";
		s.attributeTypes[2].zIndex = 2;
		s.attributeTypes[2].selections[0].name = "clean-shaven";
		s.attributeTypes[2].selections[0].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAJklEQVRIie3NMQEAAAjDMMC/52ECvlRA00nqs3m9AwAAAAAAAJy1C7oDLddyCRYAAAAASUVORK5CYII=";
		s.attributeTypes[2].selections[1].name = "light-black-beard";
		s.attributeTypes[2].selections[1].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAWklEQVRIiWNgGAWjYBSMglEwBAAjAfn/DAwMjP///8dtACN+I5hIdxNpgCgfILFJ1U9YATLQkOZEtoTxxtPvBPUQG0QwgxmRMLI4ToDXB7DIhUYkWUE0CggCAFKiEAptnzDCAAAAAElFTkSuQmCC";
		s.attributeTypes[2].selections[2].name = "luxurious-black-beard";
		s.attributeTypes[2].selections[2].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAV0lEQVRIiWNgGAWjYBSMglEwDMB/Sg1gJMECbGr/45FjYGBgYGAhwTFk+YYUCxgy9Tng7OkXfxClh5QgIsscQhYQYwleM5iIsIAiQIwPGBhw+4JY/bQDAH/ICg2UlJRMAAAAAElFTkSuQmCC";
		s.attributeTypes[2].selections[3].name = "luxurious-brown-beard";
		s.attributeTypes[2].selections[3].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAb0lEQVRIie2SwQ3AIAwDTcUIGSO7ZFZ2YQx2oB8e9IEJUvuolJN4OdgIBwiCIAh+QGKiqfTdDACU2pba5XhEH+dUAwBkR8BsdsxJwOMrTOX9AK/pDO2AleedoQGmkphBqQ2mQrdsu4KDVcHe+99xA7xgGIOdUSP1AAAAAElFTkSuQmCC";
		s.attributeTypes[2].selections[4].name = "luxurious-white-beard";
		s.attributeTypes[2].selections[4].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAXElEQVRIie2RsQ6AQAhDn8aB//9atrvFQQePNsbBhJcwlVCg0DRN0/yAbSVm5qh6ACLiUduFJcZZrgbAIRhch9k4BnB/l2ToGthXVBmUAVc9SsivUAxWGyoXfssE2vkLFOM3eo0AAAAASUVORK5CYII=";
		s.attributeTypes[2].selections[5].name = "messy-black-beard";
		s.attributeTypes[2].selections[5].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAUElEQVRIie3OMQ3AMAxE0W8iwRUsBVAswRUi16XtlMgeM9yTvNjSncHMzOwEkpAEoMV8t62oFESEAO7e/v01ZikjLeD9NLHNqRRkJdUMW3sARbsW9stvItIAAAAASUVORK5CYII=";
		s.attributeTypes[2].selections[6].name = "messy-brown-beard";
		s.attributeTypes[2].selections[6].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAT0lEQVRIiWNgGAWjYBSMglEwCugAGAkp8NcRgTH/49K/8cobnPqZiHQIzHBGJIzLUhTAQoLhuAz8z4AnJIjxAaFgxCtPbBDhMoRgHA59AAAOaAkP1WdX/QAAAABJRU5ErkJggg==";
		s.attributeTypes[2].selections[7].name = "messy-white-beard";
		s.attributeTypes[2].selections[7].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAXElEQVRIie2RSwrAMAhENRT0/qfVlV2UQAIxpptCYR4Igjr+iAAAAIAP4CrBzLobWb2qpvXtcJAuzoNlTSeuF+KZYNDmEicbVGfcxssfRDxDu/vyByJCzKXMj7kBQtwQDHofincAAAAASUVORK5CYII=";
		s.attributeTypes[2].selections[8].name = "mustache";
		s.attributeTypes[2].selections[8].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAANUlEQVRIiWNgGAWjYBSMglEwCugAGElQ+58c/URb8P//fwZNGS64JdeffGNkZCTFfaNg2AIAG1wIA3z2UBoAAAAASUVORK5CYII=";
		s.attributeTypes[2].selections[9].name = "normal-black-beard";
		s.attributeTypes[2].selections[9].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAATklEQVRIiWNgGAWjYBSMglEwDMB/Sg1gIsaS//9x2kPQAYyEDCfCAXjNYCHCADhoi5CDs6tWPCJKDyEfMDAQ9gVeM4ixAJ8lxOofBbgBAHzcDARfx9EJAAAAAElFTkSuQmCC";
		s.attributeTypes[2].selections[10].name = "normal-brown-beard+mustache";
		s.attributeTypes[2].selections[10].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAYElEQVRIiWNgGAWjYBSMglEwBAAjPkl/HZH/MDUbr7whywImItT8J+AAvICFSIcQNIhSCxj8dUQYbr7/CuerC3JTxQJGBiTXE2soMiAmDvAlBLyJhFgLYAahG0bQ8OEBAJ/aDHffpuzIAAAAAElFTkSuQmCC";
		s.attributeTypes[2].selections[11].name = "normal-brown-beard";
		s.attributeTypes[2].selections[11].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAXklEQVRIiWNgGAWjYBSMglEwBAAjPkl/HZH/2NRsvPKGwV9HBM7GB5iIcMR/LBbjlEMHLERYQJRBlFoAA8jBRZSlhCxgRDOIZJ8QEwf4EgLeREKsBTCD0A0jaPjwAADYZA2kSnCpuwAAAABJRU5ErkJggg==";
		s.attributeTypes[2].selections[12].name = "normal-white-beard";
		s.attributeTypes[2].selections[12].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAaElEQVRIie2SSw6AMAhEp8YE7n9aWNWNNf0oJXWl4S1hMo8FQBAEQfABkrUUkVwyRHSbUVUw82PH7jgiA0iq2gyJCOfsOmJVUEoaeuFbQaG+dJCuCFJX5Cqt2RwZ8xFme4/AKpnJf8ABUW4V7jT70ZsAAAAASUVORK5CYII=";
		s.attributeTypes[2].selections[13].name = "shadow-beard+mustache";
		s.attributeTypes[2].selections[13].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAATElEQVRIiWNgGAWjYBSMglEwDIAvpQYwUWgJQQcQYwHMoP9YMEHAQqQFDAwMDH5tEXJwTtWKR0RpYiRCDaFg2EypBfgswWv4KCAKAACQpwuI9rNocQAAAABJRU5ErkJggg==";
		s.attributeTypes[2].selections[14].name = "shadow-beard";
		s.attributeTypes[2].selections[14].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAR0lEQVRIie2PMQ4AIAgDW+P3fC0PxMkVGt1MbyKB9ApgjDHmA9ZrwHiUtAWmWOT6E1UAAMjMODNJSUrhpguKaqkIKkkZbiQ26RMHQWPmna4AAAAASUVORK5CYII=";
		s.attributeTypes[2].selections[15].name = "short-grey-beard";
		s.attributeTypes[2].selections[15].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAWElEQVRIie2RMQrAMAwD3dLBz86z5clZGujQuAqZCjoIOAh0YJsJIYT4OwAaABsvM+35B/DZcRKeNoaImGYzLkJAFe0K3kSU9KjCe8dlkbuX+dINFjPB0QFh+SU2GiukKQAAAABJRU5ErkJggg==";
		s.attributeTypes[2].selections[16].name = "short-white-beard";
		s.attributeTypes[2].selections[16].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAW0lEQVRIie2SwQoAIQhEbVnQ//9aPbWnwA3WZukUzDsFyrwsRQghhBxAq4ru3nOPqkpEvHrMrBRcwCX6OMzhufbFDQigoF3BID8pJF0J2hT0exLkD6pFKJeEQDz1Vw/7DjytYQAAAABJRU5ErkJggg==";
		s.attributeTypes[2].selections[17].name = "sideburns";
		s.attributeTypes[2].selections[17].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAJElEQVRIiWNgGAWjYBSMglEwCgiD/5QawERrS4ixYBSMAvwAAHjSAgOKnbIlAAAAAElFTkSuQmCC";
		s.attributeTypes[2].selections[18].name = "stylish-mustache";
		s.attributeTypes[2].selections[18].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAASUlEQVRIiWNgGAWjYBSMglEwCgYL+P//PwMDA8N/LJggYCHBHkYNaU64oTeefmckQS9+APUBWYBYV/xnYGBgRLeIkZF6nhjBAACZWRL8XsTmNAAAAABJRU5ErkJggg==";
		s.attributeTypes[2].selections[19].name = "stytlish-black-sideburns";
		s.attributeTypes[2].selections[19].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAARUlEQVRIiWNgGAWjYBSMglEwChgYGAnI/2dgYGD8//8/ds2MhLQTZwFMHTZbCNrAQtAJSIZpSHMiW8J44+l3ErSPgmELAN2tCgjgVOLMAAAAAElFTkSuQmCC";
		s.attributeTypes[2].selections[20].name = "sytlish-brown-sideburns";
		s.attributeTypes[2].selections[20].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAT0lEQVRIiWNgGAWjYBSMglEwChgYGPFJ6kry/GdgYGC89Owzds2MeLUzMDAwMLAQ4Yj/mjJcjKz/mP+T6kBiLWBgYGBg+M30l7BzR8HIBAAutglaHYvmRgAAAABJRU5ErkJggg==";

		// s.attributeTypes[3].name = "Headgear";
		// s.attributeTypes[3].description = "Things NFTs wear on the head";
		// s.attributeTypes[3].zIndex = 3;
		// s.attributeTypes[3].selections[0].name = "brown-shemagh+agal";
		// s.attributeTypes[3].selections[0].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAmUlEQVRIie2TWxJAMAxFb4yNsA02wIJ1A7oNXUp9eExL2k5QH8b5MkROcwXw83kIAKy1wQKjVfghQFXTLRdEbEERsyeaA4A1WkULyouNOQk7AhsREUkEXq8j7ATTOIi7123P3mcF6wv8VxNyisjJXySQTkAAsK3gHbw1FW6PXODyxOljguQPJBbkiMcT5OIdQa54dkFOfkGSGXvmMfEUVW5uAAAAAElFTkSuQmCC";
		// s.attributeTypes[3].selections[1].name = "brown-shemagh+crown";
		// s.attributeTypes[3].selections[1].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAyklEQVRIie2TsQ7CIBCG/zO+gUuXJvocToy+cDt2aR/AF2iHmujk4uJ2LtIAATwUOvklDFC47ziuwBow8zJizF0V3+Bh4wsydxXzfW8F03Pfuj4jEtTqRm7QEOZ381xUoLmcn7HY4n1egXsLX1kk2QcFOSEAVvcQ0VfdkvwGtboCAHbqIZqHKH4DaIE5xr5JFoR+0q27MA0tA8DYN6kOmeANAcDhePpZYD2yzj4nwS7KkX1MwNPQ5hWUKI8lKMU6glLlWQQl+Qs+8gIjIXwAmZk8FwAAAABJRU5ErkJggg==";
		// s.attributeTypes[3].selections[2].name = "red-shemagh+agal";
		// s.attributeTypes[3].selections[2].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAqUlEQVRIie1UQQ7DIAxLYF8p9+7/b4B795bOu6yTYA6Fih6m1VIUKUJ2TCAiF/4DAMyIbgIAsBzd9Dl3SKBGXor0ClRJWba4dRPIiqo7LdlcJZzlaLPemqtgd3/AAcWtLCQfMK+LRB+6iO7PB62zGSD5oCIi87o0C6jSEXzNAOndeQ95DZlA8mEYcQb2/mu/m0WLgLkGhgiQH/pbDtiOGSewt4ovB6c6eAEZZo6zhsvaXwAAAABJRU5ErkJggg==";
		// s.attributeTypes[3].selections[3].name = "red-shemagh+crown";
		// s.attributeTypes[3].selections[3].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAA3klEQVRIie2UsQ6DIBiED+gbdHEx6SJ7H8En9w0kXbvaxE5dunRprosaUKDQaJMm/RJiQP4775cAfAOS04jRNUV8gwfpE+magrwdHLFx7lsfa5IMyvoq5qIh7Pd2XdRg5HJ6xLST93kN5il8bUn5+qDBmggAzukRQnx0WrL/QVn3AIB9fU+ah9g8wW6+QBJG6ck8FbKHEMuSRYuM0jw+zznaURYtAkCjtACAXKOUBBzaky0ewjEwSq8m7GDdpmxlxQHkjncGk3grK7ayWtfAFh+ev5WAmybwiP8TfC/BC9UDQ1RUVVXlAAAAAElFTkSuQmCC";
		// s.attributeTypes[3].selections[4].name = "red-shemagh";
		// s.attributeTypes[3].selections[4].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAnElEQVRIie2UwQoCMQxE0+Zbmrv+/zc0d/0WHU8rbpmNG6kHcQdCoC3zGGgicug/BGCzem0AANZ7bc93HwEi8xGSBYSmrKcAWfNeWw4wM0FZAK9yNSx3e3W+X+l5HQ9cDafbJeMdiiWAqxURkQyoFB54TABXk6x5pBXA1aYZr8R+TzTdrPYANtfAFAD537+VgE3oPMC7VXwk+GqCB5POyzSgVCG6AAAAAElFTkSuQmCC";
		// s.attributeTypes[3].selections[5].name = "white-shemagh+agal";
		// s.attributeTypes[3].selections[5].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAcklEQVRIie2RQQrAMAgE15L/f9neSiir1qA9hMwpoGFWBQ7bIwCgql6PV5TnIUIbriCAa/5Qx1j9SHrpCFRgjbsCFQQ3oVihrBUBxshZ2JHz8ZMCoCg9E5SmZ4JyLEHZJLOgfD1vQQu/CVrWMwvaOIKQGwRhECvRC0yWAAAAAElFTkSuQmCC";
		// s.attributeTypes[3].selections[6].name = "white-shemagh+gold-agal";
		// s.attributeTypes[3].selections[6].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAiklEQVRIie2S0Q2AMAhED+MILuNgTuFgLuMO+KUxeoCN1A/T+2oK9MFRoOn3EgBQVS/HC8pxEKEJXdCAS34QR88uRUQBYJmGqB7jvO4QOkI0wWtZOwhHvz1kLIFa5BWUigEUCH8Wa4jeWztI6Z4Bir0vBaTLAqRNcgak23MFVNFngCr2nAHV1AChNv9TFyvQnEPfAAAAAElFTkSuQmCC";
		// s.attributeTypes[3].selections[7].name = "white-shemagh+stylish-gold-agal";
		// s.attributeTypes[3].selections[7].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAk0lEQVRIie2RwQ2AIAxFf40j6DAOpks4mA7jDvWEIaWlkoAHwzsZLbz/K9D5PQQAzJybyX2k54FIHRjVU0QMAMc6eQF52a9EliSQDYLAaRZmswK1QeDcZlfgBgDUpH50eZHxE8wG1oFSNMHr/YtA6vvBmi+6PYMUFO++VFAdS1CtSSyovh4paMJngibriQXN6AKXGy2VHYE1/rxiAAAAAElFTkSuQmCC";
		// s.attributeTypes[3].selections[8].name = "white-shemagh-crown";
		// s.attributeTypes[3].selections[8].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAsUlEQVRIie2SMQ7CMAxFv7lCly6VuEpO3jNwhiLBxMLCZpYGpaltHOR04kkd0sR+thPgCJj581ks82gfEDhJSZZ5ZH6cN8nyWvqfY1yCKd2pTqpR7pdxpiBzvbys3O5zoqDuQhqLp3pVEAkB2LweIvrptTTfwZRuAIAhPV1rje4d7AQrnPdaINqHSCNqrt5Cu4Pm6r2C0OolQTiaIKyTUhA+nlrQhcMEXcZTCrrxF3zlDe6NXkzwLacCAAAAAElFTkSuQmCC";
		// s.attributeTypes[3].selections[9].name = "white-shemagh";
		// s.attributeTypes[3].selections[9].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAbElEQVRIie2QQQ7AIAgEl6b//zK9NaZZoCp4MM7JBMywCxy2RwBAVb0dbyjvQ4QuXMEBrvnHHPfoR7JLI0QJpikXWBUBRuReWIKe/ocEQNL1TJB6PROkYwnSkrSC9Hq+ghKWCUrqaQVlHEHIAw+SDSQbz7hoAAAAAElFTkSuQmCC";

		// s.attributeTypes[4].name = "Eyewear";
		// s.attributeTypes[4].description = "Things NFTs wear on the eyes";
		// s.attributeTypes[4].zIndex = 4;
		// s.attributeTypes[4].selections[0].name = "3d-glasses";
		// s.attributeTypes[4].selections[0].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAUUlEQVRIiWNgGAWjYBQMfcCIS+LDhw//STFIQEAAq1k4LUC2xGkuL1xsX/JnBgYGBgZeJye42Od9+3BawESOq0gBBA0gNqio4ZhRMApGwWAFAEc1Ejeq220gAAAAAElFTkSuQmCC";
		// s.attributeTypes[4].selections[1].name = "big-round-shades";
		// s.attributeTypes[4].selections[1].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAUUlEQVRIie2RSwoAMQxCde5/Z7sqk5b+sikUfEsjShLAGPM+HImSfgOpMGKd9XqqAIAmOiSxC19mTZt3RadZXyJgGZQyhzsD7RbRf/QDY8wFCtsjEwidCTWDAAAAAElFTkSuQmCC";
		// s.attributeTypes[4].selections[2].name = "big-shades";
		// s.attributeTypes[4].selections[2].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAARklEQVRIie3NMQ4AIAwCwOL//4yTU0tNJ2PCbdIIEWb2P1zuTAEJAClXXd1AVdIpu5ZsJ8sPKlfkADDqmQ+cHfFWuZm9sAEFNwwMvtjHMQAAAABJRU5ErkJggg==";
		// s.attributeTypes[4].selections[3].name = "classic-shades";
		// s.attributeTypes[4].selections[3].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAATUlEQVRIiWNgGAWjYBQMfcCIR+4/NcxhIqCJkYGBgSHGkp8hxpIfxTA0MZyAhRjnZduwMjAwMDAsOY5fjBLwnwEzyLCJjYJRMAqGJQAAfgwLxb2GAqQAAAAASUVORK5CYII=";
		// s.attributeTypes[4].selections[4].name = "gold-classic-shades";
		// s.attributeTypes[4].selections[4].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAQElEQVRIie3OMQ4AIAhD0Y/3Pw+Xc8DVGMXFmGj6xpICICLvs2QWJ/aUTckAqhvVrc/HbCk7cFUAMXw8y0TkSw2vZQ8xGBu/HgAAAABJRU5ErkJggg==";
		// s.attributeTypes[4].selections[5].name = "green-big-shades";
		// s.attributeTypes[4].selections[5].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAW0lEQVRIiWNgGAWjYBQMfcBIQP4/Dj24xEmyAGJIjilCZMppBBtTHKtZLDhN//+fkZGR8T+DECc2R2ETxwpwWsDICHWQFC92BbjEyQD/4XiGNzHio2AUjAJ6AwAtLBRS8+LsIwAAAABJRU5ErkJggg==";
		// s.attributeTypes[4].selections[6].name = "green-classic-shades";
		// s.attributeTypes[4].selections[6].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAQklEQVRIiWNgGAWjYBQMfcCIR+4/NcxhIqAJojHHFIKRDUMVwwlYiHKfggBxYhSA/wwMDP8ZelwJiY2CUTAKhiUAADNaCY3TvN4hAAAAAElFTkSuQmCC";
		// s.attributeTypes[4].selections[7].name = "horn-rimmed-glasses";
		// s.attributeTypes[4].selections[7].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAPElEQVRIiWNgGAWjYBQMfcCIR+4/NcxiIaTr1PN/hTC2mSRTPy4xXICJgIvQXUWsGFEWjIJRMApGARQAAHD5CRC/FaSZAAAAAElFTkSuQmCC";
		// s.attributeTypes[4].selections[8].name = "laser-eyes-gold";
		// s.attributeTypes[4].selections[8].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAATklEQVRIiWNgGAWjYBQMDvDsMsN/UsSRARP1nUMieHaZ4f//7zP/o7sWlzhJhsLx//8ohsHloeIwTJFlVPUBNktIEUcGAx/Jo2AUjAAAALCvXiUZVCr/AAAAAElFTkSuQmCC";
		// s.attributeTypes[4].selections[9].name = "laser-eyes";
		// s.attributeTypes[4].selections[9].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAdElEQVRIie3RyQ1AUBDG8b/tiZO7HjShDr3oTBN60ILlRcaJiC2IwzvM7/hNMksGlFJusJmRN/mW//86LwfYzMhUJIdtr/K98K4pwATEVc5Ag62RqB29pb7kPYkABHVH1I7e0+vWYX2ZytkFZ/knTj9ZKQUzVcU3kjmeWXEAAAAASUVORK5CYII=";
		// s.attributeTypes[4].selections[10].name = "nerd-glasses";
		// s.attributeTypes[4].selections[10].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAQElEQVRIiWNgGAWjYBQMfcBIhJr/WPRgEyPZArghDbdvQWhVNQYcYjjNYcJjASMOjcT4miTFFAXRKBgFo2A4AACcqwsJ54Si9AAAAABJRU5ErkJggg==";
		// s.attributeTypes[4].selections[11].name = "no-eyewear";
		// s.attributeTypes[4].selections[11].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAJklEQVRIie3NMQEAAAjDMMC/52ECvlRA00nqs3m9AwAAAAAAAJy1C7oDLddyCRYAAAAASUVORK5CYII=";
		// s.attributeTypes[4].selections[12].name = "pixel-big-shades";
		// s.attributeTypes[4].selections[12].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAATklEQVRIie3OywrAIBBDUdP//+frSqjMw3ZVCjkgQsTMjGFm/6fDOyEASQp51dUNyEo6adf19AOw7jSvdAO2EikuWOVvsQ5w33jLzexDE9XdI/GsgjX+AAAAAElFTkSuQmCC";
		// s.attributeTypes[4].selections[13].name = "pixel-regular-shades";
		// s.attributeTypes[4].selections[13].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAATElEQVRIie2PwQoAIAhDXf//z+tQgYnWoVOwdxHm2NRMCPE/qBYkDQBfs1rpDuEk10SmV5QFPmh+k3lSfTv0UDAM7hNfGvVbkRDiZzpfrCH/gTYLqwAAAABJRU5ErkJggg==";
		// s.attributeTypes[4].selections[14].name = "purple-big-shades";
		// s.attributeTypes[4].selections[14].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAZUlEQVRIiWNgGAWjYBQMfcBIQP4/Dj24xEmy4D8DAwNDJo8rXGD6l91wNhZxrGax4DT9/39GRkbG/8qMYtgchU0cK8BpASMjxEGKIqwIwc8IJi5xbK4hBJDDm5EI8VEwCkYBvQEAMigS3fpBCRkAAAAASUVORK5CYII=";
		// s.attributeTypes[4].selections[15].name = "reflective-regular-shades";
		// s.attributeTypes[4].selections[15].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAASklEQVRIie3NMQ6AMAxDUYdT+f4X+yxUQqgZChOV3xQ5kSNFxP9VtwBUVXztOtrrR7nt8bhm+TJAkpCEbcbc5a8e3MuuwjaPiJ2dNrAt0onoBJkAAAAASUVORK5CYII=";
		// s.attributeTypes[4].selections[16].name = "reflective-square-shades";
		// s.attributeTypes[4].selections[16].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAARklEQVRIie3QSwoAIAxDwfZWvf/F4lKMFX+rQgbcPEWxZiJSn2cRQD/gDtp2AGm/eRi8ImJq1J/x5bs+OPnWahRfIxKRShoMWyGO08BWQAAAAABJRU5ErkJggg==";
		// s.attributeTypes[4].selections[17].name = "regular-shades";
		// s.attributeTypes[4].selections[17].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAL0lEQVRIiWNgGAWjYBSMAoKAEYf4f2qZhcsCfJYxEhAnC/zHYiA+8VEwCkbBsAIAZRwG/3nqKWUAAAAASUVORK5CYII=";
		// s.attributeTypes[4].selections[18].name = "rimless-glasses";
		// s.attributeTypes[4].selections[18].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAWElEQVRIie3Qyw2AIBCE4X+NRdiIfUkn9EUjdDGeTLjAmhhv8x33MWQBM7NULHoCQlIeEvOYLXlcq+U39qQfgFpXeQrnERWgdV3DXJ0FTC8YvubbCWb2vxuBDRC+NvhJ3QAAAABJRU5ErkJggg==";
		// s.attributeTypes[4].selections[19].name = "round-shades";
		// s.attributeTypes[4].selections[19].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAMklEQVRIiWNgGAWjYBSMHPAfiokVhwNGPAaSCrCahcsCfJYxEhAnC5AdRKNgFIyC4QAAsegK+01gFc0AAAAASUVORK5CYII=";
		// s.attributeTypes[4].selections[20].name = "small-shades";
		// s.attributeTypes[4].selections[20].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAL0lEQVRIiWNgGAWjYBSMAoKAkYD8fyqYQZTh/7FYhk0MAzDhkSPbZaNgFIyC4QYAovwGAIP/A58AAAAASUVORK5CYII=";
		// s.attributeTypes[4].selections[21].name = "square-shades";
		// s.attributeTypes[4].selections[21].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAPUlEQVRIie3NMQ4AIAxCUfD+d8bR2DS1jkbeiDUfMLP3MRslrQNS4ZmS0r0dABA/d1wFqhgP+2Y0Amb2vQnbuwsGU218pwAAAABJRU5ErkJggg==";
		// s.attributeTypes[4].selections[22].name = "stylish-nerd-glasses";
		// s.attributeTypes[4].selections[22].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAARUlEQVRIiWNgGAWjYBQMfcBIhJr/WPRgEyPZArghn1YXMzAwMDDwhfYy4BDDaQ4THgsYcWgkxtckKaYoiEbBKBgFwwEAAJpbCwl+/AqTAAAAAElFTkSuQmCC";
		// s.attributeTypes[4].selections[23].name = "vr";
		// s.attributeTypes[4].selections[23].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAWElEQVRIiWNgGAWjYBTQHDASoeY/JeYQsuD/woULGZSUlHAquHfvHkN8fDwxZmEavmjRov+HDx/+zwDxBVaMJI8VMOG14T8xoYMf0DyIaB7Jo2AUjAI6AABkXyVwTmw1BAAAAABJRU5ErkJggg==";

		// s.attributeTypes[5].name = "Mouthpiece";
		// s.attributeTypes[5].description = "Things NFTs put on/in their mouths";
		// s.attributeTypes[5].zIndex = 5;
		// s.attributeTypes[5].selections[0].name = "bubble-gum";
		// s.attributeTypes[5].selections[0].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAXklEQVRIiWNgGAWjYBSMglEwBAAjpQb8b1j1H8XAhjAUMymy4H/Dqv8MYvyogq8+oljCRLHhmW6oEmL8KL4iywIUw6fvwquWLAsYG8IYGV59JGg4AwMd4oDmqWjoAwDWyySle1Ot6wAAAABJRU5ErkJggg==";
		// s.attributeTypes[5].selections[1].name = "cigar";
		// s.attributeTypes[5].selections[1].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAPklEQVRIiWNgGAWjYBSMAvqDu3fvNiDzmWht4agFAw8YKdD7nxhzWcg13UBODKv4hUevsNtEBiDKB6Ng4AEAaw0IJrHp4okAAAAASUVORK5CYII=";
		// s.attributeTypes[5].selections[2].name = "cigarette-1";
		// s.attributeTypes[5].selections[2].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAQ0lEQVRIiWNgGAWjYBSMAhRw7969BnQxJlpbOmrBwFtAc8BIgd7/xJhJrgX/jx07hiEoMzWBQW7pLRRzae6DUTDwAADdDQsodjv/MgAAAABJRU5ErkJggg==";
		// s.attributeTypes[5].selections[3].name = "cigarette-2";
		// s.attributeTypes[5].selections[3].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAO0lEQVRIiWNgGAWjYBSMAhRw7969BnQxJlpbOmrBwFsw9AEjmfr+Hzt2DENQZmoCg9zSW+SaOQqGKgAAxHkJJmqeTccAAAAASUVORK5CYII=";
		// s.attributeTypes[5].selections[4].name = "no-mouthpiece";
		// s.attributeTypes[5].selections[4].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAJklEQVRIie3NMQEAAAjDMMC/52ECvlRA00nqs3m9AwAAAAAAAJy1C7oDLddyCRYAAAAASUVORK5CYII=";
		// s.attributeTypes[5].selections[5].name = "pear-wood-pipe";
		// s.attributeTypes[5].selections[5].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAh0lEQVRIie2TQQqAIBBFXx3Fa7QXPIGnEYJu4iUC9x6ioLNMK0OiRZQFhQ8+4iD/MzgDlUql8j4hhD6/N0+Za617gLZkwD/Y/8H3KNmBnHl0dYokOrMPkQPd2gOJztANY/JJoQBb/fIeRGeabhjJO1nmify8TTKPzmzyVgkg3qqyIbm8VaSAFcI9PlqIqn+nAAAAAElFTkSuQmCC";
		// s.attributeTypes[5].selections[6].name = "rose-wood-pipe";
		// s.attributeTypes[5].selections[6].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAf0lEQVRIiWNgGAWjYBSMAvqDXbt2NSDzGWlluJubWwMDAwMDEzUtGB4APQ6GHqCmD/4To4jcVPS/NVAE3ZL/WDBF+eB/a6AIQ/X6NzBzYJYyMDAwwMUpyQeM1evfMCD75PHrLwzINMxmSgGKyx+//sIw48gPuNnUKirQIxxuLgCh0C579GpTowAAAABJRU5ErkJggg==";
		// s.attributeTypes[5].selections[7].name = "vape-1";
		// s.attributeTypes[5].selections[7].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAANElEQVRIiWNgGAWjYBSMglEwCugAGCnQ+58Yc1nINTwyMhJDcPnzZQwMB1DdTHMfjIKBBwApIAcGzyI6egAAAABJRU5ErkJggg==";
		// s.attributeTypes[5].selections[8].name = "vape-2";
		// s.attributeTypes[5].selections[8].dataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAALUlEQVRIiWNgGAWjYBSMglEwCoYDYCRT3//IyEgMweXPlzEwHGAk18xRMFQBAAuwBQIJXf2yAAAAAElFTkSuQmCC";

        // add your own state variables 
        // EIP-2535 specifies that the `diamondCut` function takes two optional 
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface 
    }


}