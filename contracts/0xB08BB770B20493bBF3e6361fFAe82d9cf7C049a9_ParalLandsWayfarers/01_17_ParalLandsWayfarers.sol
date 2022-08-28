//SPDX-License-Identifier: None
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./utils/ERC721AUpgradeable.sol";
import "./utils/parallabsWhitelist.sol";

contract ParalLandsWayfarers is
    ERC721AUpgradeable, 
    OwnableUpgradeable,
    PausableUpgradeable, 
    Whitelist, 
    ReentrancyGuardUpgradeable
{
    struct list {
        uint startTime;
        uint endTime;
        uint remainingTokens;
        uint purchaseLimit;
        uint price;
    }

    string public baseURI;
    address public designatedSigner;
    address payable public treasury;

    uint public maxSupply;
    uint public ownerRemainingTokens;

    list public ogList1;
    list public ogList2;
    list public wlList;
    list public pbList;

    mapping(address => uint) public ogList1MintTracker;
    mapping(address => uint) public ogList2MintTracker;
    mapping(address => uint) public wlListMintTracker;
    mapping(address => uint) public pbListMintTracker;

    modifier checkSupply(uint256 _amount) {
        require(
            _amount > 0,
            "Invalid amount"
        );
        require(
            totalSupply() + _amount <= maxSupply - ownerRemainingTokens,
            "Exceeding max supply"
        );
        _;
    }

    /**
    @notice This is initializer function is used to initialize values of contracts  
    @param _name Collection name  
    @param _symbol Collection Symbol  
    @param _designatedSigner Whitelist signer address of presale buyers  
    */

    function initialize (string memory _name, string memory _symbol, address _designatedSigner) 
        public 
        initializer 
    {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC721A_init(_name, _symbol); 
        __ParallabsSigner_init();

        designatedSigner = _designatedSigner;
        treasury = payable(0xA9D7Be4508aDf12Ce211Bfc2D2Bc52724B2958Ff);
        maxSupply = 10000;
        ownerRemainingTokens = 200;

        ogList1.startTime = 1661691600;
        ogList1.endTime = ogList1.startTime + 2 days;
        ogList1.purchaseLimit = 2;
        ogList1.remainingTokens = 600;
        ogList1.price = 0.1 ether;

        ogList2.startTime = ogList1.endTime;
        ogList2.endTime = ogList2.startTime + 2 days;
        ogList2.purchaseLimit = 600;
        ogList2.remainingTokens = 600;
        ogList2.price = 0.1 ether;

        wlList.startTime = 1663246800;
        wlList.endTime = wlList.startTime + 3 days;
        wlList.purchaseLimit = 1;
        wlList.remainingTokens = 4400;
        wlList.price = 0.05 ether;

        pbList.startTime = wlList.endTime;
        pbList.endTime = pbList.startTime + 3 days;
        pbList.purchaseLimit = 2;
        pbList.remainingTokens = 9800;
        pbList.price = 0.1 ether;
    }

    function ownerMint(uint _amount) 
        external 
        onlyOwner
    {
        require(_amount + totalSupply() <= maxSupply, "Exceeding Max Supply");
        require(_amount <= ownerRemainingTokens, "Exceeding Owner Limit");
        
        ownerRemainingTokens -= _amount;
        _mint(msg.sender, _amount);
    }

    /**
    @notice This is function is used to mint tokens for OG Presale  
    @param _whitelist whitelisted object which contains user address and backend signature for verification  
    @param _amount amount of tokens to mint in one transaction  
    */

    function ogList1Mint(whitelist memory _whitelist, uint _amount) 
        external
        payable
        nonReentrant
        whenNotPaused
        checkSupply(_amount) 
    {
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == msg.sender, "!Sender");
        require(_whitelist.listType == 1, "!List");
        require(
                block.timestamp > ogList1.startTime && block.timestamp <= ogList1.endTime,
                "OG1 Sale Closed"
            );
        require(
                _amount + ogList1MintTracker[_whitelist.userAddress] <= ogList1.purchaseLimit,
                "OG1 Indv. Quota Depleted"
            );
        require(_amount <= ogList1.remainingTokens, "OG1 Sold Out");
        require(msg.value == _amount * ogList1.price, "OG1 !(Exact Fee)");

        ogList1MintTracker[_whitelist.userAddress] += _amount;
        ogList1.remainingTokens -= _amount;
        ogList2.remainingTokens -= _amount;
        pbList.remainingTokens -= _amount;

        _mint(_whitelist.userAddress, _amount);
    } 

    /**
    @notice This function is used to mint tokens for OG Open Sale  
    @param _whitelist whitelisted object which contains user address and backend signature for verification  
    @param _amount amount of tokens to mint in one transaction  
    */

    function ogList2Mint(whitelist memory _whitelist, uint _amount) 
        external
        payable
        nonReentrant 
        whenNotPaused
        checkSupply(_amount) 
    {
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == msg.sender, "!Sender");
        require(_whitelist.listType == 1, "!List");
        require(
                block.timestamp > ogList2.startTime && block.timestamp <= ogList2.endTime, 
                "OG2 Sale Closed"
            );
        require(
                _amount + ogList2MintTracker[_whitelist.userAddress] <= ogList2.purchaseLimit,
                "OG2 Indv. Quota Depleted"
            );
        require(_amount <= ogList2.remainingTokens, "OG2 Sold Out");
        require(msg.value == _amount * ogList2.price, "OG2 !(Exact Fee)");

        ogList2MintTracker[_whitelist.userAddress] += _amount;
        ogList2.remainingTokens -= _amount;
        pbList.remainingTokens -= _amount;
        
        _mint(_whitelist.userAddress, _amount);
    } 

    /**
    @notice This is function is used to mint tokens for WL Presale 
    @param _whitelist whitelisting object which contains user address and backend signature for verification  
    @param _amount amount of tokens to mint in one transaction  
    */
    function wlListMint(whitelist memory _whitelist, uint256 _amount)
        external
        payable
        nonReentrant
        whenNotPaused
        checkSupply(_amount)
    {
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == msg.sender, "!Sender");
        require(_whitelist.listType == 2, "!List");
        require(
                block.timestamp > wlList.startTime && block.timestamp <= wlList.endTime,
                "WL Sale Closed"
        );
        require(
                _amount + wlListMintTracker[_whitelist.userAddress] <= wlList.purchaseLimit,
                "WL Indv. Quota Depleted"
        );
        require(_amount <= wlList.remainingTokens, "WL Sold Out");
        require(msg.value == _amount * wlList.price, "WL !(Exact Fee)");
            
        wlListMintTracker[_whitelist.userAddress] += _amount;
        wlList.remainingTokens -= _amount;
        pbList.remainingTokens -= _amount;
        
        _mint(_whitelist.userAddress, _amount);
    }

    /**
    @notice This is function is used to mint tokens in public sale    
    @param _amount amount of tokens to mint in one transaction   
    */
    function publicMint(uint256 _amount) 
        external 
        payable 
        nonReentrant 
        whenNotPaused
        checkSupply(_amount) 
    {
        require(msg.sender == tx.origin, "PB !Wallet");
        require(
            block.timestamp > pbList.startTime && block.timestamp <= pbList.endTime,
            "PB Sale Closed"
        );
        require(
            _amount + pbListMintTracker[msg.sender] <= pbList.purchaseLimit,
            "PB Indv. Quota Depleted"
        );
        require(_amount <= pbList.remainingTokens, "PB Sold Out");
        require(msg.value == _amount * pbList.price, "PB !(Exact Fee)");

        pbListMintTracker[msg.sender] += _amount;
        pbList.remainingTokens -= _amount;
        
        _mint(msg.sender, _amount);
    }
    
    /**
    @notice The function allows owner to withdraw accumulated funds   
    */
    function withdraw() external onlyOwner {
        require(treasury != address(0), "Treasury address not set");
        treasury.transfer(address(this).balance);
    }

    /**
    @notice The function is used to pause/ unpause all mint functions   
    */
    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    ////////////////
    ////Setters////
    //////////////
    
    /**
    @notice This function is used to set base URI  
    @param baseURI_ New Base URI  
    */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        require(bytes(baseURI_).length > 0, "Invalid Base URI Provided");
        baseURI = baseURI_;
    }

    function setDesignatedSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Invalid Address Provided");
        designatedSigner = _signer;
    }
    
    function setMaxSupply(uint _supply) external onlyOwner {
        require(totalSupply() < _supply, "Total Supply Exceeding");
        maxSupply = _supply;
    }
    
    function setOwnerCap(uint _cap) external onlyOwner {
        require(_cap <= maxSupply - totalSupply(), "Exceeding Max Supply");
        ownerRemainingTokens = _cap;
    }
    
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid address");
        treasury = payable(_treasury);
    }

    function setOG1StartTime(uint _time) external onlyOwner {
        ogList1.startTime = _time;
    }

    function setOG1EndTime(uint _time) external onlyOwner {
        ogList1.endTime = _time;
    }
    
    function setOG1PurchaseLimit(uint _cap) external onlyOwner {
        ogList1.purchaseLimit = _cap;
    }
    
    function setOG1RemainingTokens(uint _cap) external onlyOwner {
        ogList1.remainingTokens = _cap;
    }
    
    function setOG1Price(uint _price) external onlyOwner {
        ogList1.price = _price;
    }
    
    function setOG2StartTime(uint _time) external onlyOwner {
        ogList2.startTime = _time;
    }

    function setOG2EndTime(uint _time) external onlyOwner {
        ogList2.endTime = _time;
    }

    function setOG2PurchaseLimit(uint _cap) external onlyOwner {
        ogList2.purchaseLimit = _cap;
    }

    function setOG2RemainingTokens(uint _cap) external onlyOwner {
        ogList2.remainingTokens = _cap;
    }
    
    function setOG2Price(uint _price) external onlyOwner {
        ogList2.price = _price;
    }
    
    function setWLStartTime(uint _time) external onlyOwner {
        wlList.startTime = _time;
    }

    function setWLEndTime(uint _time) external onlyOwner {
        wlList.endTime = _time;
    }

    function setWLPurchaseLimit(uint _cap) external onlyOwner {
        wlList.purchaseLimit = _cap;
    }
    
    function setWLRemainingTokens(uint _cap) external onlyOwner {
        wlList.remainingTokens = _cap;
    }

    function setWLPrice(uint _price) external onlyOwner {
        wlList.price = _price;
    }
    
    function setPBStartTime(uint _time) external onlyOwner {
        pbList.startTime = _time;
    }

    function setPBEndTime(uint _time) external onlyOwner {
        pbList.endTime = _time;
    }

    function setPBPurchaseLimit(uint _cap) external onlyOwner {
        pbList.purchaseLimit = _cap;
    }
    
    function setPBRemainingTokens(uint _cap) external onlyOwner {
        pbList.remainingTokens = _cap;
    }

    function setPBPrice(uint _price) external onlyOwner {
        pbList.price = _price;
    }

    /////////////////
    ////Overrides///
    ///////////////
    
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}