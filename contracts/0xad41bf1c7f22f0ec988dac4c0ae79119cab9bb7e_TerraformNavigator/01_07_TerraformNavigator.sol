// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "hardhat/console.sol";
import "./libs/ToString.sol";
import "./interfaces/ITerraforms.sol";
import "./interfaces/ITerraformsData.sol";
import "./interfaces/ITerraformsDataInterfaces.sol";

import {IScriptyBuilder, WrappedScriptRequest} from "./interfaces/IScriptyBuilder.sol";


contract TerraformNavigator {

    address immutable terraformsAddress;
    address immutable terraformsDataAddress;
    address immutable terraformsCharactersAddress;

    address immutable scriptyBuilderAddress;
    address immutable ethfsFileStorageAddress;

    mapping(ITerraforms.Status => string) statusToLabel;

    constructor(
        address _terraformsAddress,
        address _terraformsDataAddress,
        address _terraformsCharactersAddress,
        address _scriptyBuilderAddress, 
        address _ethfsFileStorageAddress) {

        terraformsAddress = _terraformsAddress;
        terraformsDataAddress = _terraformsDataAddress;
        terraformsCharactersAddress = _terraformsCharactersAddress;

        scriptyBuilderAddress = _scriptyBuilderAddress;
        ethfsFileStorageAddress = _ethfsFileStorageAddress;

        statusToLabel[ITerraforms.Status.Terrain] = "Terrain";
        statusToLabel[ITerraforms.Status.Daydream] = "Daydream";
        statusToLabel[ITerraforms.Status.Terraformed] = "Terraformed";
        statusToLabel[ITerraforms.Status.OriginDaydream] = "Origin Daydream";
        statusToLabel[ITerraforms.Status.OriginTerraformed] = "Origin Terraformed";
    }

    function resolveMode() external pure returns (bytes32) {
        return "manual";
    }

    fallback(bytes calldata cdata) external returns (bytes memory) {
        if(cdata.length == 0) {
            return bytes("");
        }
        else if(cdata[0] != 0x2f) {
            return abi.encode("Incorrect path");
        }

        // Frontpage call
        if (cdata.length == 1) {
          return bytes(abi.encode(indexHTML(1)));
        }
        // /index/[uint]
        else if(cdata.length >= 6 && ToString.compare(string(cdata[1:6]), "index")) {
            uint page = 1;
            if(cdata.length >= 8) {
                page = ToString.stringToUint(string(cdata[7:]));
            }
            if(page == 0) {
                return abi.encode("404");
            }
            return abi.encode(indexHTML(page));
        }
        // /view/[uint]
        // Until ERC-7087 is accepted : do a proxy for the terraform SVGs
        // /view/[uint].svg
        else if(cdata.length >= 5 && ToString.compare(string(cdata[1:5]), "view")) {
            uint terraformsTotalSupply = ITerraforms(terraformsAddress).totalSupply();

            bool renderAsSvg = false;
            if(cdata.length >= 11 && ToString.compare(string(cdata[cdata.length - 4:]), ".svg")) {
                renderAsSvg = true;
                cdata = cdata[:cdata.length - 4];
            }

            uint tokenId = 1;
            if(cdata.length >= 7) {
                tokenId = ToString.stringToUint(string(cdata[6:]));
            }
            if(tokenId == 0 || tokenId > terraformsTotalSupply) {
                return abi.encode("404");
            }

            if(renderAsSvg) {
                return abi.encode(ITerraforms(terraformsAddress).tokenSVG(tokenId));
            }
            return abi.encode(viewHTML(tokenId));
        }

        return abi.encode("404");
    }

    function indexHTML(uint pageNumber) internal view returns (string memory) {

        uint terraformsTotalSupply = ITerraforms(terraformsAddress).totalSupply();
        uint terraformsPerPage = 10;
        uint pagesCount = terraformsTotalSupply / terraformsPerPage + (terraformsTotalSupply % terraformsPerPage > 0 ? 1 : 0);

        (string memory headerCSS, string memory headerHTML) = getHeader();

        WrappedScriptRequest[] memory requests = new WrappedScriptRequest[](3);

        requests[0].wrapType = 4; // [wrapPrefix][script][wrapSuffix]
        requests[0].wrapPrefix = '<link rel="stylesheet" href="data:text/css;base64,';
        requests[0].name = "simple-2.1.1-06b44bd.min.css";
        requests[0].contractAddress = ethfsFileStorageAddress;
        requests[0].wrapSuffix = '" />';

        requests[1].wrapType = 4; // [wrapPrefix][script][wrapSuffix]
        requests[1].wrapPrefix = "<style>";
        requests[1].scriptContent = abi.encodePacked(
            'body{'
                'grid-template-columns: 1fr min(80rem,90%) 1fr'
            '}',
            headerCSS,
            '.items{'
                'display:grid; gap: 2rem; grid-template-columns: repeat(5, 1fr); grid-auto-rows: min-content;'
            '}'
            '@media (max-width: 1024px){'
                '.items{'
                    'grid-template-columns: repeat(3, 1fr);'
                '}'
            '}'
            '@media (max-width: 768px){'
                '.items{'
                    'grid-template-columns: repeat(2, 1fr);'
                '}'
            '}'
            '.item{'
                'text-align: center; margin-bottom: 10px'
            '}'
            '.item img{'
                'display: block; margin-bottom: 6px'
            '}'
            '.item .detail{'
                'line-height: 1.3'
            '}'
            '.center{'
                'text-align: center'
            '}'
        );
        requests[1].wrapSuffix = "</style>";

        string memory page;
        for(uint tokenId = (pageNumber - 1) * terraformsPerPage + 1; tokenId <= pageNumber * terraformsPerPage && tokenId <= terraformsTotalSupply; tokenId++) {

            ITerraforms.TokenData memory tokenData = ITerraforms(terraformsAddress).tokenSupplementalData(tokenId);
            (,,, uint biomeIndex) = ITerraformsData(terraformsDataAddress).characterSet(ITerraforms(terraformsAddress).tokenToPlacement(tokenId), ITerraforms(terraformsAddress).seed());

            page = string(abi.encodePacked(
                page,
                '<div class="item">'
                    '<a href="/view/', ToString.toString(tokenId), '">'
                        '<img src="/view/', ToString.toString(tokenId), '.svg">'
                        // Wait until ERC-7087 is accepted
                        // '<img src="web3://0x', ToString.addressToString(terraformsAddress) , ':', ToString.toString(block.chainid), '/tokenSVG/', ToString.toString(tokenId), '.svg">'
                    '</a>'
                    '<div class="detail">'
                        '<a href="/view/', ToString.toString(tokenId), '">',
                            ToString.toString(tokenId),
                        '</a>'
                    '</div>'
                    '<div class="detail">'
                        'L', ToString.toString(tokenData.level), '/B', ToString.toString(biomeIndex), '/', tokenData.zoneName,
                    '</div>'
                '</div>'
            ));
        }

        page = string(abi.encodePacked(
            headerHTML,
            '<div class="items">',
            page,
            '</div>'
            '<div class="center">'
        ));

        if(pageNumber > 1) {
            page = string(abi.encodePacked(
                page,
                '<a href="/index/', ToString.toString(int(pageNumber - 1)), '">'
                '[&lt; prev]'
                '</a>'
            ));
        }
        if(pageNumber < pagesCount) {
            page = string(abi.encodePacked(
                page,
                '<a href="/index/', ToString.toString(int(pageNumber + 1)), '">'
                '[next &gt;]'
                '</a>'
            ));
        }

        page = string(abi.encodePacked(
            page,
            '</div>'
        ));
        requests[2].wrapType = 4; // [wrapPrefix][script][wrapSuffix]
        requests[2].scriptContent = bytes(page);


        bytes memory html = IScriptyBuilder(scriptyBuilderAddress)
            .getHTMLWrapped(requests, IScriptyBuilder(scriptyBuilderAddress).getBufferSizeForHTMLWrapped(requests));

        return string(html);
    }

    // function thumbnailSVG(uint256 tokenId) public view returns (string memory) {

    //     string svg = ITerraforms(terraformsSVGAddress).tokenSVG(tokenId);

    // }

    function viewHTML(uint256 tokenId) internal view returns (string memory) {
        // Main token data
        ITerraforms.TokenData memory tokenData = ITerraforms(terraformsAddress).tokenSupplementalData(tokenId);
        // Biome
        (string[9] memory charsSet, uint font,, uint biomeIndex) = ITerraformsData(terraformsDataAddress).characterSet(ITerraforms(terraformsAddress).tokenToPlacement(tokenId), ITerraforms(terraformsAddress).seed());
        
        (string memory headerCSS, string memory headerHTML) = getHeader();

        WrappedScriptRequest[] memory requests = new WrappedScriptRequest[](3);

        requests[0].wrapType = 4; // [wrapPrefix][script][wrapSuffix]
        requests[0].wrapPrefix = '<link rel="stylesheet" href="data:text/css;base64,';
        requests[0].name = "simple-2.1.1-06b44bd.min.css";
        requests[0].contractAddress = ethfsFileStorageAddress;
        requests[0].wrapSuffix = '" />';

        requests[1].wrapType = 4; // [wrapPrefix][script][wrapSuffix]
        requests[1].wrapPrefix = "<style>";
        requests[1].scriptContent = abi.encodePacked(
            'body{'
                'grid-template-columns: 1fr min(80rem,90%) 1fr'
            '}',
            headerCSS,
            '.grid{'
                'display: grid; gap: 2rem; grid-template-columns: 1fr 1fr; grid-auto-rows: min-content;'
            '}'
            '@media (max-width: 768px){'
                '.grid{'
                    'grid-template-columns: 1fr;'
                '}'
            '}'
            '.attrs{'
                'display: grid; gap: 1rem; grid-auto-rows: min-content;'
            '}'
            '.attrs strong{'
                'display: block;'
            '}'
            '.attrs1{'
                'grid-template-columns: repeat(4, 1fr); margin-bottom: 15px'
            '}'
            '.attrs2{'
                'grid-template-columns: repeat(3, 1fr); margin-bottom: 15px'
            '}'
            '.attrs3{'
                'grid-template-columns: repeat(9, 1fr)'
            '}'
            '@font-face {'
                'font-family:"MathcastlesRemix-Regular";'
                'font-display:block;'
                'src:url(data:application/font-woff2;charset=utf-8;base64,', ITerraformsCharacters(terraformsCharactersAddress).font(font), ') format("woff");'
            '}'
            '.chars-set {'
                'font-family: "MathcastlesRemix-Regular"'
            '}'
            );
        requests[1].wrapSuffix = "</style>";

        // Splitting due to stack too deeeep
        bytes memory page;
        {
            // Mode/status
            ITerraforms.Status tokenStatus = ITerraforms(terraformsAddress).tokenToStatus(tokenId);

            page = abi.encodePacked(
                '<div class="attrs attrs1">'
                    '<div>'
                        '<strong>Mode</strong>'
                        '<span>', statusToLabel[tokenStatus], '</span>'
                    '</div>'
                    '<div>'
                        '<strong>Level</strong>'
                        '<span>', ToString.toString(tokenData.level), '</span>'
                    '</div>'
                    '<div>'
                        '<strong>Zone</strong>'
                        '<span>', tokenData.zoneName, '</span>'
                    '</div>'
                    '<div>'
                        '<strong>Biome</strong>'
                        '<span>', ToString.toString(biomeIndex), '</span>'
                    '</div>'
                '</div>'
            );
        }
        {
            // Resource ???
            uint resourceLevel = ITerraformsData(terraformsDataAddress).resourceLevel(ITerraforms(terraformsAddress).tokenToPlacement(tokenId), ITerraforms(terraformsAddress).seed());

            page = abi.encodePacked(
                page,
                '<div class="attrs attrs2">'
                    '<div>'
                        '<strong>X</strong>'
                        '<span>', ToString.toString(tokenData.xCoordinate), '</span>'
                    '</div>'
                    '<div>'
                        '<strong>Y</strong>'
                        '<span>', ToString.toString(tokenData.yCoordinate), '</span>'
                    '</div>'
                    '<div>'
                        '<strong>???</strong>'
                        '<span>', ToString.toString(resourceLevel), '</span>'
                    '</div>'
                '</div>'
            );
        }
        {
            bytes memory charsSetSection;
            for(uint i = 0; i < charsSet.length; i++) {
                charsSetSection = abi.encodePacked(
                    charsSetSection,
                    '<div>'
                        '<div class="chars-set">', charsSet[i], '</div>'
                        '<span>', ToString.toString(i), '</span>'
                    '</div>'
                );
            }

            page = abi.encodePacked(
                page,
                '<div>'
                    '<strong>Character set</strong>'
                '</div>'
                '<div class="attrs attrs3">',
                    charsSetSection,
                '</div>'
            );
        }
        {
            uint terraformsTotalSupply = ITerraforms(terraformsAddress).totalSupply();

            bytes memory links;
            if(tokenId > 1) {
                links = abi.encodePacked('<a href="/view/', ToString.toString(tokenId - 1) , '">[&lt; prev]</a> ');
            }
            if(tokenId < terraformsTotalSupply) {
                links = abi.encodePacked(links, '<a href="/view/', ToString.toString(tokenId + 1) , '">[next &gt;]</a> ');
            }
            page = abi.encodePacked(
                '<div style="display: grid; grid-template-columns: minmax(0, 1fr) auto; margin-bottom: 15px;">'
                    '<div>'
                        '<div>Parcel</div>'
                        '<div style="font-size: 1.7rem; font-weight: bold;">', ToString.toString(tokenId), '</div>'
                    '</div>'
                    '<div>',
                        links,
                    '</div>'
                '</div>',
                page
            );
        }
        page = abi.encodePacked(
            headerHTML,
            '<div class="grid">'
                '<div>'
                    '<img src="/view/', ToString.toString(tokenId) ,'.svg">'
                    // Wait until ERC-7087 is accepted
                    // '<img src="web3://0x', ToString.addressToString(terraformsAddress), ':', ToString.toString(block.chainid), '/tokenSVG/', ToString.toString(tokenId) ,'.svg">'
                '</div>'
                '<div>',
                    page,
                '</div>'
            '</div>'         
        );

        requests[2].wrapType = 4; // [wrapPrefix][script][wrapSuffix]
        requests[2].scriptContent = page;


        bytes memory html = IScriptyBuilder(scriptyBuilderAddress)
            .getHTMLWrapped(requests, IScriptyBuilder(scriptyBuilderAddress).getBufferSizeForHTMLWrapped(requests));

        return string(html);
    }

    function getHeader() internal view returns (string memory headerCSS, string memory headerHTML) {
        headerCSS = 
            '.site-title{'
                'display: grid; grid-template-columns: minmax(0, 1fr) auto; margin-top: 1.5rem;'
            '}'
            '.site-title h4 {'
                'margin-top: 0px'
            '}'
            '.site-title a{'
                'text-decoration: none;'
            '}'
            '.site-title input{'
                'width: 100px;'
            '}';

        headerHTML = 
            '<div class="site-title">'
                '<h4>'
                    '<a href="/">'
                        'Terraform navigator'
                    '</a>'
                '</h4>'
                '<div class="search-box">'
                    '<input type="text" placeholder="Token id" onkeypress="if(event.keyCode === 13){let id = parseInt(event.srcElement.value); if(isNaN(id) == false && id > 0){ window.location=\'/view/\' + id }}">'
                '</div>'
            '</div>';
    }

}