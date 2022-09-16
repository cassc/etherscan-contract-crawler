// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {LockRegistry} from "./abstract/LockRegistry.sol";
import {IBrawlerBearz} from "./interfaces/IBrawlerBearz.sol";
import {IBrawlerBearzFaction} from "./interfaces/IBrawlerBearzFaction.sol";
import {IBrawlerBearzRenderer} from "./interfaces/IBrawlerBearzRenderer.sol";
import {IBrawlerBearzDynamicItems} from "./interfaces/IBrawlerBearzDynamicItems.sol";
import {ERC721Psi, ERC721PsiRandomSeedReveal, ERC721PsiRandomSeedRevealBurnable} from "./ERC721PsiRandomSeedRevealBurnable.sol";

/*******************************************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|,|@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@|,*|&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%,**%@@@@@@@@%|******%&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##*****|||**,(%%%%%**|%@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@***,#%%%%**#&@@@@@#**,|@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@*,(@@@@@@@@@@**,(&@@@@#**%@@@@@@||(%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%|,****&@((@&***&@@@@@@%||||||||#%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&%#*****||||||**#%&@%%||||||||#@&%#(@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@&**,(&@@@@@%|||||*##&&&&##|||||(%@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@**,%@@@@@@@(|*|#%@@@@@@@@#||#%%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#||||#@@@@||*|%@@@@@@@@&|||%%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@#,,,,,,*|**||%|||||||###&@@@@@@@#|||#%@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&#||*|||||%%%@%%%#|||%@@@@@@@@&(|(%&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&&%%(||||@@@@@@&|||||(%&((||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%%(||||||||||#%#(|||||%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&%#######%%@@**||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
********************************************************************************/

/**************************************************
 * @title BrawlerBearz
 * @author @ScottMitchell18
 **************************************************/

contract BrawlerBearz is
    IBrawlerBearz,
    ERC721PsiRandomSeedRevealBurnable,
    LockRegistry,
    ReentrancyGuard,
    AccessControl
{
    address public constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    // Roles
    bytes32 constant XP_MUTATOR_ROLE = keccak256("XP_MUTATOR_ROLE");
    bytes32 constant OWNER_ROLE = keccak256("OWNER_ROLE");

    // Equip types
    bytes32 constant HEAD_ITEM_TYPE = keccak256(abi.encodePacked("HEAD"));
    bytes32 constant WEAPON_ITEM_TYPE = keccak256(abi.encodePacked("WEAPON"));
    bytes32 constant BACKGROUND_ITEM_TYPE =
        keccak256(abi.encodePacked("BACKGROUND"));
    bytes32 constant ARMOR_ITEM_TYPE = keccak256(abi.encodePacked("ARMOR"));
    bytes32 constant FACE_ARMOR_ITEM_TYPE =
        keccak256(abi.encodePacked("FACE_ARMOR"));
    bytes32 constant EYEWEAR_ITEM_TYPE = keccak256(abi.encodePacked("EYEWEAR"));
    bytes32 constant MISC_ITEM_TYPE = keccak256(abi.encodePacked("MISC"));

    /// @notice bytes32 of Chainlink keyhash
    bytes32 public immutable keyHash;

    /// @notice value of Chainlink subscription id
    uint64 public immutable subscriptionId;

    /// @notice 4% of total minted
    uint256 public teamMintAmount = 128;

    /// @notice address of treasury (e.g, gnosis safe)
    address public treasury =
        payable(0x39bfA2b4319581bc885A2d4b9F0C90C2e1c24B87);

    /*
     * @notice Whitelist Live ~ September 16th, 2022, 10AM EST
     * @dev timestamp for whitelist
     */
    uint256 public whitelistLiveAt = 1663336800;

    /*
     * @notice Public / Free Claim Live ~ September 16th, 2022, 5PM EST
     * @dev timestamp for public and free claim
     */
    uint256 public liveAt = 1663362000;

    /// @notice amount of the total supply of the collection (n - 1)
    uint256 public maxSupply = 3335; // Excludes 2666 access passes

    /// @notice price in ether
    uint256 public price = 0.045 ether;

    /// @notice amount of transactions allowed per wallet (n - 1)
    uint256 public maxPerWallet = 3;

    /// @notice boolean for if the shop drop is enabled
    bool private isShopDropEnabled = true;

    /// @notice boolean for if its revealed
    bool public isRevealed = false;

    /// @notice bytes32 hash of the merkle root
    bytes32 public merkleRoot;

    /// @notice map from token id to custom metadata
    mapping(uint256 => CustomMetadata) internal metadata;

    // @dev An address mapping for max mint per wallet
    mapping(address => uint256) public addressToMinted;

    /// @notice Vendor contract
    IBrawlerBearzDynamicItems public vendorContract;

    /// @notice Access pass contract
    IERC721 public accessPassContract;

    /// @notice The rendering library contract
    IBrawlerBearzRenderer public renderer;

    /// @notice Faction contract
    IBrawlerBearzFaction public factionContract;

    // ========================================
    // Modifiers
    // ========================================

    modifier isTokenOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != _msgSender()) {
            revert InvalidOwner();
        }
        _;
    }

    modifier isItemTokenOwner(uint256 itemTokenId) {
        if (vendorContract.balanceOf(_msgSender(), itemTokenId) == 0) {
            revert InvalidOwner();
        }
        _;
    }

    modifier isItemValidType(uint256 itemTokenId, string memory validTypeOf) {
        if (
            keccak256(abi.encodePacked(validTypeOf)) !=
            keccak256(abi.encodePacked(vendorContract.getItemType(itemTokenId)))
        ) {
            revert InvalidItemType();
        }
        _;
    }

    modifier isItemXPMet(uint256 itemTokenId, uint256 tokenId) {
        if (metadata[tokenId].xp < vendorContract.getItemXPReq(itemTokenId)) {
            revert ItemRequiresMoreXP();
        }
        _;
    }

    // " and \ are not valid
    modifier isValidString(string calldata value) {
        bytes memory str = bytes(value);
        for (uint256 i; i < str.length; i++) {
            bytes1 char = str[i];
            if ((char == 0x22) || (char == 0x5c)) revert InvalidString();
        }
        _;
    }

    constructor(
        address _vrfV2Coordinator,
        bytes32 keyHash_,
        uint64 subscriptionId_,
        address _accessPassContract,
        address _factionContract,
        address _renderingContract,
        address _vendorContract
    )
        ERC721Psi("Brawler Bearz", "BB")
        ERC721PsiRandomSeedReveal(_vrfV2Coordinator, 400000, 3)
    {
        // Chainlink VRF initialization
        keyHash = keyHash_;
        subscriptionId = subscriptionId_;
        // Setup access control
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
        // NFT integration contracts
        accessPassContract = IERC721(_accessPassContract);
        factionContract = IBrawlerBearzFaction(_factionContract);
        // On-chain metadata rendering contract
        renderer = IBrawlerBearzRenderer(_renderingContract);
        // Shop integration contract
        vendorContract = IBrawlerBearzDynamicItems(_vendorContract);
        // Placeholder mint for collection protection
        _safeMint(_msgSender(), 1, "");
    }

    // ========================================
    // Dynamic metadata
    // ========================================

    /**
     * @notice Sets the name of a particular token id
     * @dev only token owner call this function
     * @param tokenId The token id
     * @param name The name to set
     */
    function setName(uint256 tokenId, string calldata name)
        public
        override
        isTokenOwner(tokenId)
        isValidString(name)
    {
        bytes memory n = bytes(name);
        if (n.length > 25) revert InvalidLength();
        if (keccak256(n) == keccak256(bytes(metadata[tokenId].name)))
            revert InvalidValue();
        metadata[tokenId].name = name;
        emit NameChanged(tokenId, name);
    }

    /**
     * @notice Sets the lore/backstory of a particular token id
     * @dev only token owner call this function
     * @param tokenId The token id
     * @param lore The name to set
     */
    function setLore(uint256 tokenId, string calldata lore)
        public
        override
        isTokenOwner(tokenId)
        isValidString(lore)
    {
        bytes memory n = bytes(lore);
        if (keccak256(n) == keccak256(bytes(metadata[tokenId].lore)))
            revert InvalidValue();
        metadata[tokenId].lore = lore;
        emit LoreChanged(tokenId, lore);
    }

    /**
     * @notice Sets the equipped items of a particular token id and item type
     * @dev only token owner call this function
     * @param tokenId The token id of the bear
     * @param typeOf The type of item to equip
     * @param itemTokenId The token id of the item
     */
    function equip(
        uint256 tokenId,
        string calldata typeOf,
        uint256 itemTokenId
    )
        public
        override
        isTokenOwner(tokenId)
        isItemTokenOwner(itemTokenId)
        isItemValidType(itemTokenId, typeOf)
        isItemXPMet(itemTokenId, tokenId)
        nonReentrant
    {
        bytes32 itemType = keccak256(abi.encodePacked(typeOf));
        CustomMetadata storage instance = metadata[tokenId];

        if (WEAPON_ITEM_TYPE == itemType) {
            require(instance.weapon == 0, "96");
            instance.weapon = itemTokenId;
        } else if (HEAD_ITEM_TYPE == itemType) {
            require(instance.head == 0, "96");
            instance.head = itemTokenId;
        } else if (ARMOR_ITEM_TYPE == itemType) {
            require(instance.armor == 0, "96");
            instance.armor = itemTokenId;
        } else if (BACKGROUND_ITEM_TYPE == itemType) {
            require(instance.background == 0, "96");
            instance.background = itemTokenId;
        } else if (FACE_ARMOR_ITEM_TYPE == itemType) {
            require(instance.faceArmor == 0, "96");
            instance.faceArmor = itemTokenId;
        } else if (EYEWEAR_ITEM_TYPE == itemType) {
            require(instance.eyewear == 0, "96");
            instance.eyewear = itemTokenId;
        } else if (MISC_ITEM_TYPE == itemType) {
            require(instance.misc == 0, "96");
            instance.misc = itemTokenId;
        } else {
            revert InvalidItemType();
        }
        // Burn item
        vendorContract.burnItemForOwnerAddress(itemTokenId, 1, _msgSender());
        emit Equipped(tokenId, typeOf, itemTokenId);
    }

    /**
     * @notice Unsets the equipped items of a particular token id
     * @dev only token owner call this function
     * @param typeOf The type of item to equip
     * @param tokenId The token id
     */
    function unequip(uint256 tokenId, string calldata typeOf)
        public
        override
        isTokenOwner(tokenId)
        nonReentrant
    {
        uint256 itemTokenId;
        bytes32 itemType = keccak256(abi.encodePacked(typeOf));
        CustomMetadata storage instance = metadata[tokenId];

        if (WEAPON_ITEM_TYPE == itemType) {
            itemTokenId = instance.weapon;
            instance.weapon = 0;
        } else if (HEAD_ITEM_TYPE == itemType) {
            itemTokenId = instance.head;
            instance.head = 0;
        } else if (ARMOR_ITEM_TYPE == itemType) {
            itemTokenId = instance.armor;
            instance.armor = 0;
        } else if (BACKGROUND_ITEM_TYPE == itemType) {
            itemTokenId = instance.background;
            instance.background = 0;
        } else if (FACE_ARMOR_ITEM_TYPE == itemType) {
            itemTokenId = instance.faceArmor;
            instance.faceArmor = 0;
        } else if (EYEWEAR_ITEM_TYPE == itemType) {
            itemTokenId = instance.eyewear;
            instance.eyewear = 0;
        } else if (MISC_ITEM_TYPE == itemType) {
            itemTokenId = instance.misc;
            instance.misc = 0;
        } else {
            revert InvalidItemType();
        }

        require(itemTokenId > 0, "6969");
        // Mint item
        vendorContract.mintItemToAddress(itemTokenId, 1, _msgSender());
        emit Unequipped(tokenId, typeOf, itemTokenId);
    }

    // ========================================
    // NFT display helpers
    // ========================================

    /// @notice Reveal called by the governance to reveal the seed of the NFT
    function reveal() external onlyRole(OWNER_ROLE) {
        _reveal();
        emit Revealed(totalSupply());
    }

    /// @notice The custom metadata associated to a given tokenId
    function getMetadata(uint256 tokenId)
        external
        view
        override
        returns (CustomMetadata memory)
    {
        require(_exists(tokenId), "0");
        return metadata[tokenId];
    }

    /// @notice The token uri for a given tokenId
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (isRevealed == false) {
            return renderer.hiddenURI(tokenId);
        }
        require(_exists(tokenId), "0");
        CustomMetadata memory md = metadata[tokenId];
        md.isUnlocked = isUnlocked(tokenId);
        md.faction = factionContract.getFaction(ownerOf(tokenId));
        return renderer.tokenURI(tokenId, seed(tokenId), md);
    }

    // ========================================
    // Mint Helpers
    // ========================================

    /**
     * @notice Free claim mint, requires access pass ownership
     * @param _tokenIds of the access pass
     */
    function claim(uint256[] calldata _tokenIds) external nonReentrant {
        require(isPublicLive(), "0");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            accessPassContract.transferFrom(
                _msgSender(),
                DEAD_ADDRESS,
                _tokenIds[i]
            );
        }
        _safeMint(_msgSender(), _tokenIds.length, "");
    }

    /**
     * @notice Whitelisted mint, requires a merkle proof
     * @param _amount of mints
     * @param _proof hashed array proof
     */
    function whitelistMint(uint256 _amount, bytes32[] calldata _proof)
        external
        payable
        nonReentrant
    {
        require(isWhitelistLive(), "0");
        require(totalSupply() + _amount < maxSupply, "9");
        require(msg.value >= _amount * price, "1");
        require(addressToMinted[_msgSender()] + _amount < maxPerWallet, "2");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "4");
        addressToMinted[_msgSender()] += _amount;
        _safeMint(_msgSender(), _amount, "");
        // Shop drop chance game
        if (isShopDropEnabled) {
            vendorContract.shopDrop(_msgSender(), _amount);
        }
    }

    /**
     * @notice Public mint
     * @param _amount of mints
     */
    function mint(uint256 _amount) external payable {
        require(isPublicLive(), "0");
        require(totalSupply() + _amount < maxSupply, "9");
        require(msg.value >= _amount * price, "1");
        require(addressToMinted[_msgSender()] + _amount < maxPerWallet, "2");
        addressToMinted[_msgSender()] += _amount;
        _safeMint(_msgSender(), _amount, "");
    }

    /**
     * @notice Sets public price in wei
     * @dev only owner call this function
     * @param _price The new public price in wei
     */
    function setPrice(uint256 _price) public onlyRole(OWNER_ROLE) {
        price = _price;
    }

    /**
     * @notice Sets the treasury recipient
     * @dev only owner call this function
     * @param _treasury The new price in wei
     */
    function setTreasury(address _treasury) public onlyRole(OWNER_ROLE) {
        treasury = payable(_treasury);
    }

    /**
     * @notice Sets the reveal status of the metadata
     * @dev only owner call this function
     * @param _isRevealed The new boolean of the reveal
     */
    function setIsRevealed(bool _isRevealed) public onlyRole(OWNER_ROLE) {
        isRevealed = _isRevealed;
    }

    /**
     * @notice Sets max supply for the collection
     * @dev only owner call this function
     * @param _maxSupply The new max supply value
     */
    function setMaxSupply(uint256 _maxSupply) external onlyRole(OWNER_ROLE) {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Sets the max mints per wallet
     * @param _maxPerWallet The max per wallet (Keep mind its +1 n)
     */
    function setMaxPerWallet(uint256 _maxPerWallet)
        external
        onlyRole(OWNER_ROLE)
    {
        maxPerWallet = _maxPerWallet;
    }

    /**
     * @notice Sets the go live timestamp for whitelist
     * @param _whitelistLiveAt A base uri
     */
    function setWhitelistLiveAt(uint256 _whitelistLiveAt)
        external
        onlyRole(OWNER_ROLE)
    {
        whitelistLiveAt = _whitelistLiveAt;
    }

    /**
     * @notice Sets the go live timestamp
     * @param _liveAt A base uri
     */
    function setLiveAt(uint256 _liveAt) external onlyRole(OWNER_ROLE) {
        liveAt = _liveAt;
    }

    /**
     * @notice Sets the merkle root for the mint
     * @param _merkleRoot The merkle root to set
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(OWNER_ROLE) {
        merkleRoot = _merkleRoot;
    }

    /// @notice Withdraw from contract
    function withdraw() public onlyRole(OWNER_ROLE) {
        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "999");
    }

    /// @notice Team mints ~4% of max supply - resets to 0 after team mint happens
    function teamMints(address _to) external onlyRole(OWNER_ROLE) {
        require(teamMintAmount > 0, "69");
        _safeMint(_to, teamMintAmount, "");
        teamMintAmount = 0;
    }

    /**
     * @notice Sets whether shop drop is enabled
     * @param _isShopDropEnabled the bool value
     */
    function setShopDropEnabled(bool _isShopDropEnabled)
        external
        onlyRole(OWNER_ROLE)
    {
        isShopDropEnabled = _isShopDropEnabled;
    }

    // ========================================
    // Lock registry
    // ========================================

    /**
     * @dev Overrides the normal `transferFrom` to include lock check
     * @param from address
     * @param to address
     * @param tokenId of asset
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(isUnlocked(tokenId), "1337");
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Overrides the normal `safeTransferFrom` to include lock check
     * @param from address
     * @param to address
     * @param tokenId of asset
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(isUnlocked(tokenId), "1337");
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function lockId(uint256 tokenId) external onlyRole(XP_MUTATOR_ROLE) {
        require(_exists(tokenId), "0");
        _lockId(tokenId);
    }

    function unlockId(uint256 tokenId) external onlyRole(XP_MUTATOR_ROLE) {
        require(_exists(tokenId), "0");
        _unlockId(tokenId);
    }

    function freeId(uint256 tokenId, address contractAddress)
        external
        onlyRole(XP_MUTATOR_ROLE)
    {
        require(_exists(tokenId), "0");
        _freeId(tokenId, contractAddress);
    }

    // ========================================
    // External contract helpers
    // ========================================

    /**
     * @notice Adds XP to tokenId
     * @param tokenId the token
     * @param amount of xp to add
     */
    function addXP(uint256 tokenId, uint256 amount)
        external
        onlyRole(XP_MUTATOR_ROLE)
    {
        metadata[tokenId].xp += amount;
    }

    /**
     * @notice Subtracts XP from tokenId
     * @param tokenId the token
     * @param amount of xp to subtract
     */
    function subtractXP(uint256 tokenId, uint256 amount)
        external
        onlyRole(XP_MUTATOR_ROLE)
    {
        metadata[tokenId].xp -= amount;
    }

    /**
     * @notice Sets the bearz rendering library contract
     * @dev only owner call this function
     * @param _renderingContractAddress The new contract address
     */
    function setRenderingContractAddress(address _renderingContractAddress)
        external
        onlyRole(OWNER_ROLE)
    {
        renderer = IBrawlerBearzRenderer(_renderingContractAddress);
    }

    /**
     * @notice Sets the bearz vendor item contract
     * @dev only owner call this function
     * @param _vendorContractAddress The new contract address
     */
    function setVendorContractAddress(address _vendorContractAddress)
        external
        onlyRole(OWNER_ROLE)
    {
        vendorContract = IBrawlerBearzDynamicItems(_vendorContractAddress);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Psi, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ========================================
    // Read operations
    // ========================================

    // @dev Check if mint is public live
    function isWhitelistLive() public view returns (bool) {
        return block.timestamp > whitelistLiveAt;
    }

    // @dev Check if mint is public live
    function isPublicLive() public view returns (bool) {
        return block.timestamp > liveAt;
    }

    // @dev Check if mint is public live
    function getAddressMintsRemaining(address _address)
        public
        view
        returns (uint256)
    {
        return maxPerWallet - addressToMinted[_address] - 1;
    }

    /*
     * @notice Return token ids for a given address
     * @param _owner address
     */
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // ========================================
    // Chainlink integrations
    // ========================================

    function _keyHash() internal view override returns (bytes32) {
        return keyHash;
    }

    function _subscriptionId() internal view override returns (uint64) {
        return subscriptionId;
    }
}