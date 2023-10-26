// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./AnonymiceLibrary.sol";
import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";

interface IScrawlArt {
    function scrawlArtCode() external view returns (string memory);
}

contract Scrawl is ERC721, Ownable {
    /*
 ▄▀▀▀▀▄  ▄▀▄▄▄▄   ▄▀▀▄▀▀▀▄  ▄▀▀█▄   ▄▀▀▄    ▄▀▀▄  ▄▀▀▀▀▄                                                       
█ █   ▐ █ █    ▌ █   █   █ ▐ ▄▀ ▀▄ █   █    ▐  █ █    █                                                        
   ▀▄   ▐ █      ▐  █▀▀█▀    █▄▄▄█ ▐  █        █ ▐    █                                                        
▀▄   █    █       ▄▀    █   ▄▀   █   █   ▄    █      █                                                         
 █▀▀▀    ▄▀▄▄▄▄▀ █     █   █   ▄▀     ▀▄▀ ▀▄ ▄▀    ▄▀▄▄▄▄▄▄▀                                                   
 ▐      █     ▐  ▐     ▐   ▐   ▐            ▀      █                                                           
        ▐                                          ▐                                                           
 ▄▀▀█▄▄   ▄▀▀▄ ▀▀▄      ▄▀▀▄▀▀▀▄  ▄▀▀█▀▄   ▄▀▀▄  ▄▀▄  ▄▀▀█▄▄▄▄  ▄▀▀▀▀▄   ▄▀▀▄    ▄▀▀▄  ▄▀▀█▄   ▄▀▀▄ ▀▄  ▄▀▀▄ █ 
▐ ▄▀   █ █   ▀▄ ▄▀     █   █   █ █   █  █ █    █   █ ▐  ▄▀   ▐ █    █   █   █    ▐  █ ▐ ▄▀ ▀▄ █  █ █ █ █  █ ▄▀ 
  █▄▄▄▀  ▐     █       ▐  █▀▀▀▀  ▐   █  ▐ ▐     ▀▄▀    █▄▄▄▄▄  ▐    █   ▐  █        █   █▄▄▄█ ▐  █  ▀█ ▐  █▀▄  
  █   █        █          █          █         ▄▀ █    █    ▌      █      █   ▄    █   ▄▀   █   █   █    █   █ 
 ▄▀▄▄▄▀      ▄▀         ▄▀        ▄▀▀▀▀▀▄     █  ▄▀   ▄▀▄▄▄▄     ▄▀▄▄▄▄▄▄▀ ▀▄▀ ▀▄ ▄▀  █   ▄▀  ▄▀   █   ▄▀   █  
█    ▐       █         █         █       █  ▄▀  ▄▀    █    ▐     █               ▀    ▐   ▐   █    ▐   █    ▐  
▐            ▐         ▐         ▐       ▐ █    ▐     ▐          ▐                            ▐        ▐       
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

    // address for p5 code stored in separate contract
    address public scrawlArt;

    //Mappings
    mapping(uint256 => Trait[]) public traitTypes;
    mapping(address => uint256) private lastWrite;

    //Mint Checks
    mapping(address => bool) addressCircSaleMinted;
    mapping(address => bool) addressFreelistMinted;
    mapping(address => bool) addressAllowlistMinted;
    uint256 public totalSupply = 0;

    //uint256s
    uint256 public constant MAX_SUPPLY = 420;
    uint256 public constant CIRCOLORS_PRESALE_COST = 0.0256 ether;
    uint256 public constant GENERAL_MINT_COST = 0.0365 ether;

    //public mint start timestamp
    uint256 public SALE_START;

    bool initStart = false;

    mapping(uint256 => HashNeeds) tokenIdToHashNeeds;
    uint16 SEED_NONCE = 0;

    //minting flag
    bool griffMinted = false;
    bool public MINTING_LIVE = false;

    //uint arrays
    uint16[][7] TIERS;

    //p5js url
    string p5jsUrl =
        "https%3A%2F%2Fcdnjs.cloudflare.com%2Fajax%2Flibs%2Fp5.js%2F1.4.0%2Fp5.js";
    string p5jsIntegrity =
        "sha256-maU2GxaUCz5WChkAGR40nt9sbWRPEfF8qo%2FprxhoKPQ%3D";
    string animationUrl =
        "https://circolors.mypinata.cloud/ipfs/QmayAdMcP5QpWRcjf8W8hkcWLipLEMcNcm1XatTwLBP1zG?x=";
    string imageUrl = "https://scrawl-by-pixelwank.s3.amazonaws.com/output/";

    bytes32 constant circPresaleRoot =
        0xf18f21c0b9aa112dbdf6c6406635178df7d86e476a18de7d24941ddd8f3b1f62;
    bytes32 constant freelistRoot =
        0x246124155c5b50bc956d45abf72f661ba98b7fbb9605e223bed8c75b6580fcd8;

    bytes32 constant generalMintlistRoot =
        0xd5a3f650c9366b35260f7de176ca096cd5c16fbf149981b7423a743c91b9b1c2;

    constructor(address _scrawlArt) payable ERC721("SCRAWL", "SCRAWL") {
        scrawlArt = _scrawlArt;
        //Declare all the rarity tiers

        //Palettes
        TIERS[0] = [
            250,
            500,
            500,
            500,
            500,
            750,
            500,
            250,
            500,
            500,
            500,
            250,
            600,
            750,
            500,
            500,
            500,
            250,
            500,
            500,
            400
        ];
        //Bg
        TIERS[1] = [5500, 3500, 700, 300];
        //Depth
        TIERS[2] = [1000, 3500, 5500];
        //Passes
        TIERS[3] = [4200, 3300, 2000, 500];
        //Tidy
        TIERS[4] = [5000, 5000];
        //Shape
        TIERS[5] = [7500, 500, 700, 1300];
        //Border
        TIERS[6] = [2500, 2000, 500, 5000];
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

        uint256 length = TIERS[_rarityTier].length;
        for (uint8 i = 0; i < length; i++) {
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

    function buildHash(uint256 _t) internal view returns (string memory) {
        // This will generate a 8 character string.
        string memory currentHash = "";
        uint256 rInput = tokenIdToHashNeeds[_t].startHash;
        uint256 _nonce = tokenIdToHashNeeds[_t].startNonce;

        for (uint8 i = 0; i < 7; i++) {
            ++_nonce;
            uint16 _randinput = uint16(
                uint256(keccak256(abi.encodePacked(rInput, _t, _nonce))) % 10000
            );

            if (i == 0) {
                uint8 rar = rarityGen(_randinput, i);
                if (rar > 9) {
                    currentHash = string(
                        abi.encodePacked(currentHash, rar.toString())
                    );
                } else {
                    currentHash = string(
                        abi.encodePacked(currentHash, "0", rar.toString())
                    );
                }
            } else {
                currentHash = string(
                    abi.encodePacked(
                        currentHash,
                        rarityGen(_randinput, i).toString()
                    )
                );
            }
        }
        return currentHash;
    }

    /**
     * @dev Mint internal, this is to avoid code duplication.
     */
    function mintInternal() internal {
        require(
            MINTING_LIVE == true || msg.sender == owner(),
            "Minting not live"
        );
        require(initStart, "Minting not begun");
        require(block.timestamp < SALE_START + 72 hours, "Minting over");

        uint256 thisTokenId = totalSupply;

        require(thisTokenId < MAX_SUPPLY, "Minted out");

        tokenIdToHashNeeds[thisTokenId] = HashNeeds(
            hash(msg.sender),
            SEED_NONCE
        );

        lastWrite[msg.sender] = block.number;
        SEED_NONCE += 8;

        _mint(msg.sender, thisTokenId);
        ++totalSupply;
    }

    function mintGriff() external {
        require(!griffMinted, "You already minted knobhead");
        require(msg.sender == 0xdb4782d463628cc5b1de8f1220f755BA3bA4728E);

        uint256 firstId = totalSupply;
        require(firstId + 5 < MAX_SUPPLY, "Minted out");

        for (uint256 i = 0; i < 5; i++) {
            tokenIdToHashNeeds[firstId + i] = HashNeeds(
                hash(msg.sender),
                SEED_NONCE
            );

            SEED_NONCE += 8;

            _mint(msg.sender, firstId + i);
        }
        totalSupply += 5;
        griffMinted = true;
    }

    /**
     * @dev Mints new tokens.
     */
    function mintCircolorsPresale(
        address account,
        bytes32[] calldata merkleProof
    ) external payable {
        // Check address is on the merkle root
        bytes32 node = keccak256(abi.encodePacked(account));
        require(
            MerkleProof.verify(merkleProof, circPresaleRoot, node),
            "Not on Circolors Presale list"
        );
        require(account == msg.sender, "Self mint only");
        require(msg.value == CIRCOLORS_PRESALE_COST, "Mint is 0.0256eth");
        require(
            addressCircSaleMinted[msg.sender] != true,
            "Address already minted presale"
        );

        addressCircSaleMinted[msg.sender] = true;
        return mintInternal();
    }

    function mintFreelist(address account, bytes32[] calldata merkleProof)
        external
        payable
    {
        bytes32 node = keccak256(abi.encodePacked(account));
        require(
            MerkleProof.verify(merkleProof, freelistRoot, node),
            "Not on Free mint list"
        );
        require(account == msg.sender, "Self mint only");
        require(
            addressFreelistMinted[msg.sender] != true,
            "Address already free minted"
        );

        addressFreelistMinted[msg.sender] = true;
        return mintInternal();
    }

    function mintAllowlist(address account, bytes32[] calldata merkleProof)
        external
        payable
    {
        bytes32 node = keccak256(abi.encodePacked(account));
        require(
            MerkleProof.verify(merkleProof, generalMintlistRoot, node),
            "Not on Allowlist"
        );
        require(account == msg.sender, "Self mint only");
        require(msg.value == GENERAL_MINT_COST, "Mint is 0.0365eth");
        require(
            addressAllowlistMinted[msg.sender] != true,
            "Address already minted allow list"
        );
        require(
            block.timestamp > SALE_START + 24 hours,
            "Allowlist mint not started yet"
        );

        addressAllowlistMinted[msg.sender] = true;
        return mintInternal();
    }

    function mintPublic() external payable {
        require(msg.value == GENERAL_MINT_COST, "Mint is 0.0365eth");
        require(
            block.timestamp > SALE_START + 48 hours,
            "Public mint not started"
        );
        return mintInternal();
    }

    /*
 ______     ______     ______     _____     __     __   __     ______    
/\  == \   /\  ___\   /\  __ \   /\  __-.  /\ \   /\ "-.\ \   /\  ___\   
\ \  __<   \ \  __\   \ \  __ \  \ \ \/\ \ \ \ \  \ \ \-.  \  \ \ \__ \  
 \ \_\ \_\  \ \_____\  \ \_\ \_\  \ \____-  \ \_\  \ \_\\"\_\  \ \_____\ 
  \/_/ /_/   \/_____/   \/_/\/_/   \/____/   \/_/   \/_/ \/_/   \/_____/                                                                    
                                                                                           
*/
    function allowlistStart() external view returns (uint256) {
        require(initStart, "Mint start not initiated yet");
        return SALE_START + 24 hours;
    }

    function generalSaleStart() external view returns (uint256) {
        require(initStart, "Mint start not initiated yet");
        return SALE_START + 48 hours;
    }

    function mintDeadline() public view returns (uint256) {
        require(initStart, "Mint start not initiated yet");
        return SALE_START + 72 hours;
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
                "%22%20crossorigin%3D%22anonymous%22%3E%0A%3C%2Fscript%3E%0A%3Cstyle%3E%0Abody%20%7B%0A%20%20margin%3A%200%3B%0A%20%20padding%3A%200%3B%0A%20%20background%3A%20%23000%3B%0A%20%20overflow%3A%20hidden%3B%0A%7D%0A%0A%23fs%20%7B%0A%20%20position%3A%20fixed%3B%0A%20%20top%3A%200%3B%0A%20%20right%3A%200%3B%0A%20%20bottom%3A%200%3B%0A%20%20left%3A%200%3B%0A%20%20background-color%3A%20black%3B%0A%20%20display%3A%20flex%3B%0A%20%20justify-content%3A%20center%3B%0A%20%20align-items%3A%20center%3B%0A%7D%0A%0A%23fs%20canvas%20%7B%0A%20%20object-fit%3A%20contain%3B%0A%20%20max-height%3A%20100%25%3B%0A%20%20max-width%3A%20100%25%3B%0A%7D%0A%3C%2Fstyle%3E%3C%2Fhead%3E%3Cbody%3E%3Cdiv%20id%3D%22fs%22%3E%3C%2Fdiv%3E%3Cscript%3Evar%20tI%3D",
                AnonymiceLibrary.toString(_tokenId),
                "%3Bvar%20h%3D%22",
                _hash,
                "%22%3B"
            )
        );

        string memory artCode = IScrawlArt(scrawlArt).scrawlArtCode();

        htmlString = string(abi.encodePacked(htmlString, artCode));

        return htmlString;
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

        uint8 paletteTraitIndex = AnonymiceLibrary.parseInt(
            AnonymiceLibrary.substring(_hash, 0, 2)
        );

        metadataString = string(
            abi.encodePacked(
                metadataString,
                '{"trait_type":"',
                traitTypes[0][paletteTraitIndex].traitType,
                '","value":"',
                traitTypes[0][paletteTraitIndex].traitName,
                '"},'
            )
        );

        for (uint8 i = 2; i < 7; i++) {
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

            if (i != 6)
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
        require(_tokenId < totalSupply, "non existant id");

        string memory tokenHash = _tokenIdToHash(_tokenId);

        string
            memory description = '", "description": "420 SCRAWL pieces by pixelwank x Circolors. Traits generated on chain & metadata, images mirrored on chain permanently.",';

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
                                    '{"name": "SCRAWL #',
                                    AnonymiceLibrary.toString(_tokenId),
                                    description,
                                    '"animation_url":"',
                                    animationUrl,
                                    encodedTokenId,
                                    "&t=",
                                    encodedHash,
                                    '","image":"',
                                    imageUrl,
                                    AnonymiceLibrary.toString(_tokenId),
                                    '.png","attributes":',
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
        require(_tokenId < totalSupply, "non existant id");
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

    function addTraitType(uint256 _traitTypeIndex, Trait[] calldata traits)
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

    function initStartTimes() external onlyOwner {
        require(!initStart, "mint time already started");
        SALE_START = block.timestamp;
        MINTING_LIVE = true;
        initStart = true;
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
        uint256 sixty = (address(this).balance / 100) * 60;
        uint256 twentyFive = (address(this).balance / 100) * 25;
        uint256 ten = (address(this).balance / 100) * 10;
        uint256 five = (address(this).balance / 100) * 5;
        (bool sentT, ) = payable(
            address(0xE4260Df86f5261A41D19c2066f1Eb2Eb4F009e84)
        ).call{value: twentyFive}("");
        require(sentT, "Failed to send");
        (bool sentI, ) = payable(
            address(0x4533d1F65906368ebfd61259dAee561DF3f3559D)
        ).call{value: ten}("");
        require(sentI, "Failed to send");
        (bool sentC, ) = payable(
            address(0x888f8AA938dbb18b28bdD111fa4A0D3B8e10C871)
        ).call{value: five}("");
        require(sentC, "Failed to send");
        (bool sentG, ) = payable(
            address(0xdb4782d463628cc5b1de8f1220f755BA3bA4728E)
        ).call{value: sixty}("");
        require(sentG, "Failed to send");
    }
}