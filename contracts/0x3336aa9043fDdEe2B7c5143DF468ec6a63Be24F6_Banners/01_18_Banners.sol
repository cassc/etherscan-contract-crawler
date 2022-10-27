// @title Banners (for Adventurers) [https://bannersnft.com]
// @author devberry.eth
// @notice Society for Loot. Art for all.
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol';
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import './BannersStorage.sol';

    error AllowMintingDisabled();
    error ClaimingDisabled();
    error ExceedsAllowMintLimit();
    error ExceedsPublicMintLimit();
    error ExceedsMaximumSupply();
    error InvalidEthereumValue();
    error InvalidHash();
    error InvalidSignature();
    error LegacyTokenAlreadyClaimed();
    error NotBanners();
    error PublicMintingDisabled();
    error TransferFailed();
    error X();

contract Banners is ERC721AUpgradeable, OwnableUpgradeable, IERC2981Upgradeable {

    using ECDSAUpgradeable for bytes32;

    address constant d = 0x1E9a5429b0d38f5482090f04ac84494A6eA12C89;
    address constant r = 0x2531B2FF6a7f08c6Ab12c29D1b394788F819DeB1;
    address constant b = 0xA9EC89f38a1dC912F1726EE66409a840fFc6a709;

    uint32 x;

    receive() external payable {
        uint256 one = msg.value / 100;          // 1%
        (bool D, ) = d.call{value:one*9}("");   // 9%
        if(!D) revert TransferFailed();
        (bool B, ) = b.call{value:one*91}("");  // 91%
        if(!B) revert TransferFailed();
    }

    function initialize() initializerERC721A initializer public {
        __ERC721A_init('The Painted Banners (for Adventurers)', 'BANNERS');
        __Ownable_init();
    }

    function _claimLegacy(uint256[] calldata tokenIds, bytes32 hash, bytes memory signature) external {
        BannersStorage.Layout storage store = BannersStorage.layout();
        uint256 currentIndex = ERC721AStorage.layout()._currentIndex;
        if (store._mintConfig.claimEpoch == 0 || block.timestamp < store._mintConfig.claimEpoch) revert ClaimingDisabled();
        if (hashClaim(msg.sender, tokenIds) != hash) revert InvalidHash();
        if (store._mintConfig.signer != hash.recover(signature)) revert InvalidSignature();
        for (uint256 t = 0; t < tokenIds.length; t++) {
            if (store._legacyIdToTokenId[tokenIds[t]] == 0) {
                store._legacyIdToTokenId[tokenIds[t]] = currentIndex + t;
                store._tokenIdToLegacyId[currentIndex + t] = tokenIds[t];
            } else {
                revert LegacyTokenAlreadyClaimed();
            }
        }
        internalMint(tokenIds.length);
    }

    function _allowMint(uint256 quantity, bytes32 hash, bytes memory signature) external payable {
        BannersStorage.Layout storage store = BannersStorage.layout();
        if (store._mintConfig.allowEpoch == 0 || block.timestamp < store._mintConfig.allowEpoch || block.timestamp >= store._mintConfig.publicEpoch) revert AllowMintingDisabled();
        if (msg.value != store._mintConfig.allowPrice * quantity) revert InvalidEthereumValue();
        if (store._allowMints[msg.sender] + quantity > store._mintConfig.allowLimit) revert ExceedsAllowMintLimit();
        if (store._minted+quantity>=store._mintConfig.totalSupply) revert ExceedsMaximumSupply();
        if (hashAllow(msg.sender) != hash) revert InvalidHash();
        if (store._mintConfig.signer != hash.recover(signature)) revert InvalidSignature();
        uint256 currentIndex = ERC721AStorage.layout()._currentIndex;
        for(uint256 t = 0; t < quantity; t++){
            store._tokenIdToNewId[currentIndex+t] = store._minted + t + 1;
        }
        internalMint(quantity);
        store._allowMints[msg.sender] += quantity;
        store._minted += quantity;
    }

    function _publicMint(uint256 quantity) external payable {
        BannersStorage.Layout storage store = BannersStorage.layout();
        if (store._mintConfig.publicEpoch == 0 || block.timestamp < store._mintConfig.publicEpoch) revert PublicMintingDisabled();
        if (msg.value != store._mintConfig.publicPrice * quantity) revert InvalidEthereumValue();
        if (store._publicMints[msg.sender] + quantity > store._mintConfig.publicLimit) revert ExceedsPublicMintLimit();
        if (store._minted+quantity>=store._mintConfig.totalSupply) revert ExceedsMaximumSupply();
        uint256 currentIndex = ERC721AStorage.layout()._currentIndex;
        for(uint256 t = 0; t < quantity; t++){
            store._tokenIdToNewId[currentIndex+t] = store._minted + t + 1;
        }
        internalMint(quantity);
        store._publicMints[msg.sender] += quantity;
        store._minted += quantity;
    }

    function reserveMint(uint256 quantity) external {
        BannersStorage.Layout storage store = BannersStorage.layout();
        if (msg.sender != b && msg.sender != OwnableUpgradeable.owner()) revert NotBanners();
        uint256 currentIndex = ERC721AStorage.layout()._currentIndex;
        for(uint256 t = 0; t < quantity; t++){
            store._tokenIdToNewId[currentIndex+t] = store._minted + t + 1;
        }
        internalMint(quantity);
        store._minted += quantity;
    }

    function internalMint(uint256 quantity) internal {
        if (x == 1) revert X();
        x = 1;
        _mint(msg.sender, quantity);
        x = 0;
    }

    function setMintConfig(BannersStorage.MintConfig calldata _mintConfig) external onlyOwner {
        BannersStorage.layout()._mintConfig = _mintConfig;
    }

    function mintConfig() external view returns (BannersStorage.MintConfig memory) {
        return BannersStorage.layout()._mintConfig;
    }

    function totalMinted() external view returns (uint256) {
        return BannersStorage.layout()._minted;
    }

    function legacyTokenId(uint256 tokenId) public view returns (uint256){
        return BannersStorage.layout()._tokenIdToLegacyId[tokenId];
    }

    function legacyTokenIds(uint256[] calldata tokenIds) public view returns (uint256[] memory){
        uint256[] memory legacyIds = new uint256[](tokenIds.length);
        BannersStorage.Layout storage store = BannersStorage.layout();
        for(uint256 t = 0; t < tokenIds.length; t++){
            legacyIds[t] = store._tokenIdToLegacyId[tokenIds[t]];
        }
        return legacyIds;
    }

    function newTokenId(uint256 tokenId) public view returns (uint256){
        return BannersStorage.layout()._tokenIdToNewId[tokenId];
    }

    function newTokenIds(uint256[] calldata tokenIds) public view returns (uint256[] memory){
        uint256[] memory legacyIds = new uint256[](tokenIds.length);
        BannersStorage.Layout storage store = BannersStorage.layout();
        for(uint256 t = 0; t < tokenIds.length; t++){
            legacyIds[t] = store._tokenIdToNewId[tokenIds[t]];
        }
        return legacyIds;
    }

    function newTokenIdToTokenId(uint256 newId) public view returns (uint256){
        uint256 currentIndex = ERC721AStorage.layout()._currentIndex;
        for(uint256 t = 0; t < currentIndex; t++){
            if(newTokenId(t) == newId) return newTokenId(t);
        }
        return 0;
    }

    function claimedTokenId(uint256 legacyId) public view returns (uint256){
        return BannersStorage.layout()._legacyIdToTokenId[legacyId];
    }

    function claimedTokenIds(uint256[] calldata legacyIds) public view returns (uint256[] memory){
        uint256[] memory tokenIds = new uint256[](legacyIds.length);
        BannersStorage.Layout storage store = BannersStorage.layout();
        for(uint256 t = 0; t < legacyIds.length; t++){
            tokenIds[t] = store._legacyIdToTokenId[legacyIds[t]];
        }
        return tokenIds;
    }

    function hashClaim(address minter, uint256[] memory tokenIds)
    private
    pure
    returns (bytes32)
    {
        return ECDSAUpgradeable.toEthSignedMessageHash(keccak256(abi.encodePacked(minter, tokenIds)));
    }

    function hashAllow(address minter)
    private
    pure
    returns (bytes32)
    {
        return ECDSAUpgradeable.toEthSignedMessageHash(keccak256(abi.encodePacked(minter)));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        uint256 legacyId = legacyTokenId(tokenId);
        if(legacyId>0){
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, "legacy/", _toString(legacyId))) : '';
        }else{
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, "new/", _toString(newTokenId(tokenId)))) : '';
        }
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        BannersStorage.layout()._baseURI = baseURI;
    }

    function setToll(uint256 _toll) external onlyOwner {
        BannersStorage.layout()._toll = _toll;
    }

    function withdraw() external {
        if (msg.sender != b && msg.sender != OwnableUpgradeable.owner()) revert NotBanners();
        uint256 one = address(this).balance / 100;  // 1%
        (bool R, ) = r.call{value:one*2}("");       // 2%
        if(!R) revert TransferFailed();
        (bool D, ) = d.call{value:one*12}("");      // 12%
        if(!D) revert TransferFailed();
        (bool B, ) = b.call{value:one*86}("");      // 86%
        if(!B) revert TransferFailed();
    }

    function _baseURI() internal view override returns (string memory) {
        return BannersStorage.layout()._baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @inheritdoc IERC2981Upgradeable
     */
    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) public view virtual override returns (address, uint256) {
        uint256 royaltyAmount = (_salePrice * BannersStorage.layout()._toll) / 10000;
        return (address(this), royaltyAmount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AUpgradeable, IERC165Upgradeable) returns (bool) {
        return
        interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
        interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
        interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
        interfaceId == type(IERC2981Upgradeable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function devHitByBus() external {
        if (msg.sender != b) revert NotBanners();
        _transferOwnership(b);
    }

}