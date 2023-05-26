// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

//   _  _ _  _ _  _  _  _
//  | || | || | || \| || |
//  n_|||U || U || \\ || |
// \__/|___||___||_|\_||_|

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

abstract contract Zodia {
    function discoverZodia(address to, uint256 grimoireId)
        external
        virtual
        returns (uint256);
}

contract JuuniGrimoire is ERC721AQueryable, ReentrancyGuard, Ownable, ERC2981 {
    using ECDSA for bytes32;

    enum SaleState {
        CLOSED,
        PUBLIC,
        ORIGINAL_ZODIA
    }

    // Base grimoire related info
    uint256 constant MAX_SUPPLY = 5_555;
    string public baseTokenURI = "";
    address public signer;

    // Mint related info
    uint256 public maxGrimoires = 5_555;
    // PLACEHOLDER PRICE ONLY - FINAL PRICE SUBJECT TO CHANGE
    uint256 public publicMintPrice = 0.25 ether;
    // PLACEHOLDER PRICE ONLY - FINAL PRICE SUBJECT TO CHANGE
    uint256 public originalZodiaMintPrice = 0.2 ether;
    // PLACEHOLDER PRICE ONLY - FINAL PRICE SUBJECT TO CHANGE
    uint256 public maxPublicGrimoires;
    uint256 public publicGrimoiresMinted;
    uint256 public ozGrimoiresMinted;
    uint256 private teamAllocation = 100;
    SaleState public saleState;
    mapping(address => bool) public publicMintedMap;

    // Withdrawal related
    address public HEXaddress = 0xfb119f9c8A4af5d03E9D7C22296212924FC223f5;
    // 40% of initial mint sales will go to HEX
    uint256 public artistSplit = 40;

    // Zodia related properties
    bool public canDiscoverZodia;
    address public zodiaContract;
    event ZodiaDiscovered(uint256 grimoireId, uint256 zodiaId);

    error AlreadyMinted();
    error BelowCurrentSupply();
    error ContractNotAllowedToMint();
    error DiscoverZodiaNotAvailable();
    error DiscoverZodiaNotEnoughBalance();
    error ExceedMaxSalePhase();
    error ExceedMaxSupply();
    error InsufficientEther();
    error InvalidAddress();
    error InvalidMaxPublicGrimoires();
    error InvalidSignature();
    error InvalidSigner();
    error InvalidQuantity();
    error NotEnoughPublicGrimoires();
    error SaleInactive();
    error UnsupportedMarketplace();
    error WithdrawFailed();
    error ZodiaContractNotSet();

    constructor(address to) ERC721A("JUUNI Grimoire", "GRIMOIRE") {
        _mintERC2309(to, teamAllocation);
    }

    function bestowGrimoire(bytes calldata signature, uint256 quantity)
        external
        payable
    {
        if (tx.origin != msg.sender) revert ContractNotAllowedToMint();
        // Due to grimoires being able to be burned we used minted check here
        if (_totalMinted() + quantity > maxGrimoires) revert ExceedMaxSupply();
        if (saleState == SaleState.CLOSED) revert SaleInactive();

        if (saleState == SaleState.PUBLIC) {
            if (publicMintedMap[msg.sender]) revert AlreadyMinted();
            if (publicGrimoiresMinted + quantity > maxPublicGrimoires)
                revert NotEnoughPublicGrimoires();
            _verifySignature(signature, "public sale");

            if (quantity > 2) revert ExceedMaxSalePhase();
            if (msg.value < publicMintPrice * quantity)
                revert InsufficientEther();

            publicMintedMap[msg.sender] = true;
            publicGrimoiresMinted += quantity;
            _mint(msg.sender, quantity);
        }

        if (saleState == SaleState.ORIGINAL_ZODIA) {
            /// Check aux value, non-zero infers minted.
            if (_getAux(msg.sender) == 1) revert AlreadyMinted();
            _verifySignature(signature, "original zodia sale");

            if (quantity > 1) revert ExceedMaxSalePhase();
            if (msg.value < originalZodiaMintPrice) revert InsufficientEther();

            /// Set aux value.
            _setAux(msg.sender, 1);
            ozGrimoiresMinted += 1;

            /// Mint token.
            _mint(msg.sender, 1);
        }
    }

    function discoverZodia(uint256 grimoireId)
        external
        nonReentrant
        returns (uint256)
    {
        if (zodiaContract == address(0)) revert ZodiaContractNotSet();
        if (!canDiscoverZodia) revert DiscoverZodiaNotAvailable();
        address to = ownerOf(grimoireId);

        if (msg.sender != to) revert DiscoverZodiaNotEnoughBalance();

        Zodia zodia = Zodia(zodiaContract);

        _burn(grimoireId, true);

        uint256 zodiaId = zodia.discoverZodia(to, grimoireId);
        emit ZodiaDiscovered(grimoireId, zodiaId);

        return zodiaId;
    }

    function zodiasDiscovered(address addr) external view returns (uint256) {
        return _numberBurned(addr);
    }

    function totalZodiasDiscovered() external view returns (uint256) {
        return _totalBurned();
    }

    function hasAddressMintedOZ(address addr) external view returns (bool) {
        return _getAux(addr) == 1;
    }

    // Remaining if any treasury mint
    function teamMint(address to) external onlyOwner {
        if (to == address(0)) revert InvalidAddress();
        if (_totalMinted() == maxGrimoires) revert ExceedMaxSupply();

        _mint(to, maxGrimoires - _totalMinted());
    }

    // Private sale airdrops
    function privateSaleGrimoireAirdrop(address to, uint256 quantity)
        external
        onlyOwner
    {
        if (quantity > 25) revert InvalidQuantity();
        if (_totalMinted() + quantity > maxGrimoires) revert ExceedMaxSupply();

        _mint(to, quantity);
    }

    function setMaxGrimoires(uint256 newMaxGrimoires) external onlyOwner {
        if (newMaxGrimoires > MAX_SUPPLY) revert ExceedMaxSupply();

        if (newMaxGrimoires < totalSupply()) revert BelowCurrentSupply();

        maxGrimoires = newMaxGrimoires;
    }

    function toggleCanDiscoverZodia() external onlyOwner {
        canDiscoverZodia = !canDiscoverZodia;
    }

    function setOriginalZodiaMintPrice(uint256 price) external onlyOwner {
        originalZodiaMintPrice = price;
    }

    function setSaleState(SaleState newSaleState) external onlyOwner {
        saleState = newSaleState;
    }

    function setMaxPublicGrimoires(uint256 newMaxPublicGrimoires)
        external
        onlyOwner
    {
        if (newMaxPublicGrimoires > maxGrimoires - totalSupply())
            revert InvalidMaxPublicGrimoires();

        maxPublicGrimoires = newMaxPublicGrimoires;
    }

    function setPublicMintPrice(uint256 price) external onlyOwner {
        publicMintPrice = price;
    }

    function setHEXaddress(address newHEXaddress) external onlyOwner {
        HEXaddress = newHEXaddress;
    }

    function setZodiaContract(address contractAddress) external onlyOwner {
        zodiaContract = contractAddress;
    }

    function setSigner(address newSigner) external onlyOwner {
        if (newSigner == address(0)) revert InvalidSigner();
        signer = newSigner;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseTokenURI = baseURI_;
    }

    function withdraw() external onlyOwner {
        (bool artistTransferSuccess, ) = HEXaddress.call{
            value: ((address(this).balance * artistSplit) / 100)
        }("");

        (bool teamTransferSuccess, ) = msg.sender.call{
            value: address(this).balance
        }("");

        if (!artistTransferSuccess || !teamTransferSuccess)
            revert WithdrawFailed();
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function _verifySignature(bytes calldata signature, string memory action)
        internal
        view
    {
        address signedAddress = keccak256(abi.encodePacked(msg.sender, action))
            .toEthSignedMessageHash()
            .recover(signature);

        if (signedAddress != signer) revert InvalidSignature();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981, IERC721A)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}