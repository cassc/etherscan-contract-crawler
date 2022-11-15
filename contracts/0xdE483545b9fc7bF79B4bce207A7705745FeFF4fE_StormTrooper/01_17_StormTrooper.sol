// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract StormTrooper is ERC1155, ERC2981, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event CollectionCreated (
        uint256 indexed brand,
        uint256 indexed collectionId,
        uint256 indexed cap,
        uint256 mintPriceInWei,
        bool enabled,
        bool exist
    );

    event BrandCreated (
        uint256 collectionIds,
        bool enabled,
        bool exist
    );

    event UpdateCollectionMintPrice(
        uint256 indexed collectionId,
        uint256 indexed mintPriceInWei
    );

    struct StormTrooperItem {
        // categories collection
        uint256 brand; 
        uint256 cap;
        uint256 minted;
        uint256 mintPriceInWei;
        bool enabled;
        bool exist;
    }

    struct Brand {
        uint256[] collectionIds;
        bool enabled;
        bool exist;
    }

    // withdrawal variables
    address[] public wallets;
    uint256[] public walletsShares;
    uint256 public totalShares;

    // collectionId => StormTrooperItem
    mapping(uint256 => StormTrooperItem) private stormtroopers;
    // brandId => Brand
    mapping(uint256 => Brand) private brands;
    // track collection id => brand id
    mapping(uint256 => uint256) public collectionIdsBrand;

    // get all collectionIds
    uint256[] collectionIds;
    // get all brandIds
    uint256[] brandIds;
    // max mint per tx
    uint256 maxMintPerTx = 5;

    bytes32 public whitelistMerkleRoot;
    bool public isPremintOpen;
    bool public isPublicMintOpen;


    modifier onlyHasRole(bytes32 _role) {
        require(hasRole(_role, _msgSender()), "Caller does not have role");
        _;
    }

    constructor(
        string memory baseMetaURI, 
        uint96 _feeNumerator
    ) 
        ERC1155(baseMetaURI) 
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setDefaultRoyalty(_msgSender(), _feeNumerator);
        _tokenIds.increment();
    }
    // === Pre-Mint === //

    function premint(bytes32[] calldata _proof, uint256 _collectionId, uint256 _quantity) external payable {
        require(stormtroopers[_collectionId].mintPriceInWei * _quantity == msg.value, "Invalid eth price");
        _premint(_proof, _msgSender(), _collectionId, _quantity);
    }

    function premint(bytes32[] calldata _proof, address to, uint256 _collectionId, uint256 _quantity) external onlyHasRole(MINTER_ROLE) {
        _premint(_proof, to, _collectionId, _quantity);
    }

    function _premint(bytes32[] calldata _proof, address to, uint256 _collectionId, uint256 _quantity) internal {
        require(isPremintOpen, "Premint not yet opened.");

        require(
            _verifySenderProof(to, whitelistMerkleRoot, _proof),
            "Invalid proof"
        );

        _mintCollection(to, _collectionId, _quantity);
    }

    // == Public-Mint ===

    function publicMint(uint256 _collectionId, uint256 _quantity) external payable {
        require(stormtroopers[_collectionId].mintPriceInWei * _quantity == msg.value, "Invalid eth price");
        _publicMint(msg.sender, _collectionId, _quantity);
    }

    function publicMint(address _to, uint256 _collectionId, uint256 _quantity) external onlyHasRole(MINTER_ROLE) {
        _publicMint(_to, _collectionId, _quantity);
    }

    function _publicMint(address _to, uint256 _collectionId, uint256 _quantity) internal {
        require(!isPremintOpen, "Premint ongoing.");
        require(isPublicMintOpen, "PublicMint not yet started");
        _mintCollection(_to, _collectionId, _quantity);
    }

    function _mintCollection(address _to, uint256 _collectionId, uint256 _quantity) internal {
        require(_quantity > 0, "quantity cannot be zero");
        require(_quantity <= maxMintPerTx, "exceed max mint limit per tx.");

        require(stormtroopers[_collectionId].enabled, "Collection currently disabled.");
        require(stormtroopers[_collectionId].minted + _quantity <= stormtroopers[_collectionId].cap, "exceed max supply");
        stormtroopers[_collectionId].minted += _quantity;

        _mint(_to, _collectionId, _quantity, "");
    }

    function isWhitelistedAddressOnBrand(bytes32[] calldata _proof, address to) external view returns (bool) {
        return _verifySenderProof(to, whitelistMerkleRoot, _proof);
    }

    /// @dev Get next tokenId
    function nextTokenId() public view returns (uint256) {
        return _tokenIds.current();
    }

    /// @notice Return all brand ids
    function getAllBrands() external view returns (uint256[] memory) {
        return brandIds;
    }

    /// @notice Return Collection mint price
    /// @param _collectionId The CollectionID
    function getCollectionMintPrice(uint256 _collectionId) external view returns (uint256) {
        return stormtroopers[_collectionId].mintPriceInWei;
    }

    function getBrandInfo(uint256 brandId) external view returns (Brand memory) {
        return brands[brandId];
    }

    /// @dev Get all collectionIds by brand
    /// @param _brandId The brand id
    function getCollectionIdsByBrand(uint256 _brandId) public view returns (uint256[] memory) {
        return _getCollectionIdsByBrand(_brandId);
    }

    /// @dev Get token collection info by ID
    /// @param _tokenId The token collection info
    function getCollectionInfoById(uint256 _tokenId) public view returns (StormTrooperItem memory) {
        require(stormtroopers[_tokenId].exist, "Token does not exist.");
        return stormtroopers[_tokenId];
    }

    // === Admin === //

    /// @dev Set new base URI, kindly take a look on https://eips.ethereum.org/EIPS/eip-1155 for the format
    /// @param newuri The new URI to set
    function setURI(string memory newuri) public onlyHasRole(ADMIN_ROLE) {
        _setURI(newuri);
    }
    
    /// @dev Set the number mint per tx
    /// @param _maxMintPerTx The number of mint per tx
    function setMaxMintPerTx(uint256 _maxMintPerTx) public onlyHasRole(ADMIN_ROLE) {
        maxMintPerTx = _maxMintPerTx;
    }

    /// @dev Update Collection Mint Price
    /// @param _collectionId The CollectionID
    /// @param _mintPriceInWei The new Mint Price
    function updatCollectionMintPrice(uint256 _collectionId, uint256 _mintPriceInWei) external onlyHasRole(ADMIN_ROLE) {
        require(stormtroopers[_collectionId].exist, "Brand doesnt exist.");
        stormtroopers[_collectionId].mintPriceInWei = _mintPriceInWei;

        emit UpdateCollectionMintPrice({
            collectionId: _collectionId,
            mintPriceInWei: _mintPriceInWei
        });
    }

    /// @dev Set Brand 
    /// @param brandId The Brand ID
    function createBrand(uint256 brandId) public onlyHasRole(ADMIN_ROLE) {
        require(!brands[brandId].exist, "Brand already exist.");

        brands[brandId] = Brand({
            collectionIds: new uint256[](0),
            enabled: true,
            exist: true
        });

        brandIds.push(brandId);

        emit BrandCreated({
            collectionIds: 0,
            enabled: true,
            exist: true
        });
    }

    /// @dev Create collection
    /// @param cap The collection supply
    /// @param brand The brand to categories collection
    function createCollection(uint256 cap, uint256 brand, uint256 mintPriceInWei, bool isEnabled) external onlyHasRole(ADMIN_ROLE) {
        require(brands[brand].exist, "Brand doesnt exist.");
        require(cap > 0, "Collection supply cannot be zero");
        uint256 tokenId = nextTokenId();
        stormtroopers[tokenId] = StormTrooperItem(
            brand, // tag to categories collection
            cap, // token cap
            0, // mint count
            mintPriceInWei, // mint price
            isEnabled, // enabled
            true // exist
        );

        _tokenIds.increment();

        collectionIds.push(tokenId);
        collectionIdsBrand[tokenId] = brand;
        brands[brand].collectionIds.push(tokenId);

        emit CollectionCreated({
            brand: brand, 
            collectionId: tokenId, 
            mintPriceInWei: mintPriceInWei,
            cap: cap,
            enabled: isEnabled,
            exist: true
        });
    }

    /// @dev Get all collections by brand
    /// @param _brandId The brand id
    function _getCollectionIdsByBrand(uint256 _brandId) internal view returns (uint256[] memory) {
        return brands[_brandId].collectionIds;
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) public onlyHasRole(ADMIN_ROLE) {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function setIsPremintOpen(bool _isPremintOpen) public onlyHasRole(ADMIN_ROLE) {
        isPremintOpen = _isPremintOpen;
    }

    function setIsPublicMintOpen(bool _isPublicMintOpen) public onlyHasRole(ADMIN_ROLE) {
        isPublicMintOpen = _isPublicMintOpen;
    }

    /// @notice Enable Brand
    /// @param brandId The Brand to enable
    function enableBrand(uint256 brandId) public onlyHasRole(ADMIN_ROLE) {
        require(brands[brandId].exist, "Brand doesnt exist.");
        require(!brands[brandId].enabled, "Brand already enabled.");
        brands[brandId].enabled = true;
    }

    /// @notice Disable Brand
    /// @param brandId The Brand to disable
    function disableBrand(uint256 brandId) public onlyHasRole(ADMIN_ROLE) {
        require(brands[brandId].exist, "Brand doesnt exist.");
        require(brands[brandId].enabled, "Brand already disabled.");
        brands[brandId].enabled = false;
    }

    /// @notice Disable minting for this specific collection
    /// @param _id the collection id
    function enableCollection(uint256 _id) public onlyHasRole(ADMIN_ROLE) {
        require(stormtroopers[_id].exist, "Collection ID doesnt exist.");
        require(!stormtroopers[_id].enabled, "Collection already enabled.");
        stormtroopers[_id].enabled = true;
    }

    /// @notice Disable minting for this specific collection
    /// @param _id the collection id
    function disableCollection(uint256 _id) public onlyHasRole(ADMIN_ROLE) {
        require(stormtroopers[_id].exist, "Collection ID doesnt exist.");
        require(stormtroopers[_id].enabled, "Collection already disabled.");
        stormtroopers[_id].enabled = false;
    }

    /// @dev Update max supply of collection
    /// @param tokenId The collection id to update
    /// @param cap The collection supply
    function updateCapCollection(uint256 tokenId, uint256 cap) external onlyHasRole(ADMIN_ROLE) {
        require(cap > 0, "Collection supply cannot be zero");
        require(stormtroopers[tokenId].enabled, "Collection ID doesnt exist.");
        require(stormtroopers[tokenId].cap >= stormtroopers[tokenId].minted, "Cap cannot less than minted token.");
        StormTrooperItem storage item =  stormtroopers[tokenId];
        item.cap = cap;
    }

    // === Royalty === //

    /// @dev Set the royalty for all collection
    /// @param _feeNumerator The fee for collection
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator)
        public
        onlyHasRole(ADMIN_ROLE)
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /// @dev Set royalty fee for specific token
    /// @param _tokenId The tokenId where to add the royalty
    /// @param _receiver The royalty receiver
    /// @param _feeNumerator the fee for specific tokenId
    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _feeNumerator
    ) public onlyHasRole(ADMIN_ROLE) {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    /// @dev Allow owner to delete the default royalty for all collection
    function deleteDefaultRoyalty() external onlyHasRole(ADMIN_ROLE) {
        _deleteDefaultRoyalty();
    }

    /// @dev Reset specific royalty
    /// @param tokenId The token id where to reset the royalty
    function resetTokenRoyalty(uint256 tokenId)
        external
        onlyHasRole(ADMIN_ROLE)
    {
        _resetTokenRoyalty(tokenId);
    }

    // === Verify MerkleProof === //

    function _verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function _verifySenderProof(
        address sender,
        bytes32 merkleRoot,
        bytes32[] calldata proof
    ) internal pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        return _verify(proof, merkleRoot, leaf);
    }

    // === Withdrawal ===

    /// @dev Set wallets shares
    /// @param _wallets The wallets
    /// @param _walletsShares The wallets shares
    function setWithdrawalInfo(
        address[] memory _wallets,
        uint256[] memory _walletsShares
    ) public onlyHasRole(ADMIN_ROLE) {
        require(_wallets.length == _walletsShares.length, "not equal");
        wallets = _wallets;
        walletsShares = _walletsShares;

        totalShares = 0;
        for (uint256 i = 0; i < _walletsShares.length; i++) {
            totalShares += _walletsShares[i];
        }
    }

    /// @dev Withdraw contract native token balance
    function withdraw() external onlyHasRole(ADMIN_ROLE) {
        require(address(this).balance > 0, "no eth to withdraw");
        uint256 totalReceived = address(this).balance;
        for (uint256 i = 0; i < walletsShares.length; i++) {
            uint256 payment = (totalReceived * walletsShares[i]) / totalShares;
            Address.sendValue(payable(wallets[i]), payment);
        }
    }

    // === SupportInterface === //

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(AccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}