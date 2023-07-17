// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AnonymiceLibrary.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SnowCrash is ERC721, Ownable {
    /*
 ______     __   __     ______     __     __     ______     ______     ______     ______     __  __    
/\  ___\   /\ "-.\ \   /\  __ \   /\ \  _ \ \   /\  ___\   /\  == \   /\  __ \   /\  ___\   /\ \_\ \   
\ \___  \  \ \ \-.  \  \ \ \/\ \  \ \ \/ ".\ \  \ \ \____  \ \  __<   \ \  __ \  \ \___  \  \ \  __ \  
 \/\_____\  \ \_\\"\_\  \ \_____\  \ \__/".~\_\  \ \_____\  \ \_\ \_\  \ \_\ \_\  \/\_____\  \ \_\ \_\ 
  \/_____/   \/_/ \/_/   \/_____/   \/_/   \/_/   \/_____/   \/_/ /_/   \/_/\/_/   \/_____/   \/_/\/_/ 
*/
    using AnonymiceLibrary for uint8;

    struct Trait {
        string traitName;
        string traitType;
    }

    //Mappings
    mapping(uint256 => Trait[]) public traitTypes;
    mapping(uint256 => string) internal tokenIdToHash;
    mapping(address => uint256) private lastWrite;

    //Mint Checks
    mapping(address => bool) addressFreeMinted;
    mapping(address => bool) contributorMints;
    uint256 contributorCount = 0;
    uint256 regularCount = 0;
    uint256 public totalSupply = 0;

    //uint256s
    uint256 constant MAX_SUPPLY = 256;
    uint256 constant MINT_COST = 0.0256 ether;
    uint256 constant PUBLIC_START_BLOCK = 14651420;
    uint256 SEED_NONCE = 0;

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

    bytes32 constant whitelistRoot =
        0x2cd756bd043061e7f4cd5b02ccfbd86ac3965d315356463f26afa7c6915ab14f;

    constructor() payable ERC721("SnwCrsh", "SNOW") {
        //Declare all the rarity tiers

        //col
        TIERS[0] = [1600, 1200, 550, 550, 1200, 700, 1600, 700, 1200, 700];
        //border size
        TIERS[1] = [1000, 4000, 4000, 1000];
        //noise Max
        TIERS[2] = [1000, 2000, 4000, 3000];
        //speed
        TIERS[3] = [1000, 5500, 2500, 1000];
        //Slice thickness
        TIERS[4] = [2500, 3500, 2500, 1500];
        //secCol
        TIERS[5] = [7000, 3000];
        //charset
        TIERS[6] = [1000, 2500, 3000, 2500, 500, 500];
        //flowType
        TIERS[7] = [8500, 1500];
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
                abi.encodePacked(
                    currentHash,
                    rarityGen(_randinput, i).toString()
                )
            );
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
        uint256 _totalSupply = totalSupply;
        require(_totalSupply < MAX_SUPPLY);
        require(!AnonymiceLibrary.isContract(msg.sender));
        require(regularCount < 241);
        uint256 thisTokenId = _totalSupply;

        tokenIdToHash[thisTokenId] = hash(thisTokenId, msg.sender, 0);
        lastWrite[msg.sender] = block.number;

        ++totalSupply;

        _mint(msg.sender, thisTokenId);
    }

    function mintOgBatch(address[] memory _addresses)
        external
        payable
        onlyOwner
    {
        require(ogMinted == false);
        require(_addresses.length == 10);
        for (uint256 i = 0; i < 10; i++) {
            uint256 thisTokenId = i;
            tokenIdToHash[thisTokenId] = hash(thisTokenId, _addresses[i], 0);
            _mint(_addresses[i], thisTokenId);
        }
        totalSupply = 10;
        regularCount = 10;
        ogMinted = true;
    }

    /**
     * @dev Mints new tokens.
     */
    function mintFreeSnowCrash(address account, bytes32[] calldata merkleProof)
        external
    {
        bytes32 node = keccak256(abi.encodePacked(account));

        require(MerkleProof.verify(merkleProof, whitelistRoot, node));
        require(
            addressFreeMinted[msg.sender] != true,
            "Address already free minted"
        );

        addressFreeMinted[msg.sender] = true;
        ++regularCount;
        return mintInternal();
    }

    function mintPaidSnowCrash() external payable {
        require(msg.value == MINT_COST, "Insufficient ETH sent");
        require(block.number > PUBLIC_START_BLOCK);
        ++regularCount;
        return mintInternal();
    }

    function mintCircolorsContributor() external {
        require(contributorMints[msg.sender] == true);
        require(contributorCount < 16);

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
                "let%20f%3D0%3Blet%20cSet%3D%5B%22%C3%91%2450c-%22%2C%22%4097%3F%3B%2C%22%2C%22%238%C2%A3%21%3A.%22%2C%22%E2%82%A942a%2B_%22%2C%22%25gm%3B%29%27%22%2C%220101%2F%20%22%5D%3Blet%20xoff1%2Cyoff1%2Cxyoff%2Cn%2Ccols%3D%5B0%2C1%2C2%2C4%2C5%2C6%2C7%2C8%2C9%2C11%5D%2CfSizes%3D%5B12.5%2C9%2C6%2C4.7%5D%2CnoiseEnd%3D%5B.001%2C.002%2C.005%2C.008%5D%2Cspds%3D%5B.7%2C1.2%2C2.5%2C2.6%5D%2CtextCol%3D%5B0%2C100%5D%2CcSprd%3D%5B.06%2C.12%2C.18%2C.24%5D%2Ct%3D0%2CsT%3D0%2CcT%3D0%2Clp%3D%210%2Crv%3D%211%2Cw%3D500%2Ch%3D500%3Bfunction%20setup%28%29%7BcreateCanvas%28w%2Ch%29%2CcolorMode%28HSB%2C360%2C100%2C100%29%2CtextFont%28%22Courier%22%29%2CnoiseSeed%28tokenId%29%2CcO%3D30%2Acols%5BparseInt%28hash.substring%280%2C1%29%29%5D%2CfW%3Dwidth%2FfSizes%5BparseInt%28hash.substring%281%2C2%29%29%5D%2CfH%3Dheight%2FfSizes%5BparseInt%28hash.substring%281%2C2%29%29%5D%2Cend%3DnoiseEnd%5BparseInt%28hash.substring%282%2C3%29%29%5D%2Csp%3Dspds%5BparseInt%28hash.substring%283%2C4%29%29%5D%2F%28fW%2BfH%29%2F3%2Cs%3DcSprd%5BparseInt%28hash.substring%284%2C5%29%29%5D%2CbT%3DtextCol%5BparseInt%28hash.substring%285%2C6%29%29%5D%2Cc%3DparseInt%28hash.substring%286%2C7%29%29%2CfTyp%3DparseInt%28hash.substring%287%2C8%29%29%2CsO%3D80%2C100%3D%3DbT%3FbO%3D85%3AbO%3D100%2Cfill%28cT%2CsT%2CbT%29%7Dfunction%20draw%28%29%7Bbackground%28cO%2CsO%2CbO%29%3Bfor%28let%20e%3DfW%3Be%3C%3Dwidth-fW%3Be%2B%3D10%29for%28let%20o%3DfH%3Bo%3C%3Dheight-fH%3Bo%2B%3D10%29xoff1%3Dmap%28e%2CfW%2Cwidth%2C0%2Cend%29%2Cyoff1%3Dmap%28o%2CfH%2Cheight%2C0%2Cend%29%2Cxyoff%3Dxoff1%2Byoff1%2Cn%3Dnoise%28e%2Axyoff%2Bt%2Co%2Axyoff%2Bt%2Cf%29%2CnoStroke%28%29%2Cfill%28cT%2CsT%2CbT%29%2Cn%3E.5%2B.8%2As%7C%7Cn%3C.5-.8%2As%3Ftext%28cSet%5Bc%5D%5B0%5D%2Ce%2Co%29%3An%3E.5%2B.65%2As%7C%7Cn%3C.5-.65%2As%3Ftext%28cSet%5Bc%5D%5B1%5D%2Ce%2Co%29%3An%3E.5%2B.5%2As%7C%7Cn%3C.5-.5%2As%3Ftext%28cSet%5Bc%5D%5B2%5D%2Ce%2Co%29%3An%3E.5%2B.35%2As%7C%7Cn%3C.5-.35%2As%3Ftext%28cSet%5Bc%5D%5B3%5D%2Ce%2Co%29%3An%3E.5%2B.2%2As%7C%7Cn%3C.5-.2%2As%3Ftext%28cSet%5Bc%5D%5B4%5D%2Ce%2Co%29%3Atext%28cSet%5Bc%5D%5B5%5D%2Ce%2Co%29%3B0%3D%3Drv%3F0%3D%3DfTyp%3Ft%2B%3Dsp%3A%28f%2B%3Dsp%2Ct%2B%3Dsp%2F10%29%3A0%3D%3DfTyp%3Ft-%3Dsp%3A%28f-%3Dsp%2Ct-%3Dsp%2F10%29%2Ctext%28%22%23%22%2BtokenId.toString%28%29%2C10%2Cheight-10%29%7Dfunction%20mouseClicked%28%29%7BcB%3DcO%2CsB%3DsO%2CbB%3DbO%2CcO%3DcT%2CsO%3DsT%2CbO%3DbT%2CcT%3DcB%2CsT%3DsB%2CbT%3DbB%7Dfunction%20keyPressed%28%29%7B32%3D%3D%3DkeyCode%26%261%3D%3Dlp%3F%28noLoop%28%29%2Clp%3D%211%29%3AkeyCode%3D%3D%3DLEFT_ARROW%3F%28rv%3D%211%2Cloop%28%29%2Clp%3D%210%29%3AkeyCode%3D%3D%3DRIGHT_ARROW%3F%28rv%3D%210%2Cloop%28%29%2Clp%3D%210%29%3AkeyCode%3D%3D%3DUP_ARROW%3FresizeCanvas%28750%2C250%29%3AkeyCode%3D%3D%3DDOWN_ARROW%3FresizeCanvas%28500%2C500%29%3A16%3D%3D%3DkeyCode%3FresizeCanvas%28350%2C600%29%3A%28loop%28%29%2Clp%3D%210%29%7D%3C%2Fscript%3E%3C%2Fbody%3E%3C%2Fhtml%3E"
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
        disallowIfStateIsChanging
        returns (string memory)
    {
        string memory metadataString;

        for (uint8 i = 0; i < 8; i++) {
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

            if (i != 7)
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
            memory description = '", "description": "256 ASCII SnowCrashes. Metadata & images mirrored on chain permanently and loops infinitely",';

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
                                    '{"name": "SnowCrash #',
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
        string memory tokenHash = tokenIdToHash[_tokenId];

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
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}