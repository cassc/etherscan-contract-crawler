//SPDX-License-Identifier: None
pragma solidity ^0.8.10;

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
import "./utils/ERC721AUpgradeable.sol";
import "./utils/GasGuzzlersWhitelist.sol";

contract GasGuzzlers is
ERC721AUpgradeable,
OwnableUpgradeable,
PaymentSplitterUpgradeable,
Whitelist,
ReentrancyGuardUpgradeable
{
    /**
    @notice A struct that defines a Sale
    @params startTime Time when the Sale begins
    @params endTime Time when the Sale ends
    @params buyLimit Maximum number of tokens a wallet may mint
    @params maxAvailable Maximum number of tokens that may be sold in the Sale
    @params mintPrice Price to mint one token
    @params register Registry of minters 
    */
    struct sale {
        uint256 startTime;
        uint256 endTime;
        uint256 buyLimit;
        uint256 maxAvailable;
        uint256 mintPrice;
        mapping(address => uint256) register;
    }

    // Early Access Mint
    sale public EA;

    // Early Access Claim
    sale public EAclaim;

    // Blacklist Mint
    sale public BL;

    // Public Mint
    sale public PB;

    string public baseURI;
    address public designatedSigner;

    uint256 public maxSupply;
    uint256 public ownerRemainingTokens;

    modifier checkSupply(uint256 _amount) {
        require(_amount > 0, "Invalid Amount");

        if (EAclaim.startTime <= block.timestamp && block.timestamp <= EAclaim.endTime) {
            require(
                _amount + totalSupply() <= maxSupply - ownerRemainingTokens - EAclaim.maxAvailable,
                "None available at the moment"
            );
        } else {
            require(_amount + totalSupply() <= maxSupply - ownerRemainingTokens, "Sold out");
        }
        _;
    }

    /**
    @notice This function initializes Sale parameters  
    @param _name Collection name  
    @param _symbol Collection Symbol  
    @param _designatedSigner Public address of dedicated private key used for Whitelisting  
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
        __PaymentSplitter_init(_payees, _shares);
        __GasGuzzlersSigner_init();

        baseURI = _uri;
        designatedSigner = _designatedSigner;
        maxSupply = 5555;
        ownerRemainingTokens = 100;

        EA.startTime = block.timestamp; // T = NOW FOR TESTING
        EA.endTime = EA.startTime + 8 hours;
        EA.buyLimit = 3;
        EA.maxAvailable = maxSupply - ownerRemainingTokens;
        EA.mintPrice = 0.055 ether;

        EAclaim.startTime = EA.startTime;
        EAclaim.endTime = EAclaim.startTime + 6 hours;
        EAclaim.buyLimit = 1;
        EAclaim.maxAvailable = 1300; // To be changed later
        EAclaim.mintPrice = EA.mintPrice;

        BL.startTime = EA.startTime;
        BL.endTime = EA.endTime;
        BL.buyLimit = 3;
        BL.maxAvailable = maxSupply - ownerRemainingTokens;
        BL.mintPrice = EA.mintPrice;

        PB.startTime = BL.endTime;
        PB.endTime = PB.startTime + 100 days;
        PB.buyLimit = 3;
        PB.maxAvailable = maxSupply - ownerRemainingTokens;
        PB.mintPrice = EA.mintPrice;
    }

    /**
    @notice This function allows only the owner to airdrop tokens to any address
    @param _amount Amount of tokens to mint in one transaction  
    @param _address Address of the recipient
    */
    function airDrop(uint256 _amount, address _address) external onlyOwner {
        require(_amount + totalSupply() <= maxSupply, "Exceeding supply");
        require(_amount <= ownerRemainingTokens, "Exceeding airdrop allotment");
        require(_address != address(0), "Invalid address");

        ownerRemainingTokens -= _amount;
        _mint(_address, _amount);
    }

    /**
    @notice This function allows members in Early Access list to claim  
    @param _whitelist Whitelisting object which contains user address signed by the designated signer  
    @param _amount Amount of tokens to mint in one transaction   
    */
    function earlyAccessClaim(whitelist memory _whitelist, uint256 _amount)
    external
    payable
    nonReentrant
    {
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == msg.sender, "!Sender");
        require(_whitelist.listType == 1, "!List");

        require(block.timestamp > EAclaim.startTime && block.timestamp <= EAclaim.endTime, "EAclaim sale not active");
        require(_amount + EAclaim.register[msg.sender] <= EAclaim.buyLimit, "EAclaim cannot claim more");

        require(_amount <= EAclaim.maxAvailable, "EAclaim supply over");
        require(msg.value >= _amount * EAclaim.mintPrice, "EAclaim pay more");

        EAclaim.register[msg.sender] += _amount;
        EAclaim.maxAvailable -= _amount;

        if (msg.value > _amount * EAclaim.mintPrice) {
            payable(msg.sender).transfer(msg.value - _amount * EAclaim.mintPrice);
        }

        _mint(msg.sender, _amount);
    }

    /**
    @notice This function allows members in Early Access list to mint  
    @param _whitelist Whitelisting object which contains user address signed by the designated signer  
    @param _amount Amount of tokens to mint in one transaction   
    */
    function earlyAccessMint(whitelist memory _whitelist, uint256 _amount)
    external
    payable
    nonReentrant
    checkSupply(_amount)
    {
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == msg.sender, "!Sender");
        require(_whitelist.listType == 1, "!List");

        require(block.timestamp > EA.startTime && block.timestamp <= EA.endTime, "EA sale not active");
        require(_amount + EA.register[msg.sender] <= EA.buyLimit, "EA cannot mint more");

        require(_amount <= EA.maxAvailable, "EA sold out");
        require(msg.value >= _amount * EA.mintPrice, "EA need to pay more");

        EA.register[msg.sender] += _amount;
        EA.maxAvailable -= _amount;

        if (msg.value > _amount * EA.mintPrice) {
            payable(msg.sender).transfer(msg.value - _amount * EA.mintPrice);
        }

        _mint(msg.sender, _amount);
    }

    /**
    @notice This function allows members in the Blacklist to mint 
    @param _whitelist Whitelisting object which contains user address signed by the designated signer 
    @param _amount Amount of tokens to mint in one transaction  
    */
    function blackListMint(whitelist memory _whitelist, uint256 _amount)
    external
    payable
    nonReentrant
    checkSupply(_amount)
    {
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == msg.sender, "!Sender");
        require(_whitelist.listType == 2, "!List");

        require(block.timestamp > BL.startTime && block.timestamp <= BL.endTime, "BL sale not active");
        require(_amount + BL.register[msg.sender] <= BL.buyLimit, "BL cannot mint more");

        require(_amount <= BL.maxAvailable, "BL sold out");
        require(msg.value >= _amount * BL.mintPrice, "BL pay more");

        BL.register[msg.sender] += _amount;
        BL.maxAvailable -= _amount;

        if (msg.value > _amount * BL.mintPrice) {
            payable(msg.sender).transfer(msg.value - _amount * BL.mintPrice);
        }

        _mint(_whitelist.userAddress, _amount);
    }

    /**
    @notice This function allows anyone to mint   
    @param _amount Amount of tokens to mint in one transactions   
    */
    function publicMint(uint256 _amount)
    external
    payable
    nonReentrant
    checkSupply(_amount)
    {
        require(msg.sender == tx.origin, "PB only users");

        require(block.timestamp > PB.startTime && block.timestamp <= PB.endTime, "PB sale not active");
        require(_amount + PB.register[msg.sender] <= PB.buyLimit, "PB cannot mint more");

        require(_amount <= PB.maxAvailable, "PB supply over");
        require(msg.value >= _amount * PB.mintPrice, "PB pay more");

        PB.register[msg.sender] += _amount;
        PB.maxAvailable -= _amount;

        if (msg.value > _amount * PB.mintPrice) {
            payable(msg.sender).transfer(msg.value - _amount * PB.mintPrice);
        }

        _mint(msg.sender, _amount);
    }

    /**
    @notice This function returns the number of tokens minted by a member in Early Access list   
    @param _address Address of the member   
    */
    function readEAregister(address _address) public view returns (uint256) {
        require(_address != address(0), "Invalid address provided");
        return EA.register[_address];
    }

    /**
    @notice This function returns the number of tokens claimed by a member in Early Access list   
    @param _address Address of the member   
    */
    function readEAclaimRegister(address _address) public view returns (uint256) {
        require(_address != address(0), "Invalid address provided");
        return EAclaim.register[_address];
    }

    /**
    @notice This function returns the number of tokens minted by a member in Blacklist  
    @param _address Address of the member   
    */
    function readBLregister(address _address) public view returns (uint256) {
        require(_address != address(0), "Invalid address provided");
        return BL.register[_address];
    }

    /**
    @notice This function returns the number of tokens minted by a user 
    @param _address Address of the user   
    */
    function readPBregister(address _address) public view returns (uint256) {
        require(_address != address(0), "Invalid address provided");
        return PB.register[_address];
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

    function setEAconditions(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _buyLimit,
        uint256 _maxAvailable,
        uint256 _mintPrice
    ) external onlyOwner {
        require(_startTime < _endTime, "Invalid times");
        require(_maxAvailable <= maxSupply - ownerRemainingTokens, "_maxAvailable invalid");

        EA.startTime = _startTime;
        EA.endTime = _endTime;
        EA.buyLimit = _buyLimit;
        EA.maxAvailable = _maxAvailable;
        EA.mintPrice = _mintPrice;
    }

    function setEAclaimConditions(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _buyLimit,
        uint256 _maxAvailable,
        uint256 _mintPrice
    ) external onlyOwner {
        require(_startTime < _endTime, "Invalid times");
        require(_maxAvailable <= maxSupply - ownerRemainingTokens, "_maxAvailable invalid");

        EAclaim.startTime = _startTime;
        EAclaim.endTime = _endTime;
        EAclaim.buyLimit = _buyLimit;
        EAclaim.maxAvailable = _maxAvailable;
        EAclaim.mintPrice = _mintPrice;
    }

    function setBLconditions(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _buyLimit,
        uint256 _maxAvailable,
        uint256 _mintPrice
    ) external onlyOwner {
        require(_startTime < _endTime, "Invalid times");
        require(_maxAvailable <= maxSupply - ownerRemainingTokens, "_maxAvailable invalid");

        BL.startTime = _startTime;
        BL.endTime = _endTime;
        BL.buyLimit = _buyLimit;
        BL.maxAvailable = _maxAvailable;
        BL.mintPrice = _mintPrice;
    }

    function setPBconditions(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _buyLimit,
        uint256 _maxAvailable,
        uint256 _mintPrice
    ) external onlyOwner {
        require(_startTime < _endTime, "Invalid times");
        require(_maxAvailable <= maxSupply - ownerRemainingTokens, "_maxAvailable invalid");

        PB.startTime = _startTime;
        PB.endTime = _endTime;
        PB.buyLimit = _buyLimit;
        PB.maxAvailable = _maxAvailable;
        PB.mintPrice = _mintPrice;
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
}