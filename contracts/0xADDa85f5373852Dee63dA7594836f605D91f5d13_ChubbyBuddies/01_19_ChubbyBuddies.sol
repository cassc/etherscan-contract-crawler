//SPDX-License-Identifier: None
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./utils/ERC721AUpgradeable.sol";
import "./utils/ChubbyBuddiesWhitelist.sol";

contract ChubbyBuddies is
    ERC721AUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    Whitelist,
    ReentrancyGuardUpgradeable
{
    struct list {
        uint256 startTime;
        uint256 endTime;
        uint256 limit;
        uint256 remainingTokens;
    }

    IERC721 spectrumPass;
    string public baseURI;
    address public designatedSigner;

    uint256 public maxSupply;
    uint256 public ownerRemainingTokens;

    list public spectrum;
    list public presale;
    list public publicSale;

    mapping(uint256 => uint256) public spectrumTracker;
    mapping(address => uint256) public presaleTracker;

    modifier checkSupply(uint256 _amount) {
        require(_amount > 0, "Invalid Amount");
        require(_amount + totalSupply() <= maxSupply - ownerRemainingTokens, "Exceeding Max Supply");
        _;
    }

    /**
    @notice This function is used to initialize values of contracts  
    @param _name Collection name  
    @param _symbol Collection Symbol  
    @param _designatedSigner Whitelist signer address of presale buyers  
    */
    function initialize(
        string memory _name,
        string memory _symbol,
        address _designatedSigner,
        address _spectrumPass
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC721A_init(_name, _symbol);
        __ChubbyBuddiesSigner_init();

        spectrumPass = IERC721(_spectrumPass);
        designatedSigner = _designatedSigner;
        maxSupply = 5000;
        ownerRemainingTokens = 100;

        spectrum.startTime = 1661868000; // 30 Aug, 7:30pm IST
        spectrum.endTime = spectrum.startTime + 12 hours;
        spectrum.limit = 2;
        spectrum.remainingTokens = 1000;

        presale.startTime = spectrum.endTime;
        presale.endTime = presale.startTime + 12 hours;
        presale.limit = 2;
        presale.remainingTokens = 4900;

        publicSale.startTime = presale.endTime;
        publicSale.endTime = publicSale.startTime + 2400 hours;
        publicSale.limit = 2;
        publicSale.remainingTokens = 4900;
    }

    /**
    @notice This function allows owner to mint tokens for themselves  
    @param _amount amount of tokens to mint in one transaction  
    */
    function ownerMint(uint256 _amount) external onlyOwner {
        require(_amount + totalSupply() <= maxSupply, "Exceeding Supply");
        require(_amount <= ownerRemainingTokens, "Exceeding Owner Allotment");

        ownerRemainingTokens -= _amount;
        _mint(msg.sender, _amount);
    }

    /**
    @notice This function allows Spectrum Pass Holders to mint   
    @param _tokenIds Spectrum Pass Ids held by the caller  
    @param _amounts No. of tokens the caller wishes to mint against the tokenIds   
    */
    function spectrumMint(uint256[] memory _tokenIds, uint256[] memory _amounts)
        external
        whenNotPaused
        nonReentrant
    {
        uint256 totalAmountToMint = 0;
        require(block.timestamp > spectrum.startTime && block.timestamp <= spectrum.endTime, "Spectrum: Closed");
        require(_tokenIds.length == _amounts.length, "Spectrum: Invalid Input");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_tokenIds[i] != 0 && _amounts[i] != 0, "Spectrum: Null Input");
            require(spectrumPass.ownerOf(_tokenIds[i]) == msg.sender, "Spectrum: !Owner");
            require(_amounts[i] + spectrumTracker[_tokenIds[i]] <= spectrum.limit, "Spectrum: Claimed Already");
            totalAmountToMint += _amounts[i];
            spectrumTracker[_tokenIds[i]] += _amounts[i];
        }

        require(totalAmountToMint + totalSupply() <= maxSupply - ownerRemainingTokens, "Spectrum: Sold Out");
        require(totalAmountToMint <= spectrum.remainingTokens, "Spectrum: Not Enough Remaining");

        spectrum.remainingTokens -= totalAmountToMint;
        presale.remainingTokens -= totalAmountToMint;
        publicSale.remainingTokens -= totalAmountToMint;

        _mint(msg.sender, totalAmountToMint);
    }

    /**
    @notice This function allows whitelisted addresses to mint
    @param _whitelist Whitelist object which contains user address signed by a designated private key  
    @param _amount Amount of tokens to mint
    */
    function presaleMint(whitelist memory _whitelist, uint256 _amount)
        external
        whenNotPaused
        nonReentrant
        checkSupply(_amount)
    {
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == msg.sender, "!Sender");
        require(_whitelist.listType == 1, "!List");
        require(block.timestamp > presale.startTime && block.timestamp <= presale.endTime, "Presale: Closed");
        require(
            _amount + presaleTracker[_whitelist.userAddress] <= presale.limit,
            "Presale: Exceeding Individual Quota"
        );
        require(_amount <= presale.remainingTokens, "Presale: Sold Out");

        presaleTracker[_whitelist.userAddress] += _amount;
        presale.remainingTokens -= _amount;
        publicSale.remainingTokens -= _amount;

        _mint(_whitelist.userAddress, _amount);
    }

    /**
    @notice This function allows anyone to mint    
    @param _amount Amount of tokens to mint   
    */
    function publicMint(uint256 _amount) 
        external 
        whenNotPaused 
        nonReentrant 
        checkSupply(_amount) 
    {
        require(msg.sender == tx.origin, "PublicSale: Only wallets allowed");
        require(block.timestamp > publicSale.startTime, "PublicSale: Sale Closed");
        require(_amount <= publicSale.limit, "PublicSale: Exceeding Transasction Limit");

        publicSale.remainingTokens -= _amount;
    
        _mint(msg.sender, _amount);
    }


    /**
    @notice The function allows owner to pause/ unpause mint  
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

    function setBaseURI(string memory baseURI_) public onlyOwner {
        require(bytes(baseURI_).length > 0, "Invalid Base URI Provided");
        baseURI = baseURI_;
    }

    function setDesignatedSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Invalid Address Provided");
        designatedSigner = _signer;
    }

    function setMaxSupply(uint256 _supply) external onlyOwner {
        require(totalSupply() < _supply, "Total Supply Exceeding");
        maxSupply = _supply;
    }

    function setOwnerCap(uint256 _cap) external onlyOwner {
        ownerRemainingTokens = _cap;
    }

    function setSpectrumPassAddress(address _spectrumPass) external onlyOwner {
        spectrumPass = IERC721(_spectrumPass);
    }

    function setSpectrumStartTime(uint256 _startTime) external onlyOwner {
        spectrum.startTime = _startTime;
    }

    function setSpectrumEndTime(uint256 _endTime) external onlyOwner {
        spectrum.endTime = _endTime;
    }

    function setSpectrumLimit(uint256 _limit) external onlyOwner {
        spectrum.limit = _limit;
    }

    function setSpectrumCap(uint256 _cap) external onlyOwner {
        spectrum.remainingTokens = _cap;
    }

    function setPresaleStartTime(uint256 _startTime) external onlyOwner {
        presale.startTime = _startTime;
    }

    function setPresaleEndTime(uint256 _endTime) external onlyOwner {
        presale.endTime = _endTime;
    }

    function setPresaleLimit(uint256 _limit) external onlyOwner {
        presale.limit = _limit;
    }

    function setPresaleCap(uint256 _cap) external onlyOwner {
        presale.remainingTokens = _cap;
    }

    function setPubliSaleStartTime(uint256 _startTime) external onlyOwner {
        publicSale.startTime = _startTime;
    }

    function setPublicSaleEndTime(uint256 _endTime) external onlyOwner {
        publicSale.endTime = _endTime;
    }

    function setPublicSaleLimit(uint256 _limit) external onlyOwner {
        publicSale.limit = _limit;
    }

    function setPublicSaleCap(uint256 _cap) external onlyOwner {
        publicSale.remainingTokens = _cap;
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