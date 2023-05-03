// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Whitelist} from "./utils/WhiteListSigner.sol";
import {ITestNFT} from "./Interface/ITestNFT.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {PaymentSplitterUpgradeable} from "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract TestAPOMintController is
OwnableUpgradeable,
PausableUpgradeable,
PaymentSplitterUpgradeable,
ReentrancyGuardUpgradeable,
Whitelist
{
    /**
       * @notice A struct that defines a Sale
       * @params startTime Time when the Sale begins
       * @params endTime Time when the Sale ends
       * @params buyLimit Maximum number of tokens a wallet may mint
       * @params maxAvailable Maximum number of tokens that may be sold in the Sale
       * @params register Registry of minters
    */
    struct sale {
        uint16 buyLimit;
        uint16 maxAvailable;
        uint32 startTime;
        uint32 endTime;
        uint256 price;
        mapping(address => uint256) register;
    }
    // Whitelist Sale
    sale public WL;
    // Public Sale
    sale public PB;
    
    uint16 public maxSupply;
    uint16 public ownerMinted;
    uint16 public ownerReserve;
    address public designatedSigner;
    ITestNFT public APO;

    mapping(bytes => bool) public usedSignatures;
    
    modifier checkSupply(uint256 _amount) {
        require(_amount > 0, "Invalid Amount");
        require(_amount + APO.totalSupply() <= (maxSupply - ownerReserve) + ownerMinted, "Sold out");
        _;
    }
    
    /**
	   * @notice This function initializes Sale parameters
       * @param _designatedSigner Public address of dedicated private key used for Whitelisting
       * @param _payees Addresses of the payees
       * @param _shares Shares of the payees
    */
    function initialize(
        address _apollumia,
        address _designatedSigner,
        address[] memory _payees,
        uint256[] memory _shares
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __WhiteList_init();
        __PaymentSplitter_init(_payees, _shares);
        APO = ITestNFT(_apollumia);
        
        designatedSigner = _designatedSigner;
        
        maxSupply = 1000;
        ownerReserve = 10;
        
        WL.startTime = 1682054819; // Friday, 21 April 2023 10:56:59 GMT+05:30
        WL.endTime = WL.startTime + 4 hours;
        WL.buyLimit = 1;
        WL.maxAvailable = maxSupply - ownerReserve;
        WL.price = 0.046 ether;
        
        PB.startTime = WL.endTime; // Friday, 21 April 2023 10:56:59 GMT+05:30
        PB.endTime = PB.startTime + 4 hours;
        PB.buyLimit = 1;
        PB.maxAvailable = maxSupply - ownerReserve;
        PB.price = 0.046 ether;
    }
    
    /**
	   * @notice This function allows only the owner to airdrop tokens to any address
       * @param _amount Amount of tokens to mint in one transaction
       * @param _address Address of the recipient
    */
    function airDrop(uint16 _amount, address _address) external onlyOwner {
        require(_amount + APO.totalSupply() <= maxSupply, "Exceeding supply");
        require(_amount + ownerMinted <= ownerReserve, "Exceeding airdrop allotment");
        
        ownerMinted += _amount;
        APO.mint(_address, _amount);
    }
    
    /**
	   * @notice This function allows members in Whitelist-1 to mint
	   * @param _to Address of the recipient
       * @param _whitelist Whitelisting object which contains user address signed by the designated signer
       * @param _amount Amount of tokens to mint in one transaction
    */
    function WLMint(address _to, whitelist memory _whitelist, uint16 _amount)
    external
    payable
    nonReentrant
    whenNotPaused
    checkSupply(_amount)
    {
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == _to, "!Sender");
        require(_whitelist.listType == 1, "!List");
        require(_whitelist.nonce + 5 minutes >= block.timestamp, "WL nonce expired");
        require(!usedSignatures[_whitelist.signature], "WL already used");
        require(block.timestamp > WL.startTime && block.timestamp <= WL.endTime, "WL sale not active");
        require(_amount + WL.register[_to] <= WL.buyLimit, "WL cannot mint more");
        require(_amount <= WL.maxAvailable, "WL sold out");
        require(msg.value == _amount * WL.price, "WL insufficient funds sent");
        usedSignatures[_whitelist.signature] = true;
        unchecked
        {
            WL.register[_to] += _amount;
            WL.maxAvailable -= _amount;
        }
        APO.mint(_to, _amount);
    }
    
    function PBMint(address _to, uint16 _amount)
    external
    payable
    nonReentrant
    whenNotPaused
    checkSupply(_amount) {
        require(block.timestamp > PB.startTime && block.timestamp <= PB.endTime, "PB sale not active");
        require(_amount + PB.register[_to] <= PB.buyLimit, "PB cannot mint more");
        require(_amount <= PB.maxAvailable, "PB sold out");
        require(msg.value == _amount * PB.price, "PB insufficient funds sent");
        unchecked
        {
            PB.register[_to] += _amount;
            PB.maxAvailable -= _amount;
        }
        APO.mint(_to, _amount);
    }
    
    /**
        * @notice This function returns the number of tokens minted by a member in Whitelist
        * @param _address Address of the member
    */
    function readWLRegister(address _address) public view returns (uint256) {
        require(_address != address(0), "Invalid address provided");
        return WL.register[_address];
    }
    
    /**
        * @notice This function returns the number of tokens minted by a member in Early Access2 list
        * @param _address Address of the member
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
        * @notice This function is used to set the max supply
        * @param _supply Max supply of the token
    */
    function setMaxSupply(uint16 _supply) external onlyOwner {
        require(APO.totalSupply() <= _supply, "Total Supply Exceeding");
        maxSupply = _supply;
    }
    
    /**
        * @notice This function is used to set the owner reserve
        * @param _cap Owner reserve
    */
    function setOwnerCap(uint16 _cap) external onlyOwner {
        require(uint16(APO.totalSupply()) + _cap <= maxSupply, "Total Supply Exceeding");
        require(_cap >= ownerMinted, "Owner Cap Exceeding");
        ownerReserve = _cap;
    }
    
    /**
        * @notice This function is used to set the conditions for Whitelist-1
        * @param _startTime Start time of the sale
        * @param _endTime End time of the sale
        * @param _buyLimit Maximum number of tokens a member can mint
        * @param _maxAvailable Maximum number of tokens available for sale
        * @param _price Price of the token
    */
    function setWLConditions(
        uint16 _buyLimit,
        uint16 _maxAvailable,
        uint32 _startTime,
        uint32 _endTime,
        uint256 _price
    ) external onlyOwner {
        require(_startTime < _endTime, "Invalid times");
        require(_maxAvailable <= maxSupply - ownerReserve, "_maxAvailable invalid");
        
        WL.startTime = _startTime;
        WL.endTime = _endTime;
        WL.buyLimit = _buyLimit;
        WL.maxAvailable = _maxAvailable;
        WL.price = _price;
    }
    
    /**
        * @notice This function is used to set the conditions for Early Access2
        * @param _startTime Start time of the sale
        * @param _endTime End time of the sale
        * @param _buyLimit Maximum number of tokens a member can mint
        * @param _maxAvailable Maximum number of tokens available for sale
        * @param _price Price of the token
    */
    function setPBConditions(
        uint16 _buyLimit,
        uint16 _maxAvailable,
        uint32 _startTime,
        uint32 _endTime,
        uint256 _price
    ) external onlyOwner {
        require(_startTime < _endTime, "Invalid times");
        require(_maxAvailable <= maxSupply - ownerReserve, "_maxAvailable invalid");
        
        PB.startTime = _startTime;
        PB.endTime = _endTime;
        PB.buyLimit = _buyLimit;
        PB.maxAvailable = _maxAvailable;
        PB.price = _price;
    }
    
    /**
        * @notice This function is used to set the address of the APO contract
        * @param _apollumia Address of the APO contract
    */
    function setNFTContract(address _apollumia) external onlyOwner {
        require(_apollumia != address(0), "Invalid Address Provided");
        APO = ITestNFT(_apollumia);
    }
    
    /**
	 * @notice This function is used to set the PublicSale parameters
        * @param _startTime Start time of the sale
        * @param _endTime End time of the sale
    */
    function startPublicSale(uint32 _startTime, uint32 _endTime) external onlyOwner {
        WL.endTime = _startTime;
        PB.startTime = _startTime;
        PB.endTime = _endTime;
    }
    
}