//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; 

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import {RevokableOperatorFilterer} from "./RevokableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "./RevokableDefaultOperatorFilterer.sol";

contract EZSwapPioneer is ERC721, RevokableDefaultOperatorFilterer, ReentrancyGuard, Ownable, Pausable {

    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    uint256 public constant MAX_SUPPLY = 333;
    Counters.Counter private _tokenIds;

    mapping(address => bool) public isMinted;
    address public signer;
    string public baseURI;

    constructor(string memory baseURI_) ERC721("EZSwapPioneer", "EZP") {
        baseURI = baseURI_;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function mintedIds() public view returns (uint256) {
        return _tokenIds.current();
    }

    function setSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    } 

    function hashTransaction (address sender, address address_) internal pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, address_))
        ));
         return hash;
    }

    function isWhitelistAddress(bytes memory signature) internal view returns (bool) {
        bytes32 msgHash = hashTransaction(msg.sender, address(this));
        return msgHash.recover(signature) == signer;
    }

    function mint(bytes memory signature) public nonReentrant whenNotPaused {
        require(_tokenIds.current() < MAX_SUPPLY, "mint would exceed max supply");
        require(!isMinted[msg.sender],"already minted");
        require(isWhitelistAddress(signature), "caller is not in whitelist");

        _tokenIds.increment();
        isMinted[msg.sender] = true;
        _safeMint(msg.sender, _tokenIds.current());
    }

    function batchMint() external onlyOwner nonReentrant {
        while (_tokenIds.current() < MAX_SUPPLY) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner() public view virtual override (Ownable, RevokableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }
    ///////////////////////////////////////////////////////////////////////////
}