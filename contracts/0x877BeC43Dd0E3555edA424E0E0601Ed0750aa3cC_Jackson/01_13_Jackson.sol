//SPDX-License-Identifier: MIT
// Copyright (c) 2022 Lawrence X. Rogers


pragma solidity ^0.8.15;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Jackson NFT 
/// @author Lawrence X Rogers
/// @notice This smart contract creates on-chain NFT art that grows over time based on who mints from the collection.
/// @dev a major theme in this contract was balancing mint cost (minimizing storage usage on mint) and enabling the viewing of canvases with 1000 brush strokes.
/// the only way found to concatenate large number of stroke data was to use abi.encodePacked on an array of bytes32.
/// While a stroke can be generated with only 8 bytes of data, making it tempting to store only this information on mint,
/// creating the stroke from this data 1000 times was too gas expensive, so the stroke is generated and stored as 3 bytes32 upon mint.

contract Jackson is ERC721, Ownable {
    using Strings for uint256;
    
    uint16 constant MAX_SUPPLY = 1000;
    uint8 constant SVG_BYTE_SIZE = 96;

    //pre-encoded SVG stubs to save on contract storage gas
    bytes public constant svgStub1 = hex"3c7376672069643d27746865737667272076696577426f783d2730203020353030203530302720786d6c6e733d27687474703a2f2f7777772e77332e6f72672f323030302f7376672720786d6c6e733a786c696e6b3d27687474703a2f2f7777772e77332e6f72672f313939392f786c696e6b273e3c646566733e3c66696c7465722069643d2766273e3c6665476175737369616e426c757220737464446576696174696f6e3d2734272f3e3c6665436f6d706f7369746520696e3d27536f757263654772617068696327206f70657261746f723d27696e272f3e3c2f66696c7465723e3c66696c7465722069643d2767273e3c6665476175737369616e426c757220737464446576696174696f6e3d273130272f3e3c6665436f6d706f73697465206f70657261746f723d276f7665722720696e3d27536f7572636547726170686963272f3e3c2f66696c7465723e3c66696c7465722069643d2774273e3c666554757262756c656e636520747970653d276672616374616c4e6f69736527206e756d4f6374617665733d27312720626173654672657175656e63793d27302e303038273e3c616e696d617465206174747269627574654e616d653d27626173654672657175656e6379272076616c7565733d27302e3030383b302e3127206475723d27313030732720726570656174436f756e743d27696e646566696e697465272f3e3c2f666554757262756c656e63653e3c6665446973706c6163656d656e744d617020696e3d27536f757263654772617068696327207363616c653d2737272f3e3c2f66696c7465723e3c6c696e6561724772616469656e742069643d276267272078313d2730272079313d2730272078323d2731303025272079323d2730273e3c73746f70206f66667365743d273027207374796c653d2773746f702d636f6c6f723a726762283230302c3230302c3230302c302e3829272f3e3c73746f70206f66667365743d273127207374796c653d2773746f702d636f6c6f723a726762283235352c3235322c3234372c302e3729272f3e3c2f6c696e6561724772616469656e743e3c6c696e6561724772616469656e742069643d276672272078313d2730272079313d2730272078323d2731303025272079323d2730273e3c73746f70206f66667365743d2730272f3e3c73746f70206f66667365743d273127207374796c653d2773746f702d636f6c6f723a7267622834302c34302c343029272f3e3c2f6c696e6561724772616469656e743e3c6c696e6561724772616469656e742069643d277368272078313d2730272079313d2730272078323d2731303025272079323d2730273e3c73746f70206f66667365743d27302720636c6173733d2778272f3e3c73746f70206f66667365743d273127207374796c653d2773746f702d636f6c6f723a7267626128302c302c302c302e3529272f3e3c2f6c696e6561724772616469656e743e3c6c696e6561724772616469656e742069643d27736832272078313d2730272079313d2730272078323d2730272079323d2731303025273e3c73746f70206f66667365743d27302720636c6173733d2778272f3e3c73746f70206f66667365743d273127207374796c653d2773746f702d636f6c6f723a7267626128302c302c302c2e373529272f3e3c2f6c696e6561724772616469656e743e3c7374796c6520747970653d27746578742f637373273e202e78207b73746f702d636f6c6f723a7267626128302c302c302c30293b7d2e74207b66696c6c3a20677265793b20666f6e743a20357078206d6f6e6f73706163657d3c2f7374796c653e3c2f646566733e3c7265637420783d27302720793d2730272077696474683d2735303027206865696768743d2735303027207374796c653d2766696c6c3a75726c2823626729272f3e3c72656374207374796c653d2766696c6c3a75726c28237368292720783d2736322720793d273534272077696474683d27343027206865696768743d27333932272f3e3c72656374207374796c653d2766696c6c3a75726c28237368292720783d2738302720793d273532272077696474683d27323027206865696768743d27333936272f3e3c72656374207374796c653d2766696c6c3a75726c28236672292720783d273130302720793d273530272077696474683d2733303027206865696768743d27343030272f3e3c726563742069643d276376272066696c6c3d27";
    bytes public constant svgStub2 = hex"2720783d273131302720793d273630272077696474683d2732383027206865696768743d27333830272f3e3c72656374207374796c653d2766696c6c3a75726c28237368292720783d273338362720793d273630272077696474683d273527206865696768743d27333830272f3e3c72656374207374796c653d2766696c6c3a75726c2823736832292720783d273131302720793d27343337272077696474683d2732383127206865696768743d2734272f3e3c72656374207374796c653d2766696c6c3a75726c2823736832292720783d273131302720793d27343337272077696474683d2732383127206865696768743d273427207472616e73666f726d3d277363616c6528312c2d312927207472616e73666f726d2d6f726967696e3d2763656e746572272f3e3c672069643d27722720";

    uint8 public constant COLOR_BACKGROUND_FRACTION = 25; // what fraction of canvases will have a colored background, out of 255
    uint8 public constant UNLIMITED_STROKE_SUPPLY = 10; // first n mints will have unlimited stroke capacity
    uint256 constant public ADDRESS_MINT_FEE = 0.1 ether;
    uint256 constant public CUSTOM_MINT_FEE = 0.15 ether;

    uint16 public tokenCounter;
    uint public balance;
    mapping (address => bool) public hasMinted;

    event CreatedJacksonNFT(uint256 indexed tokenId);
    
    struct AttrData {
        address minter;        // who minted the NFT (NOT current owner)
        bytes backgroundColor; // of the form abi.encodePacked("rgba(r,b,g,a)")
        bytes filters;         // data for special filter attributs
        uint16 strokeCapacity; // the stroke capacity of the canvas
        bytes32 part1;         // the stroke information is stored as 3 bytes32. even though less information is required to generate the stroke
        bytes32 part2;         // this was a tradeoff between making mints cheaper, and enabling 1000 stroke canvases.
        bytes32 part3;         // without this storage mechanism, generating 1000 stroke canvases would cost more than 30M gas, which is the current block limit.
    }

    mapping (uint => AttrData) public attributes;

    constructor() ERC721("Jackson", "JKSN")
    {
        tokenCounter = 0;
        balance = 0;
    }
    
    function getTokensByOwner(address owner) external view returns(uint[] memory) {
        uint[] memory tokens = new uint[](balanceOf(owner));
        uint found = 0;
        for (uint i = 0; i < tokenCounter; i++) {
            if (ownerOf(i) == owner) {
                tokens[found] = i;
                found++;
            }
        }
        return tokens;
    }

    /// @notice mint a canvas, generating a brush stroke based on the sender's address
    function addressMint() external payable {
        require(msg.value >= ADDRESS_MINT_FEE, "Jackson: mint fee not met");
        _create(bytes8(abi.encodePacked(msg.sender)));
    }

    /// @notice mint a canvas, generating a custom stroke based on the given data
    function customMint(bytes8 strokeData) external payable {
        require (msg.value >= CUSTOM_MINT_FEE, "Jackson: mint fee not met");
        _create(strokeData);
    }

    /// @notice mints the canvas and stores data about the stroke and canvas
    function _create(bytes8 strokeData) internal {
        require(tokenCounter < MAX_SUPPLY, "Jackson: MAX SUPPLY REACHED");
        require(hasMinted[msg.sender] == false, "Jackson: Address already minted");

        hasMinted[msg.sender] = true;
        balance += msg.value;
        
        _safeMint(msg.sender, tokenCounter);
        _generateAndStoreAttributes(tokenCounter, strokeData);

        emit CreatedJacksonNFT(tokenCounter);
        
        tokenCounter++;
    }

    /// @notice uses a pseudo-random algorithm to generate canvas-specific traits
    /// @dev the pseudoRandomHash serves its purpose in a fast sellout, but is gameable in other situations:
    /// 1. if there is enough time to reverse engineer the algorithm and predict when desired traits will be found
    /// 2. if minting from a smart contract and reverting until the desired traits are found
    /// 3. if simulating mints until the desired traits are found then minting
    function _generateAndStoreAttributes(uint256 tokenId, bytes8 strokeData) internal {
        bytes20 pseudoRandomHash = bytes20(keccak256(abi.encodePacked(
            tokenId, msg.sender, block.timestamp, block.difficulty, tx.gasprice)));

        bytes memory color = abi.encodePacked("#EEE");
        if (uint8(pseudoRandomHash[0]) < COLOR_BACKGROUND_FRACTION || tokenId < UNLIMITED_STROKE_SUPPLY) {
            color = abi.encodePacked("rgba(",
                Strings.toString(uint8(pseudoRandomHash[1])), ",",
                Strings.toString(uint8(pseudoRandomHash[2])), ",",
                Strings.toString(uint8(pseudoRandomHash[3])), ",1)"    
            );
        }
        
        bytes memory strokeSVG = _generateStroke(strokeData);
        
        attributes[tokenId] = AttrData(
            msg.sender,
            color, 
            _generateFilters(_byteToPercent(pseudoRandomHash[6])),
            uint16(_calculateCapacity(tokenId, pseudoRandomHash)), 
            bytes32(strokeSVG), 
            bytesToBytes32(strokeSVG, 32), 
            bytesToBytes32(strokeSVG, 64)
        );
    }

    /// @notice the rarities of the filter traits are determined here
    function _generateFilters(uint percent) internal pure returns (bytes memory) {
        if (percent < 7) {
            if (percent < 3) return abi.encodePacked("filter='url(#t)'>"); //trippy filter
            else if (percent < 5) return abi.encodePacked("filter='url(#f)'>"); // frost filter
            else return abi.encodePacked("filter='url(#g)'>"); // glow filter
        }
        else return abi.encodePacked(">");
    }

    /// @notice helper function for the attribute metadata
    function _getFilterName(bytes memory filterBytes) internal pure returns (string memory name) {
        if (filterBytes.length == 1) return "none";
        else if (filterBytes[13] == hex"66") return "frosted";
        else if (filterBytes[13] == hex"67") return "glow";
        else if (filterBytes[13] == hex"74") return "trippy";
    }

    /// @notice the rarity of the stroke capacity traits are determined here
    function _calculateCapacity(uint tokenId, bytes20 pseudoRandomHash) internal pure returns (uint capacity) {
        uint capacityLimit =  MAX_SUPPLY - tokenId;
        if (tokenId < UNLIMITED_STROKE_SUPPLY) {
            capacity = capacityLimit;
        }
        else {
            uint capacityTier = _byteToPercent(pseudoRandomHash[4]);
            uint capacityX = _byteToPercent(pseudoRandomHash[5]);
            
            if (capacityTier < 70) { // 70% get 5-20
                capacity = uint16(5 + ((capacityX * 15) / 100));
            }
            else {//30% get 40 - 100, using x^4 to make 100 very rare
                capacity = uint16(20 + ((capacityX * capacityX * capacityX * 7) / 100000));
            }
            capacity = capacity > capacityLimit ? capacityLimit : capacity; // Min of capacity and capacity limit
        }
    }

    /// @param strokeData either the first 8 bytes of the minter's address, or the custom stroke data
    /// @return strokeBytes the SVG string of the stroke, padded to 3 * 32 bytes (to fit as 3 bytes32 later)
    function _generateStroke(bytes8 strokeData) internal pure returns(bytes memory strokeBytes) {
        uint x = 115 + ((265 * _byteToPercent(strokeData[4])) / 100);
        uint y = 80 + ((350 * _byteToPercent(strokeData[5])) / 100);

        strokeBytes = abi.encodePacked(
            "<rect x='", Strings.toString(x),
            "' y='", Strings.toString(y),
            "' width='", Strings.toString(5 + (_byteToPercent(strokeData[6]) * (380 - x)) / 100),
            "' height='", Strings.toString(5 + (_byteToPercent(strokeData[7]) * (430 - y)) / 100),
            "' fill='rgba(",
                Strings.toString(uint8(strokeData[0])), ",",
                Strings.toString(uint8(strokeData[1])), ",",
                Strings.toString(uint8(strokeData[2])), ",.",
                Strings.toString(30 + ((_byteToPercent(strokeData[3]) * 50)/ 100)),
            ")'/>"); 
            
        
        uint padding = SVG_BYTE_SIZE - strokeBytes.length;
        for (uint i = 0; i < padding; i++) {
            strokeBytes = bytes.concat(strokeBytes, abi.encodePacked(" "));
        }
    }

    /// @notice used only for testing
    /// @dev hardhat doesn't gas profile view functions, so I used this one to test the gas usage of tokenURI. 
    function testTokenURI(uint256 tokenId) public returns(string memory) {
        return tokenURI(tokenId);
    }

    /// @notice returns the most up-to-date metadata of the NFT
    /// @return theURI a base64 encoded string including the NFT attributes and image
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory theURI) {
        require(_exists(tokenId), "Jackson: Token doesn't exist");
        uint strokeCapacity = attributes[tokenId].strokeCapacity;
        bytes memory svgBytes = _generateSVG(tokenId, strokeCapacity);
        bytes memory imageURI = abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(svgBytes));
        theURI = formatTokenURI(imageURI, tokenId, strokeCapacity);
    }

    /// @notice loops through the appropriate mints and composes the strokes from those mints
    /// @dev while technically a gas-free view function, many providers limit gas consumption to the block gas limit.
    /// To compose 1000 strokes, many gas optimizations were required.
    /// The strategy of allocating an array of bytes32 and then concatenating it using abi.encodePacked was found to be the most efficient for large N
    function _generateSVG(uint256 tokenId, uint strokeCapacity) internal view returns(bytes memory) {
        uint maxStroke = tokenId + strokeCapacity < tokenCounter ? tokenId + strokeCapacity : tokenCounter;
        uint strokeCount = maxStroke - tokenId;

        bytes32[] memory allParts = new bytes32[](strokeCount * 3);

        for (uint i = 0; i < strokeCount; i++) {
            allParts[i*3] = attributes[tokenId + i].part1;
            allParts[i*3 + 1] = attributes[tokenId + i].part2;
            allParts[i*3 + 2] = attributes[tokenId + i].part3;
        }
        
        return abi.encodePacked(
            svgStub1, 
            attributes[tokenId].backgroundColor, 
            svgStub2,
            attributes[tokenId].filters,
            abi.encodePacked(allParts),  // this is where we efficiently concatenate large numbers of strokes
            "</g><text x='115' y='68' class='t'>Minter: ",
            Strings.toHexString(uint256(uint160(attributes[tokenId].minter)), 20),
            "</text><text x='115' y='74' class='t'>Stroke Count: ",
            strokeCount.toString(), "/", strokeCapacity.toString(), "</text></svg>"
        );
    }

    /// @notice converts a byte to a uint from 1 to 100
    function _byteToPercent(bytes1 theByte) internal pure returns(uint) {
        return (100* (1 + uint32(uint8(theByte)))) / 256;
    }

    /// @notice converts a byte to a bytes32
    /// @param offset: the offset into the bytes array to start
    function bytesToBytes32(bytes memory b, uint offset) private pure returns (bytes32) {
        bytes32 out;

        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
     }

    /// @notice formats the imageURI with other attribute data
    function formatTokenURI(bytes memory imageURI, uint tokenId, uint capacity) public view returns (string memory) {
        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            "Jackson #", tokenId.toString(),
                            '", "description":"On-Chain Dynamic Art",',
                            '"attributes": ['
                            '{"trait_type" : "Stroke Capacity", "value" : "',capacity.toString(),'"},',
                            '{"trait_type" : "Background", "value" : "', attributes[tokenId].backgroundColor, '"},',
                            '{"trait_type" : "Filter","value" : "', _getFilterName(attributes[tokenId].filters), '"}',
                            '],"image":"',imageURI,'"}'
                        )
                    )
                )
            );
    }

    /// @notice allow only the owner to withdraw funds from the contract
    function withdrawFunds(address _to, uint _amount) external onlyOwner {
        require(balance >= _amount, "Jackson: Not enough funds");
        balance -= _amount;
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Jackson: Transfer failed");
    }
}