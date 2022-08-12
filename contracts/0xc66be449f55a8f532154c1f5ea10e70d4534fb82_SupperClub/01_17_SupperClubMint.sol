//SPDX-License-Identifier: None
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./utils/ERC721AUpgradeable.sol";
import "./utils/SupperClubWhitelist.sol";

contract SupperClub is 
    ERC721AUpgradeable, 
    OwnableUpgradeable,
    PausableUpgradeable, 
    Whitelist, 
    ReentrancyGuardUpgradeable
{
    struct list {
        uint startTime;
        uint endTime;
        uint individualCap;
        uint listCap;
        uint spotsSold;
    }
    
    string public baseURI;
    address public designatedSigner;

    uint public maxSupply;
    uint public ownerCap;
    uint public ownerMinted;

    list public ogList;
    list public wlList;

    mapping(address => uint) public ogListMintTracker;
    mapping(address => uint) public wlListMintTracker;

    modifier checkSupply(uint _amount) {
        require(_amount > 0, "Invalid Amount");
        require(_amount + totalSupply() <= maxSupply - ownerCap, "Exceeding Max Supply");
        _;
    }

    function initialize (string memory _name, string memory _symbol, address _designatedSigner) 
        public 
        initializer 
    {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC721A_init(_name, _symbol);
        __SupperClubSigner_init();

        designatedSigner = _designatedSigner;
        maxSupply = 333;
        ownerCap = 20;

        ogList.startTime = 1660309200; // Thu, 12 Aug 2022 06:30:00 IST
        ogList.endTime = ogList.startTime + 18000;
        ogList.individualCap = 1;
        ogList.listCap = 35;

        wlList.startTime = ogList.startTime + 7200;
        wlList.endTime = ogList.endTime;
        wlList.individualCap = 1;
        wlList.listCap = 313;
    }

    function ownerMint(uint _amount) 
        external 
        onlyOwner 
    {
        require(_amount + totalSupply() <= maxSupply, "Exceeding Supply");
        require(_amount + ownerMinted <= ownerCap, "Exceeding Owner Allotment");
        
        ownerMinted += _amount;
        _mint(msg.sender, _amount);
    }

    function whitelistMint(whitelist memory _whitelist, uint _amount) 
        external
        nonReentrant 
        whenNotPaused
        checkSupply(_amount) 
    {
        require(getSigner(_whitelist) == designatedSigner, "!Signer");
        require(_whitelist.userAddress == msg.sender, "!Sender");

        if(_whitelist.isOgList) {
            require(
                block.timestamp > ogList.startTime && block.timestamp <= ogList.endTime, 
                "OG Sale Closed"
            );
            require(
                _amount + ogListMintTracker[_whitelist.userAddress] <= ogList.individualCap,
                "OG Quota Depleted"
            );
            require(_amount + ogList.spotsSold <= ogList.listCap, "OG Sold Out");
            
            ogListMintTracker[_whitelist.userAddress] += _amount;
            ogList.spotsSold += _amount;
        } 
        
        else {
            require(
                block.timestamp > wlList.startTime && block.timestamp <= wlList.endTime,
                "WL Sale Closed"
            );
            require(
                _amount + wlListMintTracker[_whitelist.userAddress] <= wlList.individualCap,
                "WL Quota Depleted"
            );
            require(_amount + wlList.spotsSold <= wlList.listCap, "WL Sold Out");

            wlListMintTracker[_whitelist.userAddress] += _amount;
            wlList.spotsSold += _amount;
        }
        _mint(_whitelist.userAddress, _amount);
    }

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
    
    function setMaxSupply(uint _supply) external onlyOwner {
        require(totalSupply() < _supply, "Total Supply Exceeding");
        maxSupply = _supply;
    }
    
    function setOwnerCap(uint _cap) external onlyOwner {
        ownerCap = _cap;
    }

    function setOGStartTime(uint _time) external onlyOwner {
        ogList.startTime = _time;
    }

    function setOGEndTime(uint _time) external onlyOwner {
        ogList.endTime = _time;
    }

    function setOGIndividualCap(uint _cap) external onlyOwner {
        ogList.individualCap = _cap;
    }

    function setOGListCap(uint _cap) external onlyOwner {
        require(ogList.spotsSold < _cap, "Sold Spots Exceeding Cap");
        ogList.listCap = _cap;
    }
    
    function setWLStartTime(uint _time) external onlyOwner {
        wlList.startTime = _time;
    }

    function setWLEndTime(uint _time) external onlyOwner {
        wlList.endTime = _time;
    }

    function setWLIndividualCap(uint _cap) external onlyOwner {
        wlList.individualCap = _cap;
    }

    function setWLListCap(uint _cap) external onlyOwner {
        require(wlList.spotsSold < _cap, "Sold Spots Exceeding Cap");
        wlList.listCap = _cap;
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