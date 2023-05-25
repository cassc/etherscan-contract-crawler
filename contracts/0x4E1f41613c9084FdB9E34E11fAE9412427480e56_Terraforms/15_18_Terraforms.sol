// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*                                 TERRAFORMS

            . . # # - _ _ > _ _ - - # # # # . + + ^ + . . # - _ } ~ 
            . . # - - _ > } } _ _ _ - - - - # . + + + + . # - _ ~ ~ 
            # # # - _ _ } ~ ~ ~ } > _ _ _ - # . + ^ ^ + . # - _ } ~ 
            # - - - _ > } ~ ~ ~ ~ ~ ~ ~ } _ - . + ^ ^ ^ + . # - > ~ 
            - - _ _ _ > ~ ~ ~ ~ ~ ~ ~ ~ ~ _ - . + ^ ^ ^ ^ + . - _ } 
            _ _ _ _ _ > } ~ ~ ~ ~ ~ ~ ~ ~ _ # . ^ ^ ^ ^ ^ + . # - _ 
            _ > > _ _ _ _ } ~ ~ ~ ~ ~ ~ > - # + ^ ^ ^ ^ ^ + . # - - 
            _ > _ _ - - - _ } ~ ~ ~ } _ _ # . ^ ^ ^ ^ ^ ^ + . # # - 
            _ _ _ - - # # - _ _ > > _ - # . ^ ^ ^ ^ ^ ^ + . # # # # 
            _ _ - # # . # # - - _ _ - # . + ^ ^ ^ ^ ^ + . # # - - # 
            - - # # . . . . # - - - # . . ^ ^ ^ ^ ^ ^ . # - - - - # 
            # # # . + ^ + + . # # # . . + ^ ^ ^ ^ ^ + . # - _ _ - - 
            # # . + ^ ^ ^ ^ + . . . . + ^ ^ ^ ^ ^ ^ . # - - _ _ - # 
            # . . ^ ^ ^ ^ ^ ^ ^ + + + ^ ^ ^ ^ ^ ^ + . # - - - - - # 
            - . . ^ ^ ^ ^ ^ ^ ^ ^ + + ^ ^ ^ ^ + + . # # # - - # # # 
            - # . + ^ ^ ^ ^ ^ ^ ^ ^ + + + + . . # # # # # # # . . . 
            _ - # . + ^ ^ ^ ^ ^ ^ ^ + . . # # - - - # # . . . + + + 
            > - # . + ^ ^ ^ ^ ^ ^ + . . # - _ _ _ _ - # . . + ^ ^ + 
            } _ - # . + ^ ^ ^ ^ ^ + . # - _ > } } _ - # . . + ^ ^ + 
            } _ - # . + ^ ^ ^ ^ ^ + . # - _ } ~ ~ } _ - # . + + ^ + 
            } _ - # . + ^ ^ ^ ^ ^ + . # - _ } ~ ~ ~ } _ - # . + + + 
            > _ - # . + ^ ^ ^ ^ ^ + . # - _ } ~ ~ ~ ~ _ - - # . + + 
            _ _ - # . + ^ ^ ^ ^ ^ + . . # - > ~ ~ ~ ~ > _ - # . + + 
            - - - # # . + ^ ^ ^ ^ ^ + . # - _ } ~ ~ } _ - - # . + ^ 
            - - # # # . . + ^ ^ ^ ^ ^ + . # - _ > } _ _ - # . + ^ ^ 
            # # # # # # # . + ^ ^ ^ ^ ^ + . # - _ _ _ - # . . + ^ ^ 
            . . # # - - - # . + + ^ ^ ^ + . # # - - - # # . + ^ ^ ^ 
            + . # # - - - - # . . + + + + . . # - - - # . + + ^ ^ ^ 
*/

import "./ITerraformsData.sol";
import "./TerraformsPlacements.sol";

/// @title  Land parcels in an onchain 3D megastructure
/// @author xaltgeist, with code direction and consultation from 0x113d
contract Terraforms is TerraformsPlacements {
    
    /// @notice Tokens are pieces of an onchain 3D megastructure. Represents a
    ///         level of the structure
    struct StructureLevel {
        uint levelNumber;
        uint tokensOnLevel;
        int structureSpaceX;
        int structureSpaceY;
        int structureSpaceZ;  
    }

    /// @notice Supplemental token data, including spatial information
    struct TokenData {
        uint tokenId;
        uint level;
        uint xCoordinate;
        uint yCoordinate;
        int elevation;
        int structureSpaceX;
        int structureSpaceY;
        int structureSpaceZ;
        string zoneName;
        string[10] zoneColors;
        string[9] characterSet;
    }

    /// @notice Address of contract managing augmentations
    address public immutable terraformsAugmentationsAddress;

    /// @notice This constant is the length of a token in 3D space
    int public constant TOKEN_SCALE = 6619 * 32;

    /// @notice An append-only list of optional (opt-in) tokenURI upgrades
    address[] public tokenURIAddresses;

    // The array index of the tokenURIAddress for each token
    mapping(uint => uint) tokenToURIAddressIndex;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * CONSTRUCTOR, FALLBACKS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    constructor(
        address _terraformsDataAddress, 
        address _terraformsAugmentationsAddress
    ) 
        ERC721("Terraforms", "TERRAFORMS")
        Ownable()
    {
        tokenURIAddresses.push(_terraformsDataAddress);
        terraformsAugmentationsAddress = _terraformsAugmentationsAddress;
    }
 
    receive() external payable {}
    fallback() external payable {}
    
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * FUNCTION MODIFIERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    modifier publicMint (uint numTokens) {
        require(numTokens <= 10, "Max 10");
        require(
            tokenCounter <= (SUPPLY - numTokens) &&
            msg.value >= numTokens * PRICE
        );
        _;
    }

    modifier postReveal (uint tokenId) {
        require(seed != 0 && _exists(tokenId));
        _;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * PUBLIC: MINTING
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @notice Mint tokens
    /// @param numTokens The amount of tokens
    function mint(uint numTokens) 
        public 
        payable 
        nonReentrant 
        publicMint(numTokens)
    {
        require(!mintingPaused, "Paused");
        _mintTokens(msg.sender, numTokens);
    }

    /// @notice Mints tokens if you hold Loot or a mintpass
    /// @dev Queries the Loot contract to check if minter is a holder
    /// @param numTokens The amount of tokens
    function earlyMint(uint numTokens) 
        public 
        payable 
        nonReentrant 
        publicMint(numTokens)
    {
        require(earlyMintActive, "Inactive");
        require(
            balanceOf(msg.sender) <= 100 && // Early wallet limit of 100
            (
                IERC721(
                    0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7
                ).balanceOf(msg.sender) > 0 || // Check if sender has Loot
                addressToMintpass[msg.sender] != Mintpass.None // Or a mintpass
            )
        );
        _mintTokens(msg.sender, numTokens);
    }

    /// @notice Redeems a mintpass for a dreaming token
    function redeemMintpass() public nonReentrant {
        require(addressToMintpass[msg.sender] == Mintpass.Unused);
        addressToMintpass[msg.sender] = Mintpass.Used;
        _mintTokens(msg.sender, 1);
        dreamers += 1;
        tokenToDreamBlock[tokenCounter] = block.number;
        tokenToStatus[tokenCounter] = Status.OriginDaydream;
        emit Daydreaming(tokenCounter);
    }

    /// @notice Allows owners to claim an allotment of tokens
    /// @param to The recipient address
    /// @param numTokens The amount of tokens
    function ownerClaim(address to, uint numTokens) public onlyOwner {
        require(
            tokenCounter >= SUPPLY && 
            tokenCounter <= (MAX_SUPPLY - numTokens)
        );
        _mintTokens(to, numTokens);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * PUBLIC: TOKEN DATA
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @notice Returns the token URI
    /// @param tokenId The tokenId, from 1 to tokenCounter (max MAX_SUPPLY)
    /// @dev Token owners can specify which tokenURI address to use
    ///      on a per-token basis using setTokenURIAddress
    /// @return result A base64 encoded JSON string
    function tokenURI(uint256 tokenId) 
        public 
        view
        override
        returns (string memory result) 
    {
        if (seed == 0){ // If tokens aren't revealed yet, return a placeholder
            result = ITerraformsData(tokenURIAddresses[0]).prerevealURI(tokenId);
        } else { // Otherwise, call the token's specified tokenURI address
            result = ITerraformsData(
                tokenURIAddresses[tokenToURIAddressIndex[tokenId]]
            ).tokenURI(
                tokenId,
                uint(tokenToStatus[tokenId]),
                tokenToPlacement[tokenId],
                seed,
                _yearsOfDecay(block.timestamp),
                tokenToCanvasData[tokenId]
            );
        }
    }

    /// @notice Returns HTML containing the token SVG
    /// @param tokenId The tokenId, from 1 to tokenCounter (max MAX_SUPPLY)
    /// @return result A plaintext HTML string with a plaintext token SVG
    function tokenHTML(uint tokenId) 
        public 
        view
        postReveal(tokenId)
        returns (string memory result)
    {
        result = ITerraformsData( // Call the token's specified tokenURI address
            tokenURIAddresses[tokenToURIAddressIndex[tokenId]]
        ).tokenHTML(
            uint(tokenToStatus[tokenId]),
            tokenToPlacement[tokenId],
            seed,
            _yearsOfDecay(block.timestamp),
            tokenToCanvasData[tokenId]
        );
    }

    /// @notice Returns an SVG of the token
    /// @param tokenId The tokenId, from 1 to tokenCounter (max MAX_SUPPLY)
    /// @return A plaintext SVG
    function tokenSVG(uint tokenId) 
        public 
        view 
        postReveal(tokenId)
        returns (string memory) 
    {
        return ITerraformsData( // Call the token's specified tokenURI address
            tokenURIAddresses[tokenToURIAddressIndex[tokenId]]
        ).tokenSVG(
            uint(tokenToStatus[tokenId]),
            tokenToPlacement[tokenId],
            seed,
            _yearsOfDecay(block.timestamp),
            tokenToCanvasData[tokenId]
        );
    }

    /// @notice Returns the characters composing the token image
    /// @param tokenId The tokenId, from 1 to tokenCounter (max MAX_SUPPLY)
    /// @return A 2D array of strings
    function tokenCharacters(uint tokenId) 
        public 
        view
        postReveal(tokenId)
        returns (string[32][32] memory) 
    {
        return ITerraformsData( // Call the token's specified tokenURI address
            tokenURIAddresses[tokenToURIAddressIndex[tokenId]]
        ).tokenCharacters(
            uint(tokenToStatus[tokenId]),
            tokenToPlacement[tokenId],
            seed,
            _yearsOfDecay(block.timestamp),
            tokenToCanvasData[tokenId]
        );
    }

    /// @notice Returns the integer values that determine the token's topography
    /// @dev Values are 16-bit signed ints (i.e., +/- 65536)
    /// @param tokenId The tokenId, from 1 to tokenCounter (max MAX_SUPPLY)
    /// @return A 2D array of signed integers
    function tokenTerrainValues(uint tokenId) 
        public 
        view
        postReveal(tokenId)
        returns (int[32][32] memory) 
    {
        return ITerraformsData( // Call the token's specified tokenURI address
            tokenURIAddresses[tokenToURIAddressIndex[tokenId]]
        ).tokenTerrain(
            tokenToPlacement[tokenId], 
            seed, 
            _yearsOfDecay(block.timestamp)
        );
    }

    /// @notice Returns the stepwise height values visually represented on token
    /// @dev Values range from 0 (highest) to 8 (lowest). 9 indicates empty 
    /// @param tokenId The tokenId, from 1 to tokenCounter (max MAX_SUPPLY)
    /// @return A 2D array of unsigned integers
    function tokenHeightmapIndices(uint tokenId)
        public 
        view
        postReveal(tokenId)
        returns (uint[32][32] memory)
    {
        return ITerraformsData( // Call the token's specified tokenURI address
            tokenURIAddresses[tokenToURIAddressIndex[tokenId]]
        ).tokenHeightmapIndices(
            uint(tokenToStatus[tokenId]),
            tokenToPlacement[tokenId], 
            seed, 
            _yearsOfDecay(block.timestamp),
            tokenToCanvasData[tokenId]
        );
    }

    /// @notice Spatial information about the token structure at a given time
    /// @dev Spatial values used to generate visuals are offset by
    ///      (seed * TOKEN_SCALE). Return values remove that offset
    /// @param timestamp The point in time to visualize the structure
    /// @return structure An array of StructureLevel structs
    function structureData(uint timestamp) 
        public 
        view 
        returns (StructureLevel[20] memory structure)
    {
        ITerraformsData terraformsData = ITerraformsData(tokenURIAddresses[0]);
        uint decay = _yearsOfDecay(timestamp);

        // Structure is offset into 3D space by the seed * the size of a tile
        // That offset is removed for ease of use
        int xyzNormalization = int(seed) * TOKEN_SCALE;
        
        // Temporary variables for loop
        int x;
        int y;
        int z;
        
        for (uint i; i < 20; i++){ 
            // Get XYZ origin for 0,0 tile on each level
            (x, y, z) = terraformsData.tileOrigin(i, 0, seed, decay, timestamp);
            
            // Add level to result array
            structure[i] = StructureLevel(
                i + 1, // Adjust level from zero-index
                terraformsData.levelDimensions(i) ** 2, // n Tokens == edge^2
                x - xyzNormalization,
                y - xyzNormalization,
                z - xyzNormalization                
            );
        }

        return structure;
    }

    /// @notice Data re: a token's visual composition and location on structure
    /// @dev Spatial values used to generate visuals are offset by
    ///      (seed * TOKEN_SCALE). Return values remove that offset
    /// @param tokenId The tokenId, from 1 to tokenCounter (max MAX_SUPPLY)
    /// @return result A TokenData struct
    function tokenSupplementalData(uint tokenId) 
        public 
        view
        postReveal(tokenId)
        returns (TokenData memory result) 
    {
        ITerraformsData terraformsData = ITerraformsData(
            tokenURIAddresses[tokenToURIAddressIndex[tokenId]]
        );

        // Structure is offset into 3D space by the seed * the size of a tile
        // That offset is removed for ease of use
        int xyzNormalization = int(seed) * TOKEN_SCALE;   

        (uint level, uint tile) = terraformsData.levelAndTile(
            tokenToPlacement[tokenId], 
            seed
        );
        uint dimensions = terraformsData.levelDimensions(level);
        
        result.elevation = terraformsData.tokenElevation(level, tile, seed);
        (
            result.structureSpaceX, 
            result.structureSpaceY, 
            result.structureSpaceZ
        ) = terraformsData.tileOrigin(
            level, 
            tile, 
            seed, 
            _yearsOfDecay(block.timestamp),
            block.timestamp
        );

        (result.zoneColors, result.zoneName) = terraformsData.tokenZone(
            tokenToPlacement[tokenId], 
            seed
        );

        (result.characterSet, , , ) = terraformsData.characterSet(
            tokenToPlacement[tokenId], seed
        );

        result.level = level + 1; // Adjust from zero-index
        result.xCoordinate = tile % dimensions;
        result.yCoordinate = tile / dimensions;
        result.structureSpaceX -= xyzNormalization;
        result.structureSpaceY -= xyzNormalization;
        result.structureSpaceZ -= xyzNormalization;
        return result;
        
    }

    /// @notice Token owner can set tokenURI address for an array of tokens
    /// @param tokens The tokens to set to the new URI address
    /// @param index The index of the new tokenURIAddress in tokenURIAddresses
    function setTokenURIAddress(uint[] memory tokens, uint index) public {
        require(index < tokenURIAddresses.length);

        for(uint i; i < tokens.length; i++){
            require(msg.sender == ownerOf(tokens[i]));
            tokenToURIAddressIndex[tokens[i]] = index;
        }
    }

    /// @notice Owner can add new opt-in tokenURI address
    /// @param newAddress The new tokenURI address
    function addTokenURIAddress(address newAddress) public onlyOwner {
        tokenURIAddresses.push(newAddress);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * INTERNAL: MINTING
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @notice Internal function for minting tokens
    /// @param to The recipient address
    /// @param numTokens The amount of tokens
    function _mintTokens(address to, uint numTokens) internal {
        uint base = tokenCounter;
        while (tokenCounter < base + numTokens) {
            _shufflePlacements();
            tokenCounter += 1;
            _safeMint(to, tokenCounter);
        }
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * INTERNAL: TOKEN DATA
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @notice Returns the amount of decay to apply to the token structure
    /// @dev Decay begins unless there are enough dreamers
    /// @param timestamp The point in time for determining decay
    /// @return The years of decay affecting the tokens
    function _yearsOfDecay(uint timestamp) internal view returns (uint) {
        uint decayBegins = REVEAL_TIMESTAMP + dreamers * 3_650 days;
        if (dreamers >= 500 || timestamp <= decayBegins) {
            return 0;
        } else {
            return (timestamp - decayBegins) / 365 days;
        }
    }
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * LICENSES
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
FOR UPDATES AND ADDITIONAL INFO ABOUT THE LICENSE RELATING TO THIS PROJECT,
SEE WWW.MATHCASTLES.XYZ

AS OF DEPLOY TIME, THE FOLLOWING LICENSE APPLIES TO THIS PROJECT'S ARTWORK
(EXCLUDING ITS FONTS, WHICH ARE COVERED BY THE LICENSE BELOW THIS LICENSE):

# License - Terraforms by Mathcastles

## 1. Purpose

This license (this “**License**”) was created by Mathcastles LLC 
("**Mathcastles**") to promote the interests of and to foster the innovations 
and creativity of NFT collectors and developers. This License seeks to maximize 
the rights of owners to enjoy and profit from the NFTs they own while preserving 
their value for future owners.

## 2. Summary

### 2.A. Owners of Terraforms NFTs can:

1. Display, reproduce and commercialize the Art (defined below) while they own 
the NFTs, with optional attribution.
2. Develop and commercialize derivative works of the Art, both physical and 
virtual (including, for example, fractionalizations) while they own the 
corresponding NFTs, with optional attribution.
3. Continue to commercialize derivative works of the Art of NFTs they previously 
owned if the derivative works were developed and released while they owned the 
NFTs.
4. Use the Art for personal, non-commercial use.
5. Display the Art on marketplaces for buying and selling their NFTs.
6. Use their NFTs to interact with websites and apps, including decentralized 
apps (dapps).

### 2.B. Owners of Terraforms NFTs cannot:

1. Transfer the rights granted by this license to anyone, or to the public.
2. Commercialize the Art of NFTs they do not currently own, or develop or 
release derivative works of the Art of NFTs they do not currently own.
3. Register or attempt to enforce any intellectual property rights in any 
derivative work of the Art, in a manner that would limit a past, present or 
future owner from commercializing the Art or creating derivative works in 
accordance with this license.

### 2.C. Additional Terms for Commercial Enterprises:

If an owner, together with its direct and indirect affiliates, operates an 
enterprise that has ten (10) or more employees or US$5,000,000 or more per year 
in gross receipts, then the owner cannot make more than US$500,000 in total 
annual revenue from commercializing its NFTs or derivatives without separate 
written permission from Mathcastles.

## 3. Terms

### 3.A. Definitions

“**Art**” means any art, design, and related underlying data that may be 
associated with an NFT that you Own.

"**Commercial Enterprise**" means any natural person, incorporated entity, or 
other commercial venture, together with its direct and indirect owners and 
affiliates, which during any of the last three calendar years had, in the 
aggregate, (i) ten (10) or more employees or (ii) the equivalent of 
US$5,000,000 or more per year in gross receipts.

"**Creator**" means Mathcastles LLC.

“**Derivatives**” means extensions or derivative works created by you of 
Purchased NFTs that include, or contain or are derived from the Art.

"**NFT**" means an Ethereum blockchain-tracked non-fungible token created from
this contract.

“**Own**” means, with respect to an NFT, an NFT that you have purchased or 
otherwise rightfully acquired, where proof of such purchase is recorded on the 
relevant blockchain, and that you continue to possess.

“**Purchased NFT**” means an NFT that you Own.

“**Third Party IP**” means any third party patent rights (including, without 
limitation, patent applications and disclosures), copyrights, trade secrets, 
trademarks, know-how or any other intellectual property rights recognized in any 
country or jurisdiction in the world.

### 3.B. Ownership

You acknowledge and agree that Creator (or, as applicable, its licensors) owns 
all legal right, title and interest in and to the Art, and all intellectual 
property rights therein. The rights that you have in and to the Art are limited 
to those described in this License. Creator reserves all rights in and to the 
Art not expressly granted to you in this License.

### 3.C. License

#### 3.C.1. General Use

Subject to your continued compliance with the terms of this License, Creator 
grants you a worldwide, non-exclusive, non-transferable, royalty-free license to 
use, copy, and display the Art for your Purchased NFTs, along with any 
Derivatives that you choose to create or use, solely for the following purposes:

1. for your own personal, non-commercial use;
2. as part of a marketplace that permits the purchase and sale of your NFTs; or
3. as part of a third party website or application that permits the inclusion, 
involvement, or participation of your NFTs.

#### 3.C.2. Commercial and Derivative Use

Creator grants you a limited, worldwide, non-exclusive, non-transferable license 
to use, copy, and display the Art for your Purchased NFTs for the purpose of 
commercializing your own physical or virtual merchandise that includes, 
contains, or consists of the Art for your Purchased NFTs (“**Commercial Use**”) 
and to commercialize Derivatives of your Purchased NFTs ("**Derivative Use**"), 
provided that if you are a Commercial Enterprise, such Commercial Use and 
Derivative Use do not in the aggregate result in you earning more than Five 
Hundred Thousand U.S. Dollars (US$500,000) in gross revenue in any year. For 
the sake of clarity, nothing in this Section 3.C.2. will be deemed to restrict 
you from:

1. owning or operating a marketplace that permits the use and sale of NFTs 
generally;
2. owning or operating a third party website or application that permits the 
inclusion, involvement, or participation of NFTs generally; or
3. earning revenue from any of the foregoing, even where such revenue is in 
excess of US$500,000 per year.

### 3.D. Restrictions

#### 3.D.1. No Additional IP Rights

You may not attempt to trademark, copyright, or otherwise acquire additional 
intellectual property rights in the Art, nor permit any third party to do or 
attempt to do any of the foregoing, without Creator’s express prior written 
consent; _provided_, that this section does not prohibit an owner from acquiring 
intellectual property rights in a derivative work.

#### 3.D.2. No License Granted as to Third Party IP

To the extent that Art associated with your Purchased NFTs contains Third Party 
IP (for example, licensed intellectual property from a third party artist, 
company, or public figure), you understand and agree as follows:

1. that the inclusion of any Third Party IP in the Art does not grant you any 
rights to use such Third Party IP except as it is incorporated in the Art;
2. that, depending on the nature of the license granted from the owner of the 
Third Party IP, Creator may need to pass through additional restrictions on your 
ability to use the Art; and
3. to the extent that Creator informs you of such additional restrictions in 
writing (including by email), you will be responsible for complying with all 
such restrictions from the date that you receive the notice, and that failure 
to do so will be deemed a breach of this license.

The restrictions in this Section 3.D. will survive the expiration or termination 
of this License.

### 3.E. Limitations of License

Except for the right to Derivative Use described in Section 3.C.2., the license 
granted in this Section 3 applies only to the extent that you continue to Own 
the applicable Purchased NFT. If at any time you sell, trade, donate, give away, 
transfer, or otherwise dispose of your Purchased NFT for any reason, the license 
granted in Section 3 (except for the right to Derivative Use described in 
Section 3.C.2.) will immediately expire with respect to those NFTs without the 
requirement of notice, and you will have no further rights in or to the Art for 
those NFTs. The right to Derivative Use described in Section 3.C.2. shall 
continue indefinitely for so long as you comply with this License.

If you are a Commercial Enterprise and you exceed the US$500,000 limitation on 
annual gross revenue set forth in Section 3.C.2. above, you will be in breach of 
this License, and must send an email to Creator at [email protected] 
within fifteen (15) days, with the phrase “NFT License - Commercial Use” in the 
subject line, requesting a discussion with Creator regarding entering into a 
broader license agreement or obtaining an exemption (which may be granted or 
withheld in Creator’s sole and absolute discretion).

If you exceed the scope of the license grant in this Section 3 without entering 
into a broader license agreement with or obtaining an exemption from Creator, 
you acknowledge and agree that:

1. you are in breach of this License;
2. in addition to any remedies that may be available to Creator at law or in 
equity, the Creator may immediately terminate this License, without the 
requirement of notice; and
3. you will be responsible to reimburse Creator for any costs and expenses 
incurred by Creator during the course of enforcing the terms of this License 
against you.

********************************************************************************

THE FOLLOWING LICENSE APPLIES TO THE FONTS USED IN THIS PROJECT

Copyright 2018 The Noto Project Authors (github.com/googlei18n/noto-fonts)

This Font Software is licensed under the SIL Open Font License,
Version 1.1.

This license is copied below, and is also available with a FAQ at:
http://scripts.sil.org/OFL

-----------------------------------------------------------
SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
-----------------------------------------------------------

PREAMBLE
The goals of the Open Font License (OFL) are to stimulate worldwide
development of collaborative font projects, to support the font
creation efforts of academic and linguistic communities, and to
provide a free and open framework in which fonts may be shared and
improved in partnership with others.

The OFL allows the licensed fonts to be used, studied, modified and
redistributed freely as long as they are not sold by themselves. The
fonts, including any derivative works, can be bundled, embedded,
redistributed and/or sold with any software provided that any reserved
names are not used by derivative works. The fonts and derivatives,
however, cannot be released under any other type of license. The
requirement for fonts to remain under this license does not apply to
any document created using the fonts or their derivatives.

DEFINITIONS
"Font Software" refers to the set of files released by the Copyright
Holder(s) under this license and clearly marked as such. This may
include source files, build scripts and documentation.

"Reserved Font Name" refers to any names specified as such after the
copyright statement(s).

"Original Version" refers to the collection of Font Software
components as distributed by the Copyright Holder(s).

"Modified Version" refers to any derivative made by adding to,
deleting, or substituting -- in part or in whole -- any of the
components of the Original Version, by changing formats or by porting
the Font Software to a new environment.

"Author" refers to any designer, engineer, programmer, technical
writer or other person who contributed to the Font Software.

PERMISSION & CONDITIONS
Permission is hereby granted, free of charge, to any person obtaining
a copy of the Font Software, to use, study, copy, merge, embed,
modify, redistribute, and sell modified and unmodified copies of the
Font Software, subject to the following conditions:

1) Neither the Font Software nor any of its individual components, in
Original or Modified Versions, may be sold by itself.

2) Original or Modified Versions of the Font Software may be bundled,
redistributed and/or sold with any software, provided that each copy
contains the above copyright notice and this license. These can be
included either as stand-alone text files, human-readable headers or
in the appropriate machine-readable metadata fields within text or
binary files as long as those fields can be easily viewed by the user.

3) No Modified Version of the Font Software may use the Reserved Font
Name(s) unless explicit written permission is granted by the
corresponding Copyright Holder. This restriction only applies to the
primary font name as presented to the users.

4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
Software shall not be used to promote, endorse or advertise any
Modified Version, except to acknowledge the contribution(s) of the
Copyright Holder(s) and the Author(s) or with their explicit written
permission.

5) The Font Software, modified or unmodified, in part or in whole,
must be distributed entirely under this license, and must not be
distributed under any other license. The requirement for fonts to
remain under this license does not apply to any document created using
the Font Software.

TERMINATION
This license becomes null and void if any of the above conditions are
not met.

DISCLAIMER
THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
OTHER DEALINGS IN THE FONT SOFTWARE.
*/