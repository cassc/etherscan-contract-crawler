// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../operator-filter-registry/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "../iChecks.sol";
import "./ChecksonsArt.sol";
import "./ICheckson.sol";


/** 

                           ^77777777777777777777!!~^::.                                             
                           ^7777!~~~~~~~!!!!77777777777!~^.                                         
                           :777~  .............:^~~!7777777!~:.                                     
                           ~7777!777777777!!!~~^^:...::~!77??77!:.                                  
                          :77777777777777777??????77!!~^:::~!7???7^                                 
                          !?7777???7?77??77?777777???????7!~^:^!7??~                                
                         :???????????????????????????????????7!!???7.                               
                        .7?????????????????????????????????????????7                                
                        ~??????????????????????????????????????????7                                
                    ..^!???????????????????????????????????????????7                                
               .:~!7??JJ??????????????????????????????????????????J7                                
             :!?JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?^.                              
            !JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ??7!~^:.                       
            !?JJJ??77!!!JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?:                     
              ....     .JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?77!!~^.                     
                      .?YJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ!.                             
                     ^?!7YJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJY7^^^^:.                        
                    !7.:?YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY?.                       
                   ~7.~YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY7                        
                   . !5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY?                         
                     .:!YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY7:                       
                        JYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJJY55YYYYYYYYY5Y7.                     
                        ?5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5?::~?Y55YYYYYYYY57                     
                        :5555555555555555555555555555555555555Y?..5YJ555555555?                     
                         !55555555555555555555555555555555555555J.~: !55555555Y^                    
                          755555555555555555555555555555555555555Y~ :75555555555~                   
                          .?555555555555555555555555555555555555555?~7JY555555555^                  
                            :^^:::..::!55555555555555555555555555555Y^ .7555555YY:                  
                                      ?5555555555555555555555555555555?^!?JJ7~...                   
                                    :JP5555555555555555555555555555555P5Y7^.                        
                            ..::^~!J5P5555555555555555555555555555555555PPP5J7~:.                   
                     .^~7?JYY555PPPPP5555555PPPPPPPPPPPPPPPPPPP555555555555PPPP5Y?!^:               
                  .!J5PPPPPPPPPPPPPPPPPPPPPP?^^~!7JJJJYYJJ?77JPPPPPPPPPPPPPPPPPPPPPP5Y?!^:          
                .75PPPPPPPPPPPPPPPPPPPPPPPPP7         J~      7PPPPPPPPPPPPPPPPPPPPPPPPPP5Y?~.      
               ^5PPPPPPPPPPPPPPPPPPPPPPPPPPP5.       .J:      ^PPPPPPPPPPPPPPPPPPPPPPPPPPPPPP57.    
              ~PPPPPPPPPPPPPPPPPPPPPPPPPPPPPP?     ^Y5P!      7PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPY:   
             ~PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP~  .7PPPPP?.   ^PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPY.  
            :5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5!?5PPPPPPP57::5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP7  
           .YPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5. 
           ?PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP! 
          ~PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPY 
         ^5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP7
         JPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP57
 
*/

struct AudioAsset{
    string IPFSHash;
    string name;
    uint256 priceInWei;
}

struct AnimationAsset{
    string IPFSHash;
    string name;
    string color;
    uint256 priceInWei;
}

struct Token {
    uint256 checkId;
    uint8 animationId;
    uint8 audioId;
}

struct BackgroundAnimation{
    string step;
    string transition;
}

contract ChecksonsCore is 
ERC721,
ERC721Burnable,
ERC721Enumerable,
ERC2981, 
Ownable,
DefaultOperatorFilterer
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;   

    event MetadataUpdate(uint256 _tokenId);

    string internal _contractURI;
    string internal _baseAssetURI = "https://ipfs.io/ipfs/";

    /// @notice The VV Checks Originals contract.
    Checks public checksOriginals;

    mapping(uint256 => bool) internal _claimedCheckTokens;
    mapping(uint256 => Token) internal _tokens;
    mapping(uint8 => AnimationAsset) internal _animations;
    mapping(uint8 => AudioAsset) internal _audios;
    mapping(uint256 => string[]) internal _bgAnimSqc;

    constructor(
        address royaltyReceiver,
        uint96 royaltyFeesInBips,
        string memory contractUri
    ) ERC721("Checksons", "CKS") {
        super._setDefaultRoyalty(royaltyReceiver, royaltyFeesInBips);
         _contractURI = contractUri;
         checksOriginals = Checks(0x036721e5A769Cc48B3189EFbb9ccE4471E8A48B1);

         _bgAnimSqc[4] = ["20", "25", "45", "50", "70", "75", "95"];
         _bgAnimSqc[5] =  ["16", "20", "36", "40", "56", "60", "76", "80", "96"];
         _bgAnimSqc[10] = ["8","10","18", "20", "28", "30", "38", "40", "48", "50", "58", "60", "68", "70", "78", "80", "88", "90", "98"];
         _bgAnimSqc[20] = ["4", "5", "9", "10", "14", "15", "19", "20", "24", "25", "29", "30", "34", "35", "39", "40", "44", "45", "49", "50", "54", "55", "59", "60", "64", "65", "69", "70", "74", "75", "79", "80", "84", "85", "89", "90", "94", "95", "99"];
         _bgAnimSqc[40] = ["2", "2.5", "4.5", "5", "7", "7.5", "9.5", "10", "12", "12.5", "14.5", "15", "17", "17.5", "19.5", "20", "22", "22.5", "24.5", "25", "27", "27.5", "29.5", "30", "32", "32.5", "34.5", "35", "37", "37.5", "39.5", "40", "42", "42.5", "44.5", "45", "47", "47.5", "49.5", "50", "52", "52.5", "54.5", "55", "57", "57.5", "59.5", "60", "62", "62.5", "64.5", "65", "67", "67.5", "69.5", "70", "72", "72.5", "74.5", "75", "77", "77.5", "79.5", "80", "82", "82.5", "84.5", "85", "87", "87.5", "89.5", "90", "92", "92.5", "94.5", "95", "97", "97.5", "99.5"];
         _bgAnimSqc[80] = ["1", "1.25", "2.25", "2.5", "3.5", "3.75", "4.75", "5", "6", "6.25", "7.25", "7.5", "8.5", "8.75", "9.75", "10", "11", "11.25", "12.25", "12.5", "13.5", "13.75", "14.75", "15", "16", "16.25", "17.25", "17.5", "18.5", "18.75", "19.75", "20", "21", "21.25", "22.25", "22.5", "23.5", "23.75", "24.75", "25", "26", "26.25", "27.25", "27.5", "28.5", "28.75", "29.75", "30", "31", "31.25", "32.25", "32.5", "33.5", "33.75", "34.75", "35", "36", "36.25", "37.25", "37.5", "38.5", "38.75", "39.75", "40", "41", "41.25", "42.25", "42.5", "43.5", "43.75", "44.75", "45", "46", "46.25", "47.25", "47.5", "48.5", "48.75", "49.75", "50", "51", "51.25", "52.25", "52.5", "53.5", "53.75", "54.75", "55", "56", "56.25", "57.25", "57.5", "58.5", "58.75", "59.75", "60", "61", "61.25", "62.25", "62.5", "63.5", "63.75", "64.75", "65", "66", "66.25", "67.25", "67.5", "68.5", "68.75", "69.75", "70", "71", "71.25", "72.25", "72.5", "73.5", "73.75", "74.75", "75", "76", "76.25", "77.25", "77.5", "78.5", "78.75", "79.75", "80", "81", "81.25", "82.25", "82.5", "83.5", "83.75", "84.75", "85", "86", "86.25", "87.25", "87.5", "88.5", "88.75", "89.75", "90", "91", "91.25", "92.25", "92.5", "93.5", "93.75", "94.75", "95", "96", "96.25", "97.25", "97.5", "98.5", "98.75", "99.75"];
         
    }

    //Contract logic
    
    function addAnimationAssets(
        uint8[] calldata ids, 
        AnimationAsset[] calldata assets
    )
    external
    onlyOwner{
        require(ids.length == assets.length, "ids and assets must be the same length");
        for (uint i = 0; i < assets.length; i++) {
            _animations[ids[i]] = assets[i];
        }
    }

    function addAudioAssets(
        uint8[] calldata ids,
        AudioAsset[] calldata assets
    )
    external
    onlyOwner{
        require(ids.length == assets.length, "ids and assets must be the same length");
        for (uint i = 0; i < assets.length; i++) {
            _audios[ids[i]] = assets[i];
        }
    }

    function withdrawFunds() 
    external  
    onlyOwner{
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function trait(
        string memory traitType, 
        string memory traitValue, 
        string memory append
    ) 
    internal 
    pure 
    returns (string memory) {
        return string(abi.encodePacked(
            '{',
                '"trait_type": "', traitType, '",'
                '"value": "', traitValue, '"'
            '}',
            append
        ));
    }

    function getAttributes(
        string memory mainColor, 
        string memory audioName, 
        string memory animationName,
        uint256 numberOfChecks, 
        uint256 checkId
    ) 
    internal 
    pure 
    returns (bytes memory) {
        return abi.encodePacked(
            trait('Thumb bg Hex',  string(abi.encodePacked('#',mainColor)) , ','),
            trait('Music Track', audioName, ','),
            trait('Jacket Color', animationName, ','),
            trait('Number of Checks', ChecksonsArt.uint2str(numberOfChecks), ','),
            trait('Checks Token ID', ChecksonsArt.uint2str(checkId), '')
        ); 
    }

    function tokenURI(uint256 tokenId) 
    public 
    view 
    override 
    returns (string memory) {
        
        Token memory token = _tokens[tokenId];
        uint256 checkId = token.checkId;
        require(checkId != 0, "Token not minted");

        uint8 checksCount = checksOriginals.getCheck(checkId).checksCount;
        (string[] memory colors, ) = checksOriginals.colors(checkId);
        AnimationAsset memory animation = _animations[token.animationId];
        AudioAsset memory audio = _audios[token.audioId];

        bytes memory metadata = abi.encodePacked(
            '{',
                '"name": "Checkson ', ChecksonsArt.uint2str(tokenId), '",',
                '"description": "Checksons are a Web 3.0 art collection and art experiment by Yoni Alter. It is also a tribute to the most iconic dance and the most iconic checks. Now get up and dance!",',
                '"external_url": "https://yoniishappy.com/",',
                '"animation_url": ',
                    '"data:text/html;base64,',
                    Base64.encode(ChecksonsArt.getHtmlAnimation(IChecksons.HTMLAnimationAssets(colors, animation.IPFSHash, audio.IPFSHash,_bgAnimSqc[checksCount], _baseAssetURI))),
                '","image": ',
                    '"data:image/svg+xml;base64,',
                    Base64.encode(ChecksonsArt.getPreviewImage(colors[0],animation.color)),
                '","attributes": [', getAttributes(colors[0], audio.name, animation.name, checksCount, checkId), ']',
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(metadata)
            )
        );
    }

    function claimChecksons(
        Token[] calldata tokens
    )
    external 
    payable 
    {
        uint256 cost = 0;
         for (uint i = 0; i < tokens.length; i++) {

            address checkOwner = checksOriginals.ownerOf(tokens[i].checkId);
            
            require(!_claimedCheckTokens[tokens[i].checkId], "Check already claimed");
            require(checkOwner == msg.sender, "Check not owned by sender");   

            uint256 tokenId = _tokenIdCounter.current();

            _claimedCheckTokens[tokens[i].checkId] = true;
            _tokens[tokenId] = tokens[i];

            _safeMint(msg.sender,tokenId);    

            cost += _animations[tokens[i].animationId].priceInWei;
            cost += _audios[tokens[i].audioId].priceInWei;

            _tokenIdCounter.increment();
            
         }
            require(msg.value >= cost, "Insufficient funds"); 
    }

    /// @notice Manually update your checkson on 3rd party platform after your check has updated.
    function updateMetadata(uint256 tokenId)
    public
    {
        require(msg.sender == ownerOf(tokenId), "token must belong to caller");
        emit MetadataUpdate(tokenId);
    }

     //Setters and getters

    function isCheckClaimed(uint256 checkTokenId) 
    public 
    view 
    returns(bool){
        return _claimedCheckTokens[checkTokenId];
    }
    
    function setBaseTokenURI(string calldata baseAssetURI)
    external
    onlyOwner
    {
        _baseAssetURI = baseAssetURI;
    }

    function setContractURI(string calldata uriToSet)
    external
    onlyOwner {
        _contractURI = uriToSet;
    }

    function contractURI()
    public
    view
    returns (string memory) {
        return _contractURI;
    }

    function getAnimation(uint8 animationId) 
    public 
    view 
    returns (AnimationAsset memory) {
        return _animations[animationId];
    }

    function getAudio(uint8 audioId) 
    public 
    view 
    returns (AudioAsset memory) {
        return _audios[audioId];
    }

    /* Overrides and hooks */

    function supportsInterface(bytes4 interfaceId) 
    public 
    view 
    virtual 
    override(ERC721, ERC721Enumerable, ERC2981) 
    returns (bool) {
            return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from, 
        address to, 
        uint256 tokenId, 
        uint256 batchSize
    )
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }


    /* Opensea creator fee enforcement */

    function setApprovalForAll(
        address operator, 
        bool approved
    ) 
    public 
    override (ERC721, IERC721)
    onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator, 
        uint256 tokenId
    ) 
    public 
    override (ERC721, IERC721)
    onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from, 
        address to, 
        uint256 tokenId
    ) 
    public 
    override (ERC721, IERC721)
    onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from, 
        address to, 
        uint256 tokenId
    ) 
    public 
    override (ERC721, IERC721)
    onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from, 
        address to, 
        uint256 tokenId, 
        bytes memory data
    )
        public
        override (ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}