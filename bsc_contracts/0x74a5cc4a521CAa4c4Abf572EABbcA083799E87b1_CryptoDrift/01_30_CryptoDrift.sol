// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./ITypes.sol";

contract CryptoDrift is ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable,PausableUpgradeable, ERC721URIStorageUpgradeable,UUPSUpgradeable {

    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter public carIdCounter;
    IERC20Upgradeable public tokenContract;
    ITypes private Type; 

    //Roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant DESIGNER_ROLE = keccak256("DESIGNER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    string public baseURI; //ipfs uri

    bool public rareSaleOpen; //Super rare sale status
    bool public genesis1SaleOpen; //Genesis1 sale status
    bool public genesis2SaleOpen; //Genesis2 sale status
    bool public mysterySaleOpen; //Mystery Key sale status
    bool public regularSaleOpen; //Regular sale status
    bool public giveawaysOpen; //Giveaways status
    
    struct car{
        uint256 carId;
        uint256 carType;
    }

    //Supply
    uint256 public carMysterySaleSupply;
    uint256 public carGenesis1SaleSupply;
    uint256 public carGenesis2SaleSupply;

    mapping(uint256 => uint256) public carSaleSupply;
    mapping(uint256 => uint256) public carSaleSold;
    mapping(address => uint256) public accountTotalNFTPurchased;
    mapping(address => mapping(uint256 => uint256)) public accountNFTPurchased;
    mapping(address => mapping(uint256 => uint256)) public accountRareKeys;
    mapping(address => mapping(uint256 => uint256)) public accountRegularKeys;
    mapping(address => mapping(uint256 => uint256)) public accountKeyGiveAways;
    mapping(address => uint256) public accountMysteryKeys;
    mapping(address => uint256) public accountGenesis1Keys;
    mapping(address => uint256) public accountGenesis2Keys;
    mapping(uint256 => uint256) public CAR_TYPES;

    event carMinted(uint256 carId, uint256 carType);

    function initialize() public initializer {
        __ERC721_init("CryptoDrift Unlimited NFT", "CRDU");
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, address(this));
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(DESIGNER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);

        baseURI = "ipfs://QmRVAUNdgBbJegwMTqwu1jaKNA5E53Sgj6NQwyWMp9kcXj/";

        genesis1SaleOpen = false;
        genesis2SaleOpen = false;
        mysterySaleOpen = true;
        regularSaleOpen = true;
        giveawaysOpen = true;
    
        carMysterySaleSupply = 500000;
        carGenesis1SaleSupply = 200;
        carGenesis2SaleSupply = 300;

        //Regular Cars Supply
        carSaleSupply[1] = 100000;
        carSaleSupply[2] = 100000;    
        carSaleSupply[3] = 100000;
        carSaleSupply[4] = 100000;
        carSaleSupply[5] = 100000;    
        carSaleSupply[6] = 150000;
        carSaleSupply[7] = 150000;
        carSaleSupply[8] = 150000;    
        carSaleSupply[9] = 200000;
        carSaleSupply[10] = 200000;
        carSaleSupply[11] = 200000;    
        carSaleSupply[12] = 250000;
        carSaleSupply[13] = 250000;
        carSaleSupply[14] = 250000;    
        carSaleSupply[15] = 300000;
        carSaleSupply[16] = 300000;
        carSaleSupply[17] = 300000;    
        carSaleSupply[18] = 300000;

        //Super Rare Cars
        carSaleSupply[29] = 2;
        carSaleSupply[30] = 2;
        carSaleSupply[31] = 2;    
        carSaleSupply[32] = 2;
        carSaleSupply[33] = 2;
        carSaleSupply[34] = 2;   
        carSaleSupply[35] = 2; 

    }
    
    function addAccountRareKeys(uint256 carType, uint256 qty, address recepient) external onlyRole(MINTER_ROLE){
        require(rareSaleOpen, "Rare sale is closed");
        require(carSaleSupply[carType] - qty >= 0, "Not enough Supply");

        accountRareKeys[recepient][carType] = accountRareKeys[recepient][carType] + qty;
        carSaleSupply[carType] = carSaleSupply[carType] - qty;
    }

    function addAccountGenesis1Key(uint256 qty, address recepient) external onlyRole(MINTER_ROLE){
        require(genesis1SaleOpen, "Genesis1 sale is closed");
        require(carGenesis1SaleSupply - qty >= 0, "Not enough Supply");
    
        accountGenesis1Keys[recepient] = accountGenesis1Keys[recepient] + qty;
        carGenesis1SaleSupply = carGenesis1SaleSupply - qty;
    }

    function addAccountGenesis2Key(uint256 qty, address recepient) external onlyRole(MINTER_ROLE){
        require(genesis2SaleOpen, "Genesis2 sale is closed");
        require(carGenesis2SaleSupply - qty >= 0, "Not enough Supply");
    
        accountGenesis2Keys[recepient] = accountGenesis2Keys[recepient] + qty;
        carGenesis2SaleSupply = carGenesis2SaleSupply - qty;
    }

    function addAccountMysteryKey(uint256 qty, address recepient) external onlyRole(MINTER_ROLE){
        require(mysterySaleOpen, "Mystery sale is closed");
        require(carMysterySaleSupply - qty >= 0, "Not enough Supply");
    
        accountMysteryKeys[recepient] = accountMysteryKeys[recepient] + qty;
        carMysterySaleSupply = carMysterySaleSupply - qty;
    }

    function addAccountKeyGiveAways(uint256 carType, uint256 qty, address recepient) external onlyRole(MINTER_ROLE){
        require(giveawaysOpen, "Giveaways is closed");
        require(carType < 19, "Select other car type!");

        accountKeyGiveAways[recepient][carType] = accountKeyGiveAways[recepient][carType] + qty;
    }

    function addAccountRegularKeys(uint256 carType, uint256 qty, address recepient) external onlyRole(MINTER_ROLE){
        require(regularSaleOpen, "Regular Sale is closed");
        require(carSaleSupply[carType] - qty >= 0, "Not enough Supply");
        
        accountRegularKeys[recepient][carType] = accountRegularKeys[recepient][carType] + qty;
        carSaleSupply[carType] = carSaleSupply[carType] - qty;
    }

    function useRareKey(uint256 count,uint256 carType) external {
        require((accountRareKeys[msg.sender][carType] - count) >= 0,"Not enough key/s to use!");

        accountRareKeys[msg.sender][carType] = accountRareKeys[msg.sender][carType] - count;

        for(uint256 i=0;i < count;i++){
            uint256 id = carIdCounter.current();
            CAR_TYPES[id] = carType;
            _safeMint(msg.sender, id);
            carIdCounter.increment();
        }
    }

    function useGenesis1Key(uint256 count) external {
        require((accountGenesis1Keys[msg.sender] - count) >= 0,"Not enough key/s to use!");

        accountGenesis1Keys[msg.sender] = accountGenesis1Keys[msg.sender] - count;
        
        for(uint256 i=0;i < count;i++){
            uint256 id = carIdCounter.current();
            uint256 carType = Type.createRandomTypeGenesis1(i);
            CAR_TYPES[id] = carType;
            _safeMint(msg.sender, id);
            carIdCounter.increment();
        }
    }

    function useGenesis2Key(uint256 count) external {
        require((accountGenesis2Keys[msg.sender] - count) >= 0,"Not enough key/s to use!");

        accountGenesis2Keys[msg.sender] = accountGenesis2Keys[msg.sender] - count;
        
        for(uint256 i=0;i < count;i++){
            uint256 id = carIdCounter.current();
            uint256 carType = Type.createRandomTypeGenesis2(i);
            CAR_TYPES[id] = carType;
            _safeMint(msg.sender, id);
            carIdCounter.increment();
        }
    }

    function useMysteryKey(uint256 count) external {
        require((accountMysteryKeys[msg.sender] - count) >= 0,"Not enough key/s to use!");

        accountMysteryKeys[msg.sender]= accountMysteryKeys[msg.sender] - count;
        
        for(uint256 i=0;i < count;i++){
            uint256 id = carIdCounter.current();
            uint256 carType = Type.createRandomTypeMystery(i);
            CAR_TYPES[id] = carType;
            _safeMint(msg.sender, id);
            carIdCounter.increment();
        }
    }

    function useRegularKey(uint256 count,uint256 carType) external {
        require((accountRegularKeys[msg.sender][carType] - count) >= 0,"Not enough key/s to use!");

        accountRegularKeys[msg.sender][carType] = accountRegularKeys[msg.sender][carType]-count;
        for(uint256 i=0;i<count;i++){
            uint256 id = carIdCounter.current();
            CAR_TYPES[id] = carType;
            _safeMint(msg.sender, id);
            carIdCounter.increment();
        }
    }

    function useGiveAwayKey(uint256 count,uint256 carType) external {
        require((accountKeyGiveAways[msg.sender][carType] - count) >= 0,"Not enough key/s to use!");
        
        accountKeyGiveAways[msg.sender][carType] = accountKeyGiveAways[msg.sender][carType]-count;
        for(uint256 i=0;i<count;i++){
            uint256 id = carIdCounter.current();
            CAR_TYPES[id] = carType;
            _safeMint(msg.sender, id);
            carIdCounter.increment();
        }
    }

    //Fetch records
    function getAccountCars(address walletAddress) external view returns(car[] memory _cars){
        uint256 count = balanceOf(walletAddress);
        car[] memory list = new car[](count); 
        for(uint256 i = 0;i<count;i++){
            uint256 tokenId = tokenOfOwnerByIndex(walletAddress,i);
            uint256  _carType = CAR_TYPES[tokenId];
            car memory c = car(tokenId,_carType);    
            list[i] = c;
        }
        return list;
    }

    function getCarTypes(uint256[] memory carIds) external view returns (uint256[] memory _types){
        uint256[] memory types = new uint256[](carIds.length);
        for(uint256 i=0;i<carIds.length;i++){
            uint256 _car = carIds[i];
            types[i] = CAR_TYPES[_car];
        }
        return types;
    }

    function getClaimableKeyCount(address walletAddress, uint256 carType) external view returns (uint256 count){
        return accountRegularKeys[walletAddress][carType];
    }

    function getMysteryKeyCount(address walletAddress) external view returns (uint256 count){
        return accountMysteryKeys[walletAddress];
    }

    function getGenesis1Count(address walletAddress) external view returns (uint256 count){
        return accountGenesis1Keys[walletAddress];
    }

    function getGenesis2Count(address walletAddress) external view returns (uint256 count){
        return accountGenesis2Keys[walletAddress];
    }

    function getGiveawaysKeyCount(address walletAddress, uint256 carType) external view returns (uint256 count){
        return accountKeyGiveAways[walletAddress][carType];
    }

    //Admin settings
    function setCarSaleSupply(uint256 carType, uint256 supply) external onlyRole(DEFAULT_ADMIN_ROLE){
        carSaleSupply[carType] = supply;
    }  
    
    function setMysterySaleSupply(uint256 supply) external onlyRole(DEFAULT_ADMIN_ROLE){
        carMysterySaleSupply  = supply;
    }

    function setGenesis1SaleSupply(uint256 supply) external onlyRole(DEFAULT_ADMIN_ROLE){
        carGenesis1SaleSupply  = supply;
    }
    function setGenesis2SaleSupply(uint256 supply) external onlyRole(DEFAULT_ADMIN_ROLE){
        carGenesis2SaleSupply  = supply;
    }

    function _setTokenAddress(address contractAddress) external onlyRole(DEFAULT_ADMIN_ROLE){
        tokenContract = IERC20Upgradeable(contractAddress);
    }

    function setRareSaleOpen() external onlyRole(DEFAULT_ADMIN_ROLE){
        rareSaleOpen = !rareSaleOpen;
    } 

    function setGenesis1SaleOpen() external onlyRole(DEFAULT_ADMIN_ROLE){
        genesis1SaleOpen = !genesis1SaleOpen;
    } 

    function setGenesis2SaleOpen() external onlyRole(DEFAULT_ADMIN_ROLE){
        genesis2SaleOpen = !genesis2SaleOpen;
    } 

    function setMysteryKeySaleOpen() external onlyRole(DEFAULT_ADMIN_ROLE){
        mysterySaleOpen = !mysterySaleOpen;
    } 

    function setRegularSaleOpen() external onlyRole(DEFAULT_ADMIN_ROLE){
        regularSaleOpen = !regularSaleOpen;
    } 

    function setGiveawaysSaleOpen() external onlyRole(DEFAULT_ADMIN_ROLE){
        giveawaysOpen = !giveawaysOpen;
    } 

    function setBaseURI(string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE){
        baseURI = uri;
    } 

    function setType(address contractAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Type = ITypes(contractAddress);
    }

    function pause() external onlyRole(PAUSER_ROLE){
        _pause();
    }
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
    
    function burn(uint256[] memory ids) external onlyRole(BURNER_ROLE){
        for (uint256 i = 0; i < ids.length; ++i) {
            _burn(ids[i]);
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        uint256  carType = CAR_TYPES[tokenId];
        string memory uri= string(bytes.concat(bytes(baseURI), bytes(StringsUpgradeable.toString(carType)), bytes(".json")));
        return uri;
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable,AccessControlUpgradeable,ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdrawToken() external onlyRole(DEFAULT_ADMIN_ROLE){
        tokenContract.transfer(msg.sender,tokenContract.balanceOf(address(this)));
    }
    function withdraw(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE){
        payable(msg.sender).transfer(amount);
    }
    function withdrawBNB() external onlyRole(DEFAULT_ADMIN_ROLE){
        payable(msg.sender).transfer(address(this).balance);
    }

    //Upgrades here

}