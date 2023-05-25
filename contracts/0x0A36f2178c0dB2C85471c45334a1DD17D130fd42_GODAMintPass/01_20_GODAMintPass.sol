// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import './lib/MerkleDistributor.sol';

contract GODAMintPass is
    ERC721Enumerable,
    ERC2981,
    MerkleDistributor,
    ReentrancyGuard,
    AccessControl,
    Ownable
{
    bytes32 public constant SUPPORT_ROLE = keccak256('SUPPORT');
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant MAX_ALLOWLIST_MINT = 1;
    uint256 public constant MAX_PUBLIC_MINT = 1;
    uint256 public constant MAX_RESERVE_SUPPLY = 110;
    uint256 public constant PRICE_PER_TOKEN = 1 ether;

    string public provenance;
    string private _baseURIextended;
    bool public saleActive;
    uint256 public reserveSupply;

    address payable public immutable shareholderAddress;

    constructor(address payable shareholderAddress_) ERC721("GODA Mint Pass", "GODA") {
        require(shareholderAddress_ != address(0));

        // set immutable variables
        shareholderAddress = shareholderAddress_;

        // setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SUPPORT_ROLE, msg.sender);
    }

    /**
     * @dev checks to see if amount of tokens to be minted would exceed the maximum supply allowed
     */
    modifier supplyAvailable(uint256 numberOfTokens) {
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, 'Purchase would exceed max tokens');
        _;
    }

    /**
     * @dev checks to see whether saleActive is true
     */
    modifier isPublicSaleActive() {
        require(saleActive, 'Public sale is not active');
        _;
    }

    ////////////////
    // admin
    ////////////////
    /**
     * @dev reserves a number of tokens
     */
    function devMint(uint256 numberOfTokens)
        external
        onlyRole(SUPPORT_ROLE)
        supplyAvailable(numberOfTokens)
        nonReentrant
    {
        require(reserveSupply + numberOfTokens <= MAX_RESERVE_SUPPLY, 'Number would exceed max reserve supply');
        uint256 ts = totalSupply();

        reserveSupply += numberOfTokens;
        for (uint256 index = 0; index < numberOfTokens; index++) {
            _safeMint(msg.sender, ts + index);
        }
    }

    /**
     * @dev allows public sale minting
     */
    function setSaleActive(bool state) external onlyRole(SUPPORT_ROLE) {
        saleActive = state;
    }

    ////////////////
    // allow list
    ////////////////
    /**
     * @dev allows minting from a list of clients
     */
    function setAllowListActive(bool allowListActive) external onlyRole(SUPPORT_ROLE) {
        _setAllowListActive(allowListActive);
    }

    /**
     * @dev sets the merkle root for the allow list
     */
    function setAllowList(bytes32 merkleRoot) external onlyRole(SUPPORT_ROLE) {
        _setAllowList(merkleRoot);
    }

    ////////////////
    // tokens
    ////////////////
    /**
     * @dev sets the base uri for {_baseURI}
     */
    function setBaseURI(string memory baseURI_) external onlyRole(SUPPORT_ROLE) {
        _baseURIextended = baseURI_;
    }

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * @dev sets the provenance hash
     */
    function setProvenance(string memory provenance_) external onlyRole(SUPPORT_ROLE) {
        provenance = provenance_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    ////////////////
    // public
    ////////////////
    /**
     * @dev allow minting if the msg.sender is on the allow list
     */
    function mintAllowList(uint256 numberOfTokens, bytes32[] memory merkleProof)
        external
        payable
        isAllowListActive
        ableToClaim(msg.sender, merkleProof)
        tokensAvailable(msg.sender, numberOfTokens, MAX_ALLOWLIST_MINT)
        supplyAvailable(numberOfTokens)
        nonReentrant
    {
        require(numberOfTokens * PRICE_PER_TOKEN == msg.value, 'Ether value sent is not correct');
        uint256 ts = totalSupply();

        _setAllowListMinted(msg.sender, numberOfTokens);
        for (uint256 index = 0; index < numberOfTokens; index++) {
            _safeMint(msg.sender, ts + index);
        }
    }

    /**
     * @dev allow public minting
     */
    function mint(uint256 numberOfTokens)
        external
        payable
        isPublicSaleActive
        supplyAvailable(numberOfTokens)
        nonReentrant
    {
        require(numberOfTokens <= MAX_PUBLIC_MINT, 'Exceeded max token purchase');
        require(numberOfTokens * PRICE_PER_TOKEN == msg.value, 'Ether value sent is not correct');
        uint256 ts = totalSupply();

        for (uint256 index = 0; index < numberOfTokens; index++) {
            _safeMint(msg.sender, ts + index);
        }
    }

    ////////////////
    // royalty
    ////////////////
    /**
     * @dev See {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(SUPPORT_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty() external onlyRole(SUPPORT_ROLE) {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev See {ERC2981-_setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(SUPPORT_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_resetTokenRoyalty}.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyRole(SUPPORT_ROLE) {
        _resetTokenRoyalty(tokenId);
    }

    ////////////////
    // withdraw
    ////////////////
    /**
     * @dev withdraws ether from the contract to the shareholder address
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = shareholderAddress.call{value: address(this).balance}('');
        require(success, 'Transfer failed.');
    }
}