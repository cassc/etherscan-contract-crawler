// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {Base64} from "base64-sol/base64.sol";
import {IRender3NUM} from "./interfaces/IRender3NUM.sol";

contract Render3NUM is IRender3NUM, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    // Unauthorized(), MintLimitReached(), InvalidMaxMintCount(uint256 tokenId),
    //    TokenIdAlreadyMinted(uint256 tokenId), InvalidTokenId(uint256 tokenId) from IRender3NUM

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    // PFPMinted & BaseURIUpdated from IRender3NUM

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    Counters.Counter private _tokenSubIds; // Must be incremented before use, ID 0 not allowed.
    uint256 private _maxSubTokens = 0; // 0 means unlimited mints.
    mapping(uint256 => uint256) private subTokens;

    address public minter;
    string public edition;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    // prettier-ignore
    string private constant _SVG_START_TAG = '<svg id="Layer_1" data-name="Layer 1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 965 965">';
    string private constant _SVG_DEFS =
        '<defs><linearGradient id="lg1" x1="-83.7" y1="810.87" x2="1071.39" y2="143.01" gradientTransform="matrix(1, 0, 0, -1, 0, 966)" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#ce4da4" /><stop offset="1" stop-color="#a163f5" /></linearGradient><linearGradient id="shld" x1="565.59" y1="2024.74" x2="398.64" y2="1388.81" xlink:href="#shld2" /><linearGradient id="shld2" x1="181.56" y1="1449.33" x2="161.68" y2="1373.6" gradientTransform="translate(0 -1310.2)" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#6833db" /><stop offset="0.25" stop-color="#6833db" /><stop offset="1" stop-color="#d64db2" /></linearGradient><linearGradient id="text1" x1="834.723" y1="13.0271" x2="738.154" y2="101.412" gradientUnits="userSpaceOnUse"><stop stop-color="#7353E5" /><stop offset="1" stop-color="#CE4DA4" /></linearGradient><linearGradient id="text2" x1="862.217" y1="465.666" x2="803.294" y2="558.142" gradientUnits="userSpaceOnUse"><stop stop-color="#CE4DA4" /><stop offset="1" stop-color="#7353E5" /></linearGradient></defs>';

    string private constant _SVG_RECTS =
        '<rect fill="url(#lg1)" width="965" height="965" rx="35.64" /><rect x="28.8" y="28.8" width="907.39" height="907.39" rx="35.64" />';
    string private constant _SVG_PATH_1 =
        '<path fill="url(#shld)" d="M486.2,324.86l-187.76-49.3V506.72q0,90.84,49.53,139.77t137.39,49q87.89,0,137.41-49t49.57-139.77V275.56Z" />';

    string private constant _SVG_TEXT_1_BEGIN =
        '<text x="482.5" y="220" text-anchor="middle" font-size="50" style="font-family: arial; font-weight: bold; font-style: normal" fill="url(#text1)">';
    string private constant _SVG_TEXT_END = "</text>";
    string private constant _SVG_TEXT_2_BEGIN =
        '<text x="482.5" y="850" text-anchor="middle" font-size="48" style="font-family: arial; font-weight: bold; font-style: normal" fill="url(#text2)">';
    //string private constant _SVG_TEXT_END   = '</text>';
    string private constant _SVG_END_TAG = "</svg>";

    /*//////////////////////////////////////////////////////////////
                                LOGIC
    //////////////////////////////////////////////////////////////*/
    
    constructor(address _minter, string memory _edition) {
        minter = _minter;
        edition = _edition;
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        if (msg.sender != minter) revert Unauthorized();
        _;
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;

        emit MinterUpdated(_minter);
    }

    function setMaxMintCount(uint256 count) external onlyOwner {
        if (count != 0 && count < _tokenSubIds.current()) revert InvalidMaxMintCount(count);

        _maxSubTokens = count;

        emit MaxMintCountUpdated(_maxSubTokens);
    }

    function getMaxMintCount() external view returns (uint256) {
        return (_maxSubTokens);
    }

    function getMintCount() external view returns (uint256) {
        return (_tokenSubIds.current());
    }

    function mintPFP(uint256 tokenId) external onlyMinter returns (uint256) {
        if (_maxSubTokens != 0 && _tokenSubIds.current() >= _maxSubTokens) revert MintLimitReached(); // 0 means unlimited mints.

        _tokenSubIds.increment();

        uint256 _subTokenId = _tokenSubIds.current();

        if ( 0 != subTokens[tokenId] ) revert TokenIdAlreadyMinted(tokenId);

        subTokens[tokenId] = _subTokenId;

        emit PFPMinted(edition, tokenId, _subTokenId);

        return (_subTokenId);
    }

    /**
     * @notice Given a token ID and seed, construct a token URI for an 3NUM
     * @dev The returned value is a base64 encoded data URI or an API URL.
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        uint256 subId = subTokens[_tokenId];

        if (subId == 0) revert InvalidTokenId(_tokenId);

        string memory _name = string(
            abi.encodePacked("3NUM Shield ", edition, " #", subId.toString())
        );
        string memory description = string(
            abi.encodePacked("3NUM Shield is the first Web3 mobile number minted as a NFT that protects your identity and provides private, secure messaging.")
        );

        string memory image = generateSVGImage(subId, string(abi.encodePacked(edition, " #", subId.toString())));

        return genericDataURI(_name, description, edition, image);
    }

    /**
     * @notice Given a name, description, and 3NUM params, construct a base64 encoded data URI.
     */
    function genericDataURI(
        string memory _name,
        string memory _description,
        string memory _edition,
        string memory _image
    ) private pure returns (string memory) {

        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', _name, '", "description":"', _description,
                                          '","attributes":[{"trait_type": "Edition","value": "', _edition, 
                                          '"}], "image": "', 'data:image/svg+xml;base64,', Base64.encode(bytes(_image)),
                                          '"}')
                    )
                )
            )
        );
    }


    function addDot(
        string memory color,
        string memory x,
        string memory y
    ) private pure returns (string memory svg) {
        return string(abi.encodePacked( '<path fill="', color, '" d="M', x, ',', y, 'a36.18,36.18,0,1,1-36.18,36.18h0A36.18,36.18,0,0,1,', x, ',', y, '"/>'));
    }

    /**
     * @notice Generate a single SVG image.
     */
    string private constant x1 = '378.8';
    string private constant x2 = '485.37';
    string private constant x3 = '584.24';
    string private constant ym1 = '379.29';
    string private constant ym2 = '466.57';
    string private constant ym3 = '567.78';
    string private constant y1 = '365.36';
    string private constant y2 = '455.9';
    string private constant y3 = '553.84';

    function generateSVGImage(
        uint256 subId,
        string memory tokenLabel
    ) private pure returns (string memory svg) {

        string[4] memory c = ['#8D56DA', '#C54EAA', '#7352E3', '#30A1DD'];
        uint256 i = subId;

        return string(
            abi.encodePacked( 
                abi.encodePacked( _SVG_START_TAG, _SVG_DEFS ),
                abi.encodePacked( _SVG_RECTS, _SVG_PATH_1 ),
                abi.encodePacked( addDot(c[ i        & 0x3], x1, y1), addDot(c[(i >> 2)  & 0x3], x2, ym1), addDot(c[(i >> 4)  & 0x3], x3, y1) ),
                abi.encodePacked( addDot(c[(i >> 6)  & 0x3], x1, y2), addDot(c[(i >> 8)  & 0x3], x2, ym2), addDot(c[(i >> 10) & 0x3], x3, y2) ),
                abi.encodePacked( addDot(c[(i >> 12) & 0x3], x1, y3), addDot(c[(i >> 14) & 0x3], x2, ym3), addDot(c[(i >> 16) & 0x3], x3, y3) ),
                abi.encodePacked( _SVG_TEXT_1_BEGIN, "3NUM Shield", _SVG_TEXT_END ),
                abi.encodePacked( _SVG_TEXT_2_BEGIN, tokenLabel, _SVG_TEXT_END),
                abi.encodePacked( _SVG_END_TAG )
            )
        );
    }
}