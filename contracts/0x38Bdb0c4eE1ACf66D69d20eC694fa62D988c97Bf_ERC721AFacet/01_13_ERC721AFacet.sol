// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../LibDiamond.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./BaseFacet.sol";
import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';

contract ERC721AFacet is BaseFacet, ERC721AUpgradeable, IERC2981 {
    using Strings for uint256;
    using ECDSA for bytes32;

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(s.baseTokenURI, "/", tokenId.toString(), ".json"));
    }

    // Not in used (see @DiamondCutAndLoupeFacet)
    function supportsInterface(bytes4 interfaceId) override(ERC721AUpgradeable, IERC165) public view virtual returns (bool) {
        return false;
    }

    // Take note of the initializer modifiers.
    // - `initializerERC721A` for `ERC721AUpgradeable`.
    function initialize() external initializerERC721A onlyOwner {
        __ERC721A_init('Bayside Toolbox', 'BT');
    }

    // =========== ERC721A ===========

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    // ==================== Management ====================

    function setMethodsExposureFacetAddress(address _methodsExposureFacetAddress) external onlyOwner {
        s.methodsExposureFacetAddress = _methodsExposureFacetAddress;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        s.baseTokenURI = _baseTokenURI;
    }

    function setRoyaltiesRecipient(address _royaltiesRecipient) external onlyOwner {
        s.royaltiesRecipient = _royaltiesRecipient;
    }

    function setRoyaltiesBasisPoints(uint256 _royaltiesBasisPoints) external onlyOwner {
        s.royaltiesBasisPoints = _royaltiesBasisPoints;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        s.mintPrice = _mintPrice;
    }

    function setMaxMintsPerWallet(uint32 _maxMintsPerWallet) external onlyOwner {
        s.maxMintsPerWallet = _maxMintsPerWallet;
    }

    function setMaxSupply(uint32 _maxSupply) external onlyOwner {
        s.maxSupply = _maxSupply;
    }

    function setMaxMintsTeam(uint32 _maxMintsTeam) external onlyOwner {
        s.maxMintsTeam = _maxMintsTeam;
    }

    function setMintOpen(bool _mintOpen) external onlyOwner {
        s.mintOpen = _mintOpen;
    }

    function setPublicMintOpen(bool _publicMintOpen) external onlyOwner {
        s.publicMintOpen = _publicMintOpen;
    }

    // ==================== Views ====================

    function maxSupply() external view returns (uint32) {
        return s.maxSupply;
    }

    function maxMintsTeam() external view returns (uint32) {
        return s.maxMintsTeam;
    }

    function baseTokenURI() external view returns (string memory) {
        return s.baseTokenURI;
    }

    function mintPrice() external view returns (uint256) {
        return s.mintPrice;
    }

    function maxMintsPerWallet() external view returns (uint32) {
        return s.maxMintsPerWallet;
    }

    function royaltiesRecipient() external view returns (address) {
        return s.royaltiesRecipient;
    }

    function royaltiesBasisPoints() external view returns (uint256) {
        return s.royaltiesBasisPoints;
    }

    function mintOpen() external view returns (bool) {
        return s.mintOpen;
    }

    function publicMintOpen() external view returns (bool) {
        return s.publicMintOpen;
    }

    // =========== EIP2981 ===========

    function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount) {
        return (s.royaltiesRecipient, (_salePrice * s.royaltiesBasisPoints) / LibDiamond.PERCENTAGE_DENOMINATOR);
    }

    // =========== ERC721 ===========

    /*
        @dev
        Allowlist marketplaces to enable gas-less listings.
    */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        if (operator == LibDiamond.OPENSEA_CONDUIT) {
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
        }
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

    // =========== Mint ===========

    function mintPublic(uint32 quantity) payable external {
        require(s.publicMintOpen, "Public mint not open");
        require(_totalMinted() + quantity <= s.maxSupply, "No more mints");
        require(_numberMinted(msg.sender) + quantity <= s.maxMintsPerWallet, "Too many mints");
        require(msg.value == s.mintPrice * quantity, "Wrong value sent");

        _safeMint(msg.sender, quantity);
    }

    function mintTeam(address to, uint32 quantity) external onlyOwner {
        require(_totalMinted() + quantity <= s.maxSupply, "No more mints");
        require(s.totalMintedTeam + quantity <= s.maxMintsTeam, "Too many mints");

        s.totalMintedTeam += quantity;
        _safeMint(to, quantity);
    }

    function mint(uint256 allowedStartDate, bytes calldata signature) payable external {
        require(
            keccak256(abi.encodePacked(msg.sender, allowedStartDate)).toEthSignedMessageHash().recover(signature) ==
            s.signingAddress,
            "Invalid signature"
        );
        require(s.mintOpen, "Mint not open");
        require(_numberMinted(msg.sender) + 1 <= s.maxMintsPerWallet, "Too many mints");
        require(_totalMinted() + 1 <= s.maxSupply, "No more mints");
        require(msg.value == s.mintPrice, "Wrong value sent");
        require(allowedStartDate <= block.timestamp, "Wrong mint time");
        _safeMint(msg.sender, 1);
        Address.sendValue(payable(s.royaltiesRecipient), address(this).balance);
    }

}