// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/**
 *
 *      ███████       ███       ███████  ██        ██     ██  ████     ████
 *      ██           ██ ██      ██       ██        ██     ██  ██ ██   ██ ██
 *      ██          ██   ██     ██       ██        ██     ██  ██  ██ ██  ██
 *      ██         █████████    ██████   ██        ██     ██  ██   ███   ██
 *      ██        ██       ██   ██       ██        ██     ██  ██         ██
 *      ███████  ██         ██  ███████  ████████  █████████  ██         ██
 *
 */


import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {IERC721A, ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {OperatorFilterer} from "./OperatorFilterer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

contract Caelum is
    ERC721AQueryable,
    ERC721ABurnable,
    OperatorFilterer,
    Ownable,
    ERC2981
{
    using Strings for uint256;

    error ContractPausedError();
    error PublicSaleNotActiveError();
    error PreSaleNotActiveError();
    error ExceedingMaxSupplyError();
    error MintsPerAddressExceededError();
    error InsufficientFundsError();
    error NotWhitelistedError();
    error NotElegibleOrWrongAmountError();
    error AddressAlreadyClaimedError();

    uint256 public immutable MAX_SUPPLY;
    uint256 public PRICE_PUBLIC_SALE = 0.066 ether;
    uint256 public PRICE_PRESALE = 0.046 ether;
    uint256 public constant MAX_PER_MINT_PRESALE = 2;
    uint256 public constant MAX_PER_MINT_PUBLIC = 4;

    uint256 private RESERVED;
    uint256 private reserved_minted = 0;
    uint256 private team_minted = 0;

    bool public paused = false;
    bool public presaleActive = false;
    bool public publicSaleActive = false;
    bool private revealed = false;

    string private baseURI;
    string private notRevealedUri;
    string private constant baseExtension = ".json";

    mapping(address => uint256) public addressPresaleMintedBalance;
    mapping(address => uint256) public addressPublicMintedBalance;
    mapping(address => bool) public addressReservedMintClaim;

    bytes32 public PresaleMerkleRoot = 0x00;
    bytes32 public ReservedMerkleRoot = 0x00;

    bool public operatorFilteringEnabled;

    constructor(
        string memory _initNotRevealedUri,
        uint256 _maxSupply,
        uint256 _reserved,
        bytes32 _presaleMerkleRoot,
        bytes32 _reservedMerkleRoot
    ) ERC721A("ProjectCaelum", "CAELUM") {
        
        baseURI = _initNotRevealedUri;
        notRevealedUri = _initNotRevealedUri;
        MAX_SUPPLY = _maxSupply;
        RESERVED = _reserved;
        PresaleMerkleRoot = _presaleMerkleRoot;
        ReservedMerkleRoot = _reservedMerkleRoot;

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 350);
    }

    // SETTERS

    function setPublicPrice(uint256 _newPrice) public onlyOwner {
        PRICE_PUBLIC_SALE = _newPrice;
    }

    function setPresalePrice(uint256 _newPrice) public onlyOwner {
        PRICE_PRESALE = _newPrice;
    }

    function setPresaleState(bool _state) public onlyOwner {
        presaleActive = _state;
    }

    function setPublicSaleState(bool _state) public onlyOwner {
        publicSaleActive = _state;
    }

    function setPausedState(bool _state) public onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedUri(string memory _notRevealedUri) public onlyOwner {
        notRevealedUri = _notRevealedUri;
    }

    function setPresaleMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        PresaleMerkleRoot = _merkleRoot;
    }

    function setReservedMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        ReservedMerkleRoot = _merkleRoot;
    }

    function setReveal(
        bool _state,
        string memory _newBaseURI
    ) public onlyOwner {
        revealed = _state;
        baseURI = _newBaseURI;
    }

    // MINTING

    /**
     * Returns how much can be minted at the moment
     */
    function maxSupply() private view returns (uint256) {
        return
            MAX_SUPPLY -
            RESERVED +
            reserved_minted;
    }

    /**
     * Public mint.
     * limited by state and max minted per address
     */
    function mint(uint256 _mintAmount) public payable {
        if (paused) revert ContractPausedError();
        if (!publicSaleActive) revert PublicSaleNotActiveError();
        uint256 supply = totalSupply();
        if (supply + _mintAmount > maxSupply())
            revert ExceedingMaxSupplyError();
        uint256 ownerMintedCount = addressPublicMintedBalance[msg.sender];
        if (ownerMintedCount + _mintAmount > MAX_PER_MINT_PUBLIC)
            revert MintsPerAddressExceededError();
        if (msg.value < PRICE_PUBLIC_SALE * _mintAmount)
            revert InsufficientFundsError();

        addressPublicMintedBalance[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    /**
     * Presale mint
     * limited by state, whitelist and max minted per address
     */
    function presaleMint(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    ) public payable {
        if (paused) revert ContractPausedError();
        if (!presaleActive) revert PreSaleNotActiveError();
        if (!isWhitelistedForPresale(_merkleProof))
            revert NotWhitelistedError();
        uint256 supply = totalSupply();
        if (supply + _mintAmount > maxSupply())
            revert ExceedingMaxSupplyError();
        uint256 ownerMintedCount = addressPresaleMintedBalance[msg.sender];
        if (ownerMintedCount + _mintAmount > MAX_PER_MINT_PRESALE)
            revert MintsPerAddressExceededError();
        if (msg.value < PRICE_PRESALE * _mintAmount)
            revert InsufficientFundsError();

        addressPresaleMintedBalance[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    /**
     * Free mint for Og, employees, event winners, team members, limited by whitelist and proof
     */
    function privateMint(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    ) public {
        if (paused) revert ContractPausedError();
        if (!isWhitelistedForReservedMint(_merkleProof, _mintAmount))
            revert NotElegibleOrWrongAmountError();
        if (addressReservedMintClaim[msg.sender])
            revert AddressAlreadyClaimedError();

        addressReservedMintClaim[msg.sender] = true;
        reserved_minted += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    /**
     * Caelum mint
     */
    function teamMint(uint256 _mintAmount) public onlyOwner {
        if (paused) revert ContractPausedError();
        uint256 supply = totalSupply();
        if (supply + _mintAmount > maxSupply())
            revert ExceedingMaxSupplyError();

        team_minted += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function isWhitelistedForPresale(
        bytes32[] calldata _merkleProof
    ) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, PresaleMerkleRoot, leaf),
            "Incorrect proof"
        );
        return true;
    }

    function isWhitelistedForReservedMint(
        bytes32[] calldata _merkleProof,
        uint256 _mintAmount
    ) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _mintAmount));
        require(
            MerkleProof.verify(_merkleProof, ReservedMerkleRoot, leaf),
            "Incorrect proof"
        );
        return true;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), "Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "empty";
    }

    function withdraw() external onlyOwner {      
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //Filtering, royalties, OS..
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC2981, ERC721A, IERC721A) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}