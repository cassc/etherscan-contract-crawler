// SPDX-License-Identifier: MIT

/**

  GGGG  LL      IIIII  CCCCC  PPPPPP  IIIII XX    XX XX    XX XX    XX VV     VV EEEEEEE RRRRRR   00000   00000   2222   
 GG  GG LL       III  CC    C PP   PP  III   XX  XX   XX  XX   XX  XX  VV     VV EE      RR   RR 00   00 00   00 222222  
GG      LL       III  CC      PPPPPP   III    XXXX     XXXX     XXXX    VV   VV  EEEEE   RRRRRR  00   00 00   00     222 
GG   GG LL       III  CC    C PP       III   XX  XX   XX  XX   XX  XX    VV VV   EE      RR  RR  00   00 00   00  2222   
 GGGGGG LLLLLLL IIIII  CCCCC  PP      IIIII XX    XX XX    XX XX    XX    VVV    EEEEEEE RR   RR  00000   00000  2222222 


BERK AKA PRINCESS CAMEL SAYS HI

I WANNA THANK YOU BASTARDS AND FOR EMBRACING THE BASTARDNESS, BEING GOOD PEOPLE AND FORMING A BADA$$ FRIENDLY HELPFUL COMMUNITY

THIS PROJECT IS BOTH A GIFT TO ALL OF YOU (INCLUDING GLICPIXXXVER001 HOLDERS), ALSO AN EXPERIMENT TO HAVE A GOOD CONTRIBUTION TO CONTEMPORARY/FUTURE VISUAL CULTURE AND BOOST CREATIVITY IN NFT SPACE

EVERYTHING IS A REMIX
EVERY DIGITAL THING WE USE IS A SOFTWARE
EVERY TECHNOLOGY IS BIASED
EVERY DIGITAL MEDIA IS ENCODED WITH THOSE BIASES

ROSES ARE BLUE
& VIOLETS ARE RED
I AM GREEN
IS YOUR GLICPIXXX PURPLE?

XOXO

https://berkozdemir.com
@berkozdemir

Website:
https://glicpixxx.love/

ALSO CHECK GLICPIXXXVER001 CONTRACT: 0xba15Eb922FEb96D017e1B2ac0d6fF04044A611BB

SPECIAL THANKS TO:

@snooplyin @idiots.guide.LFG @JosephMerrick @rooster_m @rsn-16 @Shazman3 FOR WORKING ON BOOMER CALM AF GLIC PATTERN METADATA TRAIT

@kodbilen FOR HELPING WITH API
@memorycollect0r FOR HELPING WITH SOME TECHNICAL STUFF

@witrebel FOR SAVING THE PROJECT'S ASS BY NOTICING MISSING IPFS HASHES ON PROVENANCE JUST BEFORE THE LAUNCH. I HAD TO RENOUNCE OWNERSHIP OF THE PREVIOUS CONTRACT.

I HOPE I DIDN'T FORGET ANYONE ELSE

IF I DID, SORRY

*/

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ClaimFromERC721 {
    function ownerOf(uint _id) external view returns (address);
}

contract GLICPIXXXVER002 is ERC721Enumerable, Ownable, VRFConsumerBase {

string public _baseTokenURI;

// VRF SHIT

bytes32 internal keyHash;
uint256 internal fee;

// IMPORTANT STUFF REGARDING MINTING

bool public claimRunning = false;
bool public mintStartIndexDrawn = false;

uint256 public mintStartIndex; // IS DETERMINED WITH FUCKIN' VRF

// THESE ARE FOR MINT ID CALCULATION AFTER MINTSTARTINDEX IS DRAWN

uint256 public BGANPUNKSV1CLAIMSTART = 0; // 74 BGANPUNKS V1
uint256 public BGANPUNKSV2CLAIMSTART = 74; // 11305 BGANPUNKS V2 - 0 + 74
uint256 public GLICPIXV1CLAIMSTART = 11379; // 37 GLICPIXXX - 11305 + 74
uint256 public DEVMINTSTART = 11416; // 84 DEVMINT - 11379 + 37
uint256 public totalGLICPIX = 11500; // 11416 + 84

// FUCK YEAH

string public GLICPIXXXIMAGEPROVENANCEIPFSHASH = "QmbmnyfNjuDoStWVpozx2GLpEbn4VJg7RWJwkMAJMQu1jv";

mapping (uint256 => uint256) public V1BASTARDIDs; // RARIBLE SMART CONTRACTS LOVE TO PUT WEIRD ID NUMBERS FOR MINTS, SO I AM KEEPING A MAPPING TO ASSIGN IDS TO 0,1,2,3...

// MMMMMHHHHH VERY SEXY ADDRESSES

address public BGANPUNKSV1ADDRESS = 0x9126B817CCca682BeaA9f4EaE734948EE1166Af1;
address public BGANPUNKSV2ADDRESS = 0x31385d3520bCED94f77AaE104b406994D8F2168C;
address public GLICPIXV1ADDRESS = 0xba15Eb922FEb96D017e1B2ac0d6fF04044A611BB;

enum CollectionToClaim {
    BGANPUNKSV1,
    BGANPUNKSV2,
    GLICPIXV1,
    DEVMINT
}

event glicpixv2Claimed(CollectionToClaim _collection, uint256 tokenId, uint256 glicpixv2idBeingMinted, address _claimer);
event randomStartingIndexDrawn(uint256 mintStartIndex);

/**

CHAINLINK VRF MAINNET STUFF

0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
fee = 2 * 10 ** 18; // 2 LINK (Varies by network)

*/

constructor() 
    ERC721("GLICPIXXXVER002 - GRAND COLLECTION", "GLICPIXXXVER002")
    VRFConsumerBase(
        0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
        0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
    )
    {
    keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    fee = 2 * 10 ** 18; // 0.1 LINK (Varies by network)
    
    V1BASTARDIDs[5389] = 0;
    V1BASTARDIDs[10001] = 1;
    V1BASTARDIDs[10003] = 2;
    V1BASTARDIDs[10004] = 3;
    V1BASTARDIDs[10005] = 4;
    V1BASTARDIDs[10006] = 5;
    V1BASTARDIDs[10007] = 6;
    V1BASTARDIDs[10008] = 7;
    V1BASTARDIDs[10009] = 8;
    V1BASTARDIDs[10012] = 9;
    V1BASTARDIDs[10013] = 10;
    V1BASTARDIDs[10015] = 11;
    V1BASTARDIDs[10016] = 12;
    V1BASTARDIDs[10017] = 13;
    V1BASTARDIDs[10018] = 14;
    V1BASTARDIDs[10019] = 15;
    V1BASTARDIDs[10020] = 16;
    V1BASTARDIDs[10021] = 17;
    V1BASTARDIDs[10022] = 18;
    V1BASTARDIDs[10023] = 19;
    V1BASTARDIDs[10024] = 20;
    V1BASTARDIDs[10026] = 21;
    V1BASTARDIDs[10031] = 22;
    V1BASTARDIDs[10032] = 23;
    V1BASTARDIDs[10033] = 24;
    V1BASTARDIDs[10034] = 25;
    V1BASTARDIDs[10035] = 26;
    V1BASTARDIDs[10036] = 27;
    V1BASTARDIDs[10037] = 28;
    V1BASTARDIDs[10038] = 29;
    V1BASTARDIDs[10039] = 30;
    V1BASTARDIDs[10040] = 31;
    V1BASTARDIDs[10041] = 32;
    V1BASTARDIDs[10043] = 33;
    V1BASTARDIDs[10045] = 34;
    V1BASTARDIDs[10046] = 35;
    V1BASTARDIDs[10047] = 36;
    V1BASTARDIDs[10048] = 37;
    V1BASTARDIDs[10049] = 38;
    V1BASTARDIDs[10050] = 39;
    V1BASTARDIDs[10051] = 40;
    V1BASTARDIDs[10053] = 41;
    V1BASTARDIDs[10054] = 42;
    V1BASTARDIDs[10055] = 43;
    V1BASTARDIDs[10056] = 44;
    V1BASTARDIDs[10057] = 45;
    V1BASTARDIDs[10058] = 46;
    V1BASTARDIDs[10059] = 47;
    V1BASTARDIDs[10061] = 48;
    V1BASTARDIDs[10062] = 49;
    V1BASTARDIDs[10063] = 50;
    V1BASTARDIDs[10064] = 51;
    V1BASTARDIDs[10067] = 52;
    V1BASTARDIDs[10068] = 53;
    V1BASTARDIDs[10070] = 54;
    V1BASTARDIDs[10075] = 55;
    V1BASTARDIDs[10076] = 56;
    V1BASTARDIDs[10077] = 57;
    V1BASTARDIDs[10078] = 58;
    V1BASTARDIDs[10079] = 59;
    V1BASTARDIDs[10080] = 60;
    V1BASTARDIDs[10081] = 61;
    V1BASTARDIDs[10083] = 62;
    V1BASTARDIDs[10084] = 63;
    V1BASTARDIDs[10085] = 64;
    V1BASTARDIDs[10086] = 65;
    V1BASTARDIDs[10087] = 66;
    V1BASTARDIDs[10088] = 67;
    V1BASTARDIDs[10089] = 68;
    V1BASTARDIDs[10090] = 69;
    V1BASTARDIDs[10091] = 70;
    V1BASTARDIDs[10093] = 71;
    V1BASTARDIDs[10094] = 72;
    V1BASTARDIDs[10095] = 73;
    }

    function showLicense(uint _id) public view returns(string memory) {
        require(_id < totalGLICPIX, "CHOOSE A GLICPIXXX INSIDE RANGE");
        return "IF YOU OWN A GLICPIXXX, YOU CAN DO WHATEVER THE FUCK YOU WANT WITH IT! YOUR GLICPIXXX, YOUR CALL. MAKE GLICPIXXX YOUR BEST FRIEND. MAKE WONDERS WITH IT. XOXO";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function startClaim() public onlyOwner {
        require(mintStartIndexDrawn, "RANDOM NUMBER STILL HASN'T DRAWN");
        claimRunning = true;
    }
    
    function pauseClaim() public onlyOwner {
        claimRunning = false;
    }

    // I REMOVED TOKENSOFOWNER FUNCTION BECAUSE I RAN OUT OF BYTESIZE FOR DEPLOYING THE CONTRACT. 
    // IF YOU NEED THIS FUNCTION FOR YOUR FRONTEND, USE THIS CONTRACT FROM GENIUS 0XMONS CREATOR WHERE YOU CAN GET IDS A WALLET OWNS FROM ANY ERC721 CONTRACT
    // ADDRESS: 0xF83eEE39E723526605d784917b6e38ebCF0f0207
    
    // function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
    //     uint256 tokenCount = balanceOf(_owner);
    //     if (tokenCount == 0) {
    //         // Return an empty array
    //         return new uint256[](0);
    //     } else {
    //         uint256[] memory result = new uint256[](tokenCount);
    //         uint256 index;
    //         for (index = 0; index < tokenCount; index++) {
    //             result[index] = tokenOfOwnerByIndex(_owner, index);
    //         }
    //         return result;
    //     }
    // }
    
    // YEAH ALSO I HAD TO COMMENT THIS FUNCTION CAUSE THERE WASN'T ANY SPACE LEFT

    // function calculateStartingIndexPerCollection(CollectionToClaim _collection)  public view returns(uint256){
        
    //     if(_collection == CollectionToClaim.BGANPUNKSV1) {
    //         return (BGANPUNKSV1CLAIMSTART + mintStartIndex) % totalGLICPIX;
    //     }
    //     else if (_collection == CollectionToClaim.BGANPUNKSV2) {
    //         return (BGANPUNKSV2CLAIMSTART + mintStartIndex) % totalGLICPIX;
    //     }
    //     else if (_collection == CollectionToClaim.GLICPIXV1) {
    //         return (GLICPIXV1CLAIMSTART + mintStartIndex) % totalGLICPIX;
    //     }
    //     else if (_collection == CollectionToClaim.DEVMINT) {
    //         return (DEVMINTSTART + mintStartIndex) % totalGLICPIX;
    //     }
    //     else {
    //         revert();
    //     }
        
    // }
    
    // I THINK THE NAME IS SUPER CLEAR LMAO

     function getWhichGLICPIXXYouAreGetting_BATCH(CollectionToClaim _collection, uint256[] memory tokenIds) public view returns(uint256[] memory) {
        require(mintStartIndexDrawn);
        
        uint256[] memory ids = new uint256[](tokenIds.length);

        if(_collection == CollectionToClaim.BGANPUNKSV1) {
            for(uint i = 0; i<tokenIds.length;i++) {
                uint tokenId = tokenIds[i];
                require(tokenId == 5389 || V1BASTARDIDs[tokenId] != 0);
                ids[i]= (V1BASTARDIDs[tokenId] + BGANPUNKSV1CLAIMSTART + mintStartIndex) % totalGLICPIX;
            }
        }
        else if (_collection == CollectionToClaim.BGANPUNKSV2) {
            for(uint i = 0; i<tokenIds.length;i++) {
                uint tokenId = tokenIds[i];
                require(tokenId < 11305);
                ids[i] = (tokenId + BGANPUNKSV2CLAIMSTART + mintStartIndex) % totalGLICPIX;
            }
        }
        else if (_collection == CollectionToClaim.GLICPIXV1) {
            for(uint i = 0; i<tokenIds.length;i++) {
                uint tokenId = tokenIds[i];
                require(tokenId < 37);
                ids[i] = (tokenId + GLICPIXV1CLAIMSTART + mintStartIndex) % totalGLICPIX;
            }
        }
        else if (_collection == CollectionToClaim.DEVMINT) {
            for(uint i = 0; i<tokenIds.length;i++) {
                uint tokenId = tokenIds[i];
                require(tokenId < 84);
                ids[i] = (tokenId + DEVMINTSTART + mintStartIndex) % totalGLICPIX;

            }
        }
        else {
            revert();
        }
        
        return ids;       
        
    }
    
    // ARE THE GLICPIXXX CLAIMED BOOLEAN
    
    function isGLICPIXXXTaken_BATCH(CollectionToClaim _collection, uint256[] memory tokenIds) public view returns(bool[] memory) {
        uint256[] memory ids = getWhichGLICPIXXYouAreGetting_BATCH(_collection, tokenIds);
        bool[] memory isit = new bool[](tokenIds.length);
        for(uint i = 0; i<tokenIds.length;i++) {
            isit[i] = _exists(ids[i]);
        }
        return isit;
    }
    
    // BERK GETS SOME SWEET SNACKS

    function devMint_BATCH(uint256[] memory tokenIds , address _mintTo) public onlyOwner {
        require(claimRunning && mintStartIndexDrawn);
        for(uint i = 0; i<tokenIds.length;i++) {
            uint tokenId = tokenIds[i];
            require(tokenId < 84);
            uint glicpixv2idBeingMinted = (tokenId + DEVMINTSTART + mintStartIndex) % totalGLICPIX;
            _safeMint(_mintTo, glicpixv2idBeingMinted);
            emit glicpixv2Claimed(CollectionToClaim.DEVMINT, tokenId, glicpixv2idBeingMinted, _mintTo);
        }
    }


    // PEOPLE GET SOME SWEET GLITCHY SNACKS

    function mintGLICPIXV2_BATCH(CollectionToClaim _collection, uint256[] memory tokenIds) public {
        
        require(claimRunning && mintStartIndexDrawn);
        require(tokenIds.length > 0 && tokenIds.length <= 30);

        if(_collection == CollectionToClaim.BGANPUNKSV1) {
            for(uint i = 0; i<tokenIds.length;i++) {
                uint tokenId = tokenIds[i];
                require(tokenId == 5389 || V1BASTARDIDs[tokenId] != 0);
                require(ClaimFromERC721(BGANPUNKSV1ADDRESS).ownerOf(tokenId) == msg.sender);
                uint glicpixv2idBeingMinted = (V1BASTARDIDs[tokenId] + BGANPUNKSV1CLAIMSTART + mintStartIndex) % totalGLICPIX;
                _safeMint(msg.sender, glicpixv2idBeingMinted);
                emit glicpixv2Claimed(_collection, tokenId, glicpixv2idBeingMinted, msg.sender);
            }
        }
        else if (_collection == CollectionToClaim.BGANPUNKSV2) {
            for(uint i = 0; i<tokenIds.length;i++) {
                uint tokenId = tokenIds[i];
                require(tokenId < 11305);
                require(ClaimFromERC721(BGANPUNKSV2ADDRESS).ownerOf(tokenId) == msg.sender);
                uint glicpixv2idBeingMinted = (tokenId + BGANPUNKSV2CLAIMSTART + mintStartIndex) % totalGLICPIX;
                _safeMint(msg.sender, glicpixv2idBeingMinted);
                emit glicpixv2Claimed(_collection, tokenId, glicpixv2idBeingMinted, msg.sender);
            }
        }
        
        else if (_collection == CollectionToClaim.GLICPIXV1) {
            for(uint i = 0; i<tokenIds.length;i++) {
                uint tokenId = tokenIds[i];
                require(tokenId < 37);
                require(ClaimFromERC721(GLICPIXV1ADDRESS).ownerOf(tokenId) == msg.sender);
                uint glicpixv2idBeingMinted = (tokenId + GLICPIXV1CLAIMSTART + mintStartIndex) % totalGLICPIX;
                _safeMint(msg.sender, glicpixv2idBeingMinted);
                emit glicpixv2Claimed(_collection, tokenId, glicpixv2idBeingMinted, msg.sender);
            }
        }
        
        else {
            revert();
        }
    
    }
    
    // THIS IS CALLED ONLY ONCE BEFORE CLAIMS ARE OPENED. THE FUNCTIONS BELOW REQUEST A RANDOM NUMBER FROM CHAINLINK TO SHIFT WHICH NFT CAN CLAIM WHICH GLICPIX
    
    /** 
     * Requests randomness 
     */
    function setRandomNumberForStartingIndexOfMintIds() public onlyOwner returns (bytes32 requestId) {
        require(!mintStartIndexDrawn , "RNG ALREADY DRAWN");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
     
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        mintStartIndex = randomness % totalGLICPIX;
        if(mintStartIndex == 0) {
            mintStartIndex = 1;
        }

        emit randomStartingIndexDrawn(mintStartIndex);

        mintStartIndexDrawn = true;
    }

    function withdrawLink() external onlyOwner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    } 
    
    
    // COMMENT THIS FUNCTION ON PRODUCTION. ONLY FOR TESTING
    
    // function testt() public onlyOwner{
    //     mintStartIndex = 2000;
    //     mintStartIndexDrawn = true;
    // }
}