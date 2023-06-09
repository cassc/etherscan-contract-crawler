/*

$$$$$$$\  $$$$$$$$\  $$$$$$\  $$$$$$$$\ $$\      $$\ $$$$$$$$\ $$$$$$$\   $$$$$$\ $$$$$$$$\ $$$$$$$$\  $$$$$$\  
$$  __$$\ $$  _____|$$  __$$\ $$  _____|$$$\    $$$ |$$  _____|$$  __$$\ $$  __$$\\__$$  __|$$  _____|$$  __$$\ 
$$ |  $$ |$$ |      $$ /  \__|$$ |      $$$$\  $$$$ |$$ |      $$ |  $$ |$$ /  $$ |  $$ |   $$ |      $$ /  \__|
$$ |  $$ |$$$$$\    $$ |$$$$\ $$$$$\    $$\$$\$$ $$ |$$$$$\    $$$$$$$  |$$$$$$$$ |  $$ |   $$$$$\    \$$$$$$\  
$$ |  $$ |$$  __|   $$ |\_$$ |$$  __|   $$ \$$$  $$ |$$  __|   $$  __$$< $$  __$$ |  $$ |   $$  __|    \____$$\ 
$$ |  $$ |$$ |      $$ |  $$ |$$ |      $$ |\$  /$$ |$$ |      $$ |  $$ |$$ |  $$ |  $$ |   $$ |      $$\   $$ |
$$$$$$$  |$$$$$$$$\ \$$$$$$  |$$$$$$$$\ $$ | \_/ $$ |$$$$$$$$\ $$ |  $$ |$$ |  $$ |  $$ |   $$$$$$$$\ \$$$$$$  |
\_______/ \________| \______/ \________|\__|     \__|\________|\__|  \__|\__|  \__|  \__|   \________| \______/ 
                                                                                                                
                                                                                                                
                                                                                                                
Degemerates - The NFT Collection for the shameless degenerate.
https://Degemerates.com

Twitter: @Degemerates

*/

pragma solidity ^0.8.9;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract DeGems is VRFConsumerBaseV2, ERC721A, Ownable, ReentrancyGuard {
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 subscriptionId;
    address public vrfCoordinator;
    bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef; //eth mainnet 200 gwei hash
    uint32 callbackGasLimit = 500_000;
    uint16 requestConfirmations = 3;
    string public baseTokenURI;
    string public baseTokenRemote = "https://degemerates.com/api/metadata?id=";
    bool public baseTokenURILocked = false;
    bool public mintActive = true; 

    uint256 public constant SOFTCAP = 500; //500 max supply, IF atleast 3 diamonds minted
    uint256 public constant MIN_DIAMONDS = 3;

    uint256 public numMinted = 0;

    uint256 public MINT_PRICE = 0.2 ether;
    uint256 private constant MIN_MINT_PRICE = 0.1 ether; // 0.1 Ether
    uint256 private constant INCREMENT = 0.01 ether;

    uint256 public NUM_DIAMONDS_MINTED = 0;

    enum GemType {
        Diamond,
        Ruby,
        Emerald,
        Sapphire,
        Amethyst
    }

    struct TokenMetadata {
        uint256 mintSent;
        uint256 mintCost;
        GemType gem;
        address minter;
    }

    struct Request {
        address user;
        uint256 sentEther;
    }

    mapping(uint256 => TokenMetadata) public tokenMetadata;
    mapping(uint256 => Request) public requests;

    event BaseTokenURIChanged(string oldURI, string newURI);
    event GemMinted(
        address indexed user,
        uint256 amountSent,
        uint256 mintCost,
        GemType gemType,
        uint256 tokenId
    );
    event Refunded(address indexed user, uint refundAmount);
    event RequestedRandomness(uint256 reqId);
    event BraindeadPresaleAttempt(address indexed user, uint256 amountSent);

    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator
    ) ERC721A("Degemerates", "DEGEMS") VRFConsumerBaseV2(_vrfCoordinator) {
        vrfCoordinator = _vrfCoordinator;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        subscriptionId = _subscriptionId;
    }

    //This aint no Ben send me eth presale. If idiots want to send eth to this address, I'll allow it.
    receive() external payable {
        emit BraindeadPresaleAttempt(msg.sender, msg.value);
    }

    function checkCanMint() internal view {
        require(mintActive, "Minting is not active.");
        require(msg.value >= MINT_PRICE, "Did not send enough to mint.");
        require(
            numMinted < SOFTCAP || NUM_DIAMONDS_MINTED < MIN_DIAMONDS,
            "Sold Out!"
        );
    }

    function mintComplete() public view returns (bool) {
        return numMinted >= SOFTCAP && NUM_DIAMONDS_MINTED >= MIN_DIAMONDS;
    }

    function mint() external payable {
        //Max 1 at a time can be minted
        checkCanMint();
        //Increment a minted counter, the value of _totalMinted is not accurate yet, as there is a delay in it minting. Using a minting counter lets us maintain accuracy even during a surge.
        uint256 reqId = requestRandomness();
        numMinted++;
        requests[reqId] = Request(msg.sender, msg.value);
    }

    function setMintActive(bool _mintActive) external onlyOwner {
        mintActive = _mintActive;
    }

    function getGemType(
        uint256 randomNumber,
        uint256 sentEther
    ) private view returns (GemType) {
        uint256 randMod = randomNumber % 1000;
        uint256 diamondBoost = 0;

        if (sentEther > 1 ether) {
            diamondBoost = (sentEther - 1 ether) / 100000000000000000;
        }

        if (randMod < (10 + diamondBoost)) {
            // 1% base chance + diamondBoost
            return GemType.Diamond;
        } else if (randMod < 100) {
            // 9% chance
            return GemType.Ruby;
        } else if (randMod < 300) {
            // 20% chance
            return GemType.Emerald;
        } else if (randMod < 600) {
            // 30% chance
            return GemType.Sapphire;
        } else {
            // 40% chance
            return GemType.Amethyst;
        }
    }

    function requestRandomness() private returns (uint256 reqID) {
        reqID = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            2
        );
        emit RequestedRandomness(reqID);
        return reqID;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override nonReentrant {
        Request memory request = requests[requestId];
        address user = request.user;
        uint randNum = randomWords[0];
        uint256 sentEther = request.sentEther;
        uint256 randomMintPrice = MIN_MINT_PRICE +
            ((randomWords[1] %
                (((sentEther - MIN_MINT_PRICE) / INCREMENT) + 1)) * INCREMENT);

        uint256 refund = sentEther - randomMintPrice;
        uint256 tokenId = _nextTokenId();
        _mint(user, 1);
        GemType gemType = getGemType(randNum, request.sentEther);
        if (gemType == GemType.Diamond) {
            NUM_DIAMONDS_MINTED++;
        }

        tokenMetadata[tokenId] = TokenMetadata(
            sentEther,
            randomMintPrice,
            gemType,
            user
        );

        if (refund > 0) {
            (bool success, ) = user.call{value: refund}("");
            emit Refunded(user, refund);
            require(success, "Refund failed");
        }

        emit GemMinted(user, sentEther, randomMintPrice, gemType, tokenId);
        delete requests[requestId];
    }

    function triggerRequestAgain(uint256 requestId) public onlyOwner {
        //Not even sure if it could happen, but if Chainlink fails to fulfill the request, this allows re-requesting to try and prevent it from getting stuck. Should never need to call this.
        //Cant be called if the initial mint Chainlink request is fulfilled

        //require requests[requestId] to exist
        require(
            requests[requestId].user != address(0),
            "Request does not exist"
        );
        Request memory request = requests[requestId];

        uint256 newRequest = requestRandomness();
        requests[newRequest] = Request(request.user, request.sentEther);
        delete requests[requestId];
    }

    function getTokenMetadata(
        uint256 tokenId
    ) external view returns (TokenMetadata memory) {
        return tokenMetadata[tokenId];
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        require(!baseTokenURILocked, "Base Token URI is locked from changing.");

        emit BaseTokenURIChanged(baseTokenURI, _baseTokenURI);
        baseTokenURI = _baseTokenURI;
    }

    function lockBaseTokenURI() external onlyOwner {
        baseTokenURILocked = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        if (bytes(baseTokenURI).length > 0) {
            return baseTokenURI;
        } else {
            return baseTokenRemote;
        }
    }

    function withdrawContract() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}