// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Base64.sol";

/*
@title  Rowpepens
@author @marka_eth
@notice “The impediment to action advances action. What stands in the way becomes the way." — Marcus Aurelius
@notice Thanks to @backseats_eth for input & reference code, @JosephRoccisan0 for continued help, and of course, the king @jalil_eth
*/

contract Rowpepens is ERC721A, Ownable {

    address systemAddress;
    bool mintEnabled;

    struct Rowpepen {
        uint256 num;
        uint24 score; // could be over 65535 so uint16 not enough 
        uint16 rows; // 255 enough? nah, saruo or jebus are guns so let's go with uint16
        uint8 level; // 255 enough? surely!
        uint8 leaderboredPos;   // 0, 1 , 2 or 3 [sic...]
        uint8 gameplayMode; // Season, Tournament, In It For The Art modes FOR THE CULTURE
        uint8[200] boredGame;   // Hat tip to @BoredElonMusk, largest hodler of Opepens at time of contract deployment
    }

    string[] public gameplayModes = ["Season", "Tournament", "In It For The Art 001", "In It For The Art 003", "In It For The Art 006", "In It For The Art 0TG"];
    string[] public colours001 = ["","60c9bf", "9cf0bf", "68d3de", "4291a7", "85e48d", "b6f13b", "110f10", "110f10", "3eb9a1", "9cf0bf", "ffffff", "b6f13b", "b6f13b", "9cf0bf", "68d3de", "60c9bf"];
    string[] public colours003 = ["","f41913", "f41913", "1ab01e", "3f27f2", "efe51d", "110f10", "e6e4ef"];
    string[] public colours006 = ["","f43e13", "f99bc2", "f9be02", "088c57", "110f10", "e9e1d2", "e9e1d2", "e9e1d2", "f99bc2", "088c57", "f9be02", "1601ff", "f99bc2", "f9be02", "f43e13", "110f10"];
    string[] public colours0TG = ["","7cc14a", "d2da8f", "d2da8f", "97a043", "97a043", "513f55", "513f55", "513f55", "74c84e", "97a043", "a08385", "110f10", "d2da8f", "d2da8f", "f4a4c1", "a08385"];
    string[] public idsToUse = ["","qtl", "qtr", "qbl", "qbr"];
    string[] public coloursLB = ["","000","1ded88","1D9BF0"];

    // tokenId => Rowpepen
    mapping(uint256 => Rowpepen) public rowpepens;

    // Tracking which nonces have been used from the server
    mapping (string => bool) usedNonces;

    error MintClosed();
    error NoContracts();
    error NonceAlreadyUsed();
    error InvalidSignature();
    error InvalidLeaderboredPos();
    error InvalidGameplayMode();

    constructor() ERC721A("Rowpepens", "ROWPEPEN") {
    }

    // Mint
    function mint(uint8[200] calldata boredGame, uint24 score, uint16 rows, uint8 level, uint8 gameplayMode, uint8 leaderboredPos, string calldata nonce, bytes calldata signature) external payable {
        
        if (msg.sender != tx.origin) revert NoContracts();
        if (mintEnabled == false) revert MintClosed();
        if (leaderboredPos < 0 || leaderboredPos > 3) revert InvalidLeaderboredPos();
        if (gameplayMode < 0 || gameplayMode > 5) revert InvalidGameplayMode();
        if (!isValidSignature(keccak256(abi.encodePacked(msg.sender, nonce)), signature)) revert InvalidSignature();
        if (usedNonces[nonce]) revert NonceAlreadyUsed();
        
        uint256 tokenId = uint256(totalSupply() + 1);

        rowpepens[tokenId] = Rowpepen({
            num: tokenId,
            boredGame: boredGame,
            score: score,
            rows: rows,
            level: level,
            leaderboredPos: leaderboredPos,
            gameplayMode: gameplayMode
        });

        usedNonces[nonce] = true;

        _mint(msg.sender, 1);
    }

    using ECDSA for bytes32;
    /// @notice Checks if the private key that singed the nonce matches the system address of the contract
    function isValidSignature(bytes32 hash, bytes calldata signature) internal view returns (bool) {
        require(systemAddress != address(0), "Missing system address");
        bytes32 signedHash = hash.toEthSignedMessageHash();
        return signedHash.recover(signature) == systemAddress;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require( _exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return buildMetadata(_tokenId);
    }

    function buildMetadata(uint256 _tokenId) internal view returns (string memory) {

        Rowpepen memory currentRowpepen = rowpepens[_tokenId];

        bytes memory svg = buildImage(_tokenId);

        string memory name = string(
            abi.encodePacked(
                "Rowpepen #", toString(currentRowpepen.num)
            )
        );

        bytes memory metadata = abi.encodePacked(
            '{',
                '"name":"', name,'",', 
                '"image": ',
                    '"data:image/svg+xml;base64,',
                    Base64.encode(svg),
                    '",',
                '"attributes": [', attributes(currentRowpepen), ']',
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(metadata)
            )
        );
    }

    /// @dev Generate cells
    function generateCells(uint8[200] memory currentBoredGame, uint8 gameplayMode ) internal view returns (bytes memory) {
        bytes memory cellBytes;
        uint8 cellSize = 38;
        uint16 xStart = 324;
        uint16 yStart = 790;

        string memory colourToUse = 'ffffff'; //default to white

        // generate cells
        for(uint i = 0; i < 200; i++) {
            uint8 cell = currentBoredGame[i];
            if (cell != 0) {
                uint x = xStart + (i % 10) * cellSize;
                uint y = yStart - (i / 10) * cellSize;
                string memory idToUse = "sq"; // default to sq

                if(gameplayMode == 2) { // IIFTA 001
                    if(cell >= 0 && cell < 17) {
                        colourToUse = colours001[cell];
                        if(cell > 8) idToUse = (cell > 12) ? idsToUse[cell - 12] :  idsToUse[cell - 8];
                    }
                }
                else if(gameplayMode == 3) { // IIFTA 003
                    colourToUse = colours003[cell];
                }
                else if(gameplayMode == 4) { // IIFTA 006
                    if(cell >= 0 && cell < 17) {
                        colourToUse = colours006[cell];
                        if(cell > 8) idToUse = (cell > 12) ? idsToUse[cell - 12] :  idsToUse[cell - 8];
                    }
                }
                else if(gameplayMode == 5) { // IIFTA 0TG
                    if(cell >= 0 && cell < 17) {
                        colourToUse = colours0TG[cell];
                        if(cell > 8) idToUse = (cell > 12) ? idsToUse[cell - 12] :  idsToUse[cell - 8];
                    }
                } 
                else { // modes 0 and 1
                    if(cell > 3 && cell < 8) idToUse = idsToUse[cell - 3];
                }
                
                cellBytes = abi.encodePacked(cellBytes, abi.encodePacked(
                    '<g transform="translate(', toString(x), ' ', toString(y), ')"><use href="#', idToUse, '" fill="#', colourToUse, '"/></g>'
                ));
            }
        }

        return cellBytes;
    }

    /// @dev Generate Rowpepen head and body
    function generateRowpepen(Rowpepen memory currentRowpepen) internal view returns (bytes memory) {

        bytes memory rowpepenBytes;

        string memory headBgColour = '#272727';
        if(currentRowpepen.gameplayMode == 4 ) headBgColour = '#F2F2F2';
        else if(currentRowpepen.gameplayMode == 5 ) headBgColour = '#514956';
   
        // generate body
        rowpepenBytes = abi.encodePacked(rowpepenBytes, abi.encodePacked(
            '<path d="M709,1029H315c0-54,44-98,98-98h198C665,931,709,975,709,1029z" class="l"/>',
            '<line x1="415" x2="415" y1="930" y2="1024" class="l"/><line x1="512" x2="512" y1="930" y2="1024" class="l"/><line x1="612" x2="612" y1="930" y2="1024" class="l"/>'
        ));

        // generate body lines
        rowpepenBytes = abi.encodePacked(rowpepenBytes, abi.encodePacked(
            '<g><use href="#line"/></g>',
            '<g transform="translate(97 0)"><use href="#line"/></g>',
            '<g transform="translate(197 0)"><use href="#line"/></g>'
        ));

        // generate head 
        rowpepenBytes = abi.encodePacked(rowpepenBytes, abi.encodePacked(
            '<path d="M678.8,835.2H345.2c-16.6,0-30.2-13.7-30.2-30.2V59.8h363.8c16.6,0,30.2,13.7,30.2,30.2v714.9C709,822.5,695.4,835.2,678.8,835.2z" fill="', headBgColour ,'"/>'
        ));
       
        // generate cells 
        rowpepenBytes = abi.encodePacked(rowpepenBytes, abi.encodePacked(
            generateCells(currentRowpepen.boredGame, currentRowpepen.gameplayMode)
        ));

        // generate border 
        rowpepenBytes = abi.encodePacked(rowpepenBytes, abi.encodePacked(
            '<path d="M678.8,835.2H345.2c-16.6,0-30.2-13.7-30.2-30.2V59.8h363.8c16.6,0,30.2,13.7,30.2,30.2v714.9C709,822.5,695.4,835.2,678.8,835.2z" fill="none" stroke="#272727" stroke-width="8"/>'
        ));
        
        return rowpepenBytes; 
    }

    /// @dev Check if this is a top 3 leaderboard opepen and if so def Check and include it
    /// @param currentRowpepen The current Rowpepen
    function generateCheck(Rowpepen memory currentRowpepen) internal view returns (bytes memory) {

        bytes memory checkBytes;

        checkBytes = abi.encodePacked(
            '<path id="check" fill-rule="evenodd" d="M21.36 9.886A3.933 3.933 0 0 0 18 8c-1.423 0-2.67.755-3.36 1.887a3.935 3.935 0 0 0-4.753 4.753A3.933 3.933 0 0 0 8 18c0 1.423.755 2.669 1.886 3.36a3.935 3.935 0 0 0 4.753 4.753 3.933 3.933 0 0 0 4.863 1.59 3.953 3.953 0 0 0 1.858-1.589 3.935 3.935 0 0 0 4.753-4.754A3.933 3.933 0 0 0 28 18a3.933 3.933 0 0 0-1.887-3.36 3.934 3.934 0 0 0-1.042-3.711 3.934 3.934 0 0 0-3.71-1.043Zm-3.958 11.713 4.562-6.844c.566-.846-.751-1.724-1.316-.878l-4.026 6.043-1.371-1.368c-.717-.722-1.836.396-1.116 1.116l2.17 2.15a.788.788 0 0 0 1.097-.22Z"/>',
            '</defs>',
            '<g transform="translate(713, 15) scale(1.5)"><use href="#check" fill="#', coloursLB[currentRowpepen.leaderboredPos], '"></use></g>'
        );

        return checkBytes; 
    }
    
    function buildImage(uint256 _tokenId) internal view returns (bytes memory) {
        Rowpepen memory currentRowpepen = rowpepens[_tokenId];

        bytes memory squareSize = abi.encodePacked(
            '<g id="sq"><rect width="38" height="38"/></g>',
            '<g id="qtl"><path d="M38,38h-38v0c0-18.8,15.2-38,38-38h0V0z"/></g>',
            '<g id="qtr"><use href="#qtl" transform="rotate(90,19,19)" /></g>',
            '<g id="qbl"><use href="#qtl" transform="rotate(-90,19,19)" /></g>',
            '<g id="qbr"><use href="#qtl" transform="rotate(-180,19,19)" /></g>'
        );

        bytes memory squareSizeSmall = abi.encodePacked(
            '<g id="sq"><rect width="34" height="34"/></g>',
            '<g id="qtl"><path d="M34,34h-34v0c0-18.8,15.2-34,34-34h0V0z"/></g>',
            '<g id="qtr"><use href="#qtl" transform="rotate(90,17,17)" /></g>',
            '<g id="qbl"><use href="#qtl" transform="rotate(-90,17,17)" /></g>',
            '<g id="qbr"><use href="#qtl" transform="rotate(-180,17,17)" /></g>'
        );

        return abi.encodePacked(
            '<svg ',
                'xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" ',
                 'style="width:100%;background:#ededed;"',
            '>',
                '<style>.l {fill:none;stroke:#272727;stroke-width:10;</style>',
                '<defs>',
                    (currentRowpepen.gameplayMode == 0 || currentRowpepen.gameplayMode == 1  || currentRowpepen.gameplayMode == 3 ) ?  squareSizeSmall : squareSize ,
                    '<g id="line"><line x1="415" x2="415" y1="930" y2="1024" class="l" /></g>',
                    (currentRowpepen.gameplayMode < 2 && currentRowpepen.leaderboredPos >= 1 && currentRowpepen.leaderboredPos <= 3) ? generateCheck(currentRowpepen) : bytes("</defs>"),
                    generateRowpepen(currentRowpepen),
            '</svg>'         
        );
    }
    

    /// @dev Render the JSON atributes for a given token.
    function attributes(Rowpepen memory currentRowpepen) internal view returns (bytes memory) {

        return abi.encodePacked(
            (currentRowpepen.gameplayMode < 2) ? trait('Score', toString(currentRowpepen.score) , ',') : '',
            (currentRowpepen.gameplayMode < 2) ? trait('Level', toString(currentRowpepen.level) , ',') : '',
            (currentRowpepen.gameplayMode < 2) ? trait('Rows', toString(currentRowpepen.rows) , ',') : '',
            (currentRowpepen.leaderboredPos != 0 && currentRowpepen.gameplayMode < 2) ? trait('Leaderboard Position', toString(currentRowpepen.leaderboredPos), ',') : '',
            trait('Gameplay Mode', gameplayModes[currentRowpepen.gameplayMode] , '')
         );
    }

    /// @dev Generate the XML for a single attribute
    function trait(string memory traitType, string memory traitValue, string memory append) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '{',
                '"trait_type": "', traitType, '",'
                '"value": "', traitValue, '"'
            '}',
            append
        ));
    }

    // Plucked from OpenZeppelin's Strings.sol
    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function _startTokenId() internal view virtual override returns (uint) {
        return 1;
    }

    // Setters

    function setSystemAddress(address _systemAddress) external onlyOwner {
      systemAddress = _systemAddress;
    }

    function setMintOpen(bool _val) external onlyOwner {
        mintEnabled = _val;
    }

     // Withdraw

    function withdraw() external onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "Withdraw failed");
    }

}