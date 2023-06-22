// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBallerBars.sol";
import "./ChainsLibrary.sol";
import "./IChains.sol";
import "./IChainsTraits.sol";

contract Chains is ERC721Enumerable, Ownable {

    /**

     _______  ________ __    __      _______   ______  __       __       ________ _______
    |       \|        \  \  |  \    |       \ /      \|  \     |  \     |        \       \
    | ▓▓▓▓▓▓▓\ ▓▓▓▓▓▓▓▓ ▓▓\ | ▓▓    | ▓▓▓▓▓▓▓\  ▓▓▓▓▓▓\ ▓▓     | ▓▓     | ▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓\
    | ▓▓__/ ▓▓ ▓▓__   | ▓▓▓\| ▓▓    | ▓▓__/ ▓▓ ▓▓__| ▓▓ ▓▓     | ▓▓     | ▓▓__   | ▓▓__| ▓▓
    | ▓▓    ▓▓ ▓▓  \  | ▓▓▓▓\ ▓▓    | ▓▓    ▓▓ ▓▓    ▓▓ ▓▓     | ▓▓     | ▓▓  \  | ▓▓    ▓▓
    | ▓▓▓▓▓▓▓\ ▓▓▓▓▓  | ▓▓\▓▓ ▓▓    | ▓▓▓▓▓▓▓\ ▓▓▓▓▓▓▓▓ ▓▓     | ▓▓     | ▓▓▓▓▓  | ▓▓▓▓▓▓▓\
    | ▓▓__/ ▓▓ ▓▓_____| ▓▓ \▓▓▓▓    | ▓▓__/ ▓▓ ▓▓  | ▓▓ ▓▓_____| ▓▓_____| ▓▓_____| ▓▓  | ▓▓
    | ▓▓    ▓▓ ▓▓     \ ▓▓  \▓▓▓    | ▓▓    ▓▓ ▓▓  | ▓▓ ▓▓     \ ▓▓     \ ▓▓     \ ▓▓  | ▓▓
     \▓▓▓▓▓▓▓ \▓▓▓▓▓▓▓▓\▓▓   \▓▓     \▓▓▓▓▓▓▓ \▓▓   \▓▓\▓▓▓▓▓▓▓▓\▓▓▓▓▓▓▓▓\▓▓▓▓▓▓▓▓\▓▓   \▓▓

     _______  ______ _______       ________ __    __ ________
    |       \|      \       \     |        \  \  |  \        \
    | ▓▓▓▓▓▓▓\\▓▓▓▓▓▓ ▓▓▓▓▓▓▓\     \▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓▓▓▓▓▓▓
    | ▓▓  | ▓▓ | ▓▓ | ▓▓  | ▓▓       | ▓▓  | ▓▓__| ▓▓ ▓▓__
    | ▓▓  | ▓▓ | ▓▓ | ▓▓  | ▓▓       | ▓▓  | ▓▓    ▓▓ ▓▓  \
    | ▓▓  | ▓▓ | ▓▓ | ▓▓  | ▓▓       | ▓▓  | ▓▓▓▓▓▓▓▓ ▓▓▓▓▓
    | ▓▓__/ ▓▓_| ▓▓_| ▓▓__/ ▓▓       | ▓▓  | ▓▓  | ▓▓ ▓▓_____
    | ▓▓    ▓▓   ▓▓ \ ▓▓    ▓▓       | ▓▓  | ▓▓  | ▓▓ ▓▓     \
     \▓▓▓▓▓▓▓ \▓▓▓▓▓▓\▓▓▓▓▓▓▓         \▓▓   \▓▓   \▓▓\▓▓▓▓▓▓▓▓

     _______  __        ______   ______  __    __  ______  __    __  ______  ______ __    __
    |       \|  \      /      \ /      \|  \  /  \/      \|  \  |  \/      \|      \  \  |  \
    | ▓▓▓▓▓▓▓\ ▓▓     |  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\ ▓▓ /  ▓▓  ▓▓▓▓▓▓\ ▓▓  | ▓▓  ▓▓▓▓▓▓\\▓▓▓▓▓▓ ▓▓\ | ▓▓
    | ▓▓__/ ▓▓ ▓▓     | ▓▓  | ▓▓ ▓▓   \▓▓ ▓▓/  ▓▓| ▓▓   \▓▓ ▓▓__| ▓▓ ▓▓__| ▓▓ | ▓▓ | ▓▓▓\| ▓▓
    | ▓▓    ▓▓ ▓▓     | ▓▓  | ▓▓ ▓▓     | ▓▓  ▓▓ | ▓▓     | ▓▓    ▓▓ ▓▓    ▓▓ | ▓▓ | ▓▓▓▓\ ▓▓
    | ▓▓▓▓▓▓▓\ ▓▓     | ▓▓  | ▓▓ ▓▓   __| ▓▓▓▓▓\ | ▓▓   __| ▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓ | ▓▓ | ▓▓\▓▓ ▓▓
    | ▓▓__/ ▓▓ ▓▓_____| ▓▓__/ ▓▓ ▓▓__/  \ ▓▓ \▓▓\| ▓▓__/  \ ▓▓  | ▓▓ ▓▓  | ▓▓_| ▓▓_| ▓▓ \▓▓▓▓
    | ▓▓    ▓▓ ▓▓     \\▓▓    ▓▓\▓▓    ▓▓ ▓▓  \▓▓\\▓▓    ▓▓ ▓▓  | ▓▓ ▓▓  | ▓▓   ▓▓ \ ▓▓  \▓▓▓
     \▓▓▓▓▓▓▓ \▓▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓▓ \▓▓   \▓▓ \▓▓▓▓▓▓ \▓▓   \▓▓\▓▓   \▓▓\▓▓▓▓▓▓\▓▓   \▓▓

    **/

    // RGV2YmVycnkjNDAzMCBhbmQgcG9ua3lwaW5rIzc5MTMgd2VyZSBoZXJl

    using ChainsLibrary for uint8;

    struct Trait {
        string traitName;
        string traitType;
        string pixels;
        uint256 pixelCount;
    }

    // Mappings
    mapping(string => bool) hashToMinted;
    mapping(uint256 => string) internal tokenIdToHash;
    mapping(uint256 => uint256) internal tokenIdToTimestamp;

    // uint256s
    uint256 public constant MAX_SUPPLY = 6000;
    uint256 SEED_NONCE = 0;

    // Addresses
    address _genOneChainsAddress;
    address _genOneBallerBarsAddress;
    address _genTwoBallerBarsAddress;

    bool public _paused = true;

    uint256 public _combinedTotalSupply = 3406;

    uint256 _reserveMinted = 0;

    constructor() ERC721("Chains", "CHAIN") {}

    function rarityGen0(uint256 r) private pure returns (uint256) {
        if (r >= 330)    {return 4;}
        if (r >= 150)    {return 3;}
        if (r >=  30)    {return 2;}
        if (r >=   3)    {return 1;}
        return 0;
    }
    function rarityGen1(uint256 r) private pure returns (uint256) {
        if (r >= 504)    {return 9;}
        if (r >= 414)    {return 8;}
        if (r >= 330)    {return 7;}
        if (r >= 252)    {return 6;}
        if (r >= 180)    {return 5;}
        if (r >= 114)    {return 4;}
        if (r >=  54)    {return 3;}
        if (r >=   9)    {return 2;}
        if (r >=   3)    {return 1;}
        return 0;
    }
    function rarityGen2(uint256 r) private pure returns (uint256) {
        if (r >= 471)    {return 9;}
        if (r >= 372)    {return 8;}
        if (r >= 285)    {return 7;}
        if (r >= 207)    {return 6;}
        if (r >= 135)    {return 5;}
        if (r >=  69)    {return 4;}
        if (r >=  21)    {return 3;}
        if (r >=   9)    {return 2;}
        if (r >=   3)    {return 1;}
        return 0;
    }
    function rarityGen3(uint256 r) private pure returns (uint256) {
        if (r >= 462)    {return 7;}
        if (r >= 336)    {return 6;}
        if (r >= 222)    {return 5;}
        if (r >= 120)    {return 4;}
        if (r >=  33)    {return 3;}
        if (r >=   9)    {return 2;}
        if (r >=   3)    {return 1;}
        return 0;
    }
    function rarityGen4(uint256 r) private pure returns (uint256) {
        if (r >=  93)    {return 7;}
        if (r >=  63)    {return 6;}
        if (r >=  45)    {return 5;}
        if (r >=  33)    {return 4;}
        if (r >=  21)    {return 3;}
        if (r >=   9)    {return 2;}
        if (r >=   3)    {return 1;}
        return 0;
    }
    function rarityGen5(uint256 r) private pure returns (uint256) {
        if (r >=  93)    {return 7;}
        if (r >=  63)    {return 6;}
        if (r >=  45)    {return 5;}
        if (r >=  33)    {return 4;}
        if (r >=  21)    {return 3;}
        if (r >=   9)    {return 2;}
        if (r >=   3)    {return 1;}
        return 0;
    }

    function hash(
        uint256 _t,
        address _a
    ) internal returns (string memory) {
        // This will generate a 7 character string.
        // The last 6 digits are random, the first is 0, due to the chain is not being burned.
        SEED_NONCE++;

        bytes memory buffer = new bytes(7);
        buffer[0] = bytes1(uint8(48));

    unchecked {
        for (uint _c=0; _c<4; _c++) {
            uint256 _largeRandom =
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        _t,
                        _a,
                        _c,
                        SEED_NONCE
                    )
                )
            );


            for (uint i=0; i<4; i++) {
                buffer[1] = bytes1(uint8(48 + rarityGen0(_largeRandom % 600)));
                _largeRandom /= 600;
                buffer[2] = bytes1(uint8(48 + rarityGen1(_largeRandom % 600)));
                _largeRandom /= 600;
                buffer[3] = bytes1(uint8(48 + rarityGen2(_largeRandom % 600)));
                _largeRandom /= 600;
                buffer[4] = bytes1(uint8(48 + rarityGen3(_largeRandom % 600)));
                _largeRandom /= 600;
                buffer[5] = bytes1(uint8(48 + rarityGen4(_largeRandom % 600)));
                _largeRandom /= 600;
                buffer[6] = bytes1(uint8(48 + rarityGen5(_largeRandom % 600)));

                string memory currentHash = string(buffer);

                if (hashToMinted[currentHash] == false) {
                    return currentHash;
                }

                _largeRandom /= 600;
            }
        }

        // use background 4
        buffer[6] = bytes1(uint8(48 + 4));
    }
        return string(buffer);
    }

    /**
     * @dev Returns the current baller bar cost of a mint.
     */

    function currentBallerBarsCost() public view returns (uint256) {
        uint256 _totalSupply = _combinedTotalSupply;
        if (_totalSupply <= 3000)
            return 4 ether;
        if (_totalSupply > 3000 && _totalSupply <= 4000)
            return 8 ether;
        if (_totalSupply > 4000 && _totalSupply <= 5000)
            return 16 ether;
        return 24 ether;
    }

    /**
     * @dev Mint reserve. Owner only, for giveaways and tests
     * @param tokenQuantity Quantity of tokens
     */

    function mintReserve(uint256 tokenQuantity) onlyOwner external  {
        require(_reserveMinted+tokenQuantity<7,"EXCEEDS_RESERVE_MINTS");
        for (uint256 i = 0; i < tokenQuantity; i++) {
            ++_reserveMinted;
            mintInternal();
        }
    }

    /**
     * @dev Mint internal, this is to avoid code duplication.
     */

    function mintInternal() internal {
        require(_combinedTotalSupply < MAX_SUPPLY);
        require(tx.origin == msg.sender);

        uint256 thisTokenId = _combinedTotalSupply;

        tokenIdToHash[thisTokenId] = hash(thisTokenId, msg.sender);

        hashToMinted[tokenIdToHash[thisTokenId]] = true;

        tokenIdToTimestamp[thisTokenId] = block.timestamp;

        _combinedTotalSupply++;
        _mint(msg.sender, thisTokenId);
    }

    /**
     * @dev Mint for BallerBars
     * @param ballerBarsGeneration The generation of Baller Bars to use.
     */

    function mintWithBallerBars(uint256 ballerBarsGeneration) public {
        require(_paused==false,"PAUSED");
        IBallerBars ballerBarsContract = getBallerBarsContract(ballerBarsGeneration);
        ballerBarsContract.burnFrom(msg.sender, currentBallerBarsCost());
        mintInternal();
    }

    /**
     * @dev Mint for BallerBars with both BallerBars generation one and generation 2
     * @param bbOneAmount The amount of BB generation one to burn
     * @param bbOneAmount The amount of BB generation two to burn
     */

    function mintWithBallerBarsSpecial(uint256 bbOneAmount, uint256 bbTwoAmount) public {
        require(_paused==false,"PAUSED");
        require(bbOneAmount+bbTwoAmount==currentBallerBarsCost(),"INVALID_COMBINATION");

        IBallerBars ballerBarsGenOneContract = IBallerBars(_genOneBallerBarsAddress);
        IBallerBars ballerBarsGenTwoContract = IBallerBars(_genTwoBallerBarsAddress);

        ballerBarsGenOneContract.burnFrom(msg.sender, bbOneAmount);
        ballerBarsGenTwoContract.burnFrom(msg.sender, bbTwoAmount);

        mintInternal();
    }

    /**
     * @dev Burns and mints new.
     * @param _tokenId The token to burn.
     */
    function burnForMint(uint256 _tokenId) public {
        require(_paused==false,"PAUSED");

        //Burn token
        _transfer(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            _tokenId
        );

        mintInternal();
    }

    /**
     * @dev Burns previous generation chain and mints new one.
     * @param _tokenId The token to burn.
     */

    function burnGenOneForMint(uint256 _tokenId) public {
        require(_paused==false,"PAUSED");
        IChains chainsGenOne = IChains(_genOneChainsAddress);

        hashToMinted[chainsGenOne._tokenIdToHash(_tokenId)] = true;

        //Burn token
        chainsGenOne.transferFrom(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            _tokenId
        );

        mintInternal();
    }

    /**
     * @dev Migrates previous generation chain to this one.
     * @param _tokenId The token to migrate
     */

    function migrateGenOne(uint256 _tokenId) public {
        require(_paused==false,"PAUSED");
        migrate(_tokenId);
    }

    /**
     * @dev Migrates previous generation chain
     * @param _tokenId The token to migrate
     */

    function migrate(uint _tokenId) internal {
        require(_tokenId < 3406, "TOKEN_ID_TOO_HIGH");

        IChains chainsGenOne = IChains(_genOneChainsAddress);

        tokenIdToHash[_tokenId] = chainsGenOne._tokenIdToHash(_tokenId);
        hashToMinted[tokenIdToHash[_tokenId]] = true;

        tokenIdToTimestamp[_tokenId] = chainsGenOne.getTokenTimestamp(_tokenId);

        //Burn token
        chainsGenOne.transferFrom(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            _tokenId
        );

        _mint(msg.sender, _tokenId);
    }

    /**
     * @dev Hash to SVG function
     */

    function hashToSVG(string memory _hash)
        public
        view
        returns (string memory)
    {
        string memory svgString;

        string memory bgString;
        string memory bgColor;
        //

        bool[24][24] memory placedPixels;

        uint8 bgIndex =  ChainsLibrary.parseInt(ChainsLibrary.substring(_hash, 6, 7)); // BG

        if ( bgIndex == 0 ) {
            bgColor = "2596be";
        } else if ( bgIndex == 1 ) {
            bgColor = "10447c";
        } else if ( bgIndex == 2 ) {
            bgColor = "c8fcfc";
        } else if ( bgIndex == 3 ) {
            bgColor = "383434";
        } else if ( bgIndex == 4 ) {
            bgColor = "ffe4bc";
        } else if ( bgIndex == 5 ) {
            bgColor = "d0ccfc";
        }else if ( bgIndex == 6 ) {
            bgColor = "e0dcdc";
        }

        if ( bgIndex < 7 ) { // bg color 7 is none
            bgString = string(
                    abi.encodePacked(
                        'style="background-color:#',
                        bgColor,
                        '" '
                    )
                );
        } else {
            bgString = "";
        }

        for (uint8 i = 0; i < 6; i++) {  // 7 (we should skip BG here, so 6 will be final)
            uint8 thisTraitIndex = ChainsLibrary.parseInt(
                ChainsLibrary.substring(_hash, i, i + 1)
            );

            (,,string memory pixels,uint256 pixelCount)= IChainsTraits(_genOneChainsAddress).traitTypes(i, thisTraitIndex);

            for (
                uint16 j = 0;
                j < pixelCount; // <
                j++
            ) {
                string memory thisPixel = ChainsLibrary.substring(
                    pixels,
                    j * 4,
                    j * 4 + 4
                );

                uint8 x = uint8(bytes(thisPixel)[0]) - 96;
                uint8 y = uint8(bytes(thisPixel)[1]) - 96;

                if (placedPixels[x][y]) continue;

                svgString = string(
                    abi.encodePacked(
                        svgString,
                        "<rect class='c",
                        ChainsLibrary.substring(thisPixel, 2, 4),
                        "' x='",
                        x.toString(),
                        "' y='",
                        y.toString(),
                        "'/>"
                    )
                );

                placedPixels[x][y] = true;
            }
        }

        svgString = string(
            abi.encodePacked(
                '<svg id="c" xmlns="http://www.w3.org/2000/svg" ',
                'preserveAspectRatio="xMinYMin meet" viewBox="0 0 26 26" ',
                bgString,
                ' > ',
                svgString,
                '<style>rect{width:1px;height:1px;}#c{shape-rendering: crispedges;}.c00{fill:#d844cf}.c01{fill:#f1f1f1}.c02{fill:#ff4b54}.c03{fill:#ff6b71}.c04{fill:#ff5c64}.c05{fill:#ff132f}.c06{fill:#ff4651}.c07{fill:#ff444f}.c08{fill:#ff3644}.c09{fill:#ff3543}.c10{fill:#ff3845}.c11{fill:#ff4d57}.c12{fill:#c146fb}.c13{fill:#333aff}.c14{fill:#c2defc}.c15{fill:#eaf4ff}.c16{fill:#e3eefa}.c17{fill:#cfe4fa}.c18{fill:#b61ffc}.c19{fill:#bf42fb}.c20{fill:#bc35fb}.c21{fill:#bd36fb}.c22{fill:#fee4bf}.c23{fill:#ff8800}.c24{fill:#ffd300}.c25{fill:#ffc200}.c26{fill:#ff9a00}.c27{fill:#ffb100}.c28{fill:#ffa000}.c29{fill:#f6d900}.c30{fill:#f0ce00}.c31{fill:#eed100}.c32{fill:#00e58b}.c33{fill:#00df71}.c34{fill:#00e280}.c35{fill:#00cb59}.c36{fill:#00d874}.c37{fill:#00d963}.c38{fill:#00d36c}.c39{fill:#00de7c}.c40{fill:#ebb7a5}.c41{fill:#e3aa96}.c42{fill:#094378}.c43{fill:#c1a900}.c44{fill:#dcc000}.c45{fill:#fade11}.c46{fill:#f8dc09}.c47{fill:#00c5e6}.c48{fill:#dcdcdc}.c49{fill:#c1f8f9}.c50{fill:#b2b8b9}.c51{fill:#aab0b1}.c52{fill:#b0b4b5}.c53{fill:#e2a38d}.c54{fill:#eba992}.c55{fill:#e8b2a0}.c56{fill:#ff0043}.c57{fill:#f6767b}.c58{fill:#c74249}.c59{fill:#aa343a}.c60{fill:#4047ff}.c61{fill:#585eff}.c62{fill:#4d54ff}.c63{fill:#222bff}.c64{fill:#3d44ff}.c65{fill:#3b42ff}.c66{fill:#3239ff}.c67{fill:#343bff}.c68{fill:#4249ff}.c69{fill:#333333}.c70{fill:#222222}.c71{fill:#ccccff}</style></svg>'
            )
        );

        return svgString;
    }

    /**
     * @dev Hash to metadata function
     */

    function hashToMetadata(string memory _hash)
        public
        view
        returns (string memory)
    {
        string memory metadataString;

        for (uint8 i = 0; i < 7; i++) { //9
            uint8 thisTraitIndex = ChainsLibrary.parseInt(
                ChainsLibrary.substring(_hash, i, i + 1)
            );

            (string memory traitName,string memory traitType,,) = IChainsTraits(_genOneChainsAddress).traitTypes(i, thisTraitIndex);

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    traitType,
                    '","value":"',
                    traitName,
                    '"},'
                )
            );

        }

        metadataString = string(
            abi.encodePacked(
                metadataString,
                '{"display_type": "boost_number", "trait_type": "BB Boost", "value":',
                ChainsLibrary.toString(IBallerBars(_genTwoBallerBarsAddress)._calculateBoost(_hash)),'}'
            )
        );

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /**
     * @dev Returns the SVG and metadata for a token Id
     * @param _tokenId The tokenId to return the SVG and metadata for.
     */

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId));

        string memory tokenHash = _tokenIdToHash(_tokenId);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    ChainsLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "BlockChain #',
                                    ChainsLibrary.toString(_tokenId),
                                    '", "description": "The BlockChains collection serves as the first',
                                    'phase of Ben Baller','Did The BlockChain.","image": "data:image/svg+xml;base64,',
                                    ChainsLibrary.encode(
                                        bytes(hashToSVG(tokenHash))
                                    ),
                                    '","attributes":',
                                    hashToMetadata(tokenHash),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
     * @dev Returns a hash for a given tokenId
     * @param _tokenId The tokenId to return the hash for.
     */

    function _tokenIdToHash(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        string memory tokenHash = tokenIdToHash[_tokenId];
        //If this is a burned token, override the previous hash
        if (ownerOf(_tokenId) == 0x000000000000000000000000000000000000dEaD) {
            tokenHash = string(
                abi.encodePacked(
                    "1",
                    ChainsLibrary.substring(tokenHash, 1, 7)
                )
            );
        }

        return tokenHash;
    }


    /**
     * @dev Returns the mint timestamp of a tokenId
     * @param _tokenId The tokenId to return the timestamp for.
     */

    function getTokenTimestamp(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return tokenIdToTimestamp[_tokenId];
    }

    /**
     * @dev Returns the wallet of a given wallet. Mainly for ease for frontend devs.
     * @param _wallet The wallet to get the tokens of.
     */

    function walletOfOwner(address _wallet)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

    function togglePauseStatus() external onlyOwner {
        _paused = !_paused;
    }

    /**
     * @dev Sets BB contract address based on generation
     * @param ballerBarsAddress The BB contract address
     * @param generation The generation of chains contract
     */

    function setBallerBarsAddress(address ballerBarsAddress,uint256 generation) onlyOwner public {
        require(generation==1||generation==2,"INVALID_GEN");
        if(generation == 1){
            _genOneBallerBarsAddress = ballerBarsAddress;
        }else if(generation == 2){
            _genTwoBallerBarsAddress = ballerBarsAddress;
        }
    }

    /**
     * @dev Sets generation one chains contract address
     * @param genOneChainsAddress The chains contract address
     */

    function setGenOneChainsAddress(address genOneChainsAddress) onlyOwner public {
        _genOneChainsAddress = genOneChainsAddress;
    }

    /**
     * @dev Returns BB contract based on generation
     * @param generation The generation of contract to return. 1 or 2
     */

    function getBallerBarsContract(uint256 generation) internal view returns (IBallerBars) {
        if(generation == 1){
            return IBallerBars(_genOneBallerBarsAddress);
        }else if(generation == 2){
            return IBallerBars(_genTwoBallerBarsAddress);
        }else{
            revert("INVALID_GEN");
        }
    }

    /**
     * @dev Returns the number of rare assets of a tokenId
     * @param _tokenId The tokenId to return the number of rare assets for.
     */

    function getTokenRarityCount(uint256 _tokenId)
    public
    view
    returns (uint256)
    {
        require(_tokenId<3406,"NOT_GEN_ONE_CHAIN");
        return IChains(_genOneChainsAddress).getTokenRarityCount(_tokenId);
    }

}