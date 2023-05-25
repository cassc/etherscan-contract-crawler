pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract KiaSedona is VRFConsumerBase, ERC721Enumerable, Ownable {
    using Strings for uint256;

    address public constant LINK_TOKEN = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address public constant VRF_COORDINATOR = 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant LOT_SIZE = 500;
    uint256 public constant MAX_SUPPLY = 10000;
    address public immutable dona;
    uint8 public immutable donaDecimals;
    uint256 public immutable startBlock;

    string public tempURI;
    bytes32 public keyHash;
    uint256 public fee;

    event RoofSlap(uint256 indexed tokenId, address indexed slapper);
    event LotURISet(uint256 lotId, string uri);

    struct Lot {
        uint256 randomness;
        string uri;
    }

    mapping(uint256 => Lot) public lotData;
    // requestId => lotId
    mapping(bytes32 => uint256) public randomnessRequests;
    // tokenId => slap count
    mapping(uint256 => uint256) public slapCounter;

    constructor(address _donaToken, string memory _tempURI, uint256 _startBlock)
        VRFConsumerBase(VRF_COORDINATOR, LINK_TOKEN)
        ERC721("Jay Pegs Auto Mart", "JPAM")
    {
        dona = _donaToken;
        tempURI = _tempURI;
        startBlock = _startBlock;
        donaDecimals = ERC20(_donaToken).decimals();
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10**ERC20(LINK_TOKEN).decimals();
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 lotId = tokenId / LOT_SIZE;
        Lot storage lot = lotData[lotId];
        uint256 randomness = lot.randomness;
        string memory baseURI = lot.uri;
        if (randomness == 0 || bytes(baseURI).length == 0) return tempURI;

        return string(abi.encodePacked(baseURI, uriId(tokenId, randomness).toString()));
    }

    function roofSlap(uint256 tokenId) external {
        slapCounter[tokenId] += 1;
        emit RoofSlap(tokenId, msg.sender);
    }

    function mint(uint256 quantity) external {
        require(block.number >= startBlock, "Not started");
        require(quantity > 0, "Cannot mint 0");
        require(
            ERC20(dona).transferFrom(
                msg.sender,
                BURN_ADDRESS,
                quantity * 10**donaDecimals
            ),
            "cannot burn DONA"
        );

        uint256 tokenId = totalSupply();
        for(uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, tokenId + i);
        }
        // should never happen since there's only 10k DONA but better safe than sorry
        require(totalSupply() <= MAX_SUPPLY, "Max supply already minted");
    }

    function uriId(uint256 tokenId, uint256 randomness) public pure returns (uint256) {
        uint256 lotId = tokenId / LOT_SIZE;

        uint256 lotMin = lotId * LOT_SIZE;
        uint256 lotMax = lotMin + LOT_SIZE - 1;
        uint256 randomNumber = randomness % LOT_SIZE;
        uint256 randomizedTokenId = tokenId + randomNumber;
        if (randomizedTokenId > lotMax) {
            randomizedTokenId -= LOT_SIZE;
        }
        return randomizedTokenId;
    }

    function getRandomNumber(uint256 lotId) internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        requestId = requestRandomness(keyHash, fee);
        randomnessRequests[requestId] = lotId;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 lotId = randomnessRequests[requestId];
        Lot storage lot = lotData[lotId];
        lot.randomness = randomness;
    }

    // Admin functions

    function setLotURI(uint256 lotId, string memory uri) external onlyOwner returns (bytes32 requestId) {
        if (lotId > 0) {
            require(bytes(lotData[lotId - 1].uri).length > 0, "Previous lot not set");
        }

        Lot storage lot = lotData[lotId];
        lot.uri = uri;
        emit LotURISet(lotId, uri);

        if (lot.randomness == 0) return getRandomNumber(lotId);
    }

    function setLinkFee(uint256 newFee) external onlyOwner {
        fee = newFee;
    }

    function withdrawLink() external onlyOwner {
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }
}