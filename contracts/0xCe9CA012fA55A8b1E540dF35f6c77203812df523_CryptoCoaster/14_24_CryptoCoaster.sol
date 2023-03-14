// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**======================================================================================
   .-'--`-._                           .-'--`-._                           .-'--`-._
   '-O---O--'                          '-O---O--'                          '-O---O--'
=========================================================================================

                    ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗░█████╗░
                    ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔══██╗
                    ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░██║░░██║
                    ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██║░░██║
                    ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░╚█████╔╝
                    ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░░╚════╝░

                ░█████╗░░█████╗░░█████╗░░██████╗████████╗███████╗██████╗░
                ██╔══██╗██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗
                ██║░░╚═╝██║░░██║███████║╚█████╗░░░░██║░░░█████╗░░██████╔╝
                ██║░░██╗██║░░██║██╔══██║░╚═══██╗░░░██║░░░██╔══╝░░██╔══██╗
                ╚█████╔╝╚█████╔╝██║░░██║██████╔╝░░░██║░░░███████╗██║░░██║
                ░╚════╝░░╚════╝░╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝

/*=========================================================================================
   .-'--`-._                           .-'--`-._                           .-'--`-._
   '-O---O--'                          '-O---O--'                          '-O---O--'
=========================================================================================*/

import "./Base.sol";
import "./lib/scripty/IScriptyBuilder.sol";
import "./lib/SmallSolady.sol";
import "./Thumbnail.sol";
import "./ICryptoCoaster.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Crypto Coaster
 * @author @xtremetom
 * @notice Experiment, 100% on-chain procedurally generated roller coaster
 * @dev No fancy mint mechanics, no promise of utility, no discord, just a code experiment
 *
 *      There are parts of this contract that could be optimized but I have deliberately
 *      tried to make things easy to read and understand
 *
 *      Huge thanks to 0xthedude, frolic, dhof, ****, CODENAME883, Mathcastles community,
 *      and everyone that helped with testing
 */
contract CryptoCoaster is Base {

    using BitMaps for BitMaps.BitMap;

    address public immutable _ethfsFileStorageAddress;
    address public immutable _scriptyStorageAddress;
    address public immutable _scriptyBuilderAddress;
    uint256 public immutable _supply;
    address public _thumbnailAddress;

    uint256 public _price = 0.025 ether;

    bool public _isOpen = false;

    // Address => Minted?
    BitMaps.BitMap _minted;

    address public _signer;
    address public constant _signatureDisabled =
    address(bytes20(keccak256("signatureDisabled")));

    error MintClosed();
    error ContractMinter();
    error SoldOut();
    error GreedyMinter();
    error InsufficientFunds();
    error WalletMax();
    error TokenDoesntExist();
    error InvalidSignature();

    constructor(
        string memory name,
        string memory symbol,
        uint256 supply,
        address ethfsFileStorageAddress,
        address scriptyStorageAddress,
        address scriptyBuilderAddress,
        address thumbnailAddress
    ) Base(name, symbol) {
        _ethfsFileStorageAddress = ethfsFileStorageAddress;
        _scriptyStorageAddress = scriptyStorageAddress;
        _scriptyBuilderAddress = scriptyBuilderAddress;
        _thumbnailAddress = thumbnailAddress;

        _supply = supply;

        // mint reserve of 20 for friends that helped
        // and a few giveaways
        _safeMint(msg.sender, 20, "");
    }

    /**
     * @notice Minting starts at token id #1
     * @return Token id to start minting at
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @notice Retrieve how many tokens have been minted
     * @return Total number of minted tokens
     */
    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    /*=========================================================================================
       .-'--`-._                            MINTING
       '-O---O--'                            LOGIC
    =========================================================================================*/

    /**
     * @notice Verify signature
     * @param sender - Address of sender
     * @param signature - Signature to verify
     */
    modifier validateSignature(address sender, bytes memory signature) {
        if (_signer != _signatureDisabled) {
            bytes32 messageHash = ECDSA.toEthSignedMessageHash(abi.encode(sender));
            (address signer,) = ECDSA.tryRecover(messageHash, signature);
            if (signer != _signer) {
                revert InvalidSignature();
            }
        }
        _;
    }

    /**
     * @notice Mint those tokens
     * @dev No whitelist, just limit per wallet and signature verification
     * @param signature - Signature to verify
     */
    function mint(bytes memory signature)
        public payable
        validateSignature(msg.sender, signature)
    {
        if (!_isOpen) revert MintClosed();
        if (msg.sender != tx.origin) revert ContractMinter();
        if (_minted.get(uint160(msg.sender))) revert WalletMax();
        if (msg.value < _price) revert InsufficientFunds();
        unchecked {
            if (_totalMinted() + 1 > _supply) revert SoldOut();
        }

        _minted.set(uint160(msg.sender));
        _safeMint(msg.sender, 1, "");
    }

    /**
     * @notice Update the mint price.
     * @dev Very doubtful this gets used, but good to have
     * @param price - The new price.
     */
    function updateMintPrice(uint256 price) external onlyOwner {
        _price = price;
    }

    /**
     * @notice Update thumbnail contract address
     * @param thumbnailAddress - Address of the thumbnail contract.
     */
    function setThumbnailAddress(address thumbnailAddress) external onlyOwner {
        if (_totalMinted() == _supply) revert SoldOut();
        _thumbnailAddress = thumbnailAddress;
    }

    /**
     * @notice Open or close minting
     * @param state - Boolean state for being open or closed.
     */
    function setMintStatus(bool state) external onlyOwner {
        _isOpen = state;
    }

    /**
     * @notice Set address of signer
     * @param signer - Address of new signer
     */
    function setSigner(address signer) external onlyOwner {
        _signer = signer;
    }

    /*=========================================================================================
       .-'--`-._                            METADATA
       '-O---O--'                            LOGIC
    =========================================================================================*/

    /**
     * @notice Build all the settings into a struct
     * @param tokenIdString - Value as string
     * @return settings - All settings as a struct
     */
    function buildSettings(string memory tokenIdString) internal view returns (Settings memory settings) {

        (uint256 seed, bytes memory varSeed) = genSeed(tokenIdString);
        settings.seed = seed;
        settings.vars[0] = varSeed;

        (bytes memory varSpeed, uint256 speed) = trackSpeed(seed);
        settings.speed = speed;
        settings.vars[1] = varSpeed;

        (bytes memory varScale, uint256 scale) = worldScale(seed >> 8);
        settings.scale = scale;
        settings.vars[2] = varScale;

        (bytes memory varColor, Color memory color) = trackColor(seed >> 16);
        settings.color = color;
        settings.vars[3] = varColor;

        (bytes memory varBiome, string memory biomeName, uint256 biomeIDX) = biome(seed >> 24);
        settings.biomeName = biomeName;
        settings.biomeIDX = biomeIDX;
        settings.vars[4] = varBiome;

        (bytes memory varFlip, uint256 flip) = trackOrientation(seed >> 32);
        settings.flip = flip;
        settings.vars[5] = varFlip;
    }

    /**
     * @notice Util function to generate hash
     * @param tokenIdString - Value as string
     * @return hash - as uint256
     */
    function createHash(string memory tokenIdString) internal view returns (uint256 hash) {
        return uint256(keccak256(abi.encodePacked("coaster", tokenIdString, address(this))));
    }

    /**
     * @notice Generate seed based on tag and track ID
     * @param tokenIdString - Track id as string
     * @return seed - final seed as uint56
     * @return varSeed - JS compatible declaration of seed
     */
    function genSeed(string memory tokenIdString) internal view returns (uint256 seed, bytes memory varSeed) {
        seed = createHash(tokenIdString);
        varSeed = abi.encodePacked(
            'var seed="', SmallSolady.toString(seed), '";'
        );
    }

    /**
     * @notice Determine the track speed setting
     * @param seed - Seed for a specific track
     * @return varSpeed - JS compatible declaration of track speed
     * @return speed - Speed setting a uint256
     */
    function trackSpeed(uint256 seed) internal pure returns (bytes memory varSpeed, uint256 speed) {
        uint256 r = seed % 100;
        speed = (r > 90) ? 2 : 1;
        varSpeed = abi.encodePacked(
            'var speed="', SmallSolady.toString(speed), '";'
        );
    }

    /**
     * @notice Determine the world scale setting
     * @param seed - Seed for a specific track
     * @return varScale - JS compatible declaration of world scale
     * @return scale - Scale setting a uint256
     */
    function worldScale(uint256 seed) internal pure returns (bytes memory varScale, uint256 scale) {
        uint256 r = seed % 100;
        scale = (r > 85) ? 2 : 1;
        varScale = abi.encodePacked(
            'var scale="', SmallSolady.toString(scale), '";'
        );
    }

    /**
     * @notice Pick track color based on seed
     * @param seed - Seed for a specific track
     * @return varColor - JS compatible declaration of track color
     * @return color - Color info struct
     */
    function trackColor(uint256 seed) internal pure returns (bytes memory varColor, Color memory color) {
        string[7] memory trackHexs = ["#2710cf","#cf10c4","#10cf27","#106acf","#cf3210","#cf0808","#cfcf10"];
        string[7] memory iconHexs = ["#9530eb", "#eb30d7","#23cc16","#169bcc","#f97316","#eb3030","#f0cb38"];
        string[7] memory names = ["Purple", "Pink", "Green", "Blue", "Orange", "Red", "Yellow"];

        uint256 r = seed % 7;
        color = Color(names[r], trackHexs[r], iconHexs[r]);

        varColor = abi.encodePacked(
            'var trackColor="', color.trackHex, '";'
        );
    }

    /**
     * @notice Gather biome data based on seed
     * @param seed - Seed for a specific track
     * @return varBiome - JS compatible declaration of biomeName
     * @return biomeName - Biome name as string
     * @return biomeIDX - array index for biome
     */
    function biome(uint256 seed) internal pure returns (bytes memory varBiome, string memory biomeName, uint256 biomeIDX) {
        string[3] memory biomes = ["Snow", "Forest", "Desert"];
        biomeIDX = seed % 3;
        biomeName = biomes[biomeIDX];
        varBiome = abi.encodePacked(
            'var biomeName="', biomeName, '";'
        );
    }

    /**
     * @notice Silly adjustment to track
     * @param seed - Seed for a specific track
     * @return varTrackOr - JS compatible declaration of track orientation
     * @return flip - 0 | 1 | 2 - normal | horiz |  vert
     */
    function trackOrientation(uint256 seed) internal pure returns (bytes memory varTrackOr, uint256 flip) {
        uint256 r = seed % 100;
        flip = 0;
        if (r == 0) flip = 2;
        else if (r > 95) flip = 1;
        varTrackOr = abi.encodePacked(
            'var flip="', SmallSolady.toString(flip) , '";'
        );
    }

    /**
     * @notice Util function to help build traits
     * @param key - Trait key as string
     * @param value - Trait value as string
     * @return trait - object as string
     */
    function buildTrait(string memory key, string memory value) internal pure returns (string memory trait) {
        return string.concat('{"trait_type":"', key, '","value": "', value, '"}');
    }

    /**
     * @notice Build attributes for metadata
     * @param settings - Track settings struct
     * @return attr - array as a string
     */
    function buildAttributes(Settings memory settings) internal pure returns (bytes memory attr) {
        // orientation
        string memory orientation = "Forward";
        if (settings.flip == 1) orientation = "Backward";
        else if (settings.flip == 2) orientation = "Upside down";

        // speed
        string memory speedString = "Normal";
        if (settings.speed == 2) speedString = "Fast";

        // world scale
        string memory scaleString = "Normal";
        if (settings.scale == 2) scaleString = "Big";

        return abi.encodePacked(
            '"attributes": [',
                buildTrait("Track Color", settings.color.name),
                ',',
                buildTrait("Biome", settings.biomeName),
                ',',
                buildTrait("Orientation", orientation),
                ',',
                buildTrait("Speed", speedString),
                ',',
                buildTrait("World Scale", scaleString),
            ']'
        );
    }

    /**
     * @notice Pack and base64 encode JS compatible vars
     * @param settings - Track settings struct
     * @return vars - base64 encoded JS compatible setting variables
     */
    function buildVars(Settings memory settings) internal pure returns (bytes memory vars){
        return bytes(
            SmallSolady.encode(
                abi.encodePacked(
                    settings.vars[0],
                    settings.vars[1],
                    settings.vars[2],
                    settings.vars[3],
                    settings.vars[4],
                    settings.vars[5]
                )
            )
        );
    }

    /**
     * @notice Use Scripty to generate the final html
     * @dev I opted for the lazy dev approach and let scripty calculate the required buffersize
     *      This could be calculated and passed to the contract at any point prior to its use
     *      in `getHTMLWrappedURLSafe`
     * @param requests - Array of WrappedScriptRequest data
     * @return html - as bytes
     */
    function buildAnimationURI(WrappedScriptRequest[] memory requests) internal view returns (bytes memory html) {
        IScriptyBuilder iScriptyBuilder = IScriptyBuilder(_scriptyBuilderAddress);
        uint256 bufferSize = iScriptyBuilder.getBufferSizeForURLSafeHTMLWrapped(requests);
        return iScriptyBuilder.getHTMLWrappedURLSafe(requests, bufferSize);
    }

    /**
     * @notice Build the metadata including the full render html for the coaster
     * @dev This depends on
     *      - https://ethfs.xyz/ [stores code libraries]
     *      - https://github.com/intartnft/scripty.sol [builds rendering html and stores code libraries]
     * @param tokenId - TokenId to build coaster for
     * @return metadata - as string
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory metadata) {

        // show nothing if token doesnt exist
        if (!_exists(tokenId)) revert TokenDoesntExist();

        string memory tokenIdString = SmallSolady.toString(tokenId);

        // Generate all the settings and various objects for the metadata
        Settings memory settings = buildSettings(tokenIdString);
        bytes memory attr = buildAttributes(settings);
        bytes memory vars = buildVars(settings);
        string memory thumbnail = SmallSolady.encode(
            Thumbnail(_thumbnailAddress).buildThumbnail(settings)
        );

        // To build the html I use Scripty to manage all the annoying tagging and html construction
        // A combination of EthFS and Scripty is used for storage and this array stores the required
        // code data
        WrappedScriptRequest[] memory requests = new WrappedScriptRequest[](7);

        // The order of steps is the order the code will appear in the final
        // rendering html injected into the metadata
        //
        // 1. - CSS + dom elements
        // 2. - setting JS variables
        // 3. - gzipped 3D models as JS variable
        // 4. - gzipped ThreeJS lib
        // 5. - gzipped Coaster bundle
        // 6. - gzip handler
        //
        // When the gzip handler runs it detects scripts with `text/javascript+gzip`
        // gunzips them and appends the raw code in this order:
        //
        // - ThreeJS [no dependencies]
        // - Coaster script bundle [depends on ThreeJS]
        //   |
        //   -- GLTFLoader [requires ThreeJS]
        //   -- BufferGeometryUtils [requires ThreeJS]
        //   -- Other scripts [requires ThreeJS + setting variables]
        //   -- Scenebuilder [requires ThreeJS + 3D models]
        //
        // 3D models are explicitly gunzipped and converted into `octet-stream`
        // allowing them to easily be loaded using the glb ThreeJS loader
        // More loaders are available:
        // https://github.com/mrdoob/three.js/tree/dev/examples/jsm/loaders
        // I used .glb files as an example, however other formats like SDF and colored STL
        // would be better suited in terms of storage cost
        //
        // [PREVENTING GAS OUT]
        // It is worth noting that for this piece I am using `getHTMLWrappedURLSafe` in `buildAnimationURI()`
        // above. This ensures the code is handled with urlencoding to make it URL safe vs base64 encoding. For a
        // codebase this big (threejs + models + scripts) base64 encoding within a contract would result in a gas
        // out.
        // However, I have tried to include an example of all `wrapTypes` below, one of which is a forced base64
        // encoding, for demo purposes.


        // Step 1.
        // - create custom content blocks that have no wrapper
        // - we do this to easily inject css and dom elements
        // - double urlencoded
        // - first block is css + some JS
        // - second block is coaster settings [biome + speed]
        //
        // Final Output:
        // https://github.com/intartnft/scripty.sol/blob/main/contracts/scripty/ScriptyBuilder.sol#L648
        // [double urlencoded data]

        requests[0].wrapType = 4;
        requests[0].scriptContent = "%253Cstyle%253Ebody%252Chtml%257Boverflow%253Ahidden%253Bmargin%253A0%253Bwidth%253A100%2525%253Bheight%253A100%2525%257D%2523overlay%257Bposition%253Aabsolute%253Bwidth%253A100vw%253Bheight%253A100vh%253Btransition%253A.75s%2520ease-out%253Bbackground-color%253A%2523e2e8f0%253Bdisplay%253Aflex%253Bflex-direction%253Acolumn%253Bjustify-content%253Acenter%253Balign-items%253Acenter%257D.bbg%257Bwidth%253A75%2525%253Bmargin%253A1rem%253Bbackground-color%253A%2523cbd5e1%253Bmax-width%253A400px%253Bborder-radius%253A2rem%253Bheight%253A.8rem%257D.bbar%257Bbackground-color%253A%25236366f1%253Bwidth%253A5%2525%253Bborder-radius%253A2rem%253Bheight%253A.8rem%257D%2523info%257Bfont-family%253ATahoma%252CArial%252CHelvetica%252Csans-serif%253Bfont-size%253A.8rem%253Bcolor%253A%2523475569%253Bmin-height%253A1rem%257D%2523controls%257Bposition%253Aabsolute%253Bbottom%253A20px%253Bleft%253A20px%257D%2523camber%257Bborder%253A1px%2520solid%2520%2523fff%253Bborder-radius%253A4px%253Bbackground%253Argba(0%252C0%252C0%252C.1)%253Bcolor%253A%2523dc2626%253Btext-align%253Acenter%253Bopacity%253A.5%253Boutline%253A0%253Bmouse%253Apointer%257D%2523camber.active%257Bbackground%253Argba(255%252C255%252C255%252C.5)%253Bcolor%253A%252316a34a%253Bopacity%253A1%257D%2523camber%2520svg%257Bwidth%253A36px%253Bheight%253A36px%257D%253C%252Fstyle%253E%253Cdiv%2520id%253D'overlay'%253E%253Cdiv%2520class%253D'bbg'%253E%253Cdiv%2520id%253D'bar'%2520class%253D'bbar'%253E%253C%252Fdiv%253E%253C%252Fdiv%253E%253Cdiv%2520id%253D'info'%253E%253C%252Fdiv%253E%253C%252Fdiv%253E%253Ccanvas%2520id%253D'coaster'%253E%253C%252Fcanvas%253E%253Cdiv%2520id%253D'controls'%253E%253Cbutton%2520id%253D'camber'%2520onclick%253D'toggleActive()'%253E%253Csvg%2520viewBox%253D'0%25200%252012.7%252012.7'%2520xmlns%253D'http%253A%252F%252Fwww.w3.org%252F2000%252Fsvg'%253E%253Cg%2520style%253D'stroke%253AcurrentColor%253Bstroke-width%253A.6%253Bstroke-linecap%253Around%253Bfill%253Anone'%253E%253Crect%2520width%253D'4.217'%2520height%253D'4.217'%2520x%253D'4.257'%2520y%253D'5.388'%2520ry%253D'.31'%2520rx%253D'.31'%252F%253E%253Cpath%2520d%253D'm12.37%25206.919-.935%25201.16-1.145-1.025M.487%25206.919l.936%25201.16%25201.145-1.025'%2520transform%253D'matrix(.94246%25200%25200%2520.9392%2520.291%2520.21)'%252F%253E%253Cpath%2520d%253D'M-1.464-8.007a4.99%25205.036%25200%25200%25201-2.495%25204.36%25204.99%25205.036%25200%25200%25201-4.99%25200%25204.99%25205.036%25200%25200%25201-2.495-4.36'%2520transform%253D'matrix(-.94246%25200%25200%2520-.9392%2520.291%2520.21)'%252F%253E%253C%252Fg%253E%253C%252Fsvg%253E%253C%252Fbutton%253E%253C%252Fdiv%253E";

        // Step 2.
        // - wrap the JS variables in <script>
        // - no name is needed as we are injected the code rather than
        //   pulling it from a contract (scriptyStorage/EthFS)
        // - wrapType 1 w/ script content
        //
        //
        // Final Output:
        // https://github.com/intartnft/scripty.sol/blob/main/contracts/scripty/ScriptyBuilder.sol#L638
        // <script src="data:text/javascript;base64,[vars]"></script>

        requests[1].name = "";
        requests[1].wrapType = 1;
        requests[1].scriptContent = vars;

        // Ideally these settings would be included in the main bulk of the coaster
        // code, but to allow you to mess around with the coaster by creating your own
        // settings json, I have kept them separate
        //
        // [IMPORTANT]
        // Note how this code is not encoded in any way. The `wrapType 0` in combination with `getHTMLWrappedURLSafe`
        // from `buildAnimationURI()` results in the scriptContent being base64 encoded in Scripty
        //
        // Final Output:
        // https://github.com/intartnft/scripty.sol/blob/main/contracts/scripty/ScriptyBuilder.sol#L638
        // <script src="data:text/javascript;base64,[SCRIPT]"></script>

        requests[2].wrapType = 0;
        requests[2].scriptContent = 'const biomes={Snow:{sky:15987703,fog:14737632,ground:11526632,hemi:[14154495,13806982,.5],sun:[15127463,1,0,100,50],models:[["treePineSnowRound",200,2,7,1],["rockB",50,1,3,0,[["rock.001",5918017]]]]},Desert:{fog:15005690,sky:12446963,ground:10777144,hemi:[16770732,4142384,.605],sun:[16763989,1,0,100,50],models:[["palmDetailed",200,1,2.8,1],["grassLarge",50,1,3,0,[["foliage",4225055]]],["rockB",50,1,3,0]]},Forest:{fog:15005690,sky:12446963,ground:5535813,hemi:[16770732,4142384,.45],sun:[16763989,1,0,100,-50],models:[["treePine",250,3,8,1,[["leafsDark",1274191],["woodBarkDark",12606262]]],["grassLarge",50,1,3,0,[["foliage",4225055]]],["rockB",50,1,3,0,[["rock.001",5918017]]]]}};const data=biomes[biomeName];const speedSettings=[{acc:45e-5,dec:453e-6,max:.03,min:.004},{acc:3e-4,dec:305e-6,max:.03,min:.004}];';

        // Step 3.
        // - pull the gzipped 3D models from scriptyStorage
        //   I could have stored on EthFS, but wanted to show that pulling from
        //   another contract is possible.
        // - custom wrap to declare the data as a JS compatible variable
        // - wrapType 4 w/ script content and custom wraps
        //
        // Final Output:
        // https://github.com/intartnft/scripty.sol/blob/main/contracts/scripty/ScriptyBuilder.sol#L648
        // <script>var gzipModels="[coaster_models_v8]"</script>

        requests[3].name = "coaster_models_v8";
        requests[3].wrapType = 4;
        requests[3].wrapPrefix = "%253Cscript%253Evar%2520gzipModels%2520%253D%2522";
        requests[3].wrapSuffix = "%2522%253C%252Fscript%253E";
        requests[3].contractAddress = _scriptyStorageAddress;

        // Step 4.
        // - pull the gzipped threeJS lib from EthFS
        // - wrapType 2 will handle the gzip script wrappers
        //
        // Final Output:
        // https://github.com/intartnft/scripty.sol/blob/main/contracts/scripty/ScriptyBuilder.sol#L642
        // <script type="text/javascript+gzip" src="data:text/javascript;base64,[three-v0.147.0.min.js.gz]"></script>

        requests[4].name = "three-v0.147.0.min.js.gz";
        requests[4].wrapType = 2;
        requests[4].contractAddress = _ethfsFileStorageAddress;

        // Step 5.
        // - pull the coaster code from scriptyStorage
        //   I could have stored on EthFS, but wanted to show that pulling from
        //   another contract is possible.
        // - wrapType 2 will handle the gzip script wrappers
        //
        // Final Output:
        // https://github.com/intartnft/scripty.sol/blob/main/contracts/scripty/ScriptyBuilder.sol#L642
        // <script type="text/javascript+gzip" src="data:text/javascript;base64,[cryptoCoaster.min.js.gz]"></script>

        requests[5].name = "cryptoCoaster.min.js.gz_v2";
        requests[5].wrapType = 2;
        requests[5].contractAddress = _scriptyStorageAddress;

        // Step 6.
        // - pull the gunzip handler from EthFS
        // - wrapType 1 will handle the script tags
        //
        // Final Output:
        // https://github.com/intartnft/scripty.sol/blob/main/contracts/scripty/ScriptyBuilder.sol#L638
        // <script src="data:text/javascript;base64,[gunzipScripts-0.0.1.js]"></script>

        requests[6].name = "gunzipScripts-0.0.1.js";
        requests[6].wrapType = 1;
        requests[6].contractAddress = _ethfsFileStorageAddress;

        bytes memory json = abi.encodePacked(
            '{"name":"',
            'Track: #',
            tokenIdString,
            '", "description":"',
            'Crypto Coaster is an experiment to see just how far we can push on-chain NFTs. All the models and code are compressed then stored, and retrieved from the blockchain.',
            '","image":"data:image/svg+xml;base64,',
            thumbnail,
            '","animation_url":"',
            buildAnimationURI(requests),
            '",',
            attr,
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json,",
                json
            )
        );
    }

    /*=========================================================================================
       .-'--`-._                             GETTER
       '-O---O--'                            LOGIC
    =========================================================================================*/

    /**
     * @notice Grab settings for given Id
     * @dev Can do fun stuff with settings in the future :)
     *      On the minting app we use this to grab the settings and create each coaster without having
     *      to call tokenURI()
     * @param tokenId - Id of chosen token
     * @return settings - All settings as a struct
     */
    function getSettings(uint256 tokenId) public view returns (Settings memory settings) {
        if (!_exists(tokenId)) return settings;
        return buildSettings(SmallSolady.toString(tokenId));
    }
}
/**======================================================================================
   .-'--`-._                           .-'--`-._                           .-'--`-._
   '-O---O--'                          '-O---O--'                          '-O---O--'
=========================================================================================*/