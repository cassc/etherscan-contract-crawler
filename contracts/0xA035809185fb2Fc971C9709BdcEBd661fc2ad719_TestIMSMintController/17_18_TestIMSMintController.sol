// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Whitelist} from "./utils/WhiteListSigner.sol";
import {ITestIMS} from "./Interface/ITestIMS.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {PaymentSplitterUpgradeable} from "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract TestIMSMintController is
OwnableUpgradeable,
PausableUpgradeable,
PaymentSplitterUpgradeable,
ReentrancyGuardUpgradeable,
Whitelist
{
    
    ITestIMS public TestIMS;
    
    /**
       * @notice A struct that defines a Sale
       * @params startTime Time when the Sale begins
       * @params endTime Time when the Sale ends
       * @params multiplier Maximum number of tokens a wallet may mint
       * @params maxAvailable Maximum number of tokens that may be sold in the Sale
       * @params register Registry of minters
    */
    struct sale {
        uint256 startTime;
        uint256 endTime;
        uint256 multiplier;
        uint256 maxAvailable;
        uint256 price;
        mapping(address => uint256) register;
    }
    
    // Whitelist Sale
    sale public WL;
    
    // OG Sale
    sale public OG;
    
    // Genesis Sale
    sale public Genesis;
    
    // Public Sale
    sale public PB;

    uint256 public guaranteedMints;
    address public designatedSigner;
    
    uint256 public maxSupply;
    uint256 public ownerMinted;
    uint256 public ownerReserve;
    mapping(bytes => bool) public usedSignatures;
    
    modifier checkSupply(uint256 _amount) {
        require(_amount > 0, "Invalid Amount");
        require(_amount + TestIMS.totalSupply() <= (maxSupply - ownerReserve) + ownerMinted, "Sold out");
        _;
    }
    
    /**
	   * @notice This function initializes Sale parameters
	   * @param _TestIMS Address of TestIMS contract
       * @param _designatedSigner Public address of dedicated private key used for Whitelisting
       * @param _payees Addresses of the payees
       * @param _shares Shares of the payees
    */
    function initialize(
        address _TestIMS,
        address _designatedSigner,
        address[] memory _payees,
        uint256[] memory _shares
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __WhiteList_init();
        __PaymentSplitter_init(_payees, _shares);
        TestIMS = ITestIMS(_TestIMS);
        
        designatedSigner = _designatedSigner;
        
        maxSupply = 5555;
        guaranteedMints = 1000;
        ownerReserve = 35;
        
        OG.startTime = 1682402048; // Tuesday, 4 April 2023 7:30:00 PM GMT+05:30
        OG.endTime = OG.startTime + 4 hours;
        OG.multiplier = 5;
        OG.maxAvailable = guaranteedMints;
        OG.price = 0.039 ether;
        
        Genesis.startTime = 1682402048;
        Genesis.endTime = Genesis.startTime + 4 hours;
        Genesis.multiplier = 3;
        Genesis.maxAvailable = guaranteedMints;
        Genesis.price = 0.039 ether;
        
        WL.startTime = 1682402048; // Tuesday, 4 April 2023 7:30:00 PM GMT+05:30
        WL.endTime = WL.startTime + 10 hours;
        WL.multiplier = 2;
        WL.maxAvailable = maxSupply - guaranteedMints - ownerReserve;
        WL.price = 0.039 ether;

        PB.startTime = WL.endTime;
        PB.endTime = PB.startTime + 4 hours;
        PB.multiplier = 2;
        PB.maxAvailable = 5555;
        PB.price = 0.044 ether;
    }
    
    /**
	   * @notice This function allows only the owner to airdrop tokens to any address
       * @param _addresses Addresses of the recipient
       * @param _amount Amount of tokens to mint in one transaction to each user
    */
    function airdrop(address[] calldata _addresses, uint256[] calldata _amount) external onlyOwner {
        for (uint256 i=0;i<_addresses.length;i++)
        {
            require(TestIMS.totalSupply() + _amount[i] <= maxSupply, "Exceeds Max Supply");
            require(_amount[i] + ownerMinted <= ownerReserve, "Exceeds Owner Reserved");
            ownerMinted += _amount[i];
            TestIMS.mint(_addresses[i], _amount[i]);
        }
    }
    
    /**
        * @notice This function allows to mint during the OG Sale
        * @param _to Address of the recipient
        * @param _whitelist Whitelist struct
        * @param _amount Amount of tokens to mint in one transaction
     */
    function OGMint(address _to, whitelist memory _whitelist, uint256 _amount)
    external
    payable
    nonReentrant
    whenNotPaused
    checkSupply(_amount)
    {
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == _to, "User address mismatch");
        require(_whitelist.listType == 1, "!List");
        require(_whitelist.nonce + 5 minutes >= block.timestamp, "OG nonce expired");
        require(!usedSignatures[_whitelist.signature], "Signature already used");
        require(block.timestamp > OG.startTime && block.timestamp <= OG.endTime, "OG sale not active");
        require(_amount <= guaranteedMints, "OG sold out");
        require(msg.value == _amount * OG.price, "OG insufficient funds sent");

        uint256 buyLimit = _whitelist.availableSpots * OG.multiplier;
        require(OG.register[_to] + _amount <= buyLimit, "OG buy limit exceeded");
        
        usedSignatures[_whitelist.signature] = true;
        OG.register[_to] += _amount;
        guaranteedMints -= _amount;
        
        TestIMS.mint(_to, _amount);
    }
    
    /**
        * @notice This function allows users to mint tokens during the Genesis Sale
        * @param _to Address of the recipient
        * @param _whitelist Whitelist struct
        * @param _amount Amount of tokens to mint in one transaction
     */
    function GenesisMint(address _to, whitelist memory _whitelist, uint256 _amount)
    external
    payable
    nonReentrant
    whenNotPaused
    checkSupply(_amount)
    {
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == _to, "User address mismatch");
        require(_whitelist.listType == 2, "!List");
        require(_whitelist.nonce + 5 minutes >= block.timestamp, "Genesis nonce expired");
        require(!usedSignatures[_whitelist.signature], "Genesis already used");
        require(block.timestamp > Genesis.startTime && block.timestamp <= Genesis.endTime, "Genesis sale not active");
        require(_amount <= guaranteedMints, "Genesis sold out");
        require(msg.value == _amount * Genesis.price, "Genesis insufficient funds sent");
        
        uint256 buyLimit = _whitelist.availableSpots * Genesis.multiplier;
        require(Genesis.register[_to] + _amount <= buyLimit, "Genesis buy limit exceeded");
        
        usedSignatures[_whitelist.signature] = true;
        Genesis.register[_to] += _amount;
        guaranteedMints -= _amount;
        
        TestIMS.mint(_to, _amount);
    }
    
    /**
	   * @notice This function allows members in Whitelist to mint
	   * @dev The check for list type is removed here because users from both OG and Genesis can mint here
	   * @param _to Address of the recipient
       * @param _whitelist Whitelisting object which contains user address signed by the designated signer
       * @param _amount Amount of tokens to mint in one transaction
    */
    function WLMint(address _to, whitelist memory _whitelist, uint256 _amount)
    external
    payable
    nonReentrant
    whenNotPaused
    checkSupply(_amount)
    {
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == _to, "User address mismatch");
        require(_whitelist.nonce + 5 minutes >= block.timestamp, "WL nonce expired");
        require(!usedSignatures[_whitelist.signature], "WL already used");
        require(block.timestamp > WL.startTime && block.timestamp <= WL.endTime, "WL sale not active");
        checkWLMaxAvailable();
        require(_amount <= WL.maxAvailable, "WL sold out");
        require(msg.value == _amount * WL.price, "WL insufficient funds sent");
        require(_whitelist.listType == 3, "!List");
        uint256 buyLimit = _whitelist.availableSpots * WL.multiplier;
        require(WL.register[_to] + _amount <= buyLimit, "Whitelist buy limit exceeded");
        
        usedSignatures[_whitelist.signature] = true;
        WL.register[_to] += _amount;
        WL.maxAvailable -= _amount;
       
        TestIMS.mint(_to, _amount);
    }
    
    /**
	   * @notice This function allows anyone to mint
	   * @param _to Address of the recipient
       * @param _amount Amount of tokens to mint in one transactions
    */
    function publicMint(address _to, uint256 _amount)
    external
    payable
    nonReentrant
    whenNotPaused
    checkSupply(_amount)
    {
        require(msg.value == _amount * PB.price, "PB insufficient funds sent");
        require(block.timestamp > PB.startTime && block.timestamp <= PB.endTime, "PB sale not active");
        require(_amount + PB.register[_to] <= PB.multiplier, "PB cannot mint more");
        require(_amount <= PB.maxAvailable, "PB supply over");
        PB.register[_to] += _amount;
        PB.maxAvailable -= _amount;
        
        TestIMS.mint(_to, _amount);
    }
    
    /**
       * @notice This function returns the number of tokens minted by a member in WL list
       * @param _address Address of the member
    */
    function readWLRegister(address _address) public view returns (uint256) {
        require(_address != address(0), "Invalid address provided");
        return WL.register[_address];
    }
    
    /**
       * @notice This function returns the number of tokens minted by a member in OG list
       * @param _address Address of the member
    */
    function readOGRegister(address _address) public view returns (uint256) {
        require(_address != address(0), "Invalid address provided");
        return OG.register[_address];
    }
    
    /**
       * @notice This function returns the number of tokens minted by a member in Genesis list
       * @param _address Address of the member
    */
    function readGenesisRegister(address _address) public view returns (uint256) {
        require(_address != address(0), "Invalid address provided");
        return Genesis.register[_address];
    }
    
    /**
       * @notice This function returns the number of tokens minted by a user
       * @param _address Address of the user
    */
    function readPBRegister(address _address) public view returns (uint256) {
        require(_address != address(0), "Invalid address provided");
        return PB.register[_address];
    }
    
    /**
       * @notice The function is used to pause/ unpause mint functions
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
       * @notice This function is used to set the designated signer
       * @param _signer Address of the signer
    */
    function setDesignatedSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Invalid Address Provided");
        designatedSigner = _signer;
    }
    
    /**
       * @notice This function is used to set max supply of tokens
       * @param _supply Max supply of tokens
    */
    function setMaxSupply(uint256 _supply) external onlyOwner {
        require(TestIMS.totalSupply() <= _supply, "Total Supply Exceeding");
        maxSupply = _supply;
    }
    
    /**
       * @notice This function is used to set the owner reserve
       * @param _cap Owner reserve
    */
    function setOwnerCap(uint256 _cap) external onlyOwner {
        require(TestIMS.totalSupply() + _cap <= maxSupply, "Total Supply Exceeding");
        require(_cap >= ownerMinted, "Owner Cap Exceeding");
        ownerReserve = _cap;
    }
    
    /**
       * @notice This function is used to set the conditions for OG sale
       * @param _startTime Start time of the sale
       * @param _endTime End time of the sale
       * @param _multiplier Maximum number of tokens a member can mint
       * @param _maxAvailable Maximum number of tokens available for sale
       * @param _price Price of each token
    */
    function setOGConditions(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _multiplier,
        uint256 _maxAvailable,
        uint256 _price
    ) external onlyOwner {
        require(_startTime < _endTime, "Invalid times");
        require(_maxAvailable <= maxSupply - ownerReserve, "_maxAvailable invalid");
        require(_multiplier <= _maxAvailable, "_multiplier invalid");
        
        OG.startTime = _startTime;
        OG.endTime = _endTime;
        OG.multiplier = _multiplier;
        OG.maxAvailable = _maxAvailable;
        OG.price = _price;
    }
    
    /**
	   * @notice This function is used to set the conditions for Genesis sale
       * @param _startTime Start time of the sale
       * @param _endTime End time of the sale
       * @param _multiplier Maximum number of tokens a member can mint
       * @param _maxAvailable Maximum number of tokens available for sale
       * @param _price Price of each token
    */
    function setGenesisConditions(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _multiplier,
        uint256 _maxAvailable,
        uint256 _price
    ) external onlyOwner {
        require(_startTime < _endTime, "Invalid times");
        require(_maxAvailable <= maxSupply - ownerReserve, "_maxAvailable invalid");
        require(_multiplier <= _maxAvailable, "_multiplier invalid");
        
        Genesis.startTime = _startTime;
        Genesis.endTime = _endTime;
        Genesis.multiplier = _multiplier;
        Genesis.maxAvailable = _maxAvailable;
        Genesis.price = _price;
    }
    
    /**
       * @notice This function is used to set the conditions for Whitelist
       * @param _startTime Start time of the sale
       * @param _endTime End time of the sale
       * @param _multiplier Maximum number of tokens a member can mint
       * @param _maxAvailable Maximum number of tokens available for sale
       * @param _price Price of each token
    */
    function setWLConditions(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _multiplier,
        uint256 _maxAvailable,
        uint256 _price
    ) external onlyOwner {
        require(_startTime < _endTime, "Invalid times");
        require(_maxAvailable <= maxSupply - ownerReserve, "_maxAvailable invalid");
        require(_multiplier <= _maxAvailable, "_multiplier invalid");
        
        WL.startTime = _startTime;
        WL.endTime = _endTime;
        WL.multiplier = _multiplier;
        WL.maxAvailable = _maxAvailable;
        WL.price = _price;
    }
    
    /**
       * @notice This function is used to set the conditions for Public Sale
       * @param _startTime Start time of the sale
       * @param _endTime End time of the sale
       * @param _multiplier Maximum number of tokens a member can mint
       * @param _maxAvailable Maximum number of tokens available for sale
       * @param _price Price of each token
    */
    function setPBConditions(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _multiplier,
        uint256 _maxAvailable,
        uint256 _price
    ) external onlyOwner {
        require(_startTime < _endTime, "Invalid times");
        require(_maxAvailable <= maxSupply - ownerReserve, "_maxAvailable invalid");
        require(_multiplier <= _maxAvailable, "_multiplier invalid");
        
        PB.startTime = _startTime;
        PB.endTime = _endTime;
        PB.multiplier = _multiplier;
        PB.maxAvailable = _maxAvailable;
        PB.price = _price;
    }
    
    /**
       * @notice This function is used to set the guaranteed mints
       * @param _mints Number of guaranteed mints
    */
    function setGuaranteedMints(uint256 _mints) external onlyOwner {
        require(_mints <= maxSupply - ownerReserve, "Invalid Mints");
        guaranteedMints = _mints;
    }
    
    /**
       * @notice This function is used to set the address of the NFT contract
       * @param _TestIMS Address of the NFT contract
    */
    function setNFTContract(address _TestIMS) external onlyOwner {
        require(_TestIMS != address(0), "Invalid Address Provided");
        TestIMS = ITestIMS(_TestIMS);
    }
    
    /**
       * @notice This function is used to set the max available tokens for sale in WL Sale
    */
    function checkWLMaxAvailable() internal {
        if (block.timestamp > OG.endTime && block.timestamp > Genesis.endTime && guaranteedMints > 0) {
            WL.maxAvailable += guaranteedMints;
            guaranteedMints = 0;
        }
    }
}