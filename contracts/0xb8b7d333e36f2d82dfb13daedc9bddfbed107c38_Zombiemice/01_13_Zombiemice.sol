// contracts/Zombiemice.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./ZombiemiceUtils.sol";

contract Zombiemice is ERC721Enumerable {
    /*
     _______            _     _             _            
    (_______)          | |   (_)           (_)           
       __    ___  ____ | | _  _  ____ ____  _  ____ ____ 
      / /   / _ \|    \| || \| |/ _  )    \| |/ ___) _  )
     / /___| |_| | | | | |_) ) ( (/ /| | | | ( (__( (/ / 
    (_______)___/|_|_|_|____/|_|\____)_|_|_|_|\____)____)     

    */
    using ZombiemiceUtils for uint8;

    struct Trait {
        string traitName;
        string traitType;
        string pixels;
        uint256 pixelCount;
    }

    //Mappings
    mapping(uint256 => Trait[]) public traitTypes;
    mapping(string => bool) hashToMinted;
    mapping(uint256 => string) internal tokenIdToHash;

    //uint256s
    uint256 MAX_SUPPLY = 3287;
    uint256 SEED_NONCE = 0;
    uint256 public maxMintPerTx = 10;

    //string arrays
    string[26] LETTERS = [
        "a",
        "b",
        "c",
        "d",
        "e",
        "f",
        "g",
        "h",
        "i",
        "j",
        "k",
        "l",
        "m",
        "n",
        "o",
        "p",
        "q",
        "r",
        "s",
        "t",
        "u",
        "v",
        "w",
        "x",
        "y",
        "z"
    ];

    //strings
    string collectionDescription =
        "Zombiemice is fully onchain collection of zombie mice available in exchange for the offchain version only.";
    string svg_tail;

    //uint arrays
    uint16[][8] TIERS;

    //address
    address public gateAddress;
    address public secret = 0x5768617420686170706e7320696e204C61623739;
    address public _owner;

    constructor() ERC721("Zombiemice", "Zmice") {
        _owner = msg.sender;

        //Declare all the rarity tiers

        //Hat
        TIERS[0] = [17, 49, 66, 99, 131, 164, 197, 296, 394, 1874];
        //Whiskers
        TIERS[1] = [66, 263, 329, 986, 1643];
        //Neck
        TIERS[2] = [99, 263, 296, 329, 2300];
        //Earrings
        TIERS[3] = [16, 66, 99, 99, 3007];
        //Eyes
        TIERS[4] = [17, 34, 131, 148, 164, 230, 592, 657, 657, 657];
        //Mouth
        TIERS[5] = [469, 469, 469, 470, 470, 470, 470];
        //Nose
        TIERS[6] = [657, 658, 657, 658, 657];
        //Character
        TIERS[7] = [7, 23, 237, 329, 380, 394, 427, 471, 507, 512];
    }

    /*
     ______  _            
    |  ___ \(_)      _    
    | | _ | |_ ____ | |_  
    | || || | |  _ \|  _) 
    | || || | | | | | |__ 
    |_||_||_|_|_| |_|\___)       

   */

    /**
     * @dev Converts a digit from 0 - MAX_SUPPLY into its corresponding rarity based on the given rarity tier.
     * @param _randinput The input from 0 - MAX_SUPPLY to use for rarity gen.
     * @param _rarityTier The tier to use.
     */
    function rarityGen(
        uint256 _randinput, 
        uint8 _rarityTier
    )
        internal
        view
        returns (string memory)
    {
        uint16 currentLowerBound = 0;
        for (uint8 i = 0; i < TIERS[_rarityTier].length; i++) {
            uint16 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i.toString();
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    /**
     * @dev Generates a 9 digit hash from a tokenId, address, and random number.
     * @param _t The token id to be used within the hash.
     * @param _a The address to be used within the hash.
     * @param _c The custom nonce to be used within the hash.
     */
    function hash(
        uint256 _t,
        address _a,
        uint256 _c
    ) 
        internal 
        returns (string memory) 
    {
        require(_c < 10);

        // This will generate a 9 character string.
        // The last 8 digits are random, the first is always 0 for normal mice
        string memory currentHash = "0";

        for (uint8 i = 0; i < 8; i++) {
            SEED_NONCE++;
            uint16 _randinput = uint16(
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
                ) % MAX_SUPPLY
            );

            currentHash = string(
                abi.encodePacked(currentHash, rarityGen(_randinput, i))
            );
        }

        if (hashToMinted[currentHash]) return hash(_t, _a, _c + 1);

        return currentHash;
    }

    /**
     * @dev Mints new tokens. Available from the Gate contract only.
     * @param _claimer The address claimed the offchain mouse
     * @param _num Amount to mint
     */

    function claimMice(address _claimer, uint _num) external onlyGate {
        uint256 _startMintId = totalSupply();
        require(
            _startMintId + _num <= MAX_SUPPLY,
            "The amount exceed max supply"
        );

        for (uint i = 0; i < _num; i++) {
            uint256 _mintId = _startMintId + i;

            tokenIdToHash[_mintId] = hash(_mintId, _claimer, 0);
            hashToMinted[tokenIdToHash[_mintId]] = true;

            _mint(_claimer, _mintId);
        }
    }

    /**
     * @dev Mints new token. Available from the Gate contract only.
     * @param _claimer The address claimed the offchain mouse
     */
    function claimMouse(
        address _claimer
    ) 
        external 
        onlyGate 
    {
        uint256 _mintId = totalSupply();
        require(_mintId < MAX_SUPPLY, "No more zombiemice to claim");

        tokenIdToHash[_mintId] = hash(_mintId, _claimer, 0);
        hashToMinted[tokenIdToHash[_mintId]] = true;

        _mint(_claimer, _mintId);
    }

    /*
     ______                 _     ___                        _                  
    (_____ \               | |   / __)                  _   (_)                 
     _____) ) ____ ____  _ | |  | |__ _   _ ____   ____| |_  _  ___  ____   ___ 
    (_____ ( / _  ) _  |/ || |  |  __) | | |  _ \ / ___)  _)| |/ _ \|  _ \ /___)
        | ( (/ ( ( | ( (_| |  | |  | |_| | | | ( (___| |__| | |_| | | | |___ |
        |_|\____)_||_|\____|  |_|   \____|_| |_|\____)\___)_|\___/|_| |_(___/    

    */

    /**
     * @dev Helper function to reduce pixel size within contract
     */
    function letterToNumber(
        string memory _inputLetter
    )
        internal
        view
        returns (uint8)
    {
        for (uint8 i = 0; i < LETTERS.length; i++) {
            if (
                keccak256(abi.encodePacked((LETTERS[i]))) ==
                keccak256(abi.encodePacked((_inputLetter)))
            ) return (i + 1);
        }
        revert();
    }

    /**
     * @dev Hash to SVG function
     */
    function hashToSVG(
        string memory _hash
    )
        public
        view
        returns (string memory)
    {
        string memory svgString;
        bool[24][24] memory placedPixels;

        for (uint8 i = 0; i < 9; i++) {
            if (traitTypes[i].length == 0) {
                continue;
            }
            uint8 thisTraitIndex = ZombiemiceUtils.parseInt(
                ZombiemiceUtils.substring(_hash, i, i + 1)
            );

            for (
                uint16 j = 0;
                j < traitTypes[i][thisTraitIndex].pixelCount;
                j++
            ) {
                string memory thisPixel = ZombiemiceUtils.substring(
                    traitTypes[i][thisTraitIndex].pixels,
                    j * 4,
                    j * 4 + 4
                );

                uint8 x = letterToNumber(
                    ZombiemiceUtils.substring(thisPixel, 0, 1)
                );
                uint8 y = letterToNumber(
                    ZombiemiceUtils.substring(thisPixel, 1, 2)
                );

                if (placedPixels[x][y]) continue;

                svgString = string(
                    abi.encodePacked(
                        svgString,
                        "<rect class='c",
                        ZombiemiceUtils.substring(thisPixel, 2, 4),
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
                '<svg id="mouse-svg" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 24 24"> ',
                svgString,
                svg_tail
            )
        );

        return svgString;
    }

    /**
     * @dev Hash to metadata function
     */
    function hashToMetadata(
        string memory _hash
    )
        public
        view
        returns (string memory)
    {
        string memory metadataString;

        for (uint8 i = 0; i < 9; i++) {
            if (traitTypes[i].length == 0) {
                continue;
            }
            uint8 thisTraitIndex = ZombiemiceUtils.parseInt(
                ZombiemiceUtils.substring(_hash, i, i + 1)
            );

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    traitTypes[i][thisTraitIndex].traitType,
                    '","value":"',
                    traitTypes[i][thisTraitIndex].traitName,
                    '"}'
                )
            );

            if (i != 8)
                metadataString = string(abi.encodePacked(metadataString, ","));
        }

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /**
     * @dev Returns the SVG and metadata for a token Id
     * @param _tokenId The tokenId to return the SVG and metadata for.
     */
    function tokenURI(
        uint256 _tokenId
    )
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
                    ZombiemiceUtils.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Zombiemice #',
                                    ZombiemiceUtils.toString(_tokenId),
                                    '", "description":"',collectionDescription,'","image": "data:image/svg+xml;base64,',
                                    ZombiemiceUtils.encode(
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
    function _tokenIdToHash(
        uint256 _tokenId
    )
        public
        view
        returns (string memory)
    {
        return tokenIdToHash[_tokenId];
    }

    /**
     * @dev Returns the wallet of a given wallet. Mainly for ease for frontend devs.
     * @param _wallet The wallet to get the tokens of.
     */
    function walletOfOwner(
        address _wallet
    )
        external
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

    /*
      _____                                         _       
     / ___ \                                       | |      
    | |   | |_ _ _ ____   ____  ____     ___  ____ | |_   _ 
    | |   | | | | |  _ \ / _  )/ ___)   / _ \|  _ \| | | | |
    | |___| | | | | | | ( (/ /| |      | |_| | | | | | |_| |
     \_____/ \____|_| |_|\____)_|       \___/|_| |_|_|\__  |
                                                      (____/ 
    */

    /**
     * @dev Clears the traits.
     */
    function clearTraits() 
        external 
        onlyOwner 
    {
        for (uint256 i = 0; i < 9; i++) {
            delete traitTypes[i];
        }
    }

    /**
     * @dev Clears traits of specific type
     */
    function clearTraitType(
        uint _index
    ) 
        external 
        onlyOwner 
    {
        delete traitTypes[_index];
    }

    /**
     * @dev Add a trait type
     * @param _traitTypeIndex The trait type index
     * @param _traits Array of traits to add
     */

    function addTraitType(
        uint256 _traitTypeIndex,
        Trait[] memory _traits
    )
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _traits.length; i++) {
            traitTypes[_traitTypeIndex].push(
                Trait(
                    _traits[i].traitName,
                    _traits[i].traitType,
                    _traits[i].pixels,
                    _traits[i].pixelCount
                )
            );
        }

        return;
    }

    /**
     * @dev Set the SVG classes description
     * @param _tail tail string
     */
    function setSVGTail(
        string memory _tail
    ) 
        external 
        onlyOwner 
    {
        svg_tail = _tail;
    }

    /**
     * @dev Set the Gate contract address
     * @param _gateAddress Gate contract address
     */
    function setGateAddress(
        address _gateAddress
    ) 
        external 
        onlyOwner 
    {
        gateAddress = _gateAddress;
    }

    /**
     * @dev Set the every item description
     * @param _collectionDescription The description string
     */
    function setCollectionDescription(
        string memory _collectionDescription
    ) 
        external 
        onlyOwner 
    {
        collectionDescription = _collectionDescription;
    }

    /**
     * @dev Transfers ownership
     * @param _newOwner The new owner
     */
    function transferOwnership(
        address _newOwner
    ) 
        public 
        onlyOwner 
    {
        _owner = _newOwner;
    }

    //Modifiers

    /**
     * @dev Modifier to only allow onchaingate contract to call mint functions
     */
    modifier onlyGate() {
        require(gateAddress == msg.sender);
        _;
    }

    /**
     * @dev Modifier to only allow owner to call functions
     */
    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }
}