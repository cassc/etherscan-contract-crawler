// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "solady/src/utils/ECDSA.sol";
import "solady/src/utils/MerkleProofLib.sol";
import "solady/src/utils/SafeTransferLib.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

//               ..   ..
//             .111   111.
//            .1111   1111.
//           .11111   11111.
//          .111111   111111.
//         .111111.   .111111.
//        .1111111     1111111.
//       .1111111.     .1111111.
//      .11111111       11111111.
//     .11111111.       .11111111.
//    .111111111         111111111.
//   .11111111111111111111111111111.
//  .1111111111111111111111111111111.

//Errors

//Mint
error MaxQuantityAllowedExceeded();
error MaxEntitlementsExceeded();
error MaxSupplyExceeded();
error MintSupplyExceeded();
error ContractIsPaused();
error PriceIncorrect();
error ContractsNotAllowed();
error NonceConsumed();
error HashMismatched();
error MerkleProofInvalid();
error SignedHashMismatched();
error MintIsNotOpen();
error TreasuryNotUnlocked();

//Post-Mint
error DNASequenceHaveBeenInitialised();
error DNASequenceNotSubmitted();
error NotReadyForTransfusion();
error TransfusionSequenceCompleted();

/// @title Arcana Contract
/// @author @whyS0curious
/// @notice Beware! Arcana is only for the dauntless ones.
/// @dev Based off ERC-721A for gas optimised batch mints

contract ArcanaHQ is ERC721AQueryable, ERC721ABurnable, Ownable, OperatorFilterer, ERC2981 {
    using Strings for uint256;
    using ECDSA for *;

    enum Phases {
        CLOSED,
        ARCANA,
        ASPIRANT,
        ALLIANCE,
        PUBLIC
    }

    bool public operatorFilteringEnabled;

    uint256 public constant MAX_ENTITLEMENTS_ALLOWED = 2;
    uint256 public constant MAX_QUANTITY_ALLOWED = 3;
    uint256 public constant MINT_PRICE = 0.1 ether;
    uint256 public constant MAX_SUPPLY = 6000;


    uint256 public mintSupply = 5888;
    uint256 public nextUnlockTs = block.timestamp;
    string public notRevealedUri;
    string public baseTokenURI;
    uint256 public nextStartTime;

    uint8 public currentPhase;
    bool public paused = true;

    bytes32 public arcanaListMerkleRoot;
    bytes32 public aspirantListMerkleRoot;
    bytes32 public allianceListMerkleRoot;

    bool public isTransfused = false;
    uint256 public scheduledTransfusionTime;
    uint256 public sequenceOffset;
    string public dna;

    mapping(bytes32 => bool) public nonceRegistry;

    constructor(string memory _baseURI) ERC721A("ArcanaHQ", "ARCHQ") {
        _registerForOperatorFiltering();
        notRevealedUri = _baseURI;
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 500);
    }

    /*Royalty Enforcement*/
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC721A, ERC2981, ERC721A)
    returns (bool) {
        return (
            ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId)
        );
    }

    function registerCustomBlacklist(address subscriptionOrRegistrantToCopy, bool subscribe) external onlyOwner {
        _registerForOperatorFiltering(subscriptionOrRegistrantToCopy, subscribe);
    }

    function repeatRegistration() external onlyOwner {
        _registerForOperatorFiltering();
    }

    function setApprovalForAll(address operator, bool approved) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) external onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view virtual override returns (bool) {
        return operatorFilteringEnabled;
    }

    /*Pre-mint Configurations*/
    function setArcanaListMerkleRoot(bytes32 _merkleRootHash) external onlyOwner {
        arcanaListMerkleRoot = _merkleRootHash;
    }

    function setAspirantListMerkleRoot(bytes32 _merkleRootHash) external onlyOwner {
        aspirantListMerkleRoot = _merkleRootHash;
    }

    function setAllianceListMerkleRoot(bytes32 _merkleRootHash) external onlyOwner {
        allianceListMerkleRoot = _merkleRootHash;
    }

    function setNotRevealedBaseURI(string memory _baseURI) external onlyOwner {
        notRevealedUri = _baseURI;
    }

    function togglePause(bool _state) external payable onlyOwner {
        paused = _state;
    }

    function setNextStartTime(uint256 _timestamp) external payable onlyOwner {
        nextStartTime = _timestamp;
    }

    function setCurrentPhase(uint256 index) external payable onlyOwner {
        if (index == 0) {
            currentPhase = uint8(Phases.CLOSED);
        }
        if (index == 1) {
            currentPhase = uint8(Phases.ARCANA);
        }
        if (index == 2) {
            currentPhase = uint8(Phases.ASPIRANT);
        }
        if (index == 3) {
            currentPhase = uint8(Phases.ALLIANCE);
        }
        if (index == 4) {
            currentPhase = uint8(Phases.PUBLIC);
        }
    }

    /*Pre-reveal Configurations*/
    function setBaseTokenURI(string memory _baseURI) external onlyOwner {
        baseTokenURI = _baseURI;
    }

    function commitDNASequence(string calldata _dna) external payable onlyOwner {
        if (scheduledTransfusionTime != 0) revert DNASequenceHaveBeenInitialised();

        dna = _dna;
        scheduledTransfusionTime = block.number + 5;
    }

    function transfuse() external payable onlyOwner {
        if (scheduledTransfusionTime == 0) revert DNASequenceNotSubmitted();

        if (block.number < scheduledTransfusionTime) revert NotReadyForTransfusion();

        if (isTransfused) revert TransfusionSequenceCompleted();

        sequenceOffset = (uint256(blockhash(scheduledTransfusionTime)) % MAX_SUPPLY) + 1;

        isTransfused = true;
    }

    function withdrawETH() external payable onlyOwner {
        uint256 balance = address(this).balance;
        SafeTransferLib.forceSafeTransferETH(msg.sender, balance);
    }

    /*Mint*/

    // Community War Chest
    /// @notice Mints part of the supply in the community wallet that Arcana owns. Note: Likely hidden from OpenSea due to Aux.
    /// @dev Only the Owner of the smart contract can call this function
    /// @param _communityWalletPublicKey The address of the community wallet
    function mintWarChestReserve(address _communityWalletPublicKey, uint256 _supply, uint256 _nextUnlockTs)
        external
        payable
        isBelowOrEqualsMaxSupply(_supply)
        isUnlocked()
        onlyOwner
    {
        nextUnlockTs = _nextUnlockTs;
        _mint(_communityWalletPublicKey, _supply);
    }

    // Arcana List Mint
    /// @notice Mint function to invoke for ARCANA LIST PHASE addresses
    /// @dev Checks that enough ETH is paid, quantity to mint results in below max supply, is whitelisted, is not paused and below max quantity allowed per wallet address
    function mintArcanaList(bytes32[] calldata _merkleProof, uint256 _quantity)
        external
        payable
        isBelowOrEqualsMintSupply(_quantity)
        isWhitelisted(_merkleProof, arcanaListMerkleRoot)
        isNotPaused
        isMintOpen(Phases.ARCANA)
    {
        uint256 totalPrice = MINT_PRICE * _quantity;
        if (msg.value != totalPrice) revert PriceIncorrect();

        uint256 entitlements = getTotalEntitlements(msg.sender);
        if (entitlements + _quantity > MAX_ENTITLEMENTS_ALLOWED) revert MaxEntitlementsExceeded();

        _setAux(msg.sender, _getAux(msg.sender) + uint64(_quantity));

        _mint(msg.sender, _quantity);
    }

    // Aspirant List Mint
    /// @notice Mint function to invoke for ASPIRANT LIST PHASE addresses
    /// @dev Checks that enough ETH is paid, quantity to mint results in below max supply, is whitelisted, is not paused and below max quantity allowed per wallet address
    function mintAspirantList(bytes32[] calldata _merkleProof, uint256 _quantity)
        external
        payable
        isBelowOrEqualsMintSupply(_quantity)
        isWhitelisted(_merkleProof, aspirantListMerkleRoot)
        isNotPaused
        isMintOpen(Phases.ASPIRANT)
    {
        uint256 totalPrice = MINT_PRICE * _quantity;
        if (msg.value != totalPrice) revert PriceIncorrect();


        uint256 totalMints = getTotalMints(msg.sender);
        if (totalMints + _quantity > MAX_QUANTITY_ALLOWED) revert MaxQuantityAllowedExceeded();

        _setAux(msg.sender, _getAux(msg.sender) + uint64(_quantity << 2));

        _mint(msg.sender, _quantity);
    }

    // Alliance List Mint
    /// @notice Mint function to invoke for ALLIANCE LIST PHASE addresses
    /// @dev Checks that enough ETH is paid, quantity to mint results in below max supply, is whitelisted, is not paused and below max quantity allowed per wallet address

    function mintAllianceList(bytes32[] calldata _merkleProof, uint256 _quantity)
        external
        payable
        isBelowOrEqualsMintSupply(_quantity)
        isWhitelisted(_merkleProof, allianceListMerkleRoot)
        isNotPaused
        isMintOpen(Phases.ALLIANCE)
    {
        uint256 totalPrice = MINT_PRICE * _quantity;
        if (msg.value != totalPrice) revert PriceIncorrect();

        uint256 totalMints = getTotalMints(msg.sender);
        if (totalMints + _quantity > MAX_QUANTITY_ALLOWED) revert MaxQuantityAllowedExceeded();

        _setAux(msg.sender, _getAux(msg.sender) + uint64(_quantity << 2));

        _mint(msg.sender, _quantity);
    }

    // Public Mint
    /// @notice Mint function to invoke during public phase
    /// @dev Same conditions as whitelist and raffle mints, max 3 per wallet instead of 2, 
    // replay attack is mitigated by checking whether contract is minting and using signed unique nonce generated in the client.
    function mintPublic(uint256 _quantity, bytes32 _nonce, bytes32 _hash, uint8 v, bytes32 r, bytes32 s)
        external
        payable
        isBelowOrEqualsMintSupply(_quantity)
        isNotPaused
        isMintOpen(Phases.PUBLIC)
    {
        if (tx.origin != msg.sender) revert ContractsNotAllowed();

        if (nonceRegistry[_nonce]) revert NonceConsumed();

        if (_hash != keccak256(abi.encodePacked(msg.sender, _quantity, _nonce))) revert HashMismatched();

        if (msg.sender != _hash.toEthSignedMessageHash().recover(v, r, s)) revert SignedHashMismatched();

        nonceRegistry[_nonce] = true;

        uint256 totalPrice = MINT_PRICE * _quantity;
        if (msg.value != totalPrice) revert PriceIncorrect();

        uint256 totalMints = getTotalMints(msg.sender);
        if (totalMints + _quantity > MAX_QUANTITY_ALLOWED) revert MaxQuantityAllowedExceeded();

        _setAux(msg.sender, _getAux(msg.sender) + uint64(_quantity << 2));

        _mint(msg.sender, _quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function numberBurned(address owner) public view returns (uint256) {
        return _numberBurned(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view returns (uint256) { 
        return _totalBurned(); 
    }

    function tokenURI(uint256 _tokenId) public view override(IERC721A, ERC721A) returns (string memory) {
        if (isTransfused) {
            uint256 assignedPFPId = (_tokenId + sequenceOffset) % MAX_SUPPLY;

            return bytes(baseTokenURI).length > 0
                ? string(abi.encodePacked(baseTokenURI, _toString(assignedPFPId), ".json"))
                : "";
        } else {
            return notRevealedUri;
        }
    }

    // Future-proof
    function setMintSupply(uint256 _mintSupply) external onlyOwner isBelowOrEqualsMaxSupply(_mintSupply) {
        mintSupply = _mintSupply;
    }

    /*Utility Methods*/

    function getBits(uint256 _input, uint256 _startBit, uint256 _length) private pure returns (uint256) {
        uint256 bitMask = ((1 << _length) - 1) << _startBit;

        uint256 outBits = _input & bitMask;

        return outBits >> _startBit;
    }

    function getTotalEntitlements(address _minter) public view returns (uint256) {
        return getBits(_getAux(_minter), 0, 2);
    }

    function getTotalMints(address _minter) public view returns (uint256) {
        return getBits(_getAux(_minter), 2, 5);
    }

    /*Modifiers*/

    modifier isUnlocked() {
        if (block.timestamp < nextUnlockTs) revert TreasuryNotUnlocked();
        _;
    }

    modifier isMintOpen(Phases phase) {
        if (uint8(phase) != currentPhase) revert MintIsNotOpen();
        _;
    }

    modifier isNotPaused() {
        if (paused) revert ContractIsPaused();
        _;
    }

    modifier isBelowOrEqualsMaxSupply(uint256 _amount) {
        if ((_totalMinted() + _amount) > MAX_SUPPLY) revert MaxSupplyExceeded();
        _;
    }

    modifier isBelowOrEqualsMintSupply(uint256 _amount) {
        if ((_totalMinted() + _amount) > mintSupply) revert MintSupplyExceeded();
        _;
    }

    /// @notice Verifies whitelist or raffle list
    /// @dev generate proof offchain and invoke mint function with proof as parameter
    modifier isWhitelisted(bytes32[] calldata _merkleProof, bytes32 _merkleRoot) {
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProofLib.verify(_merkleProof, _merkleRoot, node)) {
            revert MerkleProofInvalid();
        }
        _;
    }
}