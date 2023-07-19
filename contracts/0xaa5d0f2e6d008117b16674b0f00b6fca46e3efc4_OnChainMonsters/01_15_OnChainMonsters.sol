// contracts/OnChainMonsters.sol
// SPDX-License-Identifier: MIT
// Inspired by Anonymice. <3
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./IMonsterDough.sol";
import "./OnChainMonstersLib.sol";

contract OnChainMonsters is ERC721Enumerable {
    using OnChainMonstersLib for uint8;

    struct Trait {
        string name;
        string data;
    }

    mapping(uint256 => Trait[]) public allTraits;
    mapping(bytes8 => bool) traitsHashToIsMinted;

    bytes8[10000] internal _tokenIdToTraitsHash;
   // mapping(uint256 => bytes8) internal _tokenIdToTraitsHash;

    uint256 internal constant MAX_SUPPLY = 10000;
    uint256 internal constant MINTS_PER_TIER = 2000;

    uint256 salt = 0xC0FFEE2C0DE;

    address doughAddress;
    address _owner;

    string[7] internal TRAIT_TYPE_NAMES = [
        "tail",
        "body",
        "head",
        "eyes",
        "arms",
        "mouth",
        "burned"
    ];

    string[3][9] internal COLORS = [
        ["4d5265", "d6bd0a", "Gold"],
        ["95868d", "e7e5d9", "Light"],
        ["dae7ea", "828795", "Dark"],
        ["49fed3", "f2ec55", "Yellow"],
        ["fef749", "79bbe3", "Blue"],
        ["f56060", "6fd067", "Green"],
        ["60d1f5", "f9b5c1", "Pink"],
        ["60f561", "ea7e75", "Red"],
        ["fed449", "b98bdb", "Purple"]
    ];

    uint8[81] internal CHARS = [
        48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 
        97, 98, 99, 100, 101, 102, 103, 104, 105, 
        106, 107, 108, 109, 110, 111, 112, 113, 
        114, 115, 116, 117, 118, 119, 120, 121, 
        122, 66, 68, 69, 70, 71, 73, 74, 75, 78, 
        79, 80, 82, 85, 87, 88, 89, 33, 35, 36, 37,
        38, 40, 41, 42, 43, 44, 45, 46, 47, 58, 59, 
        60, 61, 62, 63, 64, 91, 93, 94, 95, 96, 123, 
        124, 125, 126
    ];

    uint16[][7] rarities;

    constructor() ERC721("On-Chain Monsters", "OCMOS") {
        _owner = msg.sender;

        rarities[0] = [4000, 2000, 1000, 1000, 750, 750, 500];
        rarities[1] = [2250, 2250, 2100, 1000, 1000, 750, 400, 250];
        rarities[2] = [1275, 1275, 1010, 950, 950, 950, 900, 900, 800, 400, 300, 250, 20, 20];
        rarities[3] = [1500, 1300, 1300, 1100, 1000, 900, 800, 800, 800, 500];
        rarities[4] = [2000, 2000, 800, 800, 800, 800, 800, 750, 500, 500, 250];
        rarities[5] = [870, 870, 870, 870, 870, 870, 870, 870, 870, 870, 870, 430];
        rarities[6] = [1, 1250, 1250, 1250, 1250, 1250, 1250, 1250, 1249]; // color
    }

    // ######## MINTING

    function rarityIndexForNumber(uint256 number, uint8 traitType) internal view returns (bytes1) {
        uint16 lowerBound = 0;
        for (uint8 i = 0; i < rarities[traitType].length; i++) {
            uint16 upperBound = lowerBound + rarities[traitType][i];
            if (number >= lowerBound && number < upperBound)
                return bytes1(i);
            lowerBound = upperBound;
        }

        revert();
    }

    function createTraitsHash(uint256 t, uint256 c) internal returns (bytes8) {
        require(c < 10);

        bytes8 hashOut = 0;

        bytes8 bte = 0xff00000000000000;

        uint256 _salt = salt;

        uint256 rnd = uint256(
            keccak256(
                abi.encodePacked(
                    _salt,
                    t,
                    msg.sender,
                    c,
                    block.timestamp,
                    block.difficulty
                )
            )      
        );

        for (uint8 i = 0; i < 6; i++) {
            hashOut ^= (bte & rarityIndexForNumber((rnd >> 32*i) % 10000, i)) >> 8*i;
        }

        // color
        if(t % 2000 > 0) {
            hashOut ^= (bte & rarityIndexForNumber(_salt % 10000, 6)) >> 8*7;
        }
        
        salt = _salt ^ rnd;

        if (traitsHashToIsMinted[hashOut])
            return createTraitsHash(t, c + 1);

        return hashOut;
    }

    function currentMintingCost() public view returns (uint256) {
        uint256 totalSupply = totalSupply();

        if (totalSupply < 2000)
            return 0;
        if (totalSupply < 4000)
            return 1000000000000000000;
        if (totalSupply < 6000)
            return 2000000000000000000;
        if (totalSupply < 8000)
            return 3000000000000000000;

        return 4000000000000000000;
    }

    function mintInternal() internal {
        uint256 tokenId = totalSupply();

        require(tokenId < MAX_SUPPLY);
        require(!OnChainMonstersLib.isContract(msg.sender));

        _tokenIdToTraitsHash[tokenId] = createTraitsHash(tokenId, 0);
        traitsHashToIsMinted[_tokenIdToTraitsHash[tokenId]] = true;

        _mint(msg.sender, tokenId);
    }

    function mintMonster() public {
        if (totalSupply() < MINTS_PER_TIER)
            return mintInternal();

        IMonsterDough(doughAddress).burnFrom(msg.sender, currentMintingCost());

        return mintInternal();
    }

    function burnForMint(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender);

        _transfer(msg.sender, 0xdeaDDeADDEaDdeaDdEAddEADDEAdDeadDEADDEaD, tokenId);

        mintInternal();
    }

    // ######## READING

    function charToNumber(uint8 char) internal view returns (uint8) {
        for(uint8 i = 0; i < CHARS.length; i++) {
            if(char == CHARS[i])
                return i;
        }
        revert();
    }

    function hashToSVG(uint256 tokenId, bytes8 tHash) public view returns (string memory) {
        string memory svgString;

        for (uint8 tt = 0; tt < 7; tt++) {
            uint8 traitIndex = uint8(tHash[tt]);

            bytes memory pathsStr = bytes(allTraits[tt][traitIndex].data);

            uint256 cursor = 0;
            while(cursor < pathsStr.length) {
                uint8 colorIndex = uint8(pathsStr[cursor]);
                cursor++;

                uint256 left = uint256(charToNumber(uint8(pathsStr[cursor])));
                cursor++;
                uint256 right = uint256(charToNumber(uint8(pathsStr[cursor])));
                cursor++;
                uint256 numBytes = (left * 80) + right;

                svgString = string(
                    abi.encodePacked(
                        svgString,
                        "<path d='M "
                    )
                );

                for(uint pi = 0; pi < numBytes; pi++) {
                    uint8 c = uint8(pathsStr[cursor + pi]);

                    if(c == 67 || c == 76 || c == 86
                         || c == 72 || c == 77 || c == 90) {
                        svgString = string(abi.encodePacked(svgString, c, " "));
                    } 
                     else {
                         svgString = string(abi.encodePacked(svgString, charToNumber(c).toString(), " "));
                    }
                }

                cursor += numBytes;

                if(colorIndex != 48) {
                    svgString = string(
                        abi.encodePacked(
                            svgString,
                            "' class='c",
                            colorIndex
                        )
                    );
                }
    
                svgString = string(abi.encodePacked(svgString, "'/>"));
            }
        }

        uint8 color = uint8(tHash[7]);

        string memory tokenIdString = OnChainMonstersLib.toString(tokenId);

        svgString = string(
            abi.encodePacked(
                '<svg id="ocf-svg',
                tokenIdString,
                '" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 80 80"><rect x="0" y="0" width="80" height="80" stroke-width="0" fill="#',
                COLORS[color][0],
                '" />',
                color == 0 ? '<style>@keyframes prty{0%{opacity:0.35;transform:rotate(0);}50%{opacity:0.5;}100%{opacity:0.35;transform:rotate(359deg);}</style><ellipse cx="40" cy="40" rx="24" ry="23" style="fill:#ffff99;animation:prty 5s infinite linear;transform-origin:50% 50%;" filter="url(#f1)"/><defs><filter id="f1" x="-30" y="-30" width="60" height="60"><feGaussianBlur stdDeviation="6" /></filter></defs>' : '',
                svgString,
                "<style>path{fill:none;stroke:#343434;stroke-width:.4;stroke-linecap:round;stroke-linejoin:round;} #ocf-svg",
                tokenIdString,
                " .c1{fill:#",
                COLORS[color][1],
                "}.c2{fill:#a4a4a4}.c3{fill:#343434}.c4{fill:#ffffff}.c5{fill:#484848}.c6{fill:#d8d8d8}.c7{fill:#ff00ff}</style></svg>"
            )
        );

        return svgString;
    }

    function hashToMetadata(bytes8 tHash) public view returns (string memory) {

        string memory metadataString ='[';

        for (uint8 tt = 0; tt < 7; tt++) {
            uint8 traitIndex = uint8(tHash[tt]);

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    TRAIT_TYPE_NAMES[tt],
                    '","value":"',
                    allTraits[tt][traitIndex].name,
                    '"},'
                )
            );
        }

        metadataString = string(
            abi.encodePacked(
                metadataString,
                '{"trait_type":"color","value":"',
                COLORS[uint8(tHash[7])][2],
                '"}]'
            )
        );

        return metadataString;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId));

        bytes8 tHash = tokenIdToTraitsHash(tokenId);

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                    OnChainMonstersLib.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "On-Chain Monster #',
                                    OnChainMonstersLib.toString(tokenId),
                                    '", "description": "A collection of 10,000 unique monsters generated by code. No external dependencies. 100% Ethereum blockchain.", "image": "data:image/svg+xml;base64,',
                                    OnChainMonstersLib.encode(
                                        bytes(hashToSVG(tokenId, tHash))
                                    )
                                    ,
                                    '","attributes":',
                                    hashToMetadata(tHash),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    function tokenIdToTraitsHash(uint256 tokenId) public view returns (bytes8) {
        bytes8 tHash = _tokenIdToTraitsHash[tokenId];

        if (ownerOf(tokenId) == 0xdeaDDeADDEaDdeaDdEAddEADDEAdDeadDEADDEaD) {
            tHash ^= 0x0000000000000100;
        }

        return tHash;
    }

    function walletOfOwner(address wallet) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(wallet, i);
        }

        return tokensId;
    }

    // ######## Owner

    function clearTraits() public onlyOwner {
        for (uint256 i = 0; i < 8; i++) {
            delete allTraits[i];
        }
    }

    function addTraits(uint256 traitTypeIndex, Trait[] memory traits) public onlyOwner {
        for (uint256 i = 0; i < traits.length; i++) {
            allTraits[traitTypeIndex].push(Trait(traits[i].name, traits[i].data));
        }
    }

    function setDoughAddress(address a) public onlyOwner {
        doughAddress = a;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }
}