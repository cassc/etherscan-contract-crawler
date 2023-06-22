// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721A} from "@ERC721A/ERC721A.sol";
import {ERC2981} from "@openzeppelin/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";

import {AllowList} from "./AllowList.sol";

contract AncientEnemies is ERC721A, Ownable, AllowList, ERC2981 {
    error AllowListMintPaused();
    error IncorrectMintPrice();
    error MetadataFrozen();
    error PublicMintPaused();
    error SupplyExceeded();
    error MintLimitExceeded();
    error OnlyEOA();

    /// @notice Total number of tokens that can be minted.
    uint256 public constant TOTAL_SUPPLY = 5000;
    /// @notice Maximum number of tokens that can be minted per wallet.
    uint256 public constant WALLET_LIMIT = 10;
    /// @notice The price to mint a token if on allow list.
    uint256 public allowListMintPrice = 0;
    /// @notice The public mint price.
    uint256 public mintPrice = 0.1 ether;
    /// @notice Whether or not allow list minting is paused.
    bool public allowListCanMint = false;
    /// @notice Whether or not public minting is paused.
    bool public publicCanMint = false;
    /// @notice The base URI used to construct all individual token URIs.
    string public baseTokenURI;
    /// @notice Whether or not the baseTokenURI can be updated.
    bool public metadataFrozen = false;
    /// @notice The number of tokens minted per address via allow list.
    mapping(address => uint256) public numAllowListMints;
    /// @notice The number of tokens minted per address via public mint.
    mapping(address => uint256) public numMints;

    constructor(
        address[] memory teamAddresses,
        uint256[] memory teamAllocations,
        string memory _baseTokenURI,
        bytes32 _merkleRoot,
        address royaltyRecipient
    ) ERC721A("Ancient Enemies", "AE") {
        for (uint256 i = 0; i < teamAddresses.length; i++) {
            _mint(teamAddresses[i], teamAllocations[i]);
        }
        baseTokenURI = _baseTokenURI;
        _setMerkleRoot(_merkleRoot);
        _setDefaultRoyalty(royaltyRecipient, 500);
    }

    /// @notice Mint tokens to sender.
    /// @param amount The number of tokens to mint.
    function mint(uint256 amount) external payable {
        _onlyEOA(msg.sender);
        if (!publicCanMint) revert PublicMintPaused();
        if (msg.value != amount * mintPrice) revert IncorrectMintPrice();
        if (_totalMinted() + amount > TOTAL_SUPPLY) revert SupplyExceeded();
        if (numMints[msg.sender] + amount > WALLET_LIMIT) revert MintLimitExceeded();
        numMints[msg.sender] += amount;
        _mint(msg.sender, amount);
    }

    /// @notice Mint tokens to sender. Reverts if caller is not on the allow list.
    /// @param amount The number of tokens to mint.
    /// @param amountAllocated The number of tokens allocated to the sender via allow list.
    /// @param proof The merkle proof to verify.
    function allowListMint(uint256 amount, uint256 amountAllocated, bytes32[] calldata proof) external payable {
        _onlyEOA(msg.sender);
        if (!allowListCanMint) revert AllowListMintPaused();
        if (msg.value != amount * allowListMintPrice) revert IncorrectMintPrice();
        if (_totalMinted() + amount > TOTAL_SUPPLY) revert SupplyExceeded();
        _verifyProof(msg.sender, amountAllocated, proof);
        uint256 numMinted = numAllowListMints[msg.sender];
        if (numMinted + amount > amountAllocated) revert MintLimitExceeded();
        numAllowListMints[msg.sender] = numMinted + amount;
        _mint(msg.sender, amount);
    }

    /// @notice Returns URI for token metadata.
    /// @param tokenId The id of the token we are querying for.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(_baseURI(), _toString(tokenId))) : "";
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    //////////////////////////////////////////////////////////////////
    // ADMIN
    //////////////////////////////////////////////////////////////////

    /// @notice Allows contract owner to mint tokens to specified address for free.
    /// @param amount The number of tokens to mint.
    /// @param to The address to mint tokens to.
    function adminMint(uint256 amount, address to) external onlyOwner {
        if (_totalMinted() + amount > TOTAL_SUPPLY) revert SupplyExceeded();
        _mint(to, amount);
    }

    /// @notice Update the base token URI. Once metadata is frozen, this function will revert
    /// preventing any further updates.
    /// @param _baseTokenURI The new base token URI.
    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        if (metadataFrozen) revert MetadataFrozen();
        baseTokenURI = _baseTokenURI;
    }

    /// @notice Update the price to mint tokens via allow list.
    /// @param _allowListMintPrice The new allow list mint price.
    function setAllowListMintPrice(uint256 _allowListMintPrice) external onlyOwner {
        allowListMintPrice = _allowListMintPrice;
    }

    /// @notice Update the price to mint tokens via public minting.
    /// @param _mintPrice The new public mint price.
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /// @notice Update the merkle root used to verify allow list.
    /// @param _merkleRoot The new merkle root.
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        _setMerkleRoot(_merkleRoot);
    }

    /// @notice Update ERC2981 royalty info for the contract.
    /// @param receiver The address to receive royalties.
    /// @param feeNumerator The royalty fee numerator.
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @notice Irrevocably freeze metadata. Once frozen, the base token URI cannot be updated.
    function freezeMetadata() external onlyOwner {
        if (metadataFrozen) revert MetadataFrozen();
        metadataFrozen = true;
    }

    /// @notice Toggle whether or not allow list minting is paused.
    function toggleAllowListMinting() external onlyOwner {
        allowListCanMint = !allowListCanMint;
    }

    /// @notice Toggle whether or not public minting is paused.
    function togglePublicMinting() external onlyOwner {
        publicCanMint = !publicCanMint;
    }

    /// @notice Withdraw contract balance to owner.
    function withdraw() public onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    //////////////////////////////////////////////////////////////////
    // INTERNALS & OVERRIDES
    //////////////////////////////////////////////////////////////////

    function _onlyEOA(address account) internal view {
        if (msg.sender != tx.origin || account.code.length > 0) {
            revert OnlyEOA();
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return interfaceId == 0x2a55205a // ERC165 Interface ID for ERC2981
            || interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0x80ac58cd // ERC165 Interface ID for ERC721
            || interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }
}