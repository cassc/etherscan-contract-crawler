// SPDX-License-Identifier: GPL-3.0

/// @title A library used to construct ERC721 token URIs and SVG images

/**************************************************************************
...........................................................................
...........................................................................
...........................................................................
...........................................................................
.....................     ...............      .......      ...............
...................  .?5?:  ........... .::::::. ... .:::::.  .............
.................  :?B&@&B?:  ....... .^7??????!:. .~7??????~: ............
...............  :J#&&&&&&&#J:  .....^7??????JJJ?!!7????JJJ?J?!............
.............  ^Y#&&&&&&&&&&&#Y^  .. !J??YGGP^^~?JJ?5GGJ^^~????: ..........
...........  ^5&@&&&&&&&&&&&&&@&5~   [email protected]@B. [email protected]@Y  :????:...........
.......... :5&&BBB###&&&&#BBB###&&P: [email protected]@B. [email protected]@Y  :???7............
......... ^P&&#:..7J?G&&&5..:??J#&&G~ ~??J55Y!!!????Y5PJ!!!??7.............
......... [email protected]&&#.  7??G&&&5  :??J#&&@7  ^?????JJJ????????JJJ?7..............
......... [email protected]&&#~^^JYJB&&&P^^~JYY#&&@7 ..:~?J??????????????7^...............
......... :JB&&&&&&&&B#&#B&&&&&&&&#J: ..  .~?J????????J?!:. ...............
..........  :?BBBBBB5YB&BY5BBBBBB?:  .....  .~77???J?7!:. .................
............  ....^Y#@@&@@#Y^....  .......... ..^!7~:.. ...................
..............   .!777???777!.   ............   :^^^.   ...................
..................  .^7?7^.  .............. .~Y5#&&&G57: ..................
................  :~???????~:  .............!&&&&&&&&@@5:..................
.............. .:!?J???????J?!:  ......... ~&&&&&&&&&&&@5 .................
............ .:!??JJJ????????J?!:. ......  ^B&&&&&&&&&&&J  ................
............^!JGBG!^^7???YBBP^^~?!^. .   .^^~YG&&&&&&#57^^:   .............
......... :7??J&&&^  [email protected]@B. .?J?7: :?5G&&&#PY#&&&P5B&&&#5Y^ ............
...........~7?J&&&^  [email protected]@B. .?J?~.:Y&@G77?555#&&&Y!7J55P&&#~............
........... .^75557!!7???J55Y!!!7~.  [email protected]&&5  .???#&&&7  ^??Y&&&&: ..........
............. .^7?JJ?????????J7^. .. J&&&5  .??J#&&&7  ^??Y&&&G: ..........
............... .^7?J???????7^. ..... ?#@#55PBG5#&&&5J5PBBB&&P: ...........
................. .:!?JJJ?!:. ........ ^!JBBBGYP&&&&B5PBBBP!!. ............
................... .:!7!:. ...........   ..:JGBGGGGBG5~ ..   .............
..................... ... ................. ............ ..................
...........................................................................
...........................................................................
...........................................................................
...........................................................................
***************************************************************************/

pragma solidity ^0.8.6;

import { Base64 } from './base64.sol';
import { MultiPartRLEToSVG } from './MultiPartRLEToSVG.sol';
import { IERC721Metadata } from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import { NounsProxy, DescriptorProxy } from '../NounsProxy.sol';
import { PunkDataProxy } from "../PunkDataProxy.sol";
import { BlitmapProxy } from "../BlitmapProxy.sol";
import { ChainRunnerProxy, ChainRunnerRenderProxy } from "../ChainRunnerProxy.sol";

library NFTDescriptor {
//    address constant NOUNS_CONTRACT = address(0xe2CDF5bF7F2E9CEcAF93b2c5D894a3cA0457d0c4);
    address constant NOUNS_CONTRACT = address(0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03);
    address constant PUNK_ORIGINAL_CONTRACT = address(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
    address constant PUNK_DATA_CONTRACT = address(0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2);
    address constant BLITMAP_CONTRACT = address(0x8d04a8c79cEB0889Bdd12acdF3Fa9D207eD3Ff63);
    address constant CHAIN_RUNNER_CONTRACT = address(0x97597002980134beA46250Aa0510C9B90d87A587);
    address constant LOOT_CONTRACT = address(0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7);
    address constant ONCHAIN_MONKEY_CONTRACT = address(0x960b7a6BCD451c9968473f7bbFd9Be826EFd549A);

    struct TokenURIParams {
        string name;
        string description;
        bytes[] parts;
        string background;
        address override_contract;
        uint256 override_token_id;
    }

    // Return a substring of _data[start, end), include _data[start], exclude _data[end]
    function slice(string memory _data, uint start, uint end) internal pure returns (string memory) {
        bytes memory data = bytes(_data);
        string memory result;
        uint outputLen = end - start;

        require(start >= 0, "param error: negtive start");
        require(end > start, "param error: end is smaller or equal than start");
        require(end <= data.length, "param error: end greater than string length");

        if (data.length == 0) return "";
        assembly {
            result := add(data, start)
            mstore(result, outputLen)
        }

        return result;
    }

    function fetchTokenSvg(address tokenContract, uint256 tokenId) public view returns (string memory) {
        string memory decoded_uri = "";
        if (tokenContract == address(0)) {
            return decoded_uri;
        }
        if (NOUNS_CONTRACT == tokenContract) {
            decoded_uri = _handleNounsTokenUri(tokenContract, tokenId);
        } else if (PUNK_ORIGINAL_CONTRACT == tokenContract) {
            decoded_uri = _handlePunkTokenUri(tokenId);
        } else if (BLITMAP_CONTRACT == tokenContract) {
            decoded_uri = _handleBlitmapTokenUri(tokenContract, tokenId);
        } else if (CHAIN_RUNNER_CONTRACT == tokenContract) {
            decoded_uri = _handleChainRunnerTokenUri(tokenContract, tokenId);
        } else {
            decoded_uri = _handleGeneral721TokenUri(tokenContract, tokenId);
        }
        return decoded_uri;
    }

    function _handleNounsTokenUri(address tokenContract, uint256 tokenId) internal view returns (string memory) {
        NounsProxy otherContract = NounsProxy(tokenContract);
        (uint48 a, uint48 b, uint48 c, uint48 d, uint48 e) = otherContract.seeds(tokenId);
        NounsProxy.Seed memory seed = NounsProxy.Seed(a, b, c, d, e);
        DescriptorProxy descriptor = otherContract.descriptor();

        string memory encoded_uri = descriptor.generateSVGImage(seed);
        return string(Base64.decode(encoded_uri));
    }

    function _handlePunkTokenUri(uint256 tokenId) internal view returns (string memory) {
        PunkDataProxy otherContract = PunkDataProxy(PUNK_DATA_CONTRACT);
        string memory svgWithHeader = otherContract.punkImageSvg(uint16(tokenId));
        // remove header "data:image/svg+xml;utf8," and return
        return slice(svgWithHeader, 24, bytes(svgWithHeader).length);
    }

    function _handleBlitmapTokenUri(address tokenContract, uint256 tokenId) internal view returns (string memory) {
        BlitmapProxy otherContract = BlitmapProxy(tokenContract);
        string memory svgWithHeader = otherContract.tokenSvgDataOf(tokenId);
        return slice(svgWithHeader, 54, bytes(svgWithHeader).length);
    }

    function _handleChainRunnerTokenUri(address tokenContract, uint256 tokenId) internal view returns (string memory) {
        ChainRunnerProxy otherContract = ChainRunnerProxy(tokenContract);
        ChainRunnerRenderProxy renderContract = ChainRunnerRenderProxy(otherContract.renderingContractAddress());
        return string(Base64.decodeGetJsonImageData(renderContract.onChainTokenURI(tokenId)));
    }

    function _handleGeneral721TokenUri(address tokenContract, uint256 tokenId) internal view returns (string memory) {
        IERC721Metadata otherContract = IERC721Metadata(tokenContract);
        string memory encodedUri = otherContract.tokenURI(tokenId);
        // remove prefix "data:application/json;base64," and decode
        string memory headlessEncodedUri = slice(encodedUri, 29, bytes(encodedUri).length);
        return string(Base64.decodeGetJsonImgDecoded(headlessEncodedUri));
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(TokenURIParams memory params, mapping(uint8 => string[]) storage palettes)
        public
        view
        returns (string memory)
    {
        string memory image = generateSVGImage(
            MultiPartRLEToSVG.SVGParams({
                parts: params.parts,
                background: params.background,
                center_svg: fetchTokenSvg(params.override_contract, params.override_token_id)
            }),
            palettes
        );

        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', params.name, '", "description":"', params.description, '", "image": "', 'data:image/svg+xml;base64,', image, '"}')
                    )
                )
            )
        );
    }

    /**
     * @notice Generate an SVG image for use in the ERC721 token URI.
     */
    function generateSVGImage(MultiPartRLEToSVG.SVGParams memory params, mapping(uint8 => string[]) storage palettes)
        public
        view
        returns (string memory svg)
    {
        return Base64.encode(bytes(MultiPartRLEToSVG.generateSVG(params, palettes)));
    }
}