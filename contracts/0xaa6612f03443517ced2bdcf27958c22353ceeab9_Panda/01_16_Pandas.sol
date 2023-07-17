// contracts/Pandas.sol
// SPDX-License-Identifier: MIT
// ~Forked from Anonymice~ 
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./IShoots.sol";
import "./PandaLibrary.sol";
import "hardhat/console.sol";


contract Panda is ERC721Enumerable {
    using PandaLibrary for uint8;

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
    mapping (uint => string) internal specials;

    //uint256s
    uint256 MAX_SUPPLY = 10000;
    uint256 INITIAL_MINTS = 3000;
    uint256 SEED_NONCE = 0;
    uint256 WALLET_LIMIT = 4;

    //string arrays
    string[] LETTERS = [
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

    //uint arrays
    uint16[][8] TIERS;

    //address
    address ShootsAddress;
    address _owner;

    //bool
    bool mintEnabled;

    constructor() ERC721("Bamboozlers", "Bamboozlers") {
        _owner = msg.sender;

        //Declare all the rarity tiers
        //headwear
        TIERS[0] = [3040, 1750, 1750, 1750, 500, 500, 500, 200, 10];
        //eyes
        TIERS[1] = [3790, 1750, 1750, 500, 500, 500, 500, 500, 200, 10];
        //mouth
        TIERS[2] = [3140, 1750, 1750, 1750, 500, 500, 200, 200, 200, 10];
        //ears
        TIERS[3] = [7800, 1750, 500];
        //torso
        TIERS[4] = [4090, 1750, 1750, 500, 500, 500, 500, 200, 200, 10];
        //head
        TIERS[5] = [7800, 1750, 500];
        //body
        TIERS[6] = [3330, 3330, 3330, 10];
        //bg
        TIERS[7] = [5940, 1750, 500, 500, 500, 200, 200, 200, 200, 10];

    
    //Rave
    specials [6] = '<path fill="#fff" fill-opacity="0" stroke-width="0" d="M0 0h24v24H0z"><animate attributeType="XML" attributeName="fill-opacity" values="0;.1;.2;.3;.4;.5;.01" dur="7s" repeatCount="1"/> <animate attributeName="fill" attributeType="XML" values="#45b6fe;white;cyan" keyTimes= "0; 0.8; 1" dur="0.72s" repeatCount="indefinite"/></path>';
    //Vampire
    specials [7] = '<path fill="RED" fill-opacity="0" stroke-width="0" d="M0 0h24v24H0z"><animate attributeType="XML" attributeName="fill-opacity" values="0;0;0;0.05;0.13;0.2;0;0.12;0.08;0;0;0" dur="0.6s" repeatCount="6"/></path>';
    //Hypno
    specials [5] = '<animateTransform attributeName="transform" type="rotate" from="0 0 0" to="360 0 0" dur="3s"  repeatCount="2"  additive="sum"/>';
    specials [10] = '<circle r="35" class="c48" x="12" y="12"/>';
    //space
    specials [8] = '<animateTransform attributeName="transform" type="scale" keyTimes="0;0.25;0.5;0.75;1" values="0;0.35;0.1.28;0.75.9;1" dur="1.5s" additive="sum" transform-origin="50% 50%" />';
    //Panda Patrol
    specials [11] ='<path fill="#fff" fill-opacity="0" stroke-width="0" d="M0 0h24v24H0z"><animate attributeType="XML" attributeName="fill-opacity" values="0.03;.3;.2;.3;.25;.3;.3;.3;0.25;0.05;0.001" dur="2s" repeatCount="2"/> <animate attributeName="fill" attributeType="XML" values="red;blue;red" keyTimes= "0; 0.6; 1" dur="0.4s" repeatCount="indefinite"/></path>';
    // Toad
    specials [12] = '<g class="c28"><rect x="11" y="14"/><rect x="12" y="14"/><rect x="13" y="14"/><rect x="14" y="16"/><rect x="11" y="15"/><rect x="11" y="15"/><rect x="13" y="15"/><rect x="10" y="16"/></g><g class="c28"><rect x="11" y="16"/><rect x="13" y="16"/> <animate attributeName="display" values="inline;none;inline;none;none" keyTimes="0;0.25;0.5;0.75;1" dur="1s" repeatCount="indefinite"/></g><g class="c28"><rect x="10" y="15"/><rect x="13" y="16"/> <animate attributeName="display" values="none;inline;none;none;none" keyTimes="0;0.25;0.5;0.75;1" dur="1s" repeatCount="indefinite"/></g><g class="c28"><rect x="11" y="16"/><rect x="14" y="15"/> <animate attributeName="display" values="none;none;none;inline;none" keyTimes="0;0.25;0.5;0.75;1" dur="1s" repeatCount="indefinite"/></g>';
    }
    /*
  __  __ _     _   _             ___             _   _             
 |  \/  (_)_ _| |_(_)_ _  __ _  | __|  _ _ _  __| |_(_)___ _ _  ___
 | |\/| | | ' \  _| | ' \/ _` | | _| || | ' \/ _|  _| / _ \ ' \(_-<
 |_|  |_|_|_||_\__|_|_||_\__, | |_| \_,_|_||_\__|\__|_\___/_||_/__/
                         |___/                                     
   */

    /**
     * @dev Converts a digit from 0 - 10000 into its corresponding rarity based on the given rarity tier.
     * @param _randinput The input from 0 - 10000 to use for rarity gen.
     * @param _rarityTier The tier to use.
     */
    function rarityGen(uint256 _randinput, uint8 _rarityTier)
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
    ) internal returns (string memory) {
        require(_c < 10);

        // This will generate a 9 character string.
        //The last 8 digits are random, the first is 0, due to the panda not being burned.
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
                ) % 10000
            );

            currentHash = string(
                abi.encodePacked(currentHash, rarityGen(_randinput, i))
            );
        }

        if (hashToMinted[currentHash]) return hash(_t, _a, _c + 1);

        return currentHash;
    }

    /**
     * @dev Returns the current Shoots cost of minting.
     */
    function currentShootsCost() public view returns (uint256) {
        uint256 _totalSupply = totalSupply();

        if (_totalSupply <= INITIAL_MINTS) return 0;
        if (_totalSupply > INITIAL_MINTS && _totalSupply <= 5000)
            return 100 ether;
        if (_totalSupply > 5000 && _totalSupply <= 7000)
            return 500 ether;
        if (_totalSupply > 7000 && _totalSupply <= 9000)
            return 1000 ether;
        if (_totalSupply > 9000 && _totalSupply <= 10000)
            return 2000 ether;

        revert();
    }


    /**
     * @dev Mint internal, this is to avoid code duplication.
     */
    function mintInternal(address mintTo) internal {
        uint256 _totalSupply = totalSupply();
        require(_totalSupply < MAX_SUPPLY);
        require(!PandaLibrary.isContract(msg.sender));
        uint256 thisTokenId = _totalSupply;
        tokenIdToHash[thisTokenId] = hash(thisTokenId, msg.sender, 0);
        hashToMinted[tokenIdToHash[thisTokenId]] = true;
        _mint(mintTo, thisTokenId);
    }

    /**
     * @dev Mints new tokens.
     * No minting is permitted during the initial mint if WALLET_LIMIT is met.
     */
    function getBamboozled() public {
        require (mintEnabled);
        if (totalSupply() < INITIAL_MINTS) 
        { 
            require (balanceOf(msg.sender)<WALLET_LIMIT, "Wallet limit reached");
            return mintInternal(msg.sender);
        }

        //Burn this much Shoots
        IShoots(ShootsAddress).burnFrom(msg.sender, currentShootsCost());

        return mintInternal(msg.sender);
    }

    /**
     * @dev Dev team mint tokens.
     * disables automatically once dev mint cap is met and enables public mint
     */
    function devTeamMint(address mintTo) public onlyOwner
        {
        require (!mintEnabled);
        if (totalSupply() == 99) mintEnabled=true;
        return mintInternal(mintTo);
    }




    /**
     * @dev Burns and mints new.
     * @param _tokenId The token to burn.
     */
    function burnForMint(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender);

        //Burn token
        _transfer(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            _tokenId
        );

        mintInternal(msg.sender);
    }

    /*
 ____     ___   ____  ___        _____  __ __  ____     __ ______  ____  ___   ____   _____
|    \   /  _] /    ||   \      |     ||  |  ||    \   /  ]      ||    |/   \ |    \ / ___/
|  D  ) /  [_ |  o  ||    \     |   __||  |  ||  _  | /  /|      | |  ||     ||  _  (   \_ 
|    / |    _]|     ||  D  |    |  |_  |  |  ||  |  |/  / |_|  |_| |  ||  O  ||  |  |\__  |
|    \ |   [_ |  _  ||     |    |   _] |  :  ||  |  /   \_  |  |   |  ||     ||  |  |/  \ |
|  .  \|     ||  |  ||     |    |  |   |     ||  |  \     | |  |   |  ||     ||  |  |\    |
|__|\_||_____||__|__||_____|    |__|    \__,_||__|__|\____| |__|  |____|\___/ |__|__| \___|
                                                                                           
*/

    /**
     * @dev Helper function to reduce pixel size within contract
     */
    function letterToNumber(string memory _inputLetter)
        internal
        view
        returns (uint8)
    {
        
        for (uint8 i = 0; i < LETTERS.length; i++) {
            if (
                keccak256(abi.encodePacked((LETTERS[i]))) ==
                keccak256(abi.encodePacked((_inputLetter)))
            ) return (i); //modified from original to permit full frame art 
        }
        revert();
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
        bool[24][24] memory placedPixels;
        uint bg;
        bool use_pp;
        bool use_toad;

        for (uint8 i = 0; i < 9; i++) { 
            uint8 thisTraitIndex = PandaLibrary.parseInt(
                PandaLibrary.substring(_hash, i, i + 1)
            );

            //* @dev: Additions to Anonymice to handle animation SVG strings
            if (i==1 && thisTraitIndex==8) use_pp=true;
            if (i==8) bg = thisTraitIndex;
            if (i==3 && thisTraitIndex==8) use_toad=true;    

            //* @dev: Additions to Anonymice to handle animation SVG strings alternate decoding method implemented for full-image backgrounds (trait type 8)
            //        XY coordinates removed to save gas; assumes all 576 pixels are filled. Pixels iterate down then across ((0,0), (0,1), (0,2)...)
            if (i==8){  
                uint8 y;
                uint8 x;
                
                for (
                    uint16 j = 0;
                    j < traitTypes[i][thisTraitIndex].pixelCount;
                    j++
                ) {
                    if (y==24){
                        x++;
                        y=0;
                    }
                    string memory thisPixel = PandaLibrary.substring(
                        traitTypes[i][thisTraitIndex].pixels,
                        j * 2,
                        j * 2 + 2
                    );

                    if (placedPixels[x][y]){
                        y ++;
                        continue;
                    }
                    svgString = string(
                        abi.encodePacked(
                            svgString,
                            "<rect class='c",
                            PandaLibrary.substring(thisPixel, 0, 2),
                            "' x='",
                            x.toString(),
                            "' y='",
                            y.toString(),
                            "'/>"
                        )
                    );

                    placedPixels[x][y] = true;
                    y++;
                }
            }
            else
            {
                for (
                    uint16 j = 0;
                    j < traitTypes[i][thisTraitIndex].pixelCount;
                    j++
                ) {
                    string memory thisPixel = PandaLibrary.substring(
                        traitTypes[i][thisTraitIndex].pixels,
                        j * 4,
                        j * 4 + 4
                    );

                    uint8 x = letterToNumber(
                        PandaLibrary.substring(thisPixel, 0, 1)
                    );
                    uint8 y = letterToNumber(
                        PandaLibrary.substring(thisPixel, 1, 2)
                    );

                    if (placedPixels[x][y]) continue;

                    svgString = string(
                        abi.encodePacked(
                            svgString,
                            "<rect class='c",
                            PandaLibrary.substring(thisPixel, 2, 4),
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
        }
        

        //* @dev: Additions to Anonymice to handle animation SVG strings
        if (use_pp) bg=11;

        svgString = string(
            abi.encodePacked(
                '<svg id="panda-svg" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 24 24"> <g id="panda">',
                bg==5 ? specials [10] : '', 
                svgString,
                use_toad ? specials[12] : '',
                '<style> #panda { transform-origin: center;}</style><style>rect{width:1px;height:1px;} #panda-svg{shape-rendering: crispedges;} .c00{fill:#000000}.c01{fill:#FFFFFF}.c02{fill:#CC0595}.c03{fill:#00FFF1}.c04{fill:#794B11}.c05{fill:#452905}.c06{fill:#477764}.c07{fill:#F2E93B}.c08{fill:#373737}.c09{fill:#E9D5AB}.c10{fill:#BA7454}.c11{fill:#FF5009}.c12{fill:#FF0846}.c13{fill:#FE08B8}.c14{fill:#C008FF}.c15{fill:#720EFF}.c16{fill:#575757}.c17{fill:#0F37FF}.c18{fill:#0F87FF}.c19{fill:#0FD2FC}.c20{fill:#12FF8F}.c21{fill:#8BFF18}.c22{fill:#E7BB5A}.c23{fill:#99711B}.c24{fill:#808080}.c25{fill:#6094B3}.c26{fill:#60B3AB}.c27{fill:#60B37B}.c28{fill:#81B360}.c29{fill:#AAB360}.c30{fill:#B39260}.c31{fill:#B36C60}.c32{fill:#AEAEAE}.c33{fill:#6082B3}.c34{fill:#6068B3}.c35{fill:#7560B3}.c36{fill:#8860B3}.c37{fill:#A760B3}.c38{fill:#B3609E}.c39{fill:#B36075}.c40{fill:#DADADA}.c41{fill:#3B2B20}.c42{fill:#D12A2F}.c43{fill:#EBE4D8}.c44{fill:#2AA792}.c45{fill:#121A33}.c46{fill:#B8D9CE}.c47{fill:#7D6E80}.c48{fill:#9D7400}.c49{fill:#80B2FF}.c50{fill:#E25B26}.c51{fill:#6CD8F0}.c52{fill:#1A9CE7}.c53{fill:#3701F0}.c54{fill:#7115E6}.c55{fill:#C104FA}.c56{fill:#62001A}.c57{fill:#92E52A}.c58{fill:#FBEE25}.c59{fill:#FD9E0F}.c60{fill:#F40917}.c61{fill:#FE069E} </style>',
                specials[bg],
                '</g></svg>'
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

        for (uint8 i = 0; i < 9; i++) {
            uint8 thisTraitIndex = PandaLibrary.parseInt(
                PandaLibrary.substring(_hash, i, i + 1)
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
                    PandaLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Bamboozler #',
                                    PandaLibrary.toString(_tokenId),
                                    '", "description": "Bamboozlers is a collection of 10,000 original pandas generated 100% on-chain. No IPFS, no API. Now go Bamboozle!", "image": "data:image/svg+xml;base64,',
                                    PandaLibrary.encode(
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
                    PandaLibrary.substring(tokenHash, 1, 9)
                )
            );
        }

        return tokenHash;
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

    /*

  ___   __    __  ____     ___  ____       _____  __ __  ____     __ ______  ____  ___   ____   _____
 /   \ |  |__|  ||    \   /  _]|    \     |     ||  |  ||    \   /  ]      ||    |/   \ |    \ / ___/
|     ||  |  |  ||  _  | /  [_ |  D  )    |   __||  |  ||  _  | /  /|      | |  ||     ||  _  (   \_ 
|  O  ||  |  |  ||  |  ||    _]|    /     |  |_  |  |  ||  |  |/  / |_|  |_| |  ||  O  ||  |  |\__  |
|     ||  `  '  ||  |  ||   [_ |    \     |   _] |  :  ||  |  /   \_  |  |   |  ||     ||  |  |/  \ |
|     | \      / |  |  ||     ||  .  \    |  |   |     ||  |  \     | |  |   |  ||     ||  |  |\    |
 \___/   \_/\_/  |__|__||_____||__|\_|    |__|    \__,_||__|__|\____| |__|  |____|\___/ |__|__| \___|
                                                                                                     


    */

    /**
     * @dev Clears the traits.
     */
    function clearTraits() public onlyOwner {
        for (uint256 i = 0; i < 9; i++) {
            delete traitTypes[i];
        }
    }

    /**
     * @dev Add a trait type
     * @param _traitTypeIndex The trait type index
     * @param traits Array of traits to add
     */

    function addTraitType(uint256 _traitTypeIndex, Trait[] memory traits)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < traits.length; i++) {
            traitTypes[_traitTypeIndex].push(
                Trait(
                    traits[i].traitName,
                    traits[i].traitType,
                    traits[i].pixels,
                    traits[i].pixelCount
                )
            );
        }

        return;
    }

    /**
     * @dev Sets the Shoots ERC20 address
     * @param _ShootsAddress The Shoots address
     */

    function setShootsAddress(address _ShootsAddress) public onlyOwner {
        ShootsAddress = _ShootsAddress;
    }

    /**
     * @dev Transfers ownership
     * @param _newOwner The new owner
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _owner = _newOwner;
    }

    /**
     * @dev Modifier to only allow owner to call functions
     */
    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }
}