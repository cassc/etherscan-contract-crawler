// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AnonymiceLibrary.sol";
import "./ERC721sm.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FoldedFaces is ERC721, Ownable {
    /*
 __             __          __   __  __  __     
|__ | _| _ _|  |__  _ _ _    _) /  \  _)  _)    
|(_)|(_|(-(_|  |(_|(_(-_)   /__ \__/ /__ /__  , 
                                                
        __                                      
|_     / _  _ _ |  . _ |_ |_                    
|_)\/  \__)(-| )|__|(_)| )|_  .  
*/
    using AnonymiceLibrary for uint8;

    struct Trait {
        string traitName;
        string traitType;
    }

    struct HashNeeds {
        uint16 startHash;
        uint16 startNonce;
    }

    //Mappings
    mapping(uint256 => Trait[]) public traitTypes;
    mapping(address => uint256) private lastWrite;

    //Mint Checks
    mapping(address => bool) addressWhitelistMinted;
    mapping(address => bool) contributorMints;
    uint256 public contributorCount = 0;
    uint256 public regularCount = 0;

    //uint256s
    uint256 public constant MAX_SUPPLY = 533;
    uint256 public constant WL_MINT_COST = 0.03 ether;
    uint256 public constant PUBLIC_MINT_COST = 0.05 ether;

    //public mint start timestamp
    uint256 public constant PUBLIC_START_TIME = 1653525000;

    mapping(uint256 => HashNeeds) tokenIdToHashNeeds;
    uint16 SEED_NONCE = 0;

    //minting flag
    bool ogMinted = false;
    bool public MINTING_LIVE = false;

    //uint arrays
    uint16[][8] TIERS;

    //p5js url
    string p5jsUrl;
    string p5jsIntegrity;
    string imageUrl;
    string animationUrl;

    //stillSnowCrash
    bytes32 constant whitelistRoot =
        0x358899790e0e071faed348a1b72ef18efe59029543a4a4da16e13fa2abf2a578;

    constructor() payable ERC721("FoldedFaces", "FFACE") {
        //Declare all the rarity tiers

        //Universe
        TIERS[0] = [8000, 1000, 1000];
        //Border
        TIERS[1] = [1000, 9000];
        //Resolution
        TIERS[2] = [9800, 200];
        //WarpSpeed
        TIERS[3] = [2250, 2250, 2250, 2250, 1000];
        //Folds
        TIERS[4] = [2500, 2500, 2500, 2500];
        //Color
        TIERS[5] = [1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000];
        //TwoFace
        TIERS[6] = [9000, 1000];
        //Water
        TIERS[7] = [1000, 9000];
    }

    //prevents someone calling read functions the same block they mint
    modifier disallowIfStateIsChanging() {
        require(
            owner() == msg.sender || lastWrite[msg.sender] < block.number,
            "not so fast!"
        );
        _;
    }

    /*
 __    __     __     __   __     ______   __     __   __     ______    
/\ "-./  \   /\ \   /\ "-.\ \   /\__  _\ /\ \   /\ "-.\ \   /\  ___\   
\ \ \-./\ \  \ \ \  \ \ \-.  \  \/_/\ \/ \ \ \  \ \ \-.  \  \ \ \__ \  
 \ \_\ \ \_\  \ \_\  \ \_\\"\_\    \ \_\  \ \_\  \ \_\\"\_\  \ \_____\ 
  \/_/  \/_/   \/_/   \/_/ \/_/     \/_/   \/_/   \/_/ \/_/   \/_____/ 
                                                                                                                                                                                                                                               
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
     * @param _a The address to be used within the hash.
     */
    function hash(address _a) internal view returns (uint16) {
        uint16 _randinput = uint16(
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, block.difficulty, _a)
                )
            ) % 10000
        );

        return _randinput;
    }

    /**
     * @dev Mint internal, this is to avoid code duplication.
     */
    function mintInternal() internal {
        require(
            MINTING_LIVE == true || msg.sender == owner(),
            "Minting not live"
        );
        uint256 _totalSupply = totalSupply() - 1;

        require(_totalSupply < MAX_SUPPLY, "Minted out");
        require(!AnonymiceLibrary.isContract(msg.sender), "No Contracts");
        require(regularCount < 519, "Minted Out Non Reserved Spots");

        uint256 thisTokenId = _totalSupply;

        tokenIdToHashNeeds[thisTokenId] = HashNeeds(
            hash(msg.sender),
            SEED_NONCE
        );

        lastWrite[msg.sender] = block.number;
        SEED_NONCE += 8;

        _mint(msg.sender, thisTokenId);
    }

    function mintOgBatch(address[] memory _addresses)
        external
        payable
        onlyOwner
    {
        require(ogMinted == false);
        require(_addresses.length == 14);

        uint16 _nonce = SEED_NONCE;
        for (uint256 i = 0; i < 14; i++) {
            uint256 thisTokenId = i;
            tokenIdToHashNeeds[thisTokenId] = HashNeeds(
                hash(_addresses[i]),
                _nonce
            );
            _mint(_addresses[i], thisTokenId);
            _nonce += 8;
        }
        regularCount = 14;
        SEED_NONCE += 112;
        ogMinted = true;
    }

    /**
     * @dev Mints new tokens.
     */
    function mintWLFoldedFaces(address account, bytes32[] calldata merkleProof)
        external
        payable
    {
        bytes32 node = keccak256(abi.encodePacked(account));
        require(
            MerkleProof.verify(merkleProof, whitelistRoot, node),
            "Not on WL"
        );
        require(account == msg.sender, "Self mint only");
        require(msg.value == WL_MINT_COST, "Insufficient ETH sent");
        require(
            addressWhitelistMinted[msg.sender] != true,
            "Address already minted WL"
        );

        addressWhitelistMinted[msg.sender] = true;
        ++regularCount;
        return mintInternal();
    }

    function mintPublicFoldedFaces() external payable {
        require(msg.value == PUBLIC_MINT_COST, "Insufficient ETH sent");
        require(block.timestamp > PUBLIC_START_TIME, "Public mint not started");
        ++regularCount;
        return mintInternal();
    }

    function mintCircolorsContributor() external {
        require(contributorMints[msg.sender] == true);
        require(contributorCount < 15);

        contributorMints[msg.sender] = false;
        ++contributorCount;

        return mintInternal();
    }

    /*
 ______     ______     ______     _____     __     __   __     ______    
/\  == \   /\  ___\   /\  __ \   /\  __-.  /\ \   /\ "-.\ \   /\  ___\   
\ \  __<   \ \  __\   \ \  __ \  \ \ \/\ \ \ \ \  \ \ \-.  \  \ \ \__ \  
 \ \_\ \_\  \ \_____\  \ \_\ \_\  \ \____-  \ \_\  \ \_\\"\_\  \ \_____\ 
  \/_/ /_/   \/_____/   \/_/\/_/   \/____/   \/_/   \/_/ \/_/   \/_____/                                                                    
                                                                                           
*/
    function buildHash(uint256 _t) internal view returns (string memory) {
        // This will generate a 8 character string.
        string memory currentHash = "";
        uint256 rInput = tokenIdToHashNeeds[_t].startHash;
        uint256 _nonce = tokenIdToHashNeeds[_t].startNonce;

        for (uint8 i = 0; i < 8; i++) {
            ++_nonce;
            uint16 _randinput = uint16(
                uint256(keccak256(abi.encodePacked(rInput, _t, _nonce))) % 10000
            );
            currentHash = string(
                abi.encodePacked(
                    currentHash,
                    rarityGen(_randinput, i).toString()
                )
            );
        }
        return currentHash;
    }

    /**
     * @dev Hash to HTML function
     */
    function hashToHTML(string memory _hash, uint256 _tokenId)
        external
        view
        disallowIfStateIsChanging
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
                "function%20setup%28%29%7Bs%3D%5B.45%2C1%5D%2Cc%3D%5B0%2C1%5D%2Cn%3D%5B0%2C1%5D%2Cnnw%3D0%2Cci%3D%5B0%2C1%5D%2Cnv%3D%5B%5B.001%2C.0025%5D%2C%5B.0025%2C.01%5D%2C%5B.01%2C.0025%5D%2C%5B.0025%2C.001%5D%2C%5B.001%2C.001%5D%5D%2Cov%3D%5B%5B4500%2C5500%2C6500%2C8e3%5D%2C%5B750%2C950%2C1150%2C1250%5D%2C%5B750%2C950%2C1150%2C1250%5D%2C%5B4500%2C5500%2C6500%2C8e3%5D%2C%5B4e3%2C5e3%2C6e3%2C15e3%5D%5D%2Cp%3D%5B%5B%22%2365010c%22%2C%22%23cb1b16%22%2C%22%23ef3c2d%22%2C%22%23f26a4f%22%2C%22%23f29479%22%2C%22%23fedfd4%22%2C%22%239dcee2%22%2C%22%234091c9%22%2C%22%231368aa%22%2C%22%23033270%22%2C%22%23000%22%2C%22%23faebd7%22%5D%2C%5B%22%230f3375%22%2C%22%2313459c%22%2C%22%231557c0%22%2C%22%23196bde%22%2C%22%232382f7%22%2C%22%234b9cf9%22%2C%22%2377b6fb%22%2C%22%23a4cefc%22%2C%22%23cce4fd%22%2C%22%23e8f3fe%22%2C%22%23000%22%2C%22%23faebd7%22%5D%2C%5B%22%230e0e0e%22%2C%22%23f3bc17%22%2C%22%23d54b0c%22%2C%22%23154255%22%2C%22%23dcdcdc%22%2C%22%23c0504f%22%2C%22%2368b9b0%22%2C%22%23ecbe2c%22%2C%22%232763ab%22%2C%22%23ce4241%22%2C%22%23faebd7%22%2C%22%23000%22%5D%2C%5B%22%23ff0000%22%2C%22%23fe1c00%22%2C%22%23fd3900%22%2C%22%23fc5500%22%2C%22%23fb7100%22%2C%22%23fb8e00%22%2C%22%23faaa00%22%2C%22%23f9c600%22%2C%22%23f8e300%22%2C%22%23f7ff00%22%2C%22%23000%22%2C%22%23faebd7%22%5D%2C%5B%22%23004733%22%2C%22%232b6a4d%22%2C%22%23568d66%22%2C%22%23a5c1ae%22%2C%22%23f3f4f6%22%2C%22%23dcdfe5%22%2C%22%23df8080%22%2C%22%23cb0b0a%22%2C%22%23ad080f%22%2C%22%238e0413%22%2C%22%23000%22%2C%22%23faebd7%22%5D%2C%5B%22%231e1619%22%2C%22%233c2831%22%2C%22%235d424e%22%2C%22%238c6677%22%2C%22%23ad7787%22%2C%22%23ac675b%22%2C%22%23c86166%22%2C%22%23f078b3%22%2C%22%23ec8782%22%2C%22%23dfde80%22%2C%22%23faebd7%22%2C%22%23000%22%5D%2C%5B%22%23008080%22%2C%22%23008080%22%2C%22%23178c8c%22%2C%22%23f7ff00%22%2C%22%2346a3a3%22%2C%22%235daeae%22%2C%22%2374baba%22%2C%22%238bc5c5%22%2C%22%23a2d1d1%22%2C%22%23b5dada%22%2C%22%23000%22%2C%22%23faebd7%22%5D%2C%5B%22%23669900%22%2C%22%2399cc33%22%2C%22%23ccee66%22%2C%22%23006699%22%2C%22%233399cc%22%2C%22%23990066%22%2C%22%23cc3399%22%2C%22%23ff6600%22%2C%22%23ff9900%22%2C%22%23ffcc00%22%2C%22%23000%22%2C%22%23faebd7%22%5D%2C%5B%22%23000%22%2C%22%23fff%22%2C%22%23000%22%2C%22%23fff%22%2C%22%23000%22%2C%22%23fff%22%2C%22%23000%22%2C%22%23fff%22%2C%22%23000%22%2C%22%23fff%22%2C%22%23000%22%2C%22%23fff%22%5D%2C%5B%22%232c6e49%22%2C%22%23618565%22%2C%22%23969c81%22%2C%22%23cbb39d%22%2C%22%23e5beab%22%2C%22%23ffc9b9%22%2C%22%23f5ba9c%22%2C%22%23ebab7f%22%2C%22%23e19c62%22%2C%22%23d68c45%22%2C%22%23000%22%2C%22%23faebd7%22%5D%2C%5B%22%2365010c%22%2C%22%23cb1b16%22%2C%22%23ef3c2d%22%2C%22%23f26a4f%22%2C%22%23f29479%22%2C%22%23fedfd4%22%2C%22%239dcee2%22%2C%22%234091c9%22%2C%22%231368aa%22%2C%22%23033270%22%2C%22%23faebd7%22%2C%22%23000%22%5D%5D%2CcreateCanvas%28700%2C950%29%2CnoiseSeed%28tokenId%29%2CnoLoop%28%29%2CnoStroke%28%29%2CrectMode%28CENTER%29%2CcolorMode%28HSL%29%2CpixelDensity%285%29%2Co%3Dnoise%2Cf%3Dfill%2Cb%3DnoFill%2Cq%3Dwidth%2Ca%3Dheight%2Cyy%3DparseInt%28hash.substring%280%2C1%29%29%2Cci%3Dci%5BparseInt%28hash.substring%281%2C2%29%29%5D%2Cw%3Ds%5BparseInt%28hash.substring%282%2C3%29%29%5D%2Cx%3DparseInt%28hash.substring%283%2C4%29%29%2Czz%3DparseInt%28hash.substring%284%2C5%29%29%2Caa%3Dnv%5Bx%5D%5B0%5D%2Cvb%3Dnv%5Bx%5D%5B1%5D%2Cgb%3Dov%5Bx%5D%5Bzz%5D%2Cff%3D%5B1e-5%2Caa%5D%2Cz%3DparseInt%28hash.substring%285%2C6%29%29%2Cz2%3Dz%2B1%2Cg%3DparseInt%28hash.substring%286%2C7%29%29%2B1%2Cnnw%3Dff%5BparseInt%28hash.substring%287%2C8%29%29%5D%7Dfunction%20draw%28%29%7Bbackground%28p%5Bz%5D%5B10%5D%29%2C2%3D%3Dx%7C%7C3%3D%3Dx%3Fnn%3Dnnw%3Ann%3Daa%3Bfor%28let%20e%3D25%3Be%3C%3Dq-25%3Be%2B%3Dw%29for%28let%20c%3D25%3Bc%3C%3Da-25%3Bc%2B%3Dw%29n%3Do%28e%2Ann%2Cc%2Aaa%29%2Cn2%3Do%28e%2Avb%2Cc%2Avb%29%2Cn3%3Do%28%28e%2Bgb%2An%29%2Aaa%2C%28c%2Bgb%2An2%29%2Avb%29%2Cn4%3Do%28%28e%2Bgb%2An3%29%2Aaa%2C%28c%2Bgb%2An3%29%2Avb%29%2Cn5%3Do%28%28e%2Bgb%2An4%29%2Aaa%2C%28c%2Bgb%2An4%29%2Avb%29%2C0%3D%3Dyy%3Fe%3Cq%2Fg%3Fn5%3E.58%3Fb%28%29%3An5%3E.55%3Ff%28p%5Bz%5D%5B0%5D%29%3An5%3E.53%3Ff%28p%5Bz%5D%5B1%5D%29%3An5%3E.5%3Ff%28p%5Bz%5D%5B2%5D%29%3An5%3E.47%3Ff%28p%5Bz%5D%5B3%5D%29%3An5%3E.44%3Fb%28%29%3An5%3E.41%3Ff%28p%5Bz%5D%5B4%5D%29%3An5%3E.38%3Ff%28p%5Bz%5D%5B5%5D%29%3An5%3E.35%3Ff%28p%5Bz%5D%5B6%5D%29%3An5%3E.31%3Ff%28p%5Bz%5D%5B7%5D%29%3An5%3E.28%3Ff%28p%5Bz%5D%5B8%5D%29%3An5%3E.25%3Ff%28p%5Bz%5D%5B9%5D%29%3Ab%28%29%3An5%3E.58%3Fb%28%29%3An5%3E.55%3Ff%28p%5Bz2%5D%5B0%5D%29%3An5%3E.53%3Ff%28p%5Bz2%5D%5B1%5D%29%3An5%3E.5%3Ff%28p%5Bz2%5D%5B2%5D%29%3An5%3E.47%3Ff%28p%5Bz2%5D%5B3%5D%29%3An5%3E.44%3Fb%28%29%3An5%3E.41%3Ff%28p%5Bz2%5D%5B4%5D%29%3An5%3E.38%3Ff%28p%5Bz2%5D%5B5%5D%29%3An5%3E.35%3Ff%28p%5Bz2%5D%5B6%5D%29%3An5%3E.31%3Ff%28p%5Bz2%5D%5B7%5D%29%3An5%3E.28%3Ff%28p%5Bz2%5D%5B8%5D%29%3An5%3E.25%3Ff%28p%5Bz2%5D%5B9%5D%29%3Ab%28%29%3A1%3D%3Dyy%3Fn5%3E.6%3Fb%28%29%3An5%3E.4%3Ff%28p%5Bz%5D%5B3%5D%29%3Ab%28%29%3Af%281e3%2An2%2C100%2An5%2C100%2An5%29%2Crect%28e%2Cc%2Cw%29%3B0%3D%3Dci%26%26%28push%28%29%2Cb%28%29%2Cstroke%28p%5Bz%5D%5B10%5D%29%2CstrokeWeight%281570%29%2Ccircle%28q%2F2%2Ca%2F2%2C2e3%29%2Cpop%28%29%29%2Cpush%28%29%2CtextSize%283%29%2CtextAlign%28RIGHT%29%2Cf%28p%5Bz%5D%5B11%5D%29%2Ctext%28%22Folded%20Faces.%202022.%22%2Cq-25%2Ca-15%29%2Ctext%28hash%2Cq-25%2Ca-10%29%2Cpop%28%29%7D%3C%2Fscript%3E%3C%2Fbody%3E%3C%2Fhtml%3E"
            )
        );

        return htmlString;
    }

    function totalSupply() public view returns (uint256) {
        return regularCount + contributorCount;
    }

    /**
     * @dev Hash to metadata function
     */
    function hashToMetadata(string memory _hash)
        public
        view
        disallowIfStateIsChanging
        returns (string memory)
    {
        string memory metadataString;
        uint256 metadataLength;

        if (
            AnonymiceLibrary.parseInt(
                AnonymiceLibrary.substring(_hash, 0, 1)
            ) == 0
        ) {
            metadataLength = 6;
        } else {
            metadataLength = 5;
        }

        for (uint8 i = 0; i < metadataLength; i++) {
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

            if (i != metadataLength - 1)
                metadataString = string(abi.encodePacked(metadataString, ","));
        }

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /**
     * @dev Returns the image and metadata for a token Id
     * @param _tokenId The tokenId to return the image and metadata for.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_tokenId < totalSupply());

        string memory tokenHash = _tokenIdToHash(_tokenId);

        string
            memory description = '", "description": "533 FoldedFaces. Traits generated on chain & metadata, images mirrored on chain permanently.",';

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
                                    '{"name": "FoldedFaces #',
                                    AnonymiceLibrary.toString(_tokenId),
                                    description,
                                    '"external_url":"',
                                    animationUrl,
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
        disallowIfStateIsChanging
        returns (string memory)
    {
        require(_tokenId < totalSupply());
        string memory tokenHash = buildHash(_tokenId);

        return tokenHash;
    }

    /*
 ______     __     __     __   __     ______     ______    
/\  __ \   /\ \  _ \ \   /\ "-.\ \   /\  ___\   /\  == \   
\ \ \/\ \  \ \ \/ ".\ \  \ \ \-.  \  \ \  __\   \ \  __<   
 \ \_____\  \ \__/".~\_\  \ \_\\"\_\  \ \_____\  \ \_\ \_\ 
  \/_____/   \/_/   \/_/   \/_/ \/_/   \/_____/   \/_/ /_/ 
                                                           
    /**
     * @dev Add a trait type
     * @param _traitTypeIndex The trait type index
     * @param traits Array of traits to add
     */

    function addTraitType(uint256 _traitTypeIndex, Trait[] memory traits)
        external
        payable
        onlyOwner
    {
        for (uint256 i = 0; i < traits.length; i++) {
            traitTypes[_traitTypeIndex].push(
                Trait(traits[i].traitName, traits[i].traitType)
            );
        }

        return;
    }

    function addContributorMint(address _account) external payable onlyOwner {
        contributorMints[_account] = true;
    }

    function flipMintingSwitch() external payable onlyOwner {
        MINTING_LIVE = !MINTING_LIVE;
    }

    /**
     * @dev Sets the p5js url
     * @param _p5jsUrl The address of the p5js file hosted on CDN
     */

    function setJsAddress(string memory _p5jsUrl) external payable onlyOwner {
        p5jsUrl = _p5jsUrl;
    }

    /**
     * @dev Sets the p5js resource integrity
     * @param _p5jsIntegrity The hash of the p5js file (to protect w subresource integrity)
     */

    function setJsIntegrity(string memory _p5jsIntegrity)
        external
        payable
        onlyOwner
    {
        p5jsIntegrity = _p5jsIntegrity;
    }

    /**
     * @dev Sets the base image url
     * @param _imageUrl The base url for image field
     */

    function setImageUrl(string memory _imageUrl) external payable onlyOwner {
        imageUrl = _imageUrl;
    }

    function setAnimationUrl(string memory _animationUrl)
        external
        payable
        onlyOwner
    {
        animationUrl = _animationUrl;
    }

    function withdraw() external payable onlyOwner {
        uint256 sixtyFive = (address(this).balance / 100) * 65;
        uint256 fifteen = (address(this).balance / 100) * 15;
        uint256 five = (address(this).balance / 100) * 5;
        (bool sentT, ) = payable(
            address(0xE4260Df86f5261A41D19c2066f1Eb2Eb4F009e84)
        ).call{value: fifteen}("");
        require(sentT, "Failed to send");
        (bool sentI, ) = payable(
            address(0x4533d1F65906368ebfd61259dAee561DF3f3559D)
        ).call{value: fifteen}("");
        require(sentI, "Failed to send");
        (bool sentC, ) = payable(
            address(0x888f8AA938dbb18b28bdD111fa4A0D3B8e10C871)
        ).call{value: five}("");
        require(sentC, "Failed to send");
        (bool sentG, ) = payable(
            address(0xeFEed35D024CF5B59482Fa4BC594AaeAf694E669)
        ).call{value: sixtyFive}("");
        require(sentG, "Failed to send");
    }
}