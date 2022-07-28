//SPDX-License-Identifier: None
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./utils/ERC721AUpgradeable.sol";
import "./utils/SupperClubWhitelist.sol";

contract SupperClubMint is ERC721AUpgradeable, OwnableUpgradeable,
        PausableUpgradeable, Whitelist, ReentrancyGuardUpgradeable {

    modifier checkSupply(uint _amount) {
        require(_amount > 0, "Invalid amount");
        require(_amount + totalSupply() <= maxSupply, "Checker: Exceeding Max Supply");
        _;
    }

    string public baseURI;
    address public designatedSigner;

    uint public maxSupply;
    uint public ownerCap;
    uint public ownerMinted;
    uint public whitelistMintIndividualCap;
    uint public whitelistStartTime;
    uint public whitelistSpotCap;
    uint public whitelistSpotSold;

    mapping(address => uint) public whiteListMintTracker;

    function initialize(string memory _name, string memory _symbol, address _designatedSigner) public initializer {

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC721A_init(_name, _symbol);
        __SupperClubSigner_init();

        designatedSigner = _designatedSigner;
        maxSupply = 333;
        ownerCap = 20;
        whitelistSpotCap = 313;
        whitelistMintIndividualCap = 1;
        whitelistStartTime = 1658707200;
    }

    function OwnerMint(uint _amount) external onlyOwner checkSupply(_amount) {
        require(_amount + ownerMinted <= ownerCap, "Owner Mint Limit Exceeded");
        ownerMinted += _amount;
        _mint(msg.sender, _amount);
    }

    function WhitelistMint(whitelist memory _whitelist, uint _amount) external checkSupply(_amount)
    whenNotPaused nonReentrant{
        require(block.timestamp >= whitelistStartTime, "Whitelist: Not yet started");
        require(getSigner(_whitelist) == designatedSigner, "Whitelist: Designated Signer mismatch");
        require(_whitelist.userAddress == msg.sender, "Whitelist: Not A Whitelisted Address");
        require(_amount + whitelistSpotSold <= whitelistSpotCap, "Whitelist: Whitelist cap exceeding");
        require(_amount + whiteListMintTracker[msg.sender] <= whitelistMintIndividualCap,
            "Whitelist: Individual Cap exceeding");
        whiteListMintTracker[msg.sender] += _amount;
        whitelistSpotSold += _amount;
        _mint(_whitelist.userAddress, _amount);
    }

    ////////////////
    ////Setters////
    //////////////

    function setBaseURI(string memory baseURI_) public onlyOwner {
        require(bytes(baseURI_).length > 0, "Invalid base URI");
        baseURI = baseURI_;
    }

    function setDesignatedSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Invalid address for signer");
        designatedSigner = _signer;
    }

    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function setOwnerCap(uint _amount) external onlyOwner {
        ownerCap = _amount;
    }

    function setWhitelistStartTime(uint _amount) external onlyOwner {
        whitelistStartTime = _amount;
    }

    function setWhitelistMintIndividualCap(uint _amount) external onlyOwner {
        whitelistMintIndividualCap = _amount;
    }

    function setWhitelistSpotCap(uint _amount) external onlyOwner {
        whitelistSpotCap = _amount;
    }

    function setMaxSupply(uint _amount) external onlyOwner {
        maxSupply = _amount;
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

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

}