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
import "./utils/ERC721AUpgradeable.sol";
import "./utils/JovynnWhitelist.sol";

contract Jovynn is
ERC721AUpgradeable,
OwnableUpgradeable,
Whitelist,
ReentrancyGuardUpgradeable
{
    /**
    @notice A struct that defines a Sale
    @params startTime Time when the Sale begins
    @params endTime Time when the Sale ends
    @params buyLimit Maximum number of tokens a wallet may mint
    @params maxAvailable Maximum number of tokens that may be sold in the Sale
    @params register Registry of minters 
    */
    struct sale {
        uint256 startTime;
        uint256 endTime;
        uint256 buyLimit;
        uint256 maxAvailable;
        mapping(address => uint256) register;
    }

    sale public WL1;
    sale public WL2;
    sale public WL3;
    sale public WL4;
    sale public WL5;
    sale public WL6;

    sale public PB;

    string public baseURI;
    address public designatedSigner;

    uint256 public maxSupply;
    uint256 public ownerRemainingTokens;

    modifier checkSupply(uint256 _amount) {
        require(_amount > 0, "Invalid Amount");
        require(_amount + totalSupply() <= maxSupply - ownerRemainingTokens, "Sold out");
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
        address _designatedSigner
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721A_init(_name, _symbol);
        __JovynnSigner_init();

        baseURI = _uri;
        designatedSigner = _designatedSigner;
        maxSupply = 1000;
        ownerRemainingTokens = 100;

        WL1.startTime = 1664964000; // 5 Oct 2022, 3:30PM IST
        WL1.endTime = WL1.startTime + 4 hours;
        WL1.buyLimit = 1;
        WL1.maxAvailable = 74;

        WL2.startTime = WL1.startTime;
        WL2.endTime = WL1.endTime;
        WL2.buyLimit = 2;
        WL2.maxAvailable = 34;

        WL3.startTime = WL1.startTime;
        WL3.endTime = WL1.endTime;
        WL3.buyLimit = 3;
        WL3.maxAvailable = 15;

        WL4.startTime = WL1.startTime;
        WL4.endTime = WL1.endTime;
        WL4.buyLimit = 4;
        WL4.maxAvailable = 28;

        WL5.startTime = WL1.startTime;
        WL5.endTime = WL1.endTime;
        WL5.buyLimit = 5;
        WL5.maxAvailable = 35;

        WL6.startTime = WL1.endTime;
        WL6.endTime = WL6.startTime + 12 hours;
        WL6.buyLimit = 2;
        WL6.maxAvailable = maxSupply - ownerRemainingTokens;

        PB.startTime = WL6.endTime;
        PB.endTime = PB.startTime + 100 days;
        PB.buyLimit = 2;
        PB.maxAvailable = maxSupply - ownerRemainingTokens;
    }

    /**
    @notice This function allows only the owner to airdrop tokens to any address
    @param _amount Amount of tokens to mint in one transaction  
    @param _address Address of the recipient
    */
    function airDrop(uint256 _amount, address _address) external onlyOwner {
        require(_amount + totalSupply() <= maxSupply, "Exceeding supply");
        require(_amount <= ownerRemainingTokens, "Exceeding airdrop allotment");

        ownerRemainingTokens -= _amount;
        _mint(_address, _amount);
    }


    /**
    @notice This function allows members in Whitelist-1 to mint  
    @param _whitelist Whitelisting object which contains user address signed by the designated signer  
    @param _amount Amount of tokens to mint in one transaction   
    */
    function WL1mint(whitelist memory _whitelist, uint256 _amount)
    external
    nonReentrant
    checkSupply(_amount)
    {
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == msg.sender, "!Sender");
        require(_whitelist.listType == 1, "!List");

        require(block.timestamp > WL1.startTime && block.timestamp <= WL1.endTime, "WL1 sale not active");
        require(_amount + WL1.register[msg.sender] <= WL1.buyLimit, "WL1 cannot mint more");

        require(_amount <= WL1.maxAvailable, "WL1 sold out");

        WL1.register[msg.sender] += _amount;
        WL1.maxAvailable -= _amount;

        _mint(msg.sender, _amount);
    }


    /**
    @notice This function allows members in Whitelist-2 to claim  
    @param _whitelist Whitelisting object which contains user address signed by the designated signer  
    @param _amount Amount of tokens to mint in one transaction   
    */
    function WL2mint(whitelist memory _whitelist, uint256 _amount)
    external
    nonReentrant
    checkSupply(_amount)
    {
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == msg.sender, "!Sender");
        require(_whitelist.listType == 2, "!List");

        require(block.timestamp > WL2.startTime && block.timestamp <= WL2.endTime, "WL2 sale not active");
        require(_amount + WL2.register[msg.sender] <= WL2.buyLimit, "WL2 cannot claim more");

        require(_amount <= WL2.maxAvailable, "WL2 supply over");

        WL2.register[msg.sender] += _amount;
        WL2.maxAvailable -= _amount;

        _mint(msg.sender, _amount);
    }

    /**
    @notice This function allows members in the Whitelist-3 to mint 
    @param _whitelist Whitelisting object which contains user address signed by the designated signer 
    @param _amount Amount of tokens to mint in one transaction  
    */
    function WL3mint(whitelist memory _whitelist, uint256 _amount)
    external
    nonReentrant
    checkSupply(_amount)
    {
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == msg.sender, "!Sender");
        require(_whitelist.listType == 3, "!List");

        require(block.timestamp > WL3.startTime && block.timestamp <= WL3.endTime, "WL3 sale not active");
        require(_amount + WL3.register[msg.sender] <= WL3.buyLimit, "WL3 cannot mint more");

        require(_amount <= WL3.maxAvailable, "WL3 sold out");

        WL3.register[msg.sender] += _amount;
        WL3.maxAvailable -= _amount;

        _mint(_whitelist.userAddress, _amount);
    }

    /**
    @notice This function allows members in the Whitelist-4 to mint 
    @param _whitelist Whitelisting object which contains user address signed by the designated signer 
    @param _amount Amount of tokens to mint in one transaction  
    */
    function WL4mint(whitelist memory _whitelist, uint256 _amount)
    external
    nonReentrant
    checkSupply(_amount)
    {
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == msg.sender, "!Sender");
        require(_whitelist.listType == 4, "!List");

        require(block.timestamp > WL4.startTime && block.timestamp <= WL4.endTime, "WL4 sale not active");
        require(_amount + WL4.register[msg.sender] <= WL4.buyLimit, "WL4 cannot mint more");

        require(_amount <= WL4.maxAvailable, "WL4 sold out");

        WL4.register[msg.sender] += _amount;
        WL4.maxAvailable -= _amount;

        _mint(_whitelist.userAddress, _amount);
    }

    /**
    @notice This function allows members in the Whitelist-5 to mint 
    @param _whitelist Whitelisting object which contains user address signed by the designated signer 
    @param _amount Amount of tokens to mint in one transaction  
    */
    function WL5mint(whitelist memory _whitelist, uint256 _amount)
    external
    nonReentrant
    checkSupply(_amount)
    {
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == msg.sender, "!Sender");
        require(_whitelist.listType == 5, "!List");

        require(block.timestamp > WL5.startTime && block.timestamp <= WL5.endTime, "WL5 sale not active");
        require(_amount + WL5.register[msg.sender] <= WL5.buyLimit, "WL5 cannot mint more");

        require(_amount <= WL5.maxAvailable, "WL5 sold out");

        WL5.register[msg.sender] += _amount;
        WL5.maxAvailable -= _amount;

        _mint(_whitelist.userAddress, _amount);
    }

    /**
    @notice This function allows members in the Whitelist-6 to mint 
    @param _whitelist Whitelisting object which contains user address signed by the designated signer 
    @param _amount Amount of tokens to mint in one transaction  
    */
    function WL6mint(whitelist memory _whitelist, uint256 _amount)
    external
    nonReentrant
    checkSupply(_amount)
    {
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == msg.sender, "!Sender");
        require(_whitelist.listType == 6, "!List");

        require(block.timestamp > WL6.startTime && block.timestamp <= WL6.endTime, "WL6 sale not active");
        require(_amount + WL6.register[msg.sender] <= WL6.buyLimit, "WL6 cannot mint more");

        require(_amount <= WL6.maxAvailable, "WL6 sold out");

        WL6.register[msg.sender] += _amount;
        WL6.maxAvailable -= _amount;

        _mint(_whitelist.userAddress, _amount);
    }

    /**
    @notice This function allows anyone to mint   
    @param _amount Amount of tokens to mint in one transactions   
    */
    function publicMint(uint256 _amount)
    external
    nonReentrant
    checkSupply(_amount)
    {
        require(msg.sender == tx.origin, "PB only users");

        require(block.timestamp > PB.startTime && block.timestamp <= PB.endTime, "PB sale not active");
        require(_amount + PB.register[msg.sender] <= PB.buyLimit, "PB cannot mint more");

        require(_amount <= PB.maxAvailable, "PB supply over");

        PB.register[msg.sender] += _amount;
        PB.maxAvailable -= _amount;

        _mint(msg.sender, _amount);
    }

    /**
    @notice This function returns the number of tokens minted by a member in Early Access list   
    @param _address Address of the member   
    */
    function readWL1register(address _address) public view returns (uint256) {
        require(_address != address(0), "Invalid address provided");
        return WL1.register[_address];
    }

    /**
    @notice This function returns the number of tokens claimed by a member in Early Access list   
    @param _address Address of the member   
    */
    function readWL2register(address _address) public view returns (uint256) {
        require(_address != address(0), "Invalid address provided");
        return WL2.register[_address];
    }

    /**
    @notice This function returns the number of tokens minted by a member in Blacklist  
    @param _address Address of the member   
    */
    function readWL3register(address _address) public view returns (uint256) {
        require(_address != address(0), "Invalid address provided");
        return WL3.register[_address];
    }

    /**
    @notice This function returns the number of tokens minted by a member in Blacklist  
    @param _address Address of the member   
    */
    function readWL4register(address _address) public view returns (uint256) {
        require(_address != address(0), "Invalid address provided");
        return WL4.register[_address];
    }

    /**
    @notice This function returns the number of tokens minted by a member in Blacklist  
    @param _address Address of the member   
    */
    function readWL5register(address _address) public view returns (uint256) {
        require(_address != address(0), "Invalid address provided");
        return WL5.register[_address];
    }

    /**
    @notice This function returns the number of tokens minted by a member in Blacklist  
    @param _address Address of the member   
    */
    function readWL6register(address _address) public view returns (uint256) {
        require(_address != address(0), "Invalid address provided");
        return WL6.register[_address];
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
        require(totalSupply() <= _supply, "Total Supply Exceeding");
        maxSupply = _supply;
    }

    function setOwnerCap(uint256 _cap) external onlyOwner {
        ownerRemainingTokens = _cap;
    }

    function setWL1conditions(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _buyLimit,
        uint256 _maxAvailable
    ) external onlyOwner {
        require(_startTime < _endTime, "Invalid times");
        require(_maxAvailable <= maxSupply - ownerRemainingTokens, "_maxAvailable invalid");

        WL1.startTime = _startTime;
        WL1.endTime = _endTime;
        WL1.buyLimit = _buyLimit;
        WL1.maxAvailable = _maxAvailable;
    }

    function setWL2Conditions(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _buyLimit,
        uint256 _maxAvailable
    ) external onlyOwner {
        require(_startTime < _endTime, "Invalid times");
        require(_maxAvailable <= maxSupply - ownerRemainingTokens, "_maxAvailable invalid");

        WL2.startTime = _startTime;
        WL2.endTime = _endTime;
        WL2.buyLimit = _buyLimit;
        WL2.maxAvailable = _maxAvailable;
    }

    function setWL3conditions(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _buyLimit,
        uint256 _maxAvailable
    ) external onlyOwner {
        require(_startTime < _endTime, "Invalid times");
        require(_maxAvailable <= maxSupply - ownerRemainingTokens, "_maxAvailable invalid");

        WL3.startTime = _startTime;
        WL3.endTime = _endTime;
        WL3.buyLimit = _buyLimit;
        WL3.maxAvailable = _maxAvailable;
    }

    function setWL4conditions(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _buyLimit,
        uint256 _maxAvailable
    ) external onlyOwner {
        require(_startTime < _endTime, "Invalid times");
        require(_maxAvailable <= maxSupply - ownerRemainingTokens, "_maxAvailable invalid");

        WL4.startTime = _startTime;
        WL4.endTime = _endTime;
        WL4.buyLimit = _buyLimit;
        WL4.maxAvailable = _maxAvailable;
    }

    function setWL5conditions(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _buyLimit,
        uint256 _maxAvailable
    ) external onlyOwner {
        require(_startTime < _endTime, "Invalid times");
        require(_maxAvailable <= maxSupply - ownerRemainingTokens, "_maxAvailable invalid");

        WL5.startTime = _startTime;
        WL5.endTime = _endTime;
        WL5.buyLimit = _buyLimit;
        WL5.maxAvailable = _maxAvailable;
    }

    function setWL6conditions(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _buyLimit,
        uint256 _maxAvailable
    ) external onlyOwner {
        require(_startTime < _endTime, "Invalid times");
        require(_maxAvailable <= maxSupply - ownerRemainingTokens, "_maxAvailable invalid");

        WL6.startTime = _startTime;
        WL6.endTime = _endTime;
        WL6.buyLimit = _buyLimit;
        WL6.maxAvailable = _maxAvailable;
    }

    function setPBconditions(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _buyLimit,
        uint256 _maxAvailable
    ) external onlyOwner {
        require(_startTime < _endTime, "Invalid times");
        require(_maxAvailable <= maxSupply - ownerRemainingTokens, "_maxAvailable invalid");

        PB.startTime = _startTime;
        PB.endTime = _endTime;
        PB.buyLimit = _buyLimit;
        PB.maxAvailable = _maxAvailable;
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