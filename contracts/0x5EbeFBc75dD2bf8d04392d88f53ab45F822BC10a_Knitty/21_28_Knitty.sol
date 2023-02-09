//SPDX-License-Identifier: None
pragma solidity ^0.8.7;

/*


 .d8888b.                    888                      d8b              888               888               
d88P  Y88b                   888                      Y8P              888               888               
888    888                   888                                       888               888               
888    888 888  888 888  888 888888  .d88b.   .d8888b 888 88888b.      888       8888b.  88888b.  .d8888b  
888    888 `Y8bd8P' 888  888 888    d88""88b d88P"    888 888 "88b     888          "88b 888 "88b 88K      
888    888   X88K   888  888 888    888  888 888      888 888  888     888      .d888888 888  888 "Y8888b. 
Y88b  d88P .d8""8b. Y88b 888 Y88b.  Y88..88P Y88b.    888 888  888     888      888  888 888 d88P      X88 
 "Y8888P"  888  888  "Y88888  "Y888  "Y88P"   "Y8888P 888 888  888     88888888 "Y888888 88888P"   88888P' 
                         888                                                                               
                    Y8b d88P                                                                               
                     "Y88P"                                                                                
*/


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./utils/ERC721AUpgradeable.sol";
import "./utils/WhiteListSigner.sol";
import {RevokableOperatorFiltererUpgradeable} from "./OpenseaRegistries/RevokableOperatorFiltererUpgradeable.sol";
import {RevokableDefaultOperatorFiltererUpgradeable} from "./OpenseaRegistries/RevokableDefaultOperatorFiltererUpgradeable.sol";
import {UpdatableOperatorFilterer} from "./OpenseaRegistries/UpdatableOperatorFilterer.sol";

contract Knitty is
ERC721AUpgradeable,
OwnableUpgradeable,
PausableUpgradeable,
PaymentSplitterUpgradeable,
ReentrancyGuardUpgradeable,
RevokableDefaultOperatorFiltererUpgradeable,
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
        uint256 startTime;
        uint256 endTime;
        uint256 buyLimit;
        uint256 maxAvailable;
        uint256 price;
        mapping(address => uint256) register;
    }

    // Whitelist Sale
    sale public WL;

    // Public Sale
    sale public PB;

    string public baseURI;
    address public designatedSigner;
    
    uint256 public maxSupply;
    uint256 public ownerReserve;

    modifier checkSupply(uint256 _amount) {
        require(_amount > 0, "Invalid Amount");
        require(_amount + totalSupply() <= maxSupply - ownerReserve, "Sold out");
        _;
    }

    /**
       * @notice This function initializes Sale parameters
       * @param _name Collection name
       * @param _symbol Collection Symbol
       * @param _designatedSigner Public address of dedicated private key used for Whitelisting
       * @param _payees Addresses of the payees
       * @param _shares Shares of the payees
    */
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _designatedSigner,
        address[] memory _payees,
        uint256[] memory _shares
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721A_init(_name, _symbol);
        __Pausable_init();
        __WhiteList_init();
        __PaymentSplitter_init(_payees, _shares);

        baseURI = _uri;
        designatedSigner = _designatedSigner;
        
        maxSupply = 999;
        ownerReserve = 33;

        WL.startTime = 1675925966; // February 9, 2023 12:29:26 PM
        WL.endTime = WL.startTime + 2 hours;
        WL.buyLimit = 2;
        WL.maxAvailable = maxSupply - ownerReserve;
        WL.price = 0.018 ether;

        PB.startTime = WL.endTime;
        PB.endTime = PB.startTime + 100 days;
        PB.buyLimit = 2;
        PB.maxAvailable = maxSupply - ownerReserve;
        PB.price = 0.018 ether;
    }

    /**
       * @notice This function allows only the owner to airdrop tokens to any address
       * @param _amount Amount of tokens to mint in one transaction
       * @param _address Address of the recipient
    */
    function airDrop(uint256 _amount, address _address) external onlyOwner {
        require(_amount + totalSupply() <= maxSupply, "Exceeding supply");
        require(_amount <= ownerReserve, "Exceeding airdrop allotment");

        ownerReserve -= _amount;
        _mint(_address, _amount);
    }


    /**
       * @notice This function allows members in Whitelist-1 to mint
       * @param _whitelist Whitelisting object which contains user address signed by the designated signer
       * @param _amount Amount of tokens to mint in one transaction
    */
    function WLmint(whitelist memory _whitelist, uint256 _amount)
    external
    payable
    nonReentrant
    whenNotPaused
    checkSupply(_amount)
    {
        require(msg.sender == tx.origin, "WL only users");
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == msg.sender, "!Sender");
        require(_whitelist.listType == 1, "!List");

        require(block.timestamp > WL.startTime && block.timestamp <= WL.endTime, "WL sale not active");
        require(_amount + WL.register[msg.sender] <= WL.buyLimit, "WL cannot mint more");

        require(_amount <= WL.maxAvailable, "WL sold out");
        require(msg.value >= _amount * WL.price, "WL insufficient funds sent");
        
        WL.register[msg.sender] += _amount;
        WL.maxAvailable -= _amount;

        if (msg.value > _amount * WL.price) {
            payable(msg.sender).transfer(msg.value - _amount * WL.price);
        }

        _mint(msg.sender, _amount);
    }


    /**
       * @notice This function allows anyone to mint
       * @param _amount Amount of tokens to mint in one transactions
    */
    function publicMint(uint256 _amount)
    external
    payable
    nonReentrant
    whenNotPaused
    checkSupply(_amount)
    {
        require(msg.sender == tx.origin, "PB only users");
        require(msg.value >= _amount * PB.price, "PB insufficient funds sent");
        require(block.timestamp > PB.startTime && block.timestamp <= PB.endTime, "PB sale not active");
        require(_amount + PB.register[msg.sender] <= PB.buyLimit, "PB cannot mint more");
        require(_amount <= PB.maxAvailable, "PB supply over");

        PB.register[msg.sender] += _amount;
        PB.maxAvailable -= _amount;

        if (msg.value > _amount * PB.price) {
            payable(msg.sender).transfer(msg.value - _amount * PB.price);
        }

        _mint(msg.sender, _amount);
    }

    /**
    @notice This function returns the number of tokens minted by a member in Early Access list   
    @param _address Address of the member   
    */
    function readWLregister(address _address) public view returns (uint256) {
        require(_address != address(0), "Invalid address provided");
        return WL.register[_address];
    }

    /**
    @notice This function returns the number of tokens minted by a user 
    @param _address Address of the user   
    */
    function readPBregister(address _address) public view returns (uint256) {
        require(_address != address(0), "Invalid address provided");
        return PB.register[_address];
    }

    /**
    @notice The function is used to pause/ unpause mint functions   
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
        require(totalSupply() <= _supply, "Total Supply Exceeding");
        maxSupply = _supply;
    }

    function setOwnerCap(uint256 _cap) external onlyOwner {
        require(totalSupply() + _cap <= maxSupply, "Total Supply Exceeding");
        ownerReserve = _cap;
    }

    function setWLconditions(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _buyLimit,
        uint256 _maxAvailable,
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

    function setPBconditions(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _buyLimit,
        uint256 _maxAvailable,
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

    ////////////////
    ///Overridden///
    ////////////////

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    //----------------OpenSea Functions----------------
    
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }
    
    function approve(address operator, uint256 tokenId) public virtual override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
    function owner()
    public
    view
    virtual
    override (OwnableUpgradeable, RevokableOperatorFiltererUpgradeable)
    returns (address)
    {
        return OwnableUpgradeable.owner();
    }
    
}