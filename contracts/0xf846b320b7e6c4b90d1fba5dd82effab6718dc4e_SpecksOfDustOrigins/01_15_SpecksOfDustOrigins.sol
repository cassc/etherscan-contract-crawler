// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import 'erc721a/contracts/ERC721A.sol';
import './lib/MerkleDistributor.sol';

contract SpecksOfDustOrigins is ERC721A, MerkleDistributor, ReentrancyGuard, AccessControl {
    bytes32 public constant SUPPORT_ROLE = keccak256('SUPPORT');
    uint256 public constant MAX_SUPPLY = 350;
    uint256 public constant MAX_ALLOWLIST_MINT = 1;
    uint256 public constant MAX_PUBLIC_MINT = 1;
    uint256 public constant MAX_RESERVE_SUPPLY = 50;
    uint256 public constant PRICE_PER_TOKEN = 0.15 ether;

    string public provenance;
    string private _baseURIextended;
    bool public saleActive;
    uint256 public reserveSupply;

    address payable public immutable shareholderAddress;

    constructor(address payable shareholderAddress_) ERC721A("Specks of Dust Origins", "SPECKSORIGINS") {
        require(shareholderAddress_ != address(0));

        // set immutable variables
        shareholderAddress = shareholderAddress_;

        // setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SUPPORT_ROLE, msg.sender);
    }

    modifier ableToMint(uint256 numberOfTokens) {
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, 'Purchase would exceed max tokens');
        _;
    }

    modifier isPublicSaleActive() {
        require(saleActive, 'Public sale is not active');
        _;
    }

    /**
     * admin
     */
    function devMint(uint256 numberOfTokens) external onlyRole(SUPPORT_ROLE) ableToMint(numberOfTokens) nonReentrant {
        require(reserveSupply + numberOfTokens <= MAX_RESERVE_SUPPLY, 'Number would exceed max reserve supply');

        reserveSupply += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function setSaleActive(bool state) external onlyRole(SUPPORT_ROLE) {
        saleActive = state;
    }

    /**
     * allow list
     */
    function setAllowListActive(bool allowListActive) external onlyRole(SUPPORT_ROLE) {
        _setAllowListActive(allowListActive);
    }

    function setAllowList(bytes32 merkleRoot) external onlyRole(SUPPORT_ROLE) {
        _setAllowList(merkleRoot);
    }

    /**
     * tokens
     */
    function setBaseURI(string memory baseURI_) external onlyRole(SUPPORT_ROLE) {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance_) external onlyRole(SUPPORT_ROLE) {
        provenance = provenance_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * public
     */
    function mintAllowList(uint256 numberOfTokens, bytes32[] memory merkleProof)
        external
        payable
        isAllowListActive
        ableToClaim(msg.sender, merkleProof)
        tokensAvailable(msg.sender, numberOfTokens, MAX_ALLOWLIST_MINT)
        ableToMint(numberOfTokens)
        nonReentrant
    {
        require(numberOfTokens * PRICE_PER_TOKEN == msg.value, 'Ether value sent is not correct');

        _setAllowListMinted(msg.sender, numberOfTokens);
        _safeMint(msg.sender, numberOfTokens);
    }

    function mint(uint256 numberOfTokens) external payable isPublicSaleActive ableToMint(numberOfTokens) nonReentrant {
        require(numberOfTokens <= MAX_PUBLIC_MINT, 'Exceeded max token purchase');
        require(numberOfTokens * PRICE_PER_TOKEN == msg.value, 'Ether value sent is not correct');

        _safeMint(msg.sender, numberOfTokens);
    }

    /**
     * withdraw
     */
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        (bool success, ) = shareholderAddress.call{value: address(this).balance}('');
        require(success, 'Transfer failed.');
    }
}