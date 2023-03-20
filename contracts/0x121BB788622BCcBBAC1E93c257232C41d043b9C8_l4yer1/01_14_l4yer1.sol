// SPDX-License-Identifier: MIT
/***
 *     ▄  ▄         ▄  ▄         ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄    ▄         ▄     ▄▄▄▄     
 *    ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌  ▐░▌       ▐░▌  ▄█░░░░▌    
 *    ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌ ▄█░█▄▄▄▄▄▄▄█░█▄▐░░▌▐░░▌    
 *    ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌          ▐░▌       ▐░▌▐░░░░░░░░░░░░░░░▌▀▀ ▐░░▌    
 *    ▐░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄█░▌ ▀█░█▀▀▀▀▀▀▀█░█▀    ▐░░▌    
 *    ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌  ▐░▌       ▐░▌     ▐░░▌    
 *    ▐░▌ ▀▀▀▀▀▀▀▀▀█░▌ ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀█░█▀▀  ▄█░█▄▄▄▄▄▄▄█░█▄    ▐░░▌    
 *    ▐░▌          ▐░▌     ▐░▌     ▐░▌          ▐░▌     ▐░▌  ▐░░░░░░░░░░░░░░░▌   ▐░░▌    
 *    ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌     ▐░▌     ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌      ▐░▌  ▀█░█▀▀▀▀▀▀▀█░█▀▄▄▄▄█░░█▄▄▄ 
 *    ▐░░░░░░░░░░░▌▐░▌     ▐░▌     ▐░░░░░░░░░░░▌▐░▌       ▐░▌  ▐░▌       ▐░▌▐░░░░░░░░░░░▌
 *     ▀▀▀▀▀▀▀▀▀▀▀  ▀       ▀       ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀    ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀ 
 *                                                                                       
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract l4yer1 is ERC721, Ownable {
    uint public constant MAX_TOKENS = 6969;
    uint public CUT_SUPPLY = 6969;
    uint public numTokensMinted;
    bool public saleActive;
    address private constant claim_add = 0x0F6979e74E4aF9aBeD72298D818A2434fE0b95B6;
    mapping(uint256 => bool) public dgtokenIDClaimed;
    mapping(uint256 => bool) private tokenIdToFrozen;
    
    constructor() ERC721("l4yer#1", "l4yer") {}

    function freezeMetadata(uint256 tokenId) public {
    require(_exists(tokenId));
    require(ownerOf(tokenId) == msg.sender);

    tokenIdToFrozen[tokenId] = !tokenIdToFrozen[tokenId];
    }

    function changeCutSupply(uint256 _CutSupply) external onlyOwner {
    CUT_SUPPLY = _CutSupply;
    }
    
    function mint(uint256[] calldata _tokenIDs) external {
        uint256 numberOfTokens = _tokenIDs.length;
        require(saleActive);
        require(numTokensMinted + numberOfTokens <= MAX_TOKENS);
        require(numTokensMinted + numberOfTokens <= CUT_SUPPLY);
        IERC721 ExternalERC721FreeClaimContract = IERC721(claim_add);
        for (uint256 i = 0; i < numberOfTokens; i++) {
            require(ExternalERC721FreeClaimContract.ownerOf(_tokenIDs[i]) == msg.sender);
            require(!dgtokenIDClaimed[_tokenIDs[i]]);
            dgtokenIDClaimed[_tokenIDs[i]] = true;
            numTokensMinted = numTokensMinted + 1;
            _safeMint(msg.sender, _tokenIDs[i]);
        }
    }

    function startSale() external onlyOwner {
        require(saleActive == false);
        saleActive = true;
    }

    function stopSale() external onlyOwner {
        require(saleActive == true);
        saleActive = false;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId));
        if (!tokenIdToFrozen[tokenId])
        {    
            string memory baseSvg = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.dev/svgjs" width="800" height="800" style="background-color:', gRC(tokenId, 69), '" viewBox="0 0 800 800"><animate attributeName="fill" values="', gRC(tokenId, 1618), ';', gRC(tokenId, 161), '" dur="0.4s" repeatCount="indefinite" /><path transform="scale(2)" d="M144 67c-14 16-16 21-14 31 6 26 4 39-7 44-9 4-16 24-21 57-2 22-15 54-21 59-12 7-22 35-14 41l17 14c9 8 28 5 28-5 0-3 4-10 8-15l9-11-3 14-9 40c-7 32-6 44 5 50l10 6c4 5 51 7 55 3 2-2 8-2 15 2 8 3 15 3 35 0 13-3 25-5 26-3 8 7 17-8 17-28 0-16 1-21 5-20 5 2 19-15 46-56 11-18 11-54-1-76-3-7-6-15-6-19 0-3-4-9-8-12s-9-12-10-22c-4-20-5-22-38-31-31-8-36-12-36-27 0-51-55-73-88-36m52-3c10 5 18 22 22 43 3 21 12 27 47 37 24 7 25 7 28 22 2 9 6 19 9 22l6 11c0 4 9 27 16 42 8 14-2 41-27 74l-10 14-12-13c-13-15-24-15-26 0-1 7 2 13 9 20 15 14 15 44-1 44l-26 4c-12 4-17 3-27-3-10-5-14-6-20-2-7 5-50 1-55-5-2-1 0-14 3-29 14-70 3-97-24-60l-13 17-10-7-9-6 13-19c19-28 22-37 27-64 8-53 9-54 17-55 11-1 17-25 13-49-4-27 27-51 50-38m2 68c-4 4-16 11-27 14-35 12-44 54-22 98 23 45 55 28 55-30 0-23 6-48 17-69 9-18-9-29-23-13m-2 39c-4 12-8 32-8 45 0 14-2 26-7 33l-7 11-11-22c-19-38-13-69 13-78 9-3 17-7 18-9 8-11 8 1 2 20m31 28c-18 19-14 27 15 27h24v-18c0-24-20-28-39-9m29 7c0 3-1 6-3 6l-13 3c-10 2-10 2-2-6 8-10 18-12 18-3m14 49c-13 31-1 56 18 39 10-9 15-40 8-48-9-11-19-7-26 9m16 12c-3 10-10 22-10 16 0-4 9-27 10-27v11" stroke="', gRC(tokenId, 235), '" stroke-width="', uint2str(uint(keccak256(abi.encodePacked(block.number, tokenId))) % 5 + 1) ,'"/><defs><path id="randomPath" d="M50,50 L150,50 L150,250 L50,250 Z"/><path id="zigzag" d="M170,419 L220,150 L270,251 L420,351 L500,153 210,353 L334,455 L220,255 L195,55 Z"/></defs>'));
            IERC721 otherERC721 = IERC721(claim_add);
            uint256 balance = otherERC721.balanceOf(ownerOf(tokenId));

            for (uint256 i = 1; i < balance+1; i++) {
                uint rand1 = uint(keccak256(abi.encodePacked(block.number, tokenId, i))) % 100 + 1;
                string memory gradientId = gRG(tokenId, i);

                if (rand1 % 4 == 0  || balance == 26) {
                        uint256 i1=i;
                        uint256 tokenId1=tokenId;
                        baseSvg = string(abi.encodePacked(baseSvg,
                        '<defs>',
                        '<radialGradient id="', gradientId, '">',
                        '<stop offset="0%" stop-color="', gRC(tokenId1, i1), '"/>',
                        '<stop offset="100%" stop-color="', gRC(tokenId1, i1 + 49), '"/>',
                        '</radialGradient>',
                        '</defs>',
                        '<circle cx="', uint2str(uint(keccak256(abi.encodePacked(block.number, tokenId1, i1 + 25))) % 600 + 100), '" cy="', uint2str(uint(keccak256(abi.encodePacked(block.number, tokenId1, i1 + 5))) % 600 + 100), '" r="', uint2str(uint(keccak256(abi.encodePacked(block.number, tokenId1, i1 + 10))) % 50 + 5), '" fill="url(#', gradientId, ')" >',
                        '<animate attributeName="opacity" values="0;1;0" dur="', getDur(tokenId1, i1), 's" repeatCount="indefinite" />',
                        '<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="360" to="0 400 400" dur="', getDur(tokenId1, i1), 's" repeatCount="indefinite"/>',
                        '<animateMotion dur="', getDur(tokenId1, i1), 's" repeatCount="indefinite"><mpath href="#zigzag"/></animateMotion>',
                        '</circle>'
                        ));                        
                    }  
                else if (rand1 % 4 == 1 || balance == 75){
                        uint tokenId1 = tokenId;
                        baseSvg = string(abi.encodePacked(baseSvg,
                        '<rect width="75" height="75" ><animate attributeName="fill" values="', gRC(tokenId, i), '" dur="0.4s" repeatCount="indefinite" />',
                        '<animate attributeName="opacity" values="0;', getDur(tokenId1, i), ';0" dur="0.1s" repeatCount="indefinite" />',
                        '<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="360" to="0 ', uint2str(uint(keccak256(abi.encodePacked(block.number, tokenId1, i + 15))) % 200 + 10), ' ', uint2str(uint(keccak256(abi.encodePacked(block.number, tokenId1, i + 50))) % 300 + 10), '" dur="', uint2str(uint(keccak256(abi.encodePacked(block.number, tokenId1, i))) % 10 + 1), 's" repeatCount="indefinite"/>',
                        '<animateMotion dur="', getDur(tokenId1, i), 's" repeatCount="indefinite"><mpath href="#zigzag"></mpath></animateMotion>',
                        '</rect>'
                        ));
                        }
                else if (rand1 == 69 || rand1 > 90 || balance == 150){
                        baseSvg = string(abi.encodePacked(baseSvg,
                        '<path transform="scale(2)" d="m396 372c-1 1-4 5-6 7-1 1-2 2-3 2-3 1-5 5-3 6 0 0 1 0 1 0 0 0 1 0 1 0 1 1 2 1 4 0 2-1 1 0-1 3-4 6-6 8-9 7-2 0-3-1-3-3 0-2-1-1-1 1 0 5 8 5 12 0 3-4 9-14 9-15 0-1-1-1-2 0 0 0-1 1-1 1-1 0-3 2-4 4-2 3-3 3-2 0 3-6 8-12 10-12 1 0 1 0 1-1 0-1-2-1-2.861-.05" stroke="', gRC(tokenId, 168), '"/>'
                        ));
                        }
                else {
                        uint tokenId1 = tokenId;
                        baseSvg = string(abi.encodePacked(baseSvg,
                        '<defs><linearGradient id="', gradientId, '" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stop-color="', gRC(tokenId, i), '"/><stop offset="100%" stop-color="', gRC(tokenId, i+10), '"/></linearGradient></defs>',
                        '<rect x="', uint2str(uint(keccak256(abi.encodePacked(block.number, tokenId1, i))) % 600 + 100), '" y="', uint2str(uint(keccak256(abi.encodePacked(block.number, tokenId1, i + 5))) % 600 + 100), '" width = "50" height = "50" fill="url(#', gradientId, ')"  rx="15">',
                        '<animate attributeName="opacity" values="0;1;0" dur="0.1s" repeatCount="indefinite" /></rect>'
                        ));
                    }
                }

        baseSvg = string(abi.encodePacked(baseSvg, '</svg>'));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "NFT #', uint2str(tokenId), '", "description": "An on-chain generated NFT with random shapes and colors, animated!", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(baseSvg)), '", "attributes":[{"trait_type":"numberOfShapes", "value":"', uint2str(balance), '"}]}' ))));
        return string(abi.encodePacked('data:application/json;base64,', json));
        }
        else{
            return super.tokenURI(tokenId);
        }
    }

    function getDur(uint tokenId, uint i) internal view returns (string memory) {
    uint duration = uint(keccak256(abi.encodePacked(block.number, tokenId, i))) % 10 + 1;
    return uint2str(duration);
    }

    function gRG(uint tokenId, uint index) internal view returns (string memory) {
        bytes32 hash = keccak256(abi.encodePacked(block.number, tokenId, index));
        string memory prefix = "gradient";
        string memory suffix = uint2str(uint(hash) % 1000000);
        return string(abi.encodePacked(prefix, suffix));
    }
    function gRC(uint256 tokenId, uint256 index) internal view returns (string memory) {
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, tokenId, index)));
        uint256 r = rand % 256;
        uint256 g = (rand / 256) % 256;
        uint256 b = (rand / 256 / 256) % 256;
        return string(abi.encodePacked("rgb(", uint2str(r), ",", uint2str(g), ",", uint2str(b), ")"));
    }

    function uint2str(uint _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length;
        while (_i != 0) {
            bstr[--k] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}