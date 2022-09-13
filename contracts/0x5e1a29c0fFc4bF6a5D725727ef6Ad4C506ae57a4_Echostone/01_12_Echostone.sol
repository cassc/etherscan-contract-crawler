// SPDX-License-Identifier: MIT
// Creator: twitter.com/0xNox_ETH

//               .;::::::::::::::::::::::::::::::;.
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;
//               ;KNNNWMMWMMMMMMWWNNNNNNNNNWMMMMMN:
//                .',oXMMMMMMMNk:''''''''';OMMMMMN:
//                 ,xNMMMMMMNk;            l00000k,
//               .lNMMMMMMNk;               .....  
//                'dXMMWNO;                ....... 
//                  'd0k;.                .dXXXXX0;
//               .,;;:lc;;;;;;;;;;;;;;;;;;c0MMMMMN:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWX:
//               .,;,;;;;;;;;;;;;;;;;;;;;;;;,;;,;,.
//               'dkxkkxxkkkkkkkkkkkkkkkkkkxxxkxkd'
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               'xkkkOOkkkkkkkkkkkkkkkkkkkkkkkkkx'
//                          .,,,,,,,,,,,,,,,,,,,,,.
//                        .lKNWWWWWWWWWWWWWWWWWWWX;
//                      .lKWMMMMMMMMMMMMMMMMMMMMMX;
//                    .lKWMMMMMMMMMMMMMMMMMMMMMMMN:
//                  .lKWMMMMMWKo:::::::::::::::::;.
//                .lKWMMMMMWKl.
//               .lNMMMMMWKl.
//                 ;kNMWKl.
//                   ;dl.
//
//               We vow to Protect
//               Against the powers of Darkness
//               To rain down Justice
//               Against all who seek to cause Harm
//               To heed the call of those in Need
//               To offer up our Arms
//               In body and name we give our Code
//               
//               FOR THE BLOCKCHAIN ⚔️

pragma solidity ^0.8.16;

import "./extensions/IERC721ABurnable.sol";
import "./extensions/ERC721AQueryable.sol";
import "./ICloneforceAirdropManager.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Echostone is Ownable, ReentrancyGuard, VRFConsumerBaseV2, ERC721AQueryable, IERC721ABurnable {
    event PermanentURI(string _value, uint256 indexed _id);

    VRFCoordinatorV2Interface private VRF_COORDINATOR;
    uint64 private _chainlinkSubscriptionId;
    bytes32 private _vrfKeyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    address private constant VRF_COORDINATOR_ADDR = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    uint32 private constant CHAINLINK_CALLBACK_GAS_LIMIT = 100000;
    uint16 private constant CHAINLINK_REQ_CONFIRMATIONS = 3;

    uint256 public constant MAX_SUPPLY = 5928;
    uint256 public constant PRICE = 0.05 ether;
    
    // Holds the # of remaining tokens for each DNA
    mapping(uint256 => uint256) public dnaToRemainingSupply;

    // Holds the # of remaining gold tokens for each DNA
    mapping(uint256 => uint256) public dnaToRemainingGoldSupply;

    // Holds the # of remaining tokens available for migration
    uint256 public remainingSupply = 5928;

    mapping(uint256 => uint256) private _randomnessRequestIdToTokenId;

    // 0: Migration still in progress or token not minted
    // 1: Human
    // 2: Robot
    // 3: Demon
    // 4: Angel
    // 5: Reptile
    // 6: Undead
    // 7: Alien
    // 8: XXXX
    mapping(uint256 => uint256) public tokenIdToDna;

    // 0: Migration still in progress or token not minted
    // 1: Not gold
    // 2: Gold
    mapping(uint256 => uint256) public tokenIdToIsGold;


    bool public mintstoneMigrationPaused;
    bool public contractPaused;

    string private _baseTokenURI;
    bool public baseURILocked;

    ICloneforceAirdropManager private AIRDROP_MANAGER;
    Mintstone2Contract private USED_MINTSTONE;
    MintstoneContract private MINTSTONE;
    address private _burnAuthorizedContract;
    
    address private _admin;

    constructor(
        string memory baseTokenURI,
        address admin,
        address mintstoneContract,
        address usedMintstoneContract,
        address airdropManagerContract,
        uint64 chainlinkSubscriptionId)
    VRFConsumerBaseV2(VRF_COORDINATOR_ADDR)
    ERC721A("CF EchoStone", "ECHOSTONE") {
        _chainlinkSubscriptionId = chainlinkSubscriptionId;
        _admin = admin;
        _baseTokenURI = baseTokenURI;
        mintstoneMigrationPaused = true;

        VRF_COORDINATOR = VRFCoordinatorV2Interface(VRF_COORDINATOR_ADDR);
        MINTSTONE = MintstoneContract(mintstoneContract);
        USED_MINTSTONE = Mintstone2Contract(usedMintstoneContract);
        AIRDROP_MANAGER = ICloneforceAirdropManager(airdropManagerContract);
        
        _initializeSupplies();

        _safeMint(msg.sender, 1);
        _setTokenMetadata(0, 1, 1); // Human - Not gold
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is another contract");
        _;
    }
    
    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "Not owner or admin");
        _;
    }

    function _initializeSupplies() private {
        dnaToRemainingSupply[1] = 1500;
        dnaToRemainingGoldSupply[1] = 150;

        dnaToRemainingSupply[2] = 1188;
        dnaToRemainingGoldSupply[2] = 118;

        dnaToRemainingSupply[3] = 960;
        dnaToRemainingGoldSupply[3] = 50;

        dnaToRemainingSupply[4] = 960;
        dnaToRemainingGoldSupply[4] = 50;

        dnaToRemainingSupply[5] = 650;
        dnaToRemainingGoldSupply[5] = 35;

        dnaToRemainingSupply[6] = 450;
        dnaToRemainingGoldSupply[6] = 25;

        dnaToRemainingSupply[7] = 220;
        dnaToRemainingGoldSupply[7] = 10;
    }

    // Starts the migration process of given Mintstones.
    // Note that migration is asynchronous; the Echostone will be minted but its metadata
    // will be assigned later (see `fulfillRandomWords`) when the on-chain randomness is produced.
    function startMintstoneMigration(uint256[] memory mintstoneIds)
        external
        payable
        nonReentrant
        callerIsUser
    {
        require(!mintstoneMigrationPaused && !contractPaused, "Migration is paused");

        uint256 price = PRICE * mintstoneIds.length;
        require(msg.value >= price, "Not enough ETH");

        uint256 i;
        for (i = 0; i < mintstoneIds.length;) {
            uint256 mintstoneId = mintstoneIds[i];
            // check if the msg sender is the owner
            require(MINTSTONE.ownerOf(mintstoneId) == msg.sender, "You don't own the given mintstone");

            // burn Mintstone
            MINTSTONE.burn(mintstoneId);

            // mint Mintstone 2 with the same id
            USED_MINTSTONE.mint(msg.sender, mintstoneId);

            unchecked { i++; }
        }

        // mint Echostones
        uint256 firstEchostoneId = _nextTokenId();
        _safeMint(msg.sender, mintstoneIds.length);

        // request random metadata for Echostones
        i = firstEchostoneId;
        unchecked {
            while (true) {
                if (i >= firstEchostoneId + mintstoneIds.length) { break; }
                
                _requestRandomMetadata(i);

                if (AIRDROP_MANAGER.hasAirdrops()) {
                    AIRDROP_MANAGER.claimAll(msg.sender, i);
                }

                i++;
            }
        }

        // refund excess ETH
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function _requestRandomMetadata(uint256 tokenId) private {
        // request a random number from Chainlink to give a random metadata to the token
        uint256 requestId = VRF_COORDINATOR.requestRandomWords(
            _vrfKeyHash,
            _chainlinkSubscriptionId,
            CHAINLINK_REQ_CONFIRMATIONS,
            CHAINLINK_CALLBACK_GAS_LIMIT,
            1);
        _randomnessRequestIdToTokenId[requestId] = tokenId;
    }

    // Will be used by an admin, only if Chainlink VRF request fails and needs a retry
    function retryMintstoneMigration(uint256 tokenId) external onlyOwnerOrAdmin {
        // request a random number from Chainlink to give a random DNA to the minted Echostone
        uint256 requestId = VRF_COORDINATOR.requestRandomWords(
            _vrfKeyHash,
            _chainlinkSubscriptionId,
            CHAINLINK_REQ_CONFIRMATIONS,
            CHAINLINK_CALLBACK_GAS_LIMIT,
            1);
        _randomnessRequestIdToTokenId[requestId] = tokenId;
    }

    // Called by Chainlink when requested randomness is ready
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 tokenId = _randomnessRequestIdToTokenId[requestId];
        require(tokenId > 0, "Invalid request id");
 
        unchecked {
            uint256 rand = randomWords[0];
            uint256 randForDna = rand % remainingSupply;

            uint256 j = 0;
            for (uint256 dna = 1; dna < 8; dna++) {
                uint256 remDnaSupply = dnaToRemainingSupply[dna];
                if (remDnaSupply <= 0) {
                    // DNA is completely minted
                    continue;
                }

                j += remDnaSupply;
                if (randForDna < j) {
                    // found the DNA to assign, check if it's gold or not
                    uint256 remGoldSupply = dnaToRemainingGoldSupply[dna];
                    uint256 randForGold = (rand / 10000) % remDnaSupply;
                    uint256 gold = randForGold < remGoldSupply ? 2 : 1;

                    // assign the metadata
                    _setTokenMetadata(tokenId, dna, gold);
                    break;
                }
            }
        }
    }

    function _setTokenMetadata(uint256 tokenId, uint256 dna, uint256 gold) private {
        require(tokenIdToDna[tokenId] == 0, "Token already has a DNA");

        tokenIdToDna[tokenId] = dna;
        tokenIdToIsGold[tokenId] = gold;

        unchecked {
            if (dna > 0 && dna < 8) {
                // regular DNA, adjust supplies

                dnaToRemainingSupply[dna]--;

                if (gold == 2) {
                    dnaToRemainingGoldSupply[dna]--;
                }

                remainingSupply--;
            }
        }
    }

    // Will be used by an admin, only if Chainlink VRF totally fails and we need to assign a metadata manually
    function setTokenMetadata(uint256 tokenId, uint256 dna, uint256 gold) external onlyOwnerOrAdmin {
        _setTokenMetadata(tokenId, dna, gold);
    }
    
    function getDna(uint256 tokenId) external view returns (uint256) {
        return tokenIdToDna[tokenId];
    }

    function isGold(uint256 tokenId) external view returns (uint256) {
        return tokenIdToIsGold[tokenId];
    }

    // Only the owner of the token and its approved operators, and the authorized contract
    // can call this function.
    function burn(uint256 tokenId) public virtual override {
        // Avoid unnecessary approvals for the authorized contract
        bool approvalCheck = msg.sender != _burnAuthorizedContract;
        _burn(tokenId, approvalCheck);
    }

    // Mints a secret Echostone ;)
    function mintSecret(uint256[] calldata tokenIds)
        external
        nonReentrant
        callerIsUser
    {
        require(tokenIds.length == 7, "Invalid tokens");

        unchecked {
            bool[] memory dnaSeen = new bool[](9);
            bool allGold = true;
            
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 tokenId = tokenIds[i];
                require(ownerOf(tokenId) == msg.sender, "You don't own the given token");

                uint256 dna = tokenIdToDna[tokenId];
                require(dna > 0 && dna < 8 && !dnaSeen[dna], "Invalid tokens");

                dnaSeen[dna] = true;
                if (tokenIdToIsGold[tokenId] < 2) {
                    allGold = false;
                }

                _burn(tokenId, false);
            }

            uint256 newId = _nextTokenId();
            _safeMint(msg.sender, 1);
            _setTokenMetadata(newId, 8, allGold ? 2 : 1);
        }
    }

    function pauseMintstoneMigration(bool paused) external onlyOwnerOrAdmin {
        mintstoneMigrationPaused = paused;
    }

    function pauseContract(bool paused) external onlyOwnerOrAdmin {
        contractPaused = paused;
    }

    function _beforeTokenTransfers(
        address /* from */,
        address /* to */,
        uint256 /* startTokenId */,
        uint256 /* quantity */
    ) internal virtual override {
        require(!contractPaused, "Contract is paused");
    }

    // Locks base token URI forever and emits PermanentURI for marketplaces (e.g. OpenSea)
    function lockBaseURI() external onlyOwnerOrAdmin {
        baseURILocked = true;
        for (uint256 i = 0; i < _nextTokenId(); i++) {
            if (_exists(i)) {
                emit PermanentURI(tokenURI(i), i);
            }
        }
    }

    function ownerMint(address to, uint256 quantity) external onlyOwnerOrAdmin {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Quantity exceeds supply");

        uint256 firstEchostoneId = _nextTokenId();
        _safeMint(to, quantity);
        
        for (uint256 i = firstEchostoneId; i < firstEchostoneId + quantity; i++) {
            _requestRandomMetadata(i);
        }
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwnerOrAdmin {
        require(!baseURILocked, "Base URI is locked");
        _baseTokenURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }
    
    function setMintstoneContract(address addr) external onlyOwnerOrAdmin {
        MINTSTONE = MintstoneContract(addr);
    }

    function setUsedMintstoneContract(address addr) external onlyOwnerOrAdmin {
        USED_MINTSTONE = Mintstone2Contract(addr);
    }

    function setAirdropManagerContract(address addr) external onlyOwnerOrAdmin {
        AIRDROP_MANAGER = ICloneforceAirdropManager(addr);
    }

    function setBurnAuthorizedContract(address authorizedContract) external onlyOwnerOrAdmin {
        _burnAuthorizedContract = authorizedContract;
    }
    
    function withdrawMoney(address to) external onlyOwnerOrAdmin {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // Sets the Chainlink subscription id
    function setChainlinkSubscriptionId(uint64 id) external onlyOwnerOrAdmin {
        _chainlinkSubscriptionId = id;
    }

    // Marketplace blocklist functions
    mapping(address => bool) private _marketplaceBlocklist;

    function approve(address to, uint256 tokenId) public virtual override(ERC721A, IERC721A) {
        require(_marketplaceBlocklist[to] == false, "Marketplace is blocked");
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721A, IERC721A) {
        require(_marketplaceBlocklist[operator] == false, "Marketplace is blocked");
        super.setApprovalForAll(operator, approved);
    }

    function blockMarketplace(address addr, bool blocked) public onlyOwnerOrAdmin {
        _marketplaceBlocklist[addr] = blocked;
    }

    // OpenSea metadata initialization
    function contractURI() public pure returns (string memory) {
        return "https://cloneforce.xyz/api/echostone/marketplace-metadata";
    }
}

interface MintstoneContract {
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface Mintstone2Contract {
    function mint(address to, uint256 tokenId) external;
}