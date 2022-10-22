// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './ERC721A.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

/**
 * @title Pocket Coven Contract
 * @author ilikecalculus (https://twitter.com/i_like_calculus)
 */
contract PocketCoven is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string public baseTokenURI;
    string public defaultTokenURI;
    uint256 public maxSupply;
    uint8 public maxMintsPerAddress;

    bool public isCompleted;
    bool public isRevealed;
    bool public isSaleActive;
    bool public isPresaleActive;
    bool public isOpenSeaProxyActive;

    bytes32 witchListMerkleRoot;

    // Constants
    uint256 public constant mintPrice = 0.025 ether;
    address public constant openSeaProxyRegistryAddress =
        0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    modifier notCompleted() {
        require(
            !isCompleted,
            'Collection is completed, cannot make changes anymore.'
        );
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'The caller must be a user.');
        _;
    }

    modifier isInStock(uint8 quantity) {
        require(
            _currentIndex + quantity <= maxSupply + 1, // tokenId starts at 1
            'Pocket Coven is out of stock.'
        );
        _;
    }

    modifier isWithinMaxMints(uint8 quantity) {
        require(
            _numberMinted(msg.sender) + quantity <= maxMintsPerAddress,
            'This wallet has reached the maximum allowed number of mints.'
        );
        _;
    }

    modifier isWithinMaxMintsPerTxn(uint8 quantity) {
        require(
            quantity <= maxMintsPerAddress,
            'The quantity exceeds the maximum tokens allowed per transaction.'
        );
        _;
    }

    modifier isPaymentAmountValid(uint8 quantity) {
        require(msg.value == quantity * mintPrice, 'Incorrect payment amount.');
        _;
    }

    modifier isValidMerkleProof(bytes32 root, bytes32[] calldata proof) {
        require(
            MerkleProof.verify(
                proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            'Address is not on the witch list.'
        );
        _;
    }

    /**
     * @notice Constructor for Pocket Coven
     * @param name Token name
     * @param symbol Token symbol
     * @param baseTokenURI_ Base URI for completed tokens
     * @param defaultTokenURI_ URI for tokens that aren't completed, unrevealed if you will
     * @param maxSupply_ Max Supply of tokens
     * @param maxMintsPerAddress_ Max mints an address is allowed
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI_,
        string memory defaultTokenURI_,
        uint256 maxSupply_,
        uint8 maxMintsPerAddress_
    ) ERC721A(name, symbol) {
        require(maxSupply_ > 0, 'INVALID_SUPPLY');
        baseTokenURI = baseTokenURI_;
        defaultTokenURI = defaultTokenURI_;
        maxSupply = maxSupply_;
        maxMintsPerAddress = maxMintsPerAddress_;
        isOpenSeaProxyActive = true;
    }

    // ==================
    // Internal functions
    // ==================

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _defaultURI() internal view returns (string memory) {
        return defaultTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // =====================
    // Public read functions
    // =====================

    function tokensMintedByAddress(address ad) public view returns (uint256) {
        return _numberMinted(ad);
    }

    function getMerkleRoot() public view returns (bytes32) {
        return witchListMerkleRoot;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), 'URI query for nonexistent token.');

        if (isRevealed) {
            return
                string(
                    abi.encodePacked(_baseURI(), tokenId.toString(), '.json')
                );
        } else {
            return string(abi.encodePacked(_defaultURI()));
        }
    }

    function isCollectionComplete() public view returns (bool) {
        return isCompleted;
    }

    // ==============
    // Mint functions
    // ==============

    function mint(uint8 quantity)
        external
        payable
        callerIsUser
        isWithinMaxMintsPerTxn(quantity)
        isPaymentAmountValid(quantity)
        isInStock(quantity)
        nonReentrant
    {
        require(isSaleActive, 'Public sale is not active.');
        _safeMint(msg.sender, quantity);
    }

    function witchListMint(bytes32[] calldata merkleProof, uint8 quantity)
        external
        payable
        callerIsUser
        isWithinMaxMints(quantity)
        isPaymentAmountValid(quantity)
        isInStock(quantity)
        isValidMerkleProof(witchListMerkleRoot, merkleProof)
        nonReentrant
    {
        require(isPresaleActive, 'Witch list sale is not active.');
        _safeMint(msg.sender, quantity);
    }

    function ownerMint(uint8 quantity)
        external
        onlyOwner
        callerIsUser
        isInStock(quantity)
        nonReentrant
    {
        _safeMint(msg.sender, quantity);
    }

    // =====================================
    // Functions to withdraw funds for owner
    // =====================================

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawTokens(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    // ============================================
    // Functions to update the collection variables
    // ============================================

    function setBaseURI(string calldata _newBaseURI)
        external
        notCompleted
        onlyOwner
    {
        baseTokenURI = _newBaseURI;
    }

    function setDefaultURI(string calldata _newDefaultURI)
        external
        notCompleted
        onlyOwner
    {
        defaultTokenURI = _newDefaultURI;
    }

    function setComplete() external notCompleted onlyOwner {
        isCompleted = true;
    }

    function setIsRevealed(bool _isRevealed) external notCompleted onlyOwner {
        isRevealed = _isRevealed;
    }

    function setPresaleState(bool isActive) external notCompleted onlyOwner {
        isPresaleActive = isActive;
    }

    function setSaleState(bool isActive) external notCompleted onlyOwner {
        isSaleActive = isActive;
    }

    function setPresaleMerkleRoot(bytes32 merkleRoot)
        external
        notCompleted
        onlyOwner
    {
        witchListMerkleRoot = merkleRoot;
    }

    function setIsOpenSeaProxyActive(bool isActive)
        external
        notCompleted
        onlyOwner
    {
        isOpenSeaProxyActive = isActive;
    }

    // =========================================
    // Pre-approve OpenSea (thanks Crypto Coven)
    // =========================================

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        ProxyRegistry proxyRegistry = ProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (
            isOpenSeaProxyActive &&
            address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}