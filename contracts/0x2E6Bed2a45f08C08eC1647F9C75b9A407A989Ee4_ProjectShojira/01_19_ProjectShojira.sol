// SPDX-License-Identifier: MIT
// Creator: lohko.io

pragma solidity >=0.8.13;

import {ERC721A} from "ERC721A.sol";
import {ERC2981} from "ERC2981.sol";
import {Ownable} from "Ownable.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {Strings} from "Strings.sol";
import {PaymentSplitter} from "PaymentSplitter.sol";
import {MerkleProof} from "MerkleProof.sol";

error SaleNotStarted();
error NotOnCursedList();
error AlreadyCursed();
error QuantityOffLimits();
error MaxSupplyReached();
error InsufficientFunds();
error ContractsNotAllowed();
error InvalidInput();
error NonExistentTokenURI();

contract ProjectShojira is Ownable, ERC721A, ERC2981, ReentrancyGuard, PaymentSplitter {
    using Strings for uint256;

    uint256 public constant cursedSupply = 2222;

    uint256 public constant maxTokensPerTx = 4;
    uint256 public constant maxCursedTokensPerTx = 2;

    uint256 public constant maxCursedTokensPerWallet = 2;

    uint256 public constant cursedPrice = 0.028 ether;
    uint256 public constant price = 0.033 ether;

    uint256 public cursedSaleStart;
    uint256 public cursedSaleEnd;
    uint256 public publicSaleEnd;

    bool public revealed;

    bytes32 public merkleRoot;

    string private _baseTokenURI;
    string private notRevealedUri;

    constructor(
        string memory _initNotRevealedUri,
        address[] memory payees_,
        uint256[] memory shares_
    ) ERC721A("Project Shojira", "SHOJ") PaymentSplitter(payees_, shares_) {
        _mint(msg.sender, 1);
        notRevealedUri = _initNotRevealedUri;
    }

    // <><><><><><> Minting functions <><><><><><>

    function cursedMint(uint256 quantity, bytes32[] memory proof) external payable {
        // Validation
        if (tx.origin != msg.sender) revert ContractsNotAllowed();
        if (block.timestamp < cursedSaleStart || block.timestamp > cursedSaleEnd) revert SaleNotStarted();
        if (!(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))))) revert NotOnCursedList();
        if (_totalMinted() + quantity > cursedSupply) revert MaxSupplyReached();
        if (msg.value != cursedPrice*quantity) revert InsufficientFunds();
        if (quantity == 0 || quantity > maxCursedTokensPerTx) revert QuantityOffLimits();

        uint64 _mintSlotsUsed = _getAux(msg.sender) + uint64(quantity);
        if (_mintSlotsUsed > maxCursedTokensPerWallet) revert AlreadyCursed();

        // State changes
        _setAux(msg.sender, _mintSlotsUsed);

        _mint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable {
        if (tx.origin != msg.sender) revert ContractsNotAllowed();
        if (block.timestamp < cursedSaleEnd || block.timestamp > publicSaleEnd) revert SaleNotStarted();
        if (msg.value != price*quantity) revert InsufficientFunds();
        if (quantity == 0 || quantity > maxTokensPerTx) revert QuantityOffLimits();
        if (_totalMinted() + quantity > cursedSupply) revert MaxSupplyReached();

        _mint(msg.sender, quantity);
    }


    // <><><><><><> Frontend helpers <><><><><><>

    function isCursedSaleOpen() public view returns(bool) {
        if (block.timestamp < cursedSaleStart) {
            return false;
        }
        return true;
    }

    function isCursedSaleOver() public view returns(bool) {
        if (block.timestamp < cursedSaleEnd) {
            return false;
        }
        return true;
    }

    function isCursed(address user) public view returns(uint256) {
        return _getAux(user);
    }

    // <><><><><><> Admin functions <><><><><><>

    function contributionReward(address[] calldata receivers, uint256[] calldata amounts) external onlyOwner {
        if (receivers.length != amounts.length || receivers.length == 0) revert InvalidInput();
        for (uint256 i; i < receivers.length; ) {
            _mint(receivers[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function setCursedSaleTimestamps(uint32 _startCursed, uint32 _endCursed, uint32 _endPublic) external onlyOwner {
        cursedSaleStart = _startCursed;
        cursedSaleEnd = _endCursed;
        publicSaleEnd = _endPublic;
    }

    function setPublicSaleEnd(uint256 _timestamp) external onlyOwner {
        publicSaleEnd = _timestamp;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    // <><><><><><> Get info <><><><><><>

    function mintedByAddr(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function burnedByAddr(address owner) external view returns (uint256) {
        return _numberBurned(owner);
    }

    function totalBurned() external view virtual returns (uint256) {
        return _totalMinted() - totalSupply();
    }

    function totalMinted() external view virtual returns (uint256) {
        return _totalMinted();
    }

    // <><><><><><> Overrides <><><><><><>

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert NonExistentTokenURI();
        if (revealed == false) {
            return notRevealedUri;
        }
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
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