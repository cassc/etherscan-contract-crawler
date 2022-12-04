// SPDX-License-Identifier: MIT
// Creator: lohko.io

pragma solidity >=0.8.17;

import {ERC721A} from "ERC721A.sol";
import {Ownable} from "Ownable.sol";
import {Strings} from "Strings.sol";
import {PaymentSplitter} from "PaymentSplitter.sol";
import {MerkleProof} from "MerkleProof.sol";

error SaleNotStarted();
error InvalidProof();
error MaxAlreadyClaimed();
error MaxSupplyReached();
error InsufficientFunds();
error NonExistentTokenURI();

contract Netrunners is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 5000;

    uint256 public constant WHITELIST_PRICE = 0.02 ether;
    uint256 public constant PRICE = 0.025 ether;

    uint256 public constant MAX_CLAIMED_RUNNERS = 3;

    string public UNREVEALED_URI;
    string public BASE_URI;

    uint256 public earlySaleStart;
    uint256 public publicSaleStart;

    bool public revealed;

    bytes32 public merkleRoot;

    constructor(
        string memory _unrevealedUri,
        address[] memory payees_,
        uint256[] memory shares_
    ) ERC721A("NETRUNNERS", "NETRUNNERS") PaymentSplitter(payees_, shares_) {
        UNREVEALED_URI = _unrevealedUri;
        _mint(msg.sender, 1);
    }

    // ========== Minting functions ==========

    function earlyMint(bytes32[] memory proof) external payable {
        // If early minting has not yet begun, revert.
        if (block.timestamp < earlySaleStart) revert SaleNotStarted();

        // If the user's proof is invalid with the sent ether value, revert.
        if (!(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender, msg.value))))) revert InvalidProof();
        
        // If the MAX_SUPPLY is reached, revert.
        if (_totalMinted() + 1 > MAX_SUPPLY) revert MaxSupplyReached();

        // If the user has claimed all their runners, revert.
        if (_numberMinted(msg.sender) + 1 > MAX_CLAIMED_RUNNERS) revert MaxAlreadyClaimed();

        _mint(msg.sender, 1);
    }

    function publicMint() external payable {
        // If early minting has not yet begun, revert.
        if (block.timestamp < publicSaleStart) revert SaleNotStarted();

        // If the MAX_SUPPLY is reached, revert.
        if (_totalMinted() + 1 > MAX_SUPPLY) revert MaxSupplyReached();

        // If incorrect ether amount is sent, revert.
        if (msg.value != PRICE) revert InsufficientFunds();

        // If the user has claimed all their runners, revert.
        if (_numberMinted(msg.sender) + 1 > MAX_CLAIMED_RUNNERS) revert MaxAlreadyClaimed();

        _mint(msg.sender, 1);
    }

    // ========== Frontend helpers ==========

    function isEarlySaleOpen() public view returns(bool) {
        if (block.timestamp < earlySaleStart) {
            return false;
        }
        return true;
    }

    function isPublicSaleOpen() public view returns(bool) {
        if (block.timestamp < publicSaleStart) {
            return false;
        }
        return true;
    }

    // ========== Admin functions ==========

    function setSaleTimestamps(uint32 _earlyStart, uint32 _publicStart) external onlyOwner {
        earlySaleStart = _earlyStart;
        publicSaleStart = _publicStart;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setUnrevealedURI(string memory _UnrevealedURI) public onlyOwner {
        UNREVEALED_URI = _UnrevealedURI;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        BASE_URI = _baseURI;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    // ========== Get info ==========

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

    // ========== Overrides ==========

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
        if (!revealed) return UNREVEALED_URI;
        string memory baseURI = BASE_URI;
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        return 
            ERC721A.supportsInterface(interfaceId);
    }
}