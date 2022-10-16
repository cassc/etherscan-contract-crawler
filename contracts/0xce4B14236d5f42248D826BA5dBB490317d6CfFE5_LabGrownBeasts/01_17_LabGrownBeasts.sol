//SPDX-License-Identifier: None
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./utils/ERC721AUpgradeable.sol";
import "./utils/Whitelist.sol";

contract LabGrownBeasts is
    ERC721AUpgradeable, 
    OwnableUpgradeable,
    PausableUpgradeable, 
    ReentrancyGuardUpgradeable,
    Whitelist
{
    struct sale {
        uint startTime;
        uint endTime;
        uint maxAvailable;
        uint purchaseLimit;
        uint price;
        mapping(address => uint) register;
    }

    string public baseURI;
    address public designatedSigner;
    address payable public treasury;

    uint public maxSupply;
    uint public reserve;

    sale public beasts;
    sale public labGrownBeasts;
    sale public postMint;

    modifier checkSupply(uint256 _amount) {
        require(
            _amount > 0,
            "Invalid amount"
        );
        require(
            totalSupply() + _amount <= maxSupply - reserve,
            "Exceeding max supply"
        );
        _;
    }

    /**
    @notice This function sets Sale parameters and other required parameters  
    @param _name Collection name  
    @param _symbol Collection Symbol  
    @param _uri Collection Base URI
    @param _designatedSigner Public address of designated private key for Whitelisting  
    */

    function initialize (
        string memory _name, 
        string memory _symbol,
        string memory _uri, 
        address _designatedSigner
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC721A_init(_name, _symbol);
        __WhitelistSigner_init();

        baseURI = _uri;
        designatedSigner = _designatedSigner;
        treasury = payable(0x1dd829644504954f5885bb63aCEeD2bD9931213A);
        
        maxSupply = 1212;
        reserve = 121;

        beasts.startTime = 1665838800;
        beasts.endTime = 1665844200;
        beasts.purchaseLimit = 1;
        beasts.maxAvailable = 971;
        beasts.price = 0.12 ether;

        labGrownBeasts.startTime = beasts.startTime;
        labGrownBeasts.endTime = beasts.endTime;
        labGrownBeasts.purchaseLimit = 2;
        labGrownBeasts.maxAvailable = 971;
        labGrownBeasts.price = 0.12 ether;

        postMint.startTime = beasts.endTime + 24 hours;
        postMint.endTime = postMint.startTime + 3 days;
        postMint.purchaseLimit = 1;
        postMint.maxAvailable = 120;
        postMint.price = 0.12 ether;
    }

    function airDrop(address _address, uint _amount) 
        external 
        onlyOwner
    {
        require(_amount + totalSupply() <= maxSupply, "Exceeding Max Supply");
        require(_amount <= reserve, "Exceeding Owner Limit");
        
        reserve -= _amount;
        _mint(_address, _amount);
    }

    /**
    @notice This function mints tokens only to members in Beast List  
    @param _whitelist Whitelisted object which contains user address signed by designatedSigner  
    @param _amount Amount of tokens to mint in one transaction  
    */

    function beastsSale(whitelist memory _whitelist, uint _amount) 
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
                block.timestamp > beasts.startTime && block.timestamp <= beasts.endTime,
                "Beasts: Sale not active"
            );
        require(
                _amount + beasts.register[msg.sender] <= beasts.purchaseLimit,
                "Beasts: Cannot mint more"
            );
        require(_amount <= beasts.maxAvailable, "Beasts: Sold out");
        require(msg.value >= _amount * beasts.price, "Beasts: Pay more");

        beasts.register[msg.sender] += _amount;
        beasts.maxAvailable -= _amount;
        labGrownBeasts.maxAvailable -= _amount;

        if (msg.value > _amount * beasts.price) {
            payable(msg.sender).transfer(msg.value - _amount * beasts.price);
        }

        _mint(msg.sender, _amount);
    } 

    /**
    @notice This function mints tokens only to members in Lab Grown Beast list  
    @param _whitelist Whitelisted object which contains user address signed by designatedSigner  
    @param _amount Amount of tokens to mint in one transaction  
    */

    function labGrownBeastsSale(whitelist memory _whitelist, uint _amount) 
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
                block.timestamp > labGrownBeasts.startTime && block.timestamp <= labGrownBeasts.endTime, 
                "Lab Grown Beasts: Sale not active"
            );
        require(
                _amount + labGrownBeasts.register[msg.sender] <= labGrownBeasts.purchaseLimit,
                "Lab Grown Beasts: Cannot mint more"
            );
        require(_amount <= labGrownBeasts.maxAvailable, "Lab Grown Beasts: Sold out");
        require(msg.value >= _amount * labGrownBeasts.price, "Lab Grown Beasts: Pay more");

        labGrownBeasts.register[msg.sender] += _amount;
        labGrownBeasts.maxAvailable -= _amount;
        beasts.maxAvailable -= _amount;
        
        if (msg.value > _amount * labGrownBeasts.price) {
            payable(msg.sender).transfer(msg.value - _amount * labGrownBeasts.price);
        }

        _mint(msg.sender, _amount);
    } 

    /**
    @notice This function mints tokens only to members in Wild DNA list
    @param _whitelist Whitelisted object which contains user address signed by designatedSigner 
    @param _amount Amount of tokens to mint in one transaction  
    */
    function postMintSale(whitelist memory _whitelist, uint256 _amount)
        external
        payable
        nonReentrant
        whenNotPaused
        checkSupply(_amount)
    {
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == msg.sender, "!Sender");
        require(_whitelist.listType == 3, "!List");
        require(
                block.timestamp > postMint.startTime && block.timestamp <= postMint.endTime,
                "Post Mint: Sale not active"
        );
        require(
                _amount + postMint.register[msg.sender] <= postMint.purchaseLimit,
                "Post Mint: Cannot mint more"
        );
        require(_amount <= postMint.maxAvailable, "Post Mint: Sold out");
        require(msg.value >= _amount * postMint.price, "Post Mint: Pay more");
            
        postMint.register[msg.sender] += _amount;
        postMint.maxAvailable -= _amount;
        
        if (msg.value > _amount * postMint.price) {
            payable(msg.sender).transfer(msg.value - _amount * postMint.price);
        }

        _mint(msg.sender, _amount);
    }
    
    /**
    @notice The function allows founder to withdraw accumulated funds   
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

    /**
    @notice The function returns the number of tokens minted by a member in Beast list
    @param _address Wallet address of the member   
    */
    function readBeastsRegister(address _address) public view returns(uint) {
        require(_address != address(0), "Invalid address provided");
        return beasts.register[_address];
    }

    /**
    @notice The function returns the number of tokens minted by a member in Lab Grown Beast list
    @param _address Wallet address of the member   
    */
    function readLabGrownBeastsRegister(address _address) public view returns(uint) {
        require(_address != address(0), "Invalid address provided");
        return labGrownBeasts.register[_address];
    }

    /**
    @notice The function returns the number of tokens minted by a member in Wild DNA list
    @param _address Wallet address of the member   
    */
    function readPostMintRegister(address _address) public view returns(uint) {
        require(_address != address(0), "Invalid address provided");
        return postMint.register[_address];
    }


    ////////////////
    ////Setters////
    //////////////
    
    function setBaseURI(string memory baseURI_) external onlyOwner {
        require(bytes(baseURI_).length > 0, "Invalid URI provided");
        baseURI = baseURI_;
    }

    function setDesignatedSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Invalid address provided");
        designatedSigner = _signer;
    }
    
    function setMaxSupply(uint _supply) external onlyOwner {
        require(totalSupply() <= _supply, "Invalid amount provided");
        maxSupply = _supply;
    }
    
    function setReserve(uint _cap) external onlyOwner {
        require(_cap <= maxSupply - totalSupply(), "Exceeding max supply");
        reserve = _cap;
    }
    
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid address provided");
        treasury = payable(_treasury);
    }

    function setBeastsStartTime(uint _time) external onlyOwner {
        beasts.startTime = _time;
    }

    function setBeastsEndTime(uint _time) external onlyOwner {
        beasts.endTime = _time;
    }
    
    function setBeastsPurchaseLimit(uint _cap) external onlyOwner {
        beasts.purchaseLimit = _cap;
    }
    
    function setBeastsMaxAvailable(uint _cap) external onlyOwner {
        beasts.maxAvailable = _cap;
    }
    
    function setBeastsPrice(uint _price) external onlyOwner {
        beasts.price = _price;
    }
    
    function setLabGrownBeastsStartTime(uint _time) external onlyOwner {
        labGrownBeasts.startTime = _time;
    }

    function setLabGrownBeastsEndTime(uint _time) external onlyOwner {
        labGrownBeasts.endTime = _time;
    }

    function setLabGrownBeastsPurchaseLimit(uint _cap) external onlyOwner {
        labGrownBeasts.purchaseLimit = _cap;
    }

    function setLabGrownBeastsMaxAvailable(uint _cap) external onlyOwner {
        labGrownBeasts.maxAvailable = _cap;
    }
    
    function setLabGrownBeastsPrice(uint _price) external onlyOwner {
        labGrownBeasts.price = _price;
    }
    
    function setPostMintStartTime(uint _time) external onlyOwner {
        postMint.startTime = _time;
    }

    function setPostMintEndTime(uint _time) external onlyOwner {
        postMint.endTime = _time;
    }

    function setPostMintPurchaseLimit(uint _cap) external onlyOwner {
        postMint.purchaseLimit = _cap;
    }
    
    function setPostMintMaxAvailable(uint _cap) external onlyOwner {
        postMint.maxAvailable = _cap;
    }

    function setPostMintPrice(uint _price) external onlyOwner {
        postMint.price = _price;
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