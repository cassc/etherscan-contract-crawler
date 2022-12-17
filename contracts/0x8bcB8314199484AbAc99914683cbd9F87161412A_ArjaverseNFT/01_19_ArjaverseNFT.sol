// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";
import "./ArjaverseNFTLibrary.sol";

interface IGroth16Verifier {
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[16] memory input
    ) external view returns (bool);
}

contract ArjaverseNFT is ERC721Enumerable, VRFConsumerBaseV2, Ownable {
    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;
    event AnswerResult(address indexed user, bool result);

    uint256 constant MAX_SUPPLY = 64;
    uint256 constant TEAM_RESERVE = 8;
    uint256 constant BATCH_SZIE = 8;

    // Metadata Traits
    string constant BACKGROUND = "Background";
    string constant SPECIAL_EFFECT = "SpecialEffect";
    string constant BODY = "Body";
    string constant DECORATION = "Decoration";
    string constant EYES = "Eyes";
    string constant BALL = "Ball";
    string[8] private backgroundTraits = [
        "9A9FA8",
        "FFEF5B",
        "D2BFDC",
        "D9EEA9",
        "D8D2CA",
        "FFE3ED",
        "00589A",
        "CAFCFB"
    ];

    string[6] private specialEffectTraits = [
        "RedWave",
        "ColorSpot",
        "Spotlight",
        "Ripple",
        "RingStars",
        "Stars"
    ];

    string[5] private bodyTraits = [
        "RibbonSeal",
        "BeardedSeal",
        "HarpSeal",
        "Arja",
        "JimmyTheSeal"
    ];

    string[17] private decorationTraits = [
        "Cowboy",
        "Seaweed",
        "PearlMilk",
        "BowTieHead",
        "Scarf02",
        "FriedG",
        "TailRing",
        "Splash",
        "Dress",
        "Scarf01",
        "BowTieNeck",
        "Fries",
        "MultiGoldenRings",
        "BowTieTail",
        "GoldenNacklace",
        "Scarf03",
        "Crown"
    ];

    string[6] private eyesTraits = [
        "DollarBills",
        "Sad",
        "LineShape",
        "Watery",
        "Lightening",
        "Dot"
    ];

    string[6] private ballTraits = [
        "VolleyBall",
        "Octopus",
        "Penguin",
        "Coin",
        "Flower",
        "StarRing"
    ];

    uint64[] private allPagination = [
        0x000000000000,
        0x010101000001,
        0x020102010102,
        0x030203010203,
        0x020104000000,
        0x030304020302,
        0x030305000004,
        0x000306020005,
        0x010106010402,
        0x040207030201,
        0x010308040205,
        0x040409040306,
        0x04050a000102,
        0x00010a000502,
        0x00000a020407,
        0x04000a030306,
        0x04020a000206,
        0x02050a020304,
        0x01020a030404,
        0x04030a010502,
        0x03000a040000,
        0x04050a000204,
        0x02020b000000,
        0x04010c020406,
        0x05050d030501,
        0x00000d030205,
        0x02030d020104,
        0x00010e000202,
        0x04010e010404,
        0x02050e000002,
        0x03010e000401,
        0x05030e030300,
        0x04020f010504,
        0x02020f040403,
        0x04040f000203,
        0x05020f010106,
        0x020010010403,
        0x050410010004,
        0x010310040201,
        0x010310040301,
        0x020410030003,
        0x040310040304,
        0x030210020007,
        0x010210040006,
        0x050410000404,
        0x050010020106,
        0x030110010202,
        0x030010000306,
        0x030110040201,
        0x000510000303,
        0x010310030505,
        0x010010030204,
        0x030410020002,
        0x020510010504,
        0x030310030402,
        0x030110040100,
        0x000010020200,
        0x010510020001,
        0x020510040304,
        0x050310040402,
        0x050410010003,
        0x010410040405,
        0x030210010402,
        0x030410000003
    ];

    uint256 currentTeamReserve = 0;
    uint256 currentRevealId = 1;
    mapping(uint256 => ArjaverseNFTLibrary.Metadata) public tokenIdToMetadata;
    string BASE_URI = "ipfs://QmfGCmsdebybNBWhqor2cxnJYUU89LgJ3KWLsj9veuhADZ/";
    string baseAnimationURI = "ipfs://QmSkahSGA9fe6AGkjvB4cbKeeiE8XJxh4hgxqaCp7UeGBr/";
    IGroth16Verifier verifier;

    // VRF
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    uint64 s_subscriptionId;
    bytes32 keyHash = 0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92; // 500 gwei
    uint32 callbackGasLimit = 2500000;
    uint16 requestConfirmations = 3;

    constructor(
        address _vrfCoordinator,
        address _link,
        address _verifier
    ) ERC721("Arjaverse NFT", "ARJA") VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(_link);
        verifier = IGroth16Verifier(_verifier);
    }

    function teamReserveMint(address _to, uint32 _num) external onlyOwner {
        require(totalSupply() + _num <= MAX_SUPPLY, "Exceeds max supply");
        require(currentTeamReserve + _num <= TEAM_RESERVE, "Exceeds team reserve");
        for(uint256 i = 0; i < _num; i++) {
            _mint(_to);
        }
        currentTeamReserve += _num;
    }

    function randomDistinctItemFromAllPagination(uint256 rand) private returns (uint64) {
        uint256 index = rand % allPagination.length;
        uint64 key = allPagination[index];
        allPagination[index] = allPagination[allPagination.length - 1];
        allPagination.pop();
        return key;
    }

    function getRandomWorkFromPagination(uint256 rand) private returns (ArjaverseNFTLibrary.Metadata memory) {
        uint64 key = randomDistinctItemFromAllPagination(rand);
        ArjaverseNFTLibrary.Metadata memory currentWord;

        currentWord.background = uint8(key & 0xFF);
        key = key >> 8;
        currentWord.effect = uint8(key & 0xFF);
        key = key >> 8;
        currentWord.body = uint8(key & 0xFF);
        key = key >> 8;
        currentWord.decoration = uint8(key & 0xFF);
        key = key >> 8;
        currentWord.eyes = uint8(key & 0xFF);
        key = key >> 8;
        currentWord.ball = uint8(key & 0xFF);

        currentWord.isRevealed = true;
        return currentWord;
    }

    function concatHref(
        string memory _baseURI,
        string memory _trait,
        string memory _traitArr
    ) internal pure returns (string memory) {
        return
            string(abi.encodePacked(_baseURI, _trait, "/", _traitArr, ".png"));
    }

    function _mint(address to) internal {
        _safeMint(to, totalSupply() + 1);
    }

    function rollupMint(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[16] memory input
    )
        external
        onlyOwner
    {
        require(
            verifier.verifyProof(a, b, c, input),
            "Proof verification failed"
        );
        require(totalSupply() + BATCH_SZIE <= MAX_SUPPLY, "Exceeds max supply");
        for(uint256 i = 0; i < BATCH_SZIE; i++) {
            address to = address(uint160(input[BATCH_SZIE + i]));
            bool result = (input[i] == 1);
            emit AnswerResult(to, result);
            if(result) {
                _mint(to);
            }
        }
    }

    function updateAnimationURI(string memory _newAnimationURI) external onlyOwner {
        baseAnimationURI = _newAnimationURI;
    }

    function setWord(uint256 tokenId, uint256 rand) internal {
        require(!tokenIdToMetadata[tokenId].isRevealed, "Already revealed");
        tokenIdToMetadata[tokenId] = getRandomWorkFromPagination(rand);
    }

    function getAttributesTopHalf(uint256 _tokenId)
        private 
        view
        returns (string memory)
    {
        ArjaverseNFTLibrary.Metadata memory currentWord = tokenIdToMetadata[_tokenId];
        return ArjaverseNFTLibrary.getAttributesLeft(
            backgroundTraits[currentWord.background],
            specialEffectTraits[currentWord.effect],
            bodyTraits[currentWord.body]
        );
    }

    function getAttributesBottomHalf(uint256 _tokenId)
        private
        view
        returns (string memory)
    {
        ArjaverseNFTLibrary.Metadata memory currentWord = tokenIdToMetadata[_tokenId];
        return ArjaverseNFTLibrary.getAttributesRight(
            decorationTraits[currentWord.decoration],
            eyesTraits[currentWord.eyes],
            ballTraits[currentWord.ball]
        );
    }

    function getAnimationUrl(uint256 _tokenId) private view returns (bytes memory) {
        string memory token = Strings.toString(_tokenId);
        ArjaverseNFTLibrary.Metadata memory currentWord = tokenIdToMetadata[_tokenId];
        return abi.encodePacked(
            baseAnimationURI,
            '?bg=', backgroundTraits[currentWord.background],
            '&ball=', ballTraits[currentWord.ball],
            '&id=', token
        );
    }

    function buildMetadata(uint256 _tokenId)
        private
        view
        returns (string memory)
    {
        string memory token = Strings.toString(_tokenId);
        ArjaverseNFTLibrary.Metadata memory currentWord = tokenIdToMetadata[_tokenId];
        bytes memory imageHash = abi.encodePacked(
            currentWord.background.toString(), '-',
            currentWord.effect.toString(), '-',
            currentWord.body.toString(), '-',
            currentWord.decoration.toString(), '-',
            currentWord.eyes.toString(), '-',
            currentWord.ball.toString()
        );
        
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{ "name": "',"Arjaverse #", token,
                                '","image": "',BASE_URI, imageHash, '.png',
                                '","attributes": [',
                                        getAttributesTopHalf(_tokenId),
                                        getAttributesBottomHalf(_tokenId),
                                    ']',
                                ',"animation_url":"',getAnimationUrl(_tokenId),'"'
                                ',"description": "A mysterious creature of immense size appears in the galaxy, floating out of nowhere and slowly approaching Earth.\\nSuddenly! A mouth opened, and the Earth was unexpectedly swallowed up in an instant, emitting an unknown light - BANG! The Seal explodes!\\nFrom then on, a planet full of sea otters was born - the Arjaverse!\\nThe planet is 75% water, ice, and gems, and its exterior retains the appearance of Earth and the unknown creature, becoming a fantastical illusion.\\nThis gave rise to the incredibly cute and unique adventurers - the seal citizens from Arjaverse."',
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return buildMetadata(_tokenId);
    }


    // VRF
    function setSubscriptionId(uint64 subscriptionId) public onlyOwner {
        s_subscriptionId = subscriptionId;
    }

    function setKeyHash(bytes32 _keyHash) public onlyOwner {
        keyHash = _keyHash;
    }

    function setVrfCallbackGasLimit(uint32 _callbackGasLimit) public onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    function requestRandomWords(uint32 numWords) internal {
        COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256,
        uint256[] memory randomWords
    ) internal override {
        for(uint256 index = 0; index < randomWords.length; index++) {
            uint256 rand = randomWords[index];
            setWord(currentRevealId + index, rand);
        }
        currentRevealId += randomWords.length;
    }

    function reveal(uint32 _num) external onlyOwner {
        require(currentRevealId <= MAX_SUPPLY, "All NFT revealed");
        requestRandomWords(_num);
    }
}