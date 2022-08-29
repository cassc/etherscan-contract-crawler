//SPDX-License-Identifier: None
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./utils/ERC721AUpgradeable.sol";
import "./utils/SwagSocietyWhitelist.sol";

contract SwagSociety is
    ERC721AUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    Whitelist,
    ReentrancyGuardUpgradeable
{
    struct list {
        uint256 startTime;
        uint256 endTime;
        uint256 buyLimitPerWallet;
        uint256 remainingTokens;
    }

    string public baseURI;
    address public designatedSigner;

    uint256 public maxSupply;
    uint256 public ownerRemainingCap;

    list public whiteListMint;

    mapping(address => uint256) public whiteListMintTracker;
    
    modifier checkSupply(uint256 _amount) {
        require(_amount > 0, "Invalid Amount");
        require(_amount + totalSupply() <= maxSupply - ownerRemainingCap, "Exceeding Max Supply");
        _;
    }

    /**
    @notice This is initializer function is used to initialize values of contracts  
    @param _name Collection name  
    @param _symbol Collection Symbol  
    @param _designatedSigner Whitelist signer address of presale buyers  
    */
    function initialize(
        string memory _name,
        string memory _symbol,
        address _designatedSigner
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC721A_init(_name, _symbol);
        __SwagSocietySigner_init();

        designatedSigner = _designatedSigner;
        maxSupply = 1111;
        ownerRemainingCap = 8;

        whiteListMint.startTime = 1661878800; // 30 Aug, 1PM EST
        whiteListMint.endTime = whiteListMint.startTime + 2400 hours;
        whiteListMint.buyLimitPerWallet = 1;
        whiteListMint.remainingTokens = 1003;
    }

    /**
    @notice This is function is used to mint tokens for owner  
    @param _amount amount of tokens to mint in one transaction  
    */
    function ownerMint(uint256 _amount) external onlyOwner {
        require(_amount + totalSupply() <= maxSupply, "Exceeding Supply");
        require(_amount <= ownerRemainingCap, "Exceeding Owner Allotment");

        ownerRemainingCap -= _amount;
        _mint(msg.sender, _amount);
    }

    /**
    @notice This is function is used to mint tokens for whiteList sale  
    @param _whitelist whitelisting object which contains user address and backend signature for verification  
    @param _amount amount of tokens to mint in one transaction   
    */
    function whitelistMint(whitelist memory _whitelist, uint256 _amount)
        external
        whenNotPaused
        nonReentrant
        checkSupply(_amount)
    {
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == msg.sender, "!Sender");
        require(_whitelist.listType == 1, "WhiteList: Wrong list type");
        require(
            block.timestamp > whiteListMint.startTime && block.timestamp <= whiteListMint.endTime,
            "WhiteList: Sale Closed"
        );
        require(
            _amount + whiteListMintTracker[_whitelist.userAddress] <= whiteListMint.buyLimitPerWallet,
            "WhiteList: Individual Cap exceeding"
        );
        require(_amount <= whiteListMint.remainingTokens, "WhiteList: All Sold Out");

        whiteListMintTracker[_whitelist.userAddress] += _amount;
        whiteListMint.remainingTokens -= _amount;
        
        _mint(_whitelist.userAddress, _amount);
    }

    /**
    @notice The function is use to pause and unpause the mint   
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

    /**
    @notice This function is used to set designated signer  
    @param _signer New signer address    
    */
    function setDesignatedSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Invalid Address Provided");
        designatedSigner = _signer;
    }

    /**
    @notice This function is used to set max supply of collection  
    @param _supply New max supply     
    */
    function setMaxSupply(uint256 _supply) external onlyOwner {
        require(totalSupply() < _supply, "Total Supply Exceeding");
        maxSupply = _supply;
    }
    
    /**
    @notice This function is used to owner's reserves 
    @param _cap New max supply     
    */
    function setOwnerCap(uint256 _cap) external onlyOwner {
        ownerRemainingCap = _cap;
    }

    /**
    @notice This function is used to set whiteList start time    
    @param _time New whiteList time       
    */
    function setWhiteListStartTime(uint256 _time) external onlyOwner {
        whiteListMint.startTime = _time;
    }

    /**
    @notice This function is used to set whiteList end time  
    @param _time whiteList end time     
    */
    function setWhiteListEndTime(uint256 _time) external onlyOwner {
        whiteListMint.endTime = _time;
    }

    /**
    @notice This function is used to set whiteList buyLimitPerWallet   
    @param _cap New whiteList buyLimitPerWallet       
    */
    function setWhiteListBuyLimitPerWallet(uint256 _cap) external onlyOwner {
        whiteListMint.buyLimitPerWallet = _cap;
    }

    /**
    @notice This function is used to set whiteList list supply cap   
    @param _cap New whiteList list supply cap    
    */
    function setWhiteListSupplyCap(uint256 _cap) external onlyOwner {
        whiteListMint.remainingTokens = _cap;
    }

    ////////////////
    ///Overridden///
    ////////////////

    /**
    @notice This function is used to get first token id      
    */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
    @notice This function is used to get base URI value     
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}