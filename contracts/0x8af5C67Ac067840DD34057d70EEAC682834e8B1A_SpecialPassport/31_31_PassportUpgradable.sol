// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";


import "./PassportRegistry.sol";


abstract contract PassportUpgradable is Initializable, ERC721Upgradeable, PausableUpgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable, AccessControlEnumerableUpgradeable {

    error InvalidSignature();
    error InvalidBlockNumber();
    error BlockNumberTooOld();

    event LevelUpgraded(uint256 indexed tokenId, uint256 indexed level);

    using ECDSA for bytes32;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using AddressUpgradeable for address;

    PassportRegistry public registry;
    uint256 public maxSupply;

    uint256 public maxBlockDiff = 250;

    CountersUpgradeable.Counter private _tokenIdCounter;
    string[] public levels;
    mapping(uint256 => uint256) tokensToLevels;
    bytes32 private constant TRANSFERER_ROLE = keccak256("TRANSFERER_ROLE");
    bytes32 private constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    function __Passport_init(address defaultAdmin_, string[] memory levels_, uint256 maxSupply_, string memory name_, string memory symbol_, PassportRegistry registry_) internal onlyInitializing {
        require(defaultAdmin_ != address(0), "Passport: defaultAdmin is the zero address");
        require(address(registry_) != address(0), "Passport: registry is the zero address");
        require(address(registry_).isContract(), "Passport: registry address is not a contract address");

        __ERC721_init(name_, symbol_);
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, defaultAdmin_);
        _setupRole(TRANSFERER_ROLE, defaultAdmin_);

        levels = levels_;
        maxSupply = maxSupply_;
        registry = registry_;
    }

    function updateMaxSupply(uint256 maxSupply_) external onlyOwner {
        require(maxSupply_ > _tokenIdCounter.current(), "Passport: new maxSupply must be greater than current token count");
        maxSupply = maxSupply_;
    }

    function updateLevels(string[] memory levels_) external onlyOwner {
        require(levels_.length > 0, "Passport: levels must not be empty");
        require(levels_.length <= 256, "Passport: levels must not be greater than 256");
        levels = levels_;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override onlyRole(TRANSFERER_ROLE) {
        super._transfer(from, to, tokenId);
    }

    function getVersion() external virtual pure returns (string memory) {
        return "v1";
    }

    function setRegistry(PassportRegistry registry_) external onlyOwner {
        require(address(registry_) != address(0), "Passport: registry is the zero address");
        require(address(registry_).isContract(), "Passport: registry address is not a contract address");
        registry = registry_;
    }

    function setMaxBlockDiff(uint256 maxBlockDiff_) external onlyOwner {
        require(maxBlockDiff_ > 0, "Passport: maxBlockDiff must be greater than 0");
        require(maxBlockDiff_ < 1000, "Passport: maxBlockDiff must be less than 1000");
        maxBlockDiff = maxBlockDiff_;
    }

    function upgradeLevel(uint256[] calldata tokens, uint256[] calldata levels) external onlyRole(UPGRADER_ROLE) {
        uint256 levelsLength = levels.length;
        require(tokens.length == levelsLength, "Passport: lengths do not match");

        uint256 i = 0;
        for (; i < levelsLength;) {
            tokensToLevels[tokens[i]] = levels[i];
            emit LevelUpgraded(tokens[i], levels[i]);
        unchecked {i++;}
        }
    }

    function upgradeLevelFromUser(bytes calldata adminSignature,
        uint256 blockNumberUsed, uint256 tokenId, uint256 level) external {

        (address signerAddress) = _recoverValueFromSignature(
            adminSignature,
            blockNumberUsed,
            tokenId,
            level
        );

        require(signerAddress == this.owner(), "Passport: invalid signature");
        tokensToLevels[tokenId] = level;
        emit LevelUpgraded(tokenId, level);
    }


    function getTokenCounter() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function getLevel(uint256 tokenId) public view returns (uint256){
        _exists(tokenId);
        return tokensToLevels[tokenId];
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721Upgradeable)
    returns (string memory)
    {
        return levels[tokensToLevels[tokenId]];
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) public virtual {
        require(balanceOf(to) == 0, "Passport: only one passport per address can be minted");
        address[] memory allPassports = registry.getAllPassports();

        for (uint256 i = 0; i < allPassports.length; i++) {
            require(ERC721Upgradeable(allPassports[i]).balanceOf(to) == 0, "Passport: only one passport per address can be minted");
        }

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        require(tokenId < maxSupply, "Passport: Maximum supply reached");
        _safeMint(to, tokenId);
        tokensToLevels[tokenId] = 0;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    whenNotPaused
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlEnumerableUpgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _recoverValueFromSignature(
        bytes calldata adminSignature,
        uint256 blockNumberUsed,
        uint256 tokenId,
        uint256 level
    ) internal view returns (address) {
        if (block.number <= blockNumberUsed) {
            revert InvalidBlockNumber();
        }

    unchecked {
        if (
            block.number - blockNumberUsed >
            maxBlockDiff
        ) {
            revert BlockNumberTooOld();
        }
    }

        bytes32 blockHash = blockhash(blockNumberUsed);
        bytes32 signedHash = keccak256(
            abi.encodePacked(_msgSender(), blockHash, tokenId, level)
        ).toEthSignedMessageHash();

        return signedHash.recover(adminSignature);
    }
}