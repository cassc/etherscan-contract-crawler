// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC721A, ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {OperatorFilterer} from "./OperatorFilterer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// dev
error InvalidPhase();
error AddressCannotBeZero();
error ETHTransferFail();
// mint
error ExceedsMaxSupply();
error ExceedsMintSupply();
error ExceedsMaxPerWallet();
error AlreadyMintedKandylist();
error MintIsNotOpen();
error CallerIsAContract();
error IncorrectETHSent();
error Unauthorized();

/// @title Kandyland NFT Contract
/// @author @kangadev
/// @dev Based off ERC-721A for gas optimised batch mints

contract Kandyland is
    ERC721AQueryable,
    OperatorFilterer,
    ReentrancyGuard,
    Ownable,
    ERC2981
{
    using ECDSA for bytes32;

    enum Phases {
        CLOSED,
        KANDYLIST,
        WAITLIST,
        PUBLIC,
        COMPLETE
    }

    // Mint Information
    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant MAX_PER_WALLET = 2;
    uint256 public MINT_PRICE = 0.11 ether;
    uint256 public MINT_SUPPLY = 7777;
    uint8 public currentPhase;
    
    bytes32 private kandylistMerkleRoot;
    address private waitlistSigner;

    // General
    address payable public ownerFund;
    string private _baseTokenURI;
    bool public operatorFilteringEnabled;

    // Events
    event UpdateBaseURI(string baseURI);
    event UpdateMintPrice(uint256 _price);
    event UpdateSalePhase(uint256 index);
    event UpdateOwnerFund(address _ownerFund);

    constructor() ERC721A("Kandyland", "KLAND") {
        ownerFund = payable(msg.sender);
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 500);
    }

    //===============================================================
    //                    Modifiers
    //===============================================================
    
    /// @notice Checks that the user sent the correct amount of ETH.
    modifier isCorrectEth(uint256 _quantity) {
        if (msg.value != MINT_PRICE * _quantity) revert IncorrectETHSent();
        _;
    }

    /// @notice Checks that the quantity to mint does not exceed the max quantity per wallet.
    modifier isBelowOrEqualsMaxPerWallet(uint256 _quantity) {
        if(_numberMinted(msg.sender) + _quantity > MAX_PER_WALLET) revert ExceedsMaxPerWallet();
        _;
    }

    /// @notice Checks that a user has not already minted kandylist.
    modifier hasNotMintedKandylist() {
        if (_numberMinted(msg.sender) != 0) revert AlreadyMintedKandylist();
        _;
    }

    /// @notice Checks that the quantity to mint does not exceed the max supply.
    modifier isBelowOrEqualsMaxSupply(uint256 _quantity) {
        if ((_totalMinted() + _quantity) > MAX_SUPPLY) revert ExceedsMaxSupply();
        _;
    }

    /// @notice Checks that the quantity to mint does not exceed the mint supply.
    modifier isBelowOrEqualsMintSupply(uint256 _quantity) {
        if ((_totalMinted() + _quantity) > MINT_SUPPLY) revert ExceedsMintSupply();
        _;
    }

    /// @notice Checks that the mint phase is open.
    modifier isMintOpen(Phases phase) {
        if (uint8(phase) != currentPhase) revert MintIsNotOpen();
        _;
    }

    /// @notice Verifies whether a user is kandylisted or waitlisted.
    /// @dev Generate proof offchain and invoke mint function with proof as parameter.
    modifier isAllowlisted(bytes32[] calldata _merkleProof, bytes32 _merkleRoot) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verifyCalldata(_merkleProof, _merkleRoot, leaf)) {
            revert Unauthorized();
        }
        _;
    }

    /// @notice Verifies whether a user is kandylisted or waitlisted.
    /// @dev Generate signature offchain and invoke mint function with signature as parameter.
    modifier isWaitlisted(bytes calldata _signature) {
        address _signer = keccak256(abi.encodePacked(msg.sender)).toEthSignedMessageHash().recover(_signature);
        if(_signer != waitlistSigner) {
            revert Unauthorized();
        }
        _;
    }

    //===============================================================
    //                    Minting Functions
    //===============================================================

    /// @notice This function allows kandylisted users to mint during the KANDYLIST phase.
    function kandylistMint(bytes32[] calldata _merkleProof, uint256 _quantity)
        external
        payable
        nonReentrant
        isMintOpen(Phases.KANDYLIST)
        isAllowlisted(_merkleProof, kandylistMerkleRoot)
        isCorrectEth(_quantity)
        isBelowOrEqualsMintSupply(_quantity)
        isBelowOrEqualsMaxPerWallet(_quantity)
        hasNotMintedKandylist()
    {
        _mint(msg.sender, _quantity);
    }

    /// @notice This function allows waitlisted users to mint during the WAITLIST phase.
    function waitlistMint(bytes calldata _signature, uint256 _quantity)
        external
        payable
        nonReentrant
        isMintOpen(Phases.WAITLIST)
        isWaitlisted(_signature)
        isCorrectEth(_quantity)
        isBelowOrEqualsMintSupply(_quantity)
        isBelowOrEqualsMaxPerWallet(_quantity)
    {
        _mint(msg.sender, _quantity);
    }

    /// @notice This function allows users to mint during the PUBLIC phase.
    function publicMint(uint256 _quantity)
        external
        payable
        nonReentrant
        isMintOpen(Phases.PUBLIC)
        isCorrectEth(_quantity)
        isBelowOrEqualsMintSupply(_quantity)
        isBelowOrEqualsMaxPerWallet(_quantity)
    {
        _mint(msg.sender, _quantity);
    }

    /// @notice This function allows the owner to mint reserved NFTs.
    function ownerMint(address _to, uint256 _quantity) 
        external
        onlyOwner
        isBelowOrEqualsMaxSupply(_quantity)  
    {
        _mint(_to, _quantity);
    }

    //===============================================================
    //                    Setter Functions
    //===============================================================

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
        emit UpdateBaseURI(baseURI);
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        MINT_PRICE = _price;
        emit UpdateMintPrice(_price);
    }

    function setKandylistMerkleRoot(bytes32 _merkleRootHash) external onlyOwner {
        kandylistMerkleRoot = _merkleRootHash;
    }

    function setWaitlistSigner(address _signer) external onlyOwner {
        waitlistSigner = _signer;
    }

    function setCurrentPhase(uint256 index) external onlyOwner {
        if (index == 0) {
            currentPhase = uint8(Phases.CLOSED);
        } else if (index == 1) {
            currentPhase = uint8(Phases.KANDYLIST);
        } else if (index == 2) {
            currentPhase = uint8(Phases.WAITLIST);
        } else if (index == 3) {
            currentPhase = uint8(Phases.PUBLIC);
        } else if (index == 4) {
            currentPhase = uint8(Phases.COMPLETE);
        } else {
            revert InvalidPhase();
        }
        emit UpdateSalePhase(index);
    }

    function setMintSupply(uint256 _mintSupply) 
        external 
        onlyOwner 
        isBelowOrEqualsMaxSupply(_mintSupply) 
    {
        MINT_SUPPLY = _mintSupply;
    }

    function setOwnerFund(address _ownerFund) external onlyOwner {
        if (address(_ownerFund) == address(0)) revert AddressCannotBeZero();
        ownerFund = payable(_ownerFund);
        emit UpdateOwnerFund(_ownerFund);
    }

    //===============================================================
    //                    Getter Functions
    //===============================================================

    function getNumberMinted(address _address) external view returns (uint256) {
        return _numberMinted(_address);
    }

    //===============================================================
    //                    ETH Withdrawal
    //===============================================================

    function withdraw() external onlyOwner nonReentrant {
        uint256 currentBalance = address(this).balance;
        (bool success, ) = payable(ownerFund).call{value: currentBalance}("");
        if (!success) revert ETHTransferFail();
    }

    //===============================================================
    //                      Token Data
    //===============================================================

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //===============================================================
    //                    Royalty Enforcement
    //===============================================================

    function setApprovalForAll(address operator, bool approved) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    //===============================================================
    //                    SupportsInterface
    //===============================================================

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
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