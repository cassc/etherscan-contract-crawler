//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "./MerkleWhitelist.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';


contract Torizero is Ownable, ERC721A, MerkleWhitelist, ReentrancyGuard {

    uint256 public DA_STARTING_PRICE = 0.3 ether;

    uint256 public DA_ENDING_PRICE = 0.1 ether;

    uint256 public DA_DECREMENT = 0.02 ether;

    uint256 public DA_DECREMENT_FREQUENCY = 900;

    uint256 public DA_FINAL_PRICE;

    uint256 public WL_PRICE = 0.08 ether;


    uint256 public WL_AMOUNT = 600;
    uint256 public DA_AMOUNT = 5000;
    uint256 public MAIN_AMOUNT = 2000;
    uint256 public ALL_AMOUNT = 7777;


    uint256 public WL_START_TIME = 1650888600;
    uint256 public WL_END_TIME = 1650931800;

    uint256 public DA_START_TIME = 1650974400;
    uint256 public DA_END_TIME = 1650985200;

    uint256 public MAIN_END_TIME;
    uint256 public MAIN_LAST_TIME = 10800;


    uint256 public EXTRA_START_TIME = 1650996000;

    uint16 public WL_MINTED;
    uint16 public DA_MINTED;
    uint16 public MAIN_MINTED;
    uint16 public EXTRA_MINTED;
    uint16 public TEAM_MINTED;


    uint16 public WL_LIMIT=3;
    uint16 public DA_LIMIT=5;
    uint16 public MAIN_LIMIT=1;
    uint16 public EXTRA_LIMIT=10;
    uint16 public TEAM_LIMIT=1;

    mapping(address => uint256) public WL_WALLET_CAP;
    mapping(address => uint256) public DA_WALLET_CAP;
    mapping(address => uint256) public MAIN_WALLET_CAP;
    mapping(address => uint256) public EXTRA_WALLET_CAP;
    mapping(address => uint256) public TEAM_WALLET_CAP;

    bool _isWLActive = true;
    bool _isDAActive = true;
    bool _isMainActive = true;
    bool _isExtraActive = true;
    bool _isTeamActive = false;

    bool public INITIAL_FUNDS_WITHDRAWN;

    struct DABatchPrice {
        uint128 pricePaid;
        uint8 quantityMinted;
    }

    mapping(address => DABatchPrice[]) public userToDABatchPrice;


    uint256 public STATE = 1;

    bool public REVEALED = false;
    string public UNREVEALED_URI = "https://data.torizero.com/torizero/box.json";
    string public BASE_URI;
    string public CONTRACT_URI ="https://data.torizero.com/api/contracturl.json";


    constructor() ERC721A("torizero", "TORIZERO") {}

    function currentPrice() public view returns (uint256) {
        if(block.timestamp < DA_START_TIME)return DA_STARTING_PRICE;

        if (DA_FINAL_PRICE > 0) return DA_FINAL_PRICE;

        uint256 timeSinceStart = block.timestamp - DA_START_TIME;

        uint256 decrementsSinceStart = timeSinceStart / DA_DECREMENT_FREQUENCY;

        uint256 totalDecrement = decrementsSinceStart * DA_DECREMENT;

        if (totalDecrement >= DA_STARTING_PRICE - DA_ENDING_PRICE) {
            return DA_ENDING_PRICE;
        }

        return DA_STARTING_PRICE - totalDecrement;
    }

    function extraAmount() public view returns (uint256) {
       return  WL_AMOUNT + DA_AMOUNT + MAIN_AMOUNT - WL_MINTED - DA_MINTED - MAIN_MINTED;
    }

    function wlInfo(address user) public view returns (uint256,uint256,uint256,uint256,uint256,uint256) {
       return  (WL_AMOUNT,WL_MINTED,WL_PRICE,WL_START_TIME,WL_END_TIME,WL_WALLET_CAP[user]);
    }

    function daInfo(address user) public view returns (uint256,uint256,uint256,uint256,uint256,uint256) {
       return  (DA_AMOUNT,DA_MINTED,currentPrice(),DA_START_TIME,DA_END_TIME,DA_WALLET_CAP[user]);
    }

    function mainInfo(address user) public view returns (uint256,uint256,uint256,uint256,uint256,uint256) {
       return  (MAIN_AMOUNT,MAIN_MINTED,mainPrice(),extraAmount(),MAIN_END_TIME,MAIN_WALLET_CAP[user]);
    }

    function extraInfo(address user) public view returns (uint256,uint256,uint256,uint256,uint256,uint256) {
       return  (extraAmount(),EXTRA_MINTED,extraPrice(),EXTRA_START_TIME,0,EXTRA_WALLET_CAP[user]);
    }

  

    function mainPrice() public view returns (uint256) {
       return  ((DA_FINAL_PRICE / 100) * 80);
    }

    function extraPrice() public view returns (uint256) {
       return  ((DA_FINAL_PRICE / 100) * 80);
    }


    function mintDA(uint8 quantity) public payable {
        require(quantity > 0, "Must mint at least 1 token.");
        require(_isDAActive, "DA must be active to mint tokens");
        require(block.timestamp >= DA_START_TIME,"DA has not started!");
        require(block.timestamp < DA_END_TIME, "DA is over");
        require(DA_WALLET_CAP[msg.sender] + quantity <= DA_LIMIT, "Purchase would exceed max number of metacards per wallet."); 
        uint256 _currentPrice = currentPrice();
        require(msg.value >= quantity * _currentPrice,"Did not send enough eth.");
        require(DA_MINTED + quantity <= DA_AMOUNT,"Max supply for DA reached!");
        require(totalSupply() + quantity <= ALL_AMOUNT,"reached max supply");

        if (DA_MINTED + quantity == DA_AMOUNT){
            _isDAActive = false;
            DA_FINAL_PRICE = _currentPrice;
            MAIN_END_TIME = block.timestamp + MAIN_LAST_TIME;
            STATE = 3;
        }

        userToDABatchPrice[msg.sender].push(
            DABatchPrice(uint128(msg.value), quantity)
        );

        DA_MINTED = DA_MINTED+quantity;

        DA_WALLET_CAP[msg.sender] += quantity;

        _safeMint(msg.sender, quantity);
    }

    function mintWL(uint8 quantity,bytes32[] memory proof)
        public
        payable
        onlyWlWhitelist(proof)
    {
    
        require(quantity > 0, "Must mint at least 1 token.");
        require(_isWLActive, "WL must be active to mint tokens");
        require(block.timestamp >= WL_START_TIME,"WL has not started yet!");
        require(block.timestamp < WL_END_TIME, "WL is over");
        require(WL_WALLET_CAP[msg.sender] + quantity <= WL_LIMIT, "Purchase would exceed max number of metacards per wallet."); 
        require(msg.value >= quantity * WL_PRICE,"Did not send enough eth.");
        require(WL_MINTED + quantity <= WL_AMOUNT,"Max supply for WL reached!");
        require(totalSupply() + quantity <= ALL_AMOUNT,"reached max supply");

        WL_MINTED = WL_MINTED + quantity;

        WL_WALLET_CAP[msg.sender] += quantity;

        _safeMint(msg.sender, quantity);
    }

    function mintMain(uint8 quantity,bytes32[] memory proof)
        public
        payable
       onlyMainWhitelist(proof)
    {
        require(quantity > 0, "Must mint at least 1 token.");
        require(DA_FINAL_PRICE > 0, "Dutch action must be over!");
        require(_isMainActive, "Main must be active to mint tokens");
        require(block.timestamp < MAIN_END_TIME, "Main is over");
        require(MAIN_WALLET_CAP[msg.sender] + quantity <= MAIN_LIMIT, "Purchase would exceed max number of metacards per wallet."); 
        require(msg.value >= mainPrice() * quantity,"Must send enough eth for MAIN Mint");
        require(MAIN_MINTED + quantity <= MAIN_AMOUNT,"Max supply for MAIN reached!");
        require(totalSupply() + quantity <= ALL_AMOUNT,"reached max supply");

        MAIN_MINTED = MAIN_MINTED + quantity;

        MAIN_WALLET_CAP[msg.sender] += quantity;

        _safeMint(msg.sender, quantity);

    }

     function mintExtra(uint8 quantity,bytes32[] memory proof)
        public
        payable
        onlyExtraWhitelist(proof)
    {
        require(quantity > 0, "Must mint at least 1 token.");
        require(DA_FINAL_PRICE > 0, "Dutch action must be over!");
        require(_isExtraActive, "Extra must be active to mint tokens");
        require(block.timestamp >= EXTRA_START_TIME,"Extra has not started yet!");
        require(EXTRA_WALLET_CAP[msg.sender] + quantity <= EXTRA_LIMIT, "Purchase would exceed max number of metacards per wallet."); 
        require(msg.value >= extraPrice()* quantity,"Must send enough eth for MAIN Mint");
        require(EXTRA_MINTED + quantity <= extraAmount(),"Max supply for EXTRA reached!");
        require(totalSupply() + quantity <= ALL_AMOUNT,"reached max supply");

        EXTRA_MINTED = EXTRA_MINTED + quantity;

        EXTRA_WALLET_CAP[msg.sender] += quantity;

        _safeMint(msg.sender, quantity);

    }

    function teamMint(bytes32[] memory proof) 
        public 
        onlyTeamWhitelist(proof) 
    {
        require(DA_FINAL_PRICE > 0, "Dutch action must be over!");
        require(_isTeamActive, "team must be active to mint tokens");
        require(TEAM_WALLET_CAP[msg.sender] + 1 <= TEAM_LIMIT, "Purchase would exceed max number of metacards per wallet."); 
        require(totalSupply() + 1 <= ALL_AMOUNT, "reached max supply");
       
        TEAM_MINTED = TEAM_MINTED + 1;

        TEAM_WALLET_CAP[msg.sender] += 1;

        _safeMint(msg.sender, 1);
    }


    function userToTokenBatchLength(address user)
        public
        view
        returns (uint256)
    {
        return userToDABatchPrice[user].length;
    }

    function refundExtraETH() public {
        require(DA_FINAL_PRICE > 0, "Dutch action must be over!");

        uint256 totalRefund;

        for (
            uint256 i = userToDABatchPrice[msg.sender].length;
            i > 0;
            i--
        ) {
            //This is what they should have paid if they bought at lowest price tier.
            uint256 expectedPrice = userToDABatchPrice[msg.sender][i - 1]
                .quantityMinted * DA_FINAL_PRICE;

            //What they paid - what they should have paid = refund.
            uint256 refund = userToDABatchPrice[msg.sender][i - 1]
                .pricePaid - expectedPrice;

            //Remove this tokenBatch
            userToDABatchPrice[msg.sender].pop();

            //Send them their extra monies.
            totalRefund += refund;
        }
        payable(msg.sender).transfer(totalRefund);
    }


    function getExtraETH(address user) public view returns (uint256){

        uint256 totalRefund;

        for (
            uint256 i = userToDABatchPrice[user].length;
            i > 0;
            i--
        ) {
            //This is what they should have paid if they bought at lowest price tier.
            uint256 expectedPrice = userToDABatchPrice[user][i - 1]
                .quantityMinted * DA_FINAL_PRICE;

            //What they paid - what they should have paid = refund.
            uint256 refund = userToDABatchPrice[user][i - 1]
                .pricePaid - expectedPrice;

            //Send them their extra monies.
            totalRefund += refund;
        }
        return totalRefund;

    }

    function withdrawInitialFunds() public onlyOwner nonReentrant {
        require(
            !INITIAL_FUNDS_WITHDRAWN,
            "Initial funds have already been withdrawn."
        );
        require(DA_FINAL_PRICE > 0, "DA has not finished!");
        uint256 WLFunds = WL_MINTED * WL_PRICE;
        uint256 DAFunds = DA_MINTED * DA_FINAL_PRICE;
        uint256 MAINFunds = MAIN_MINTED * mainPrice();
        uint256 EXTRAFunds = EXTRA_MINTED * extraPrice();
        uint256 initialFunds = DAFunds + WLFunds + MAINFunds + EXTRAFunds;
        INITIAL_FUNDS_WITHDRAWN = true;
        (bool succ, ) = payable(owner()).call{
            value: initialFunds
        }("");
        require(succ, "transfer failed");
    }

    function desirableInitialFunds() public view returns (uint256) {
        uint256 WLFunds = WL_MINTED * WL_PRICE;
        uint256 DAFunds = DA_MINTED * DA_FINAL_PRICE;
        uint256 MAINFunds = MAIN_MINTED * mainPrice();
        uint256 EXTRAFunds = EXTRA_MINTED * extraPrice();
        uint256 initialFunds = DAFunds + WLFunds + MAINFunds + EXTRAFunds;
        return initialFunds;
    }

   function withdraw() public onlyOwner nonReentrant {
        (bool succ, ) = payable(owner()).call{value: address(this).balance}('');
        require(succ, "transfer failed");
   }

    function setRevealData(bool _revealed,string memory _baseURI) public onlyOwner
    {
        REVEALED = _revealed;
        BASE_URI = _baseURI;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        BASE_URI = _baseURI;
    }

    function setRevealedURI(string memory _unrevealedURI) public onlyOwner {
        UNREVEALED_URI = _unrevealedURI;
    }

    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (REVEALED) {
            return
                string(abi.encodePacked(BASE_URI, Strings.toString(_tokenId), ".json"));
        } else {
            return UNREVEALED_URI;
        }
    }


    function setAllStartTime(uint256 wlTime,uint256 wlEndTime,uint256 daTime,uint256 daEndTime,uint256 extraTime) external onlyOwner {
        WL_START_TIME = wlTime;
        WL_END_TIME = wlEndTime;
        DA_START_TIME = daTime;
        DA_END_TIME = daEndTime;
        EXTRA_START_TIME = extraTime;
    }


    function flipAllState(bool isWLActive,bool isDAActive,bool isMainActive,bool isExtraActive,uint256 _st) external onlyOwner {
        _isWLActive = isWLActive;
        _isDAActive = isDAActive;
        _isMainActive = isMainActive;
        _isExtraActive = isExtraActive;
        STATE = _st;
    }

    function flipDAState() external onlyOwner {
        require(block.timestamp > DA_END_TIME, "DA has not finished!");
        require(DA_FINAL_PRICE == 0, "Price has been set!");
        _isDAActive = false;
        DA_FINAL_PRICE = DA_ENDING_PRICE;
        STATE = 3;
        MAIN_END_TIME = block.timestamp + MAIN_LAST_TIME;
    }


    function setState(uint256 _st) external onlyOwner {
        STATE = _st;
    }

}