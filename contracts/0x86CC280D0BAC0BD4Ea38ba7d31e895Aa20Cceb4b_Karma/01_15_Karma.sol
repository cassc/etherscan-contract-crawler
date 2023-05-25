// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IOCMKarmaVIPAllowList {
    // burn a Karma VIP Allow List for burnTokenAddress (ie account)
    function burnAllowListForAddress(address burnTokenAddress) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

interface IOCMDesserts {
    // typeId is dessertType
    function burnDessertForAddress(uint256 typeId, address burnTokenAddress) external;
    // id is dessertType
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

interface IOnChainMonkey {
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IOCMRenderingContract {
    function tokenURI(uint256 tokenId, uint256 offset) external view returns (string memory);
}


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

//
//
//  888    d8P                                          
//  888   d8P                                           
//  888  d8P                                            
//  888d88K      8888b.  888d888 88888b.d88b.   8888b.  
//  8888888b        "88b 888P"   888 "888 "88b     "88b 
//  888  Y88b   .d888888 888     888  888  888 .d888888 
//  888   Y88b  888  888 888     888  888  888 888  888 
//  888    Y88b "Y888888 888     888  888  888 "Y888888 
//                                                    
//                                                    
// Karma is the OnChainMonkey membership NFT
//
// Welcome to the Monkeyverse!
//

contract Karma is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 private constant DESSERT3_TYPE = 3;
    uint256 private constant MAX_KARMA3_ID = 30015; // via Dessert3, 5 K3 are from mint in 1-10000
    uint256 private nextKarma3Id = 30001; // next mint, does not exist yet
    uint256 private constant PUBLIC_MINT_SIZE = 10000;
    uint256 public maxMintPerAllowList = 2;
    uint256 private constant MAX_PUBLIC_MINT_PER_TXN = 10;

    uint256 public salePrice = 0.5 ether;
    uint256 private constant EATING_PRICE = 0.03 ether;
    uint256 public numKarmasMintedPublicMint  = 0; // Number of Minted Karmas (not from Desserts) by Public
    uint256 public numKarmasMintedManagerMint = 0; // Number of Minted Karmas (not from Desserts) by MintManager
    // numKarmasMintedPublicMint + numKarmasMintedManagerMint <= PUBLIC_MINT_SIZE

    uint256 public nextMintManagerTokenId = 10000; // next tokenId that mintManager will mint, only decrementing
    uint256 public minimumMintManagerTokenId = 9001; // minimum tokenId that mintManager can mint, 1000 allocated initally
    uint256 public randomOffset = 10000; // if set, 0-9999, 10000 is unset
    bytes32 private merkleRoot;

    bool public allowListNFTActive      = false;
    bool public allowListActive         = false;
    bool public publicSaleActive        = false;
    bool public dessertEatingActive     = false;
    bool public freeDessertEatingActive = false;    

    address public randomizerContract; // set in constructor, used for randomOffset
    address public mintManager; // can mint from the end
    address public missionManager; // can modify level
    address public daoAddress; 
    address public providerAddress;

    IOnChainMonkey private immutable ocm;
    IOCMDesserts private immutable dessert;
    IOCMKarmaVIPAllowList private immutable allowListNFT;
    IOCMRenderingContract private renderingContract;
    bool public renderingContractLocked = false;
    
    mapping(address => uint256) public earlyDessertList;
    mapping(address => uint256) private minted; // with allowlist

    mapping(uint256 => uint256) private ocmToKarma3;

    mapping(uint256 => uint256) public karmaLevel;
    mapping(uint256 => uint256) public genesisLevel;

    // tokenId mappings
    // 
    // Dessert Karma
    //   Karma1: 10001-20000
    //   Karma2: 20001-30000
    //   Karma3: 30001-30015
    //
    // Public Mint Karma: 1-10000 (contains 5 Karma3 too)
    //
    // mintManager can mint from 10000, decrementing

    modifier onlyMissionManager() {
        require(missionManager == _msgSender(), "caller is not mission manager");
        _;
    }

    modifier onlyMintManager() {
        require(mintManager == _msgSender(), "caller is not mint manager");
        _;
    }    

    modifier onlyDao() {
        require(daoAddress == _msgSender(), "caller is not DAO");
        _;
    }

    modifier whenAllowListNFTActive() {
        require(allowListNFTActive, "Allow list NFT is not active");
        _;
    }

    modifier notSmartContract() {
        require(msg.sender == tx.origin, "You cannot mint from smart contract");
        _;
    }

    event DessertEaten(uint256 karmaId, address eaterAddress);

    constructor(address ocmAddress, address dessertAddress, address allowListNFTAddress, 
            address randomizerAddress, address renderingAddress) ERC721("Karma", "KARMA") {
        ocm = IOnChainMonkey(ocmAddress);
        dessert = IOCMDesserts(dessertAddress);
        allowListNFT = IOCMKarmaVIPAllowList(allowListNFTAddress);
        renderingContract = IOCMRenderingContract(renderingAddress);
        randomizerContract = randomizerAddress; // set once only
        missionManager = msg.sender;
        mintManager = msg.sender;
    }

    //
    // 5 mint commands (external)
    //

    function mintManagerMint(address toAddress) external onlyMintManager {
        require(nextMintManagerTokenId >= minimumMintManagerTokenId, "not allocated for mint manager");
        _safeMint(toAddress, nextMintManagerTokenId);
        nextMintManagerTokenId--;
        numKarmasMintedManagerMint++;
    }

    function mintManagerMintQuantity(address toAddress, uint256 quantity) external onlyMintManager {
        require(nextMintManagerTokenId+1-quantity >= minimumMintManagerTokenId, "not allocated for mint manager");
        for(uint256 i=0; i<quantity; i++) {
            _safeMint(toAddress, nextMintManagerTokenId);
            nextMintManagerTokenId--;
        }
        numKarmasMintedManagerMint+=quantity;
    }

    function generalMint(uint256 numKarmas, bytes32[] calldata merkleProof) external payable nonReentrant notSmartContract {
        require(numKarmasMintedPublicMint + numKarmasMintedManagerMint + numKarmas <= PUBLIC_MINT_SIZE, "Minting exceeds max supply");
        require(numKarmas > 0, "Must mint > 0");
        require((salePrice * numKarmas) <= msg.value, "ETH not enough");
        require(numKarmasMintedPublicMint + numKarmas < minimumMintManagerTokenId, "reserved");
        if (publicSaleActive) {
            require(numKarmas <= MAX_PUBLIC_MINT_PER_TXN, "Exceeds max mint");
        } else {
            require(allowListActive, "Allow list is not active");
            require(onAllowList(msg.sender, merkleProof), "Not on allow list");
            require(minted[msg.sender] + numKarmas <= maxMintPerAllowList, "Exceeds max mint");
            minted[msg.sender] += numKarmas;
        }
        for (uint256 i = numKarmasMintedPublicMint + 1; i <= numKarmasMintedPublicMint + numKarmas; i++) {
            _safeMint(msg.sender, i);
        }
        numKarmasMintedPublicMint += numKarmas;  
    }

    // mint with Karma VIP Allow List NFT
    function allowListNFTMint() external payable whenAllowListNFTActive nonReentrant notSmartContract {
        require(allowListNFT.balanceOf(msg.sender, 1) > 0, "You do not have a Karma Allow List NFT");
        require(numKarmasMintedPublicMint + numKarmasMintedManagerMint < PUBLIC_MINT_SIZE, "Minting exceeds max supply");
        require(numKarmasMintedPublicMint + 1 < minimumMintManagerTokenId, "reserved for mint manager");
        require(salePrice <= msg.value, "ETH not enough");
        allowListNFT.burnAllowListForAddress(msg.sender);
        numKarmasMintedPublicMint++;
        _safeMint(msg.sender, numKarmasMintedPublicMint);
    }
 
    // dessertType is 1-3
    // monkeyId is 1-10000 
    function eatDessert(uint256 dessertType, uint256 monkeyId) external payable nonReentrant {
        require(dessertEatingActive, "Dessert is not served yet");
        require(ocm.ownerOf(monkeyId) == msg.sender, "You are not the owner of the monkey");
        require(dessert.balanceOf(msg.sender, dessertType) > 0, "You do not have the dessert");

        uint256 karmaId;
        if (dessertType == DESSERT3_TYPE) {
            require(nextKarma3Id <= MAX_KARMA3_ID, "No more Dessert3");
            require(ocmToKarma3[monkeyId] == 0, "Monkey already ate cake");
            karmaId = nextKarma3Id;
            ocmToKarma3[monkeyId] = karmaId;
            nextKarma3Id++;
        } else {
            karmaId = getKarmaId(dessertType, monkeyId);
            require(!_exists(karmaId), "Monkey already ate this type of dessert");
        }

        if (!freeDessertEatingActive) {
             if (earlyDessertList[msg.sender] > 0) {
                 earlyDessertList[msg.sender]--;
             } else {
                 require(EATING_PRICE <= msg.value, "ETH not enough");
             }
        }
        dessert.burnDessertForAddress(dessertType, msg.sender);
        _safeMint(msg.sender, karmaId);
        emit DessertEaten(karmaId, msg.sender); // need to listen and load image
    }

    //
    // Owner functions
    //    

    function setEarlyDessertList(address[] calldata addresses, uint256[] calldata quantity) external onlyOwner {
        for(uint256 i=0; i<addresses.length;i++) {
            earlyDessertList[addresses[i]] = quantity[i];
        }
    }

    function toggleDessertEatingActive() external onlyOwner {
        dessertEatingActive = !dessertEatingActive;
    }

    function setSalePrice(uint256 newSalePrice) external onlyOwner {
        salePrice = newSalePrice;
    }

    function setMaxMintPerAllowList(uint256 newMax) external onlyOwner {
        maxMintPerAllowList = newMax;
    }

    function toggleAllowListActive() external onlyOwner {
        allowListActive = !allowListActive;
    }

    function toggleAllowListNFTActive() external onlyOwner {
        allowListNFTActive= !allowListNFTActive;
    }

    function togglePublicSaleActive() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    // Enable on Sept 11, 2022
    function toggleFreeDessertEatingActive() external onlyOwner {
        freeDessertEatingActive = !freeDessertEatingActive;
    }

    function setMinimumMintManagerTokenId(uint256 karmaId) external onlyOwner {
        minimumMintManagerTokenId = karmaId;
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function setMintManager(address newAddress) external onlyOwner {
        mintManager = newAddress;
    }

    function setMissionManager(address newAddress) external onlyOwner {
        missionManager = newAddress;
    }

    function setDaoAddress(address newAddress) external onlyOwner {
        daoAddress = newAddress;
    }

    function setProviderAddress(address newAddress) external onlyOwner {
        providerAddress = newAddress;
    }

    // can only call once for Karma randomization for new 10000
    function setRandomOffset(uint256 offset) external onlyOwner {
        require(randomOffset >= 10000, "offset already set");
        randomOffset = offset % PUBLIC_MINT_SIZE;
    }

    function setRenderingContract(address renderingAddress) external onlyOwner {
        require(!renderingContractLocked, "renderContract locked");
        renderingContract = IOCMRenderingContract(renderingAddress);
    } 

    function lockRenderingContract() external onlyOwner {
        renderingContractLocked = true;
    }

    function ownerWithdraw() external onlyOwner nonReentrant {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function daoWithdraw() external onlyDao nonReentrant {
        uint256 value = address(this).balance/2;
        Address.sendValue(payable(daoAddress), value);
        Address.sendValue(payable(providerAddress), value);
    }

    // 
    // Mission Manager functions
    //

    function setKarmaLevels(uint256[] calldata tokenIds, uint256[] calldata levels) external onlyMissionManager {
        for(uint256 i=0; i<tokenIds.length; i++) {
            karmaLevel[tokenIds[i]] = levels[i];
        }
    }

    function setGenesisLevels(uint256[] calldata tokenIds, uint256[] calldata levels) external onlyMissionManager {
        for(uint256 i=0; i<tokenIds.length; i++) {
            genesisLevel[tokenIds[i]] = levels[i];
        }
    }

    //
    // public / external functions
    //

    // get KarmaId for a matching Genesis if it exists
    function getKarmaIdForMonkeyAndDessertCombination(uint256 monkeyId, uint8 dessertType) external view returns (uint256) {
        uint256 karmaId;
        if (dessertType == DESSERT3_TYPE) {
            karmaId = ocmToKarma3[monkeyId];
        } else {
            karmaId = getKarmaId(dessertType, monkeyId);
        }
        require(_exists(karmaId), "Query for nonexistent karma");
        return karmaId;
    }

    function hasMonkeyEatenDessertType(uint256 monkeyId, uint8 dessertType) external view returns (bool) {
        if (dessertType == DESSERT3_TYPE) {
            return ocmToKarma3[monkeyId] > 0;
        }
        uint256 karmaId = getKarmaId(dessertType, monkeyId);
        return _exists(karmaId);
    }    

    function isMinted(uint256 karmaId) external view returns (bool) {
        return _exists(karmaId);
    }    

    function totalKarmaFromDesserts() external view returns (uint256) {
        return totalSupply() - numKarmasMintedPublicMint - numKarmasMintedManagerMint;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return renderingContract.tokenURI(tokenId, randomOffset);
    }

    // users can verify that they are on the allow list
    function onAllowList(address addr, bytes32[] calldata merkleProof) public view returns (bool) {
        return MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(addr)));
    }

    //
    // internal functions
    //

    // only for Karma1 and Karma2 from Desserts, not for Karma3
    function getKarmaId(uint256 dessertType, uint256 monkeyId) internal pure returns (uint256) {
        require(dessertType != DESSERT3_TYPE, "karma3 ID can't be calculated");
        return dessertType * PUBLIC_MINT_SIZE + monkeyId;
    }

}