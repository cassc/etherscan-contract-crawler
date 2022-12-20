// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

//import "hardhat/console.sol";
import "../lib/DateTime.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract WeeeNFT is ERC721, AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using DateTime for DateTime._DateTime;
    using Counters for Counters.Counter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter _tokenIdCounter = Counters.Counter(1);

    string public BASE_URI; //Base NFT token URI, default IPFS host
    IERC20 public WEEE_TOKEN; //WEEE token required for level upgrade

    //The default cost of required Weee for level upgrade.
    //If not set cost of required Weee for each specific level. 
    uint256 public defaultLevelUpgradeRequirement;

    //The default token URI if not set for specific token
    string public defaultTokenURI;
    mapping(uint256 => string) public tokenURIs; //Token URIs mapping
    
    mapping(address => bool) public beneficiaries; //Whitelist users can be minted own NFT, required minter role
    mapping(address => uint256) public tokenHolders; //User owned token mapping
    mapping(uint256 => uint256) public tokenLevels; //Token level mapping
    mapping(uint256 => uint256) public nextCheckinTimes; //Next token checkin time mapping
    mapping(uint256 => uint256) public tokenActives; //Token checking activity of daily count
    mapping(uint256 => uint256) public levelUpgradeRequirements; //The cost of required Weeee token for each level upgrade
    mapping(uint256 => BoostInfo) public boostInfo; //Boots information, mapping by level

    struct BoostInfo {
        uint256 boostingPoint;
        uint256 maxCapacity;
    }

    event LevelUp(uint256 indexed to, uint256 value);
    event RescueERC20(address indexed caller, address indexed erc20ContractAddress, address indexed recipient, uint256 amount);
    event RescueERC721(address indexed caller, address indexed erc721ContractAddress, address indexed recipient, uint256 tokenId);
    event SetWeeeTokenAddress(address indexed caller, address indexed weeeTokenAddress);

    constructor(uint256 _defaultLevelUpgradeRequirement) ERC721("WeeeNFT", "NWEEE") {
        require(_defaultLevelUpgradeRequirement > 0, "Default level upgrade requirement must not be zero");
        defaultLevelUpgradeRequirement = _defaultLevelUpgradeRequirement;
        BASE_URI = "https://ipfs.io/ipfs/";
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
    }

    function setWeeeTokenAdddress(address _weeeTokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_weeeTokenAddress != address(0) && Address.isContract(_weeeTokenAddress), "Weee token address must not be zero or not a contract");
        require(IERC20Metadata(_weeeTokenAddress).decimals() > 0, "Invalid decimals for Weee token address");
        WEEE_TOKEN = IERC20(_weeeTokenAddress);
        emit SetWeeeTokenAddress(_msgSender(), _weeeTokenAddress);
    }

    function setDefaultLevelUpgradeRequirement(uint256 _defaultLevelUpgradeRequirement) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_defaultLevelUpgradeRequirement > 0, "Value must greater than zero");
        defaultLevelUpgradeRequirement = _defaultLevelUpgradeRequirement;
    }

    function setDefaultTokenURI(string memory _defaultTokenURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        defaultTokenURI = _defaultTokenURI;
    }

    function setLevelUpgradeRequirement(uint256 _level, uint256 _levelUpgradeRequirement) external onlyRole(DEFAULT_ADMIN_ROLE) {
        levelUpgradeRequirements[_level] = _levelUpgradeRequirement;
    }

    function setBoostInfo(uint256 _level, uint256 _boostingPoint, uint256 _maxCapacity) external onlyRole(DEFAULT_ADMIN_ROLE) {
        boostInfo[_level] = BoostInfo(_boostingPoint, _maxCapacity);
    }

    function checkin(uint256 tokenId) external nonReentrant {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not token owner nor approved");
        uint256 currentTime = block.timestamp;
        uint256 nextCheckinTime = nextCheckinTimes[tokenId];

        if (nextCheckinTime == 0) {
            DateTime._DateTime memory currentDate = DateTime.parseTimestamp(currentTime);
            nextCheckinTime = DateTime.toTimestamp(currentDate.year, currentDate.month, currentDate.day);
        } else {
            uint256 endCheckinTime = nextCheckinTime + DateTime.DAY_IN_SECONDS - 1;

            if (!(currentTime >= nextCheckinTime && currentTime <= endCheckinTime || currentTime > endCheckinTime)) {
                revert(string.concat("Already checked in today, next time ", Strings.toString(nextCheckinTime)));
            }
        }

        tokenActives[tokenId] += 1;

        while (nextCheckinTime < currentTime) {
            nextCheckinTime += DateTime.DAY_IN_SECONDS;
        }

        nextCheckinTimes[tokenId] = nextCheckinTime;
    }

    function levelUp(uint256 tokenId) external nonReentrant {
        require(WEEE_TOKEN != IERC20(address(0)), "Weee token adresss has not been set up yet");
        _requireMinted(tokenId);
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not token owner nor approved");
        uint256 fee = levelUpgradeRequirements[tokenLevels[tokenId] + 1];

        if (fee == 0) {
            fee = defaultLevelUpgradeRequirement;
        }

        require(WEEE_TOKEN.balanceOf(_msgSender()) >= fee, "Insufficient balance to level up");
        require(WEEE_TOKEN.allowance(_msgSender(), address(this)) >= fee, "Insufficient allowance approval to level up");
        SafeERC20.safeTransferFrom(WEEE_TOKEN, _msgSender(), address(this), fee);
        tokenLevels[tokenId] += 1;
        emit LevelUp(tokenId, tokenLevels[tokenId]);
    }

    function mint() external nonReentrant {
        require(beneficiaries[_msgSender()], "Not a beneficiaries");
        address recipient = _msgSender();
        require(balanceOf(recipient) == 0, "This address has already minted");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        tokenLevels[tokenId] = 1;
        _mint(recipient, tokenId);
        tokenHolders[recipient] = tokenId;
    }

    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == _msgSender(), "Not an owner");
        _burn(tokenId);
        tokenHolders[_msgSender()] = 0;
        tokenLevels[tokenId] = 0;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenURI(tokenId, _tokenURI);
    }

    function setBaseURI(string memory _newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        BASE_URI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function setBeneficiary(address _caller, bool res) external onlyRole(MINTER_ROLE) {
        beneficiaries[_caller] = res;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override whenNotPaused {
        if (!(from == address(0) || to == address(0))) {
            revert("Not allow to transfer");
        }

        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function rescueERC20(address erc20Address, address recipient, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20 erc20 = IERC20(erc20Address);
        require(erc20.balanceOf(address(this)) >= amount, "Insufficient amount to resuce");
        require(recipient != address(0) && !Address.isContract(recipient), "Rescue recipient should not be zero or contract address");
        SafeERC20.safeTransfer(erc20, recipient, amount);
        emit RescueERC20(_msgSender(), erc20Address, recipient, amount);
    }

    function rescueERC721(address erc721Address, address recipient, uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC721 erc721 = IERC721(erc721Address);
        require(erc721.ownerOf(tokenId) == address(this), "Not an ERC721 owner");
        require(recipient != address(0) && !Address.isContract(recipient), "Rescue recipient should not be zero or contract address");
        erc721.safeTransferFrom(address(this), recipient, tokenId);
        emit RescueERC721(_msgSender(), erc721Address, recipient, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
    * ERC721URIStorage tokenURI(uint256 tokenId).
    */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        string memory _tokenURI = tokenURIs[tokenId];
        string memory base = _baseURI();
        bool hasDefaultTokenURI = bytes(defaultTokenURI).length > 0;

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return bytes(_tokenURI).length == 0 && hasDefaultTokenURI ? defaultTokenURI : _tokenURI;
        }

        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return hasDefaultTokenURI ? defaultTokenURI : super.tokenURI(tokenId);
    }

    /**
     * ERC721URIStorage _setTokenURI(uint256 tokenId, string memory _tokenURI).
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "URI set of nonexistent token");
        tokenURIs[tokenId] = _tokenURI;
    }

    /** 
     * ERC721URIStorage _burn(uint256 tokenId).
     */
    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);

        if (bytes(tokenURIs[tokenId]).length != 0) {
            delete tokenURIs[tokenId];
        }
    }
}