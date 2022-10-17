// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../LibDiamond.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./BaseFacet.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

contract ERC721AFacet is BaseFacet, ERC721AUpgradeable, IERC2981 {
    using Strings for uint256;
    using ECDSA for bytes32;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Humans and Bears only");
        _;
    }

    modifier supplyAvailable(uint256 quantity) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        uint256 teamMintsLeft = _as.maxMintsTeam - _as.totalMintedTeam;
        require(_totalMinted() + quantity <= _as.maxSupply - teamMintsLeft, "No more mints");
        _;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (_as.isReveal) {
            return string(abi.encodePacked(_as.baseTokenURI, "/", tokenId.toString(), ".json"));
        } else {
            return _as.unrevealURI;
        }
    }

    // Not in used (see @DiamondCutAndLoupeFacet)
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Take note of the initializer modifiers.
    // - `initializerERC721A` for `ERC721AUpgradeable`.
    function initialize() external initializerERC721A onlyOwner {
        __ERC721A_init("Budda Bears", "BUDDA");
    }

    // =========== ERC721A ===========

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // ==================== Management ====================

    function setMethodsExposureFacetAddress(address _methodsExposureFacetAddress) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.methodsExposureFacetAddress = _methodsExposureFacetAddress;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.baseTokenURI = _baseTokenURI;
    }

    function setRoyaltiesRecipient(address _royaltiesRecipient) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.royaltiesRecipient = _royaltiesRecipient;
    }

    function setRoyaltiesBasisPoints(uint256 _royaltiesBasisPoints) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.royaltiesBasisPoints = _royaltiesBasisPoints;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.mintPrice = _mintPrice;
    }

    function setMaxMintsPerWallet(uint32 _maxMintsPerWallet) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.maxMintsPerWallet = _maxMintsPerWallet;
    }

    function setMaxMintsTeam(uint32 _maxMintsTeam) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.maxMintsTeam = _maxMintsTeam;
    }

    function setMaxSupply(uint32 _maxSupply) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.maxSupply = _maxSupply;
    }

    function setReveal(bool _isReveal) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.isReveal = _isReveal;
    }

    function setPublicMintOpen(bool _publicMintOpen) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.publicMintOpen = _publicMintOpen;
    }

    function setAllowlistMintOpen(bool _allowlistMintOpen) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.allowlistMintOpen = _allowlistMintOpen;
    }

    // ==================== Views ====================

    function maxSupply() external view returns (uint32) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.maxSupply;
    }

    function baseTokenURI() external view returns (string memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.baseTokenURI;
    }

    function mintPrice() external view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.mintPrice;
    }

    function maxMintsPerWallet() external view returns (uint32) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.maxMintsPerWallet;
    }

    function maxMintsTeam() external view returns (uint32) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.maxMintsTeam;
    }

    function isReveal() external view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.isReveal;
    }

    function royaltiesRecipient() external view returns (address) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.royaltiesRecipient;
    }

    function royaltiesBasisPoints() external view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.royaltiesBasisPoints;
    }

    function publicMintOpen() external view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.publicMintOpen;
    }

    function allowlistMintOpen() external view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.allowlistMintOpen;
    }

    function numberMinted(address who) external view returns (uint256) {
        return _numberMinted(who);
    }

    function totalMintedTeam() external view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.totalMintedTeam;
    }

    // =========== EIP2981 ===========

    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return (_as.royaltiesRecipient, (_salePrice * _as.royaltiesBasisPoints) / LibDiamond.PERCENTAGE_DENOMINATOR);
    }

    // =========== ERC721 ===========

    /*
        @dev
        Allowlist marketplaces to enable gas-less listings.
    */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        // Seaport's conduit contract
        try
            LibDiamond.OPENSEA_SEAPORT_CONDUIT_CONTROLLER.getChannelStatus(
                operator,
                LibDiamond.appStorage().seaportAddress
            )
        returns (bool isOpen) {
            if (isOpen) {
                return true;
            }
        } catch {}
        // LooksRare
        if (
            operator == LibDiamond.LOOKSRARE_ERC721_TRANSFER_MANAGER ||
            // X2Y2
            operator == LibDiamond.X2Y2_ERC721_DELEGATE
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    // =========== Mints ===========

    function mint(bytes calldata signature, uint256 quantity) external payable callerIsUser supplyAvailable(quantity) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.publicMintOpen, "Mint not open");
        require(_numberMinted(msg.sender) + quantity <= _as.maxMintsPerWallet, "Too many mints");

        require(
            keccak256(abi.encodePacked(msg.sender, quantity)).toEthSignedMessageHash().recover(signature) ==
                _as.signingAddress,
            "Invalid signature"
        );

        _safeMint(msg.sender, quantity);
    }

    function allowlistMint(bytes calldata signature, uint256 quantity) external payable supplyAvailable(quantity) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.allowlistMintOpen, "Mint not open");

        // can only mint once during allowlist phase
        require(_numberMinted(msg.sender) == 0, "Too many mints");

        require(
            keccak256(abi.encodePacked(msg.sender, quantity)).toEthSignedMessageHash().recover(signature) ==
                _as.signingAddress,
            "Invalid signature"
        );

        _safeMint(msg.sender, quantity);
    }

    function mintTeam(address to, uint256 quantity) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();

        require(_as.totalMintedTeam + quantity <= _as.maxMintsTeam, "Too many mints");
        require(_totalMinted() + quantity <= _as.maxSupply, "No more mints");

        _as.totalMintedTeam += quantity;
        _safeMint(to, quantity);
    }
}