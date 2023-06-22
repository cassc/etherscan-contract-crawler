// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AnonymiceLibrary.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GenFrens is ERC721A, Ownable {
    using AnonymiceLibrary for uint8;

    struct Trait {
        string traitName;
        string traitType;
    }

    //Mappings
    mapping(uint256 => Trait[]) public traitTypes;
    mapping(string => bool) hashToMinted;
    mapping(uint256 => string) internal tokenIdToHash;
    mapping(address => bool) addressMinted;

    //uint256s
    uint256 MAX_SUPPLY = 444;
    uint256 SEED_NONCE = 0;
    uint256 MINT_COST = 0.01 ether;

    //minting flag
    bool public MINTING_LIVE = false;

    //uint arrays
    uint16[][6] TIERS;

    //p5js url
    string p5jsUrl;
    string p5jsIntegrity;
    string imageUrl;
    string externalUrl;

    constructor() ERC721A("GenFrens", "GENF", 2) {
        //Declare all the rarity tiers

        //pCol
        TIERS[0] = [1400, 1400, 1800, 700, 700, 1800, 1100, 1100];
        //sCol
        TIERS[1] = [1500, 1800, 900, 900, 1200, 1800, 1500, 400];
        //noise Max
        TIERS[2] = [4000, 3000, 2000, 1000];
        //eyeSize
        TIERS[3] = [2500, 5000, 2500];
        //Thickness
        TIERS[4] = [6000, 2500, 1500];
        //eyeLevel
        TIERS[5] = [6000, 4000];
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
        returns (uint8)
    {
        uint16 currentLowerBound = 0;
        for (uint8 i = 0; i < TIERS[_rarityTier].length; i++) {
            uint16 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    /**
     * @dev Generates a 11 digit hash from a tokenId, address, and random number.
     * @param _t The token id to be used within the hash.
     * @param _a The address to be used within the hash.
     * @param _c The custom nonce to be used within the hash.
     */
    function hash(
        uint256 _t,
        address _a,
        uint256 _c
    ) internal returns (string memory) {
        require(_c < 11);

        // This will generate a 11 character string.
        // The first 2 digits are the palette.
        string memory currentHash = "";

        for (uint8 i = 0; i < 6; i++) {
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
                abi.encodePacked(
                    currentHash,
                    rarityGen(_randinput, i).toString()
                )
            );
        }

        if (hashToMinted[currentHash]) return hash(_t, _a, _c + 1);

        return currentHash;
    }

    /**
     * @dev Mint internal, this is to avoid code duplication.
     */
    function mintInternal(uint8 mintAmount) internal {
        require(
            MINTING_LIVE == true || msg.sender == owner(),
            "Minting not live"
        );
        uint256 _totalSupply = totalSupply();
        require(_totalSupply < MAX_SUPPLY);
        require(!AnonymiceLibrary.isContract(msg.sender));
        require(addressMinted[msg.sender] != true, "Address already minted");
        require(msg.value >= MINT_COST * mintAmount, "Insufficient ETH sent");

        for (uint8 i = 0; i < mintAmount; i++) {
            uint256 thisTokenId = _totalSupply + i;

            tokenIdToHash[thisTokenId] = hash(thisTokenId, msg.sender, 0);

            hashToMinted[tokenIdToHash[thisTokenId]] = true;
        }
        addressMinted[msg.sender] = true;
        _safeMint(msg.sender, mintAmount);
    }

    /**
     * @dev Mints new tokens.
     */
    function mintFren(uint8 mintAmount) public payable {
        return mintInternal(mintAmount);
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
     * @dev Hash to HTML function
     */
    function hashToHTML(string memory _hash, uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        string memory htmlString = string(
            abi.encodePacked(
                "data:text/html,%3Chtml%3E%3Chead%3E%3Cscript%20src%3D%22",
                p5jsUrl,
                "%22%20integrity%3D%22",
                p5jsIntegrity,
                "%22%20crossorigin%3D%22anonymous%22%3E%3C%2Fscript%3E%3C%2Fhead%3E%3Cbody%3E%3Cscript%3Evar%20tokenId%3D",
                AnonymiceLibrary.toString(_tokenId),
                "%3Bvar%20hash%3D%22",
                _hash,
                "%22%3B"
            )
        );

        htmlString = string(
            abi.encodePacked(
                htmlString,
                "xo%3D1%2Csd%3D21%2AtokenId%2CpCs%3D%5B0%2C30%2C80%2C120%2C180%2C225%2C270%2C300%5D%2CsCs%3D%5B0%2C30%2C120%2C180%2C225%2C270%2C300%2C330%5D%2CnMV%3D%5B.5%2C1%2C2%2C3%5D%2CeSs%3D%5B.26%2C.33%2C.4%5D%2CtV%3D%5B10%2C25%2C70%5D%2CeLs%3D%5B0%2C15%5D%3Bfunction%20setup%28%29%7BcreateCanvas%28500%2C500%29%2CcolorMode%28HSB%2C360%2C100%2C100%29%2CstrokeCap%28ROUND%29%2CnoiseSeed%28sd%29%2CrandomSeed%28sd%29%2CpC%3DparseInt%28hash.substring%280%2C1%29%29%2CsC%3DparseInt%28hash.substring%281%2C2%29%29%2CnM%3DparseInt%28hash.substring%282%2C3%29%29%2CeS%3DparseInt%28hash.substring%283%2C4%29%29%2Ct%3DparseInt%28hash.substring%284%2C5%29%29%2CeL%3DparseInt%28hash.substring%285%2C6%29%29%2C330%3D%3DsCs%5BsC%5D%3Fk%3DpCs%5BpC%5D%3Ak%3DsCs%5BsC%5D%2CwP%3Drandom%285%2C10%29%2ChP%3Drandom%285%2C10%29%7Dfunction%20draw%28%29%7Bbackground%28255%29%3Bfor%28let%20s%3D25%3Bs%3C500%3Bs%2B%3D50%29for%28let%20e%3D25%3Be%3C500%3Be%2B%3D50%29noStroke%28%29%2Cf%3DsCs%5BsC%5D%2C330%3D%3Df%3FrC%3Drandom%28360%29%3ArC%3Dk%2Cfill%28rC%2Crandom%2825%29%2C100%29%2Cc%3Dnew%20C1%2Cpush%28%29%2Ctranslate%28s%2Ce%29%2Cscale%28.14%2C.14%29%2Cc.s%28%29%2Cpop%28%29%3Bc1%3Dnew%20C2%28pCs%5BpC%5D%2C40%2C100%2C0%29%2Cpush%28%29%2Ctranslate%28250%2C500%29%2Crotate%283.14%29%2Cscale%28.55%2C1.25%29%2Cc1.s%28%29%2Cpop%28%29%2Cpush%28%29%2Ctranslate%28250%2C250%29%2Cc1.s%28%29%2Cpop%28%29%2CnoStroke%28%29%2Ce1%3Dnew%20C2%280%2C0%2C100%2C1%29%2Cpush%28%29%2Ctranslate%28200%2C200%29%2Cscale%28.33%29%2Ce1.s%28%29%2Cpop%28%29%2Ce2%3Dnew%20C2%280%2C0%2C100%2C1%29%2Cpush%28%29%2Cpush%28%29%2Ctranslate%28300%2C200%29%2Cscale%28eSs%5BeS%5D%29%2Crotate%28PI%29%2Ce2.s%28%29%2Cpop%28%29%2Cp1%3Dnew%20C2%28k%2C100%2C100%2C1%29%2Cpush%28%29%2Ctranslate%28200%2C200%2BeLs%5BeL%5D%29%2Cscale%28.1%29%2Cp1.s%28%29%2Cpop%28%29%2Cp2%3Dnew%20C2%28k%2C100%2C100%2C1%29%2Cpush%28%29%2Ctranslate%28300%2C200-eLs%5BeL%5D%29%2Cscale%28.1%29%2Crotate%28PI%29%2Cp2.s%28%29%2Cpop%28%29%3Bfor%28let%20s%3D200%3Bs%3C%3D300%3Bs%2B%2B%29sats%3Dmap%28noise%28xo%29%2C0%2C1%2C30%2C100%29%2Cfill%28k%2Csats%2C95%29%2Cr%3Dmap%28noise%28xo%29%2C0%2C1%2C.53%2C.77%29%2Cellipse%28s%2C500%2Ar%2C28%29%2Cxo%2B%3D.015%3BnoLoop%28%29%7Dclass%20C1%7Bs%28%29%7BbeginShape%28%29%3Bfor%28let%20s%3D0%3Bs%3CTWO_PI%3Bs%2B%3D.16%29%7Blet%20e%3Dmap%28cos%28s%29%2C-1%2C1%2C0%2CnMV%5BnM%5D%29%2Ct%3Dmap%28sin%28s%29%2C-1%2C1%2C0%2CnMV%5BnM%5D%29%2Cn%3Dmap%28noise%28e%2Ct%29%2C0%2C1%2C100%2C200%29%2Ca%3Dn%2Acos%28s%29%2Cp%3Dn%2Asin%28s%29%3Bvertex%28a%2Cp%29%2Ce%2B%3D.004%7DendShape%28%29%7D%7Dclass%20C2%7Bconstructor%28s%2Ce%2Ct%2Cn%29%7Bthis.h%3Ds%2Cthis.z%3De%2Cthis.l%3Dt%2Cthis.b%3Dn%7Ds%28%29%7BbeginShape%28%29%2CnoFill%28%29%3Bfor%28let%20s%3D0%3Bs%3CTWO_PI%3Bs%2B%3D.045%29%7Blet%20e%3Dmap%28sin%28s%29%2C-1%2C1%2C0%2CnMV%5BnM%5D%29%2Cn%3Dmap%28cos%28s%29%2C-1%2C1%2C0%2CnMV%5BnM%5D%29%2Ca%3Dmap%28noise%28n%2Ce%29%2C0%2C1%2C100%2C200%29%2Cp%3Da%2Acos%28s%29%2Co%3Da%2Asin%28s%29%3B0%3D%3Dthis.b%26%26%28stroke%28this.h%2Cthis.z%2Cthis.l-25%29%2CstrokeWeight%28tV%5Bt%5D%29%29%2Cvertex%28p%2Co%29%2CendShape%28%29%2Cpush%28%29%2Cstroke%28this.h%2Cthis.z%2Cthis.l%29%2CstrokeWeight%286%29%2Cline%28p%2B7.5%2Co%2B10%2C500%2FwP%2C500%2FhP%29%2Cpop%28%29%2Cn%2B%3D.04%2Ce%2B%3D.001%7DendShape%28%29%7D%7D%3C%2Fscript%3E%3C%2Fbody%3E%3C%2Fhtml%3E"
            )
        );

        return htmlString;
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

        for (uint8 i = 0; i < 6; i++) {
            uint8 thisTraitIndex = AnonymiceLibrary.parseInt(
                AnonymiceLibrary.substring(_hash, i, i + 1)
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

            if (i != 5)
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

        string
            memory description = '", "description": "444 GenFrens to keep you company. Metadata & images mirrored on chain permanently. Your GenFren will never leave you <3",';

        string memory encodedTokenId = AnonymiceLibrary.encode(
            bytes(string(abi.encodePacked(AnonymiceLibrary.toString(_tokenId))))
        );
        string memory encodedHash = AnonymiceLibrary.encode(
            bytes(string(abi.encodePacked(tokenHash)))
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    AnonymiceLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "GenFrens #',
                                    AnonymiceLibrary.toString(_tokenId),
                                    description,
                                    '"external_url":"',
                                    externalUrl,
                                    encodedTokenId,
                                    "&t=",
                                    encodedHash,
                                    '","image":"',
                                    imageUrl,
                                    AnonymiceLibrary.toString(_tokenId),
                                    "&t=",
                                    tokenHash,
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

        return tokenHash;
    }

    /*
  ___   __    __  ____     ___  ____       _____  __ __  ____     __ ______  ____  ___   ____   _____
 /   \ |  |__|  ||    \   /  _]|    \     |     ||  |  ||    \   /  ]      ||    |/   \ |    \ / ___/
|     ||  |  |  ||  _  | /  [_ |  D  )    |   __||  |  ||  _  | /  /|      | |  ||     ||  _  (   \_ 
|  O  ||  |  |  ||  |  ||    _]|    /     |  |_  |  |  ||  |  |/  / |_|  |_| |  ||  O  ||  |  |\__  |
|     ||  `  '  ||  |  ||   [_ |    \     |   _] |  :  ||  |  /   \_  |  |   |  ||     ||  |  |/  \ |
|     | \      / |  |  ||     ||  .  \    |  |   |     ||  |  \     | |  |   |  ||     ||  |  |\    |
 \___/   \_/\_/  |__|__||_____||__|\_|    |__|    \__,_||__|__|\____| |__|  |____|\___/ |__|__| \___|
                                                                                                     
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
                Trait(traits[i].traitName, traits[i].traitType)
            );
        }

        return;
    }

    function flipMintingSwitch() public onlyOwner {
        MINTING_LIVE = !MINTING_LIVE;
    }

    /**
     * @dev Sets the p5js url
     * @param _p5jsUrl The address of the p5js file hosted on CDN
     */

    function setJsAddress(string memory _p5jsUrl) public onlyOwner {
        p5jsUrl = _p5jsUrl;
    }

    /**
     * @dev Sets the p5js resource integrity
     * @param _p5jsIntegrity The hash of the p5js file (to protect w subresource integrity)
     */

    function setJsIntegrity(string memory _p5jsIntegrity) public onlyOwner {
        p5jsIntegrity = _p5jsIntegrity;
    }

    /**
     * @dev Sets the base image url
     * @param _imageUrl The base url for image field
     */

    function setImageUrl(string memory _imageUrl) public onlyOwner {
        imageUrl = _imageUrl;
    }

    function setExternalUrl(string memory _externalUrl) public onlyOwner {
        externalUrl = _externalUrl;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}