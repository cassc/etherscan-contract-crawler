// SPDX-License-Identifier: MIT
// Creator: lohko.io

pragma solidity >=0.8.13;

import {ERC721AQueryable, ERC721A, IERC721Metadata, IERC165} from "ERC721AQueryable.sol";
import {ERC2981} from "ERC2981.sol";
import {Ownable} from "Ownable.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {PaymentSplitter} from "PaymentSplitter.sol";
import {MerkleProof} from "MerkleProof.sol";
import {IVivityCitizens} from "IVivityCitizens.sol";

error SaleNotStarted();
error NotOnReservedList();
error AlreadyClaimed();
error QuantityOffLimits();
error MaxSupplyReached();
error InsufficientFunds();
error InvalidInput();
error ClaimingNotStarted();
error NotYourToken();
error ContractsNotAllowed();

contract Vivity is Ownable, ERC721AQueryable, ERC2981, ReentrancyGuard, PaymentSplitter {

    uint256 public constant maxSupply = 5000;
    uint256 public constant reserveSupply = 4200;

    uint256 public constant reserveMaxTokensPerTx = 2;
    uint256 public constant maxTokensPerTx = 3;

    uint256 public constant reserveMaxTokensPerWallet = 2;

    uint256 public constant reservePrice = 0.018 ether;
    uint256 public constant price = 0.022 ether;

    uint256 public constant maxClaimLength = 10;

    uint256 public reserveSaleStart;
    uint256 public reserveSaleEnd;

    bool public claimingStarted;

    bytes32 public merkleRoot;

    string private _baseTokenURI;

    IVivityCitizens public vivityCitizens;

    constructor(
        string memory _URI,
        address[] memory payees_,
        uint256[] memory shares_,
        address _vivityCitizens
    ) ERC721A("Vivity", "Vivity") PaymentSplitter(payees_, shares_) {
        _mint(msg.sender, 1);
        _baseTokenURI = _URI;
        vivityCitizens = IVivityCitizens(_vivityCitizens);
    }

    // ========== Minting ==========

    function mintVivityReserve(uint256 quantity, bytes32[] memory proof) external payable {
        // Validation
        if (tx.origin != msg.sender) revert ContractsNotAllowed();
        if (block.timestamp < reserveSaleStart || block.timestamp > reserveSaleEnd) revert SaleNotStarted();
        if (!(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))))) revert NotOnReservedList();
        // (maxSupply - reserveSupply) reserved for partnerships
        if (_totalMinted() + quantity > reserveSupply) revert MaxSupplyReached();
        if (msg.value != reservePrice*quantity) revert InsufficientFunds();
        if (quantity == 0 || quantity > reserveMaxTokensPerTx) revert QuantityOffLimits();

        uint64 _mintSlotsUsed = _getAux(msg.sender) + uint64(quantity);
        if (_mintSlotsUsed > reserveMaxTokensPerWallet) revert AlreadyClaimed();

        // State changes
        _setAux(msg.sender, _mintSlotsUsed);

        // Interactions
        _mint(msg.sender, quantity);
    }

    function mintVivityPublic(uint256 quantity) external payable {
        // Validation
        if (tx.origin != msg.sender) revert ContractsNotAllowed();
        if (block.timestamp < reserveSaleEnd) revert SaleNotStarted();
        if (msg.value != price*quantity) revert InsufficientFunds();
        if (quantity == 0 || quantity > maxTokensPerTx) revert QuantityOffLimits();
        // (maxSupply - reserveSupply) reserved for partnerships
        if (_totalMinted() + quantity > reserveSupply) revert MaxSupplyReached();
        // Interactions
        _mint(msg.sender, quantity);
    }

    // ========== Claiming ==========

    function claimCitizenship(uint256[] calldata tokenIds) external nonReentrant {
        if(msg.sender != owner()) {
            if(!claimingStarted) revert ClaimingNotStarted();
        }
        if(tokenIds.length > maxClaimLength) revert InvalidInput();
        address _owner;
        for (uint256 i; i < tokenIds.length; ) {

            _owner = ownerOf(tokenIds[i]);
            if(msg.sender != _owner) revert NotYourToken();

            _burn(tokenIds[i], true);
            vivityCitizens.claimCitizenship(_owner, tokenIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    // ========== Frontend helpers ==========

    function isSaleOpen() public view returns(bool) {
        if (block.timestamp < reserveSaleStart) {
            return false;
        }
        return true;
    }

    function isReserveSaleOver() public view returns(bool) {
        if (block.timestamp < reserveSaleEnd) {
            return false;
        }
        return true;
    }

    function isClaimed(address user) public view returns(uint256) {
        return _getAux(user);
    }

    // ========== Admins ==========

    function partnershipTribute(address[] calldata receivers, uint256[] calldata amounts) external onlyOwner {
        if (receivers.length != amounts.length || receivers.length == 0) revert InvalidInput();
        for (uint256 i; i < receivers.length; ) {
            if (_totalMinted() + amounts[i] > maxSupply) revert MaxSupplyReached();
            _mint(receivers[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function toggleClaiming() external onlyOwner {
        claimingStarted = !claimingStarted;
    }

    function setVivityCitizens(address _vivityCitizens) external onlyOwner {
        vivityCitizens = IVivityCitizens(_vivityCitizens);
    }

    function setReserveSaleTimestamps(uint32 _start, uint32 _end) external onlyOwner {
        reserveSaleStart = _start;
        reserveSaleEnd = _end;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    // ========== Get info ==========

    function mintedByAddr(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function claimedByAddr(address owner) external view returns (uint256) {
        return _numberBurned(owner);
    }


    function totalClaimed() external view virtual returns (uint256) {
        return _totalMinted() - totalSupply();
    }

    function totalMinted() external view virtual returns (uint256) {
        return _totalMinted();
    }

    // ========== Backup ==========

    function claimCitizenshipBackup(uint256[] calldata tokenIds, uint256[] calldata citizenIds) external onlyOwner nonReentrant {
        // Set arbitrary vivity citizen id's for vivity token id's in case of shuffling failure
        // Can be only used for unclaimed vivity tokens
        if (tokenIds.length != citizenIds.length || tokenIds.length == 0) revert InvalidInput();
        address _owner;
        for (uint256 i; i < tokenIds.length; ) {
            _owner = ownerOf(tokenIds[i]);
            _burn(tokenIds[i], true);
            vivityCitizens.claimCitizenshipBackup(_owner, citizenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    // ========== Overrides ==========

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721Metadata) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return _baseURI();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981, IERC165) returns (bool) {
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