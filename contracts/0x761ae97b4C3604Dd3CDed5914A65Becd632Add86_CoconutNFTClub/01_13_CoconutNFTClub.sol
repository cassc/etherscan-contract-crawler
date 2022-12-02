// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

/*
 ▄▄▄▄▄▄▄▄▄▄▄  ▄▄        ▄  ▄▄▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░░▌▐░░▌      ▐░▌▐░░░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀▀▀ ▐░▌░▌     ▐░▌▐░█▀▀▀▀▀▀▀▀▀ 
▐░▌          ▐░▌▐░▌    ▐░▌▐░▌          
▐░▌          ▐░▌ ▐░▌   ▐░▌▐░▌          
▐░▌          ▐░▌  ▐░▌  ▐░▌▐░▌          
▐░▌          ▐░▌   ▐░▌ ▐░▌▐░▌          
▐░▌          ▐░▌    ▐░▌▐░▌▐░▌          
▐░█▄▄▄▄▄▄▄▄▄ ▐░▌     ▐░▐░▌▐░█▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░░▌▐░▌      ▐░░▌▐░░░░░░░░░░░▌
 ▀▀▀▀▀▀▀▀▀▀▀  ▀        ▀▀  ▀▀▀▀▀▀▀▀▀▀▀ 
                                       
Coconut NFT Club (CNC)                                                                                                                                                                                                                                                                                              
*/

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/IERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

contract CoconutNFTClub is
    ERC721A,
    ERC721AQueryable,
    DefaultOperatorFilterer,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    using MerkleProof for bytes32[];

    struct PublicSaleConfig {
        uint256 startTime;
        uint256 price;
    }

    struct WhitelistSaleConfig {
        bytes32 merkleRoot;
        uint256 startTime;
        uint256 price;
        uint16 maxPerAddress;
    }

    PublicSaleConfig public publicSaleConfig;
    WhitelistSaleConfig public whitelistSaleConfig;
    address public treasuryAddress = 0x40755674DEeF26B534a9f95cE384eCeb91f20da6;
    bool public isRevealed;
    uint16 public collectionSize = 2222;
    uint16 public maxQtyPerBatchMint = 10;

    string private _baseTokenURI;
    string private _contractURI =
        "ipfs://QmZiuNDMNBaWFENS4FRVsfs2VkXr7sBZjvqW5cD45kxDtf/contracts/contract_uri";
    string private _defaultTokenURI =
        "ipfs://QmYqsycWZQ3RRFia7ZmsPG1yDA8zV865Z3iSmyUUE3pWPx";

    constructor() ERC721A("CoconutNFTClub", "CNC") {
        // init configs
        publicSaleConfig = PublicSaleConfig({
            startTime: 1670181720, // 04/12/2022 2:22 pm EST
            price: 0.18 ether
        });
        whitelistSaleConfig = WhitelistSaleConfig({
            merkleRoot: 0x195e071df74e10dee9bd871beda173f493f5bf272bce6882c5db38d45861afa9,
            startTime: 1670008920, // 02/12/2022 2:22 pm EST
            price: 0.15 ether,
            maxPerAddress: 3
        });
    }

    error ContractNotAllowed();
    error InvalidPayableAmount();
    error InvalidMerkleProof();
    error InvalidBatchMintQty();
    error InvalidCollectionSize();
    error NonExistentToken();
    error ProxyNotAllowed();
    error PubMintExpiredOrEnded();
    error PubMintSaleNotStarted();
    error ReachedMaxSupply();
    error WithdrawalFailed();
    error WLMintExpiredOrEnded();
    error WLMintSaleNotStarted();
    error WLMintMaxQtyPerAddressReached();

    modifier notContract() {
        if (_isContract(msg.sender)) revert ContractNotAllowed();
        if (msg.sender != tx.origin) revert ProxyNotAllowed();
        _;
    }

    /**
     * Public mint sale
     * @param qty batch mint quantity
     */
    function publicMint(uint16 qty)
        external
        payable
        notContract
        whenNotPaused
        nonReentrant
    {
        if (publicSaleConfig.startTime == 0) revert PubMintExpiredOrEnded();
        if (block.timestamp < publicSaleConfig.startTime)
            revert PubMintSaleNotStarted();
        if (qty > maxQtyPerBatchMint) revert InvalidBatchMintQty();
        if (_totalMinted() + qty > collectionSize) revert ReachedMaxSupply();
        if (qty * publicSaleConfig.price != msg.value)
            revert InvalidPayableAmount();

        _mint(msg.sender, qty);
    }

    /**
     * Whitelist mint sale
     * @param qty batch mint quantity
     * @param proof merkle proof for whitelist mint
     */
    function whitelistMint(uint16 qty, bytes32[] memory proof)
        external
        payable
        notContract
        whenNotPaused
        nonReentrant
    {
        if (whitelistSaleConfig.startTime == 0) revert WLMintExpiredOrEnded();
        if (block.timestamp < whitelistSaleConfig.startTime)
            revert WLMintSaleNotStarted();
        if (!verifyMerkleProof(msg.sender, proof)) revert InvalidMerkleProof();
        if (qty > whitelistSaleConfig.maxPerAddress)
            revert InvalidBatchMintQty();
        if (_totalMinted() + qty > collectionSize) revert ReachedMaxSupply();
        if (qty * whitelistSaleConfig.price != msg.value)
            revert InvalidPayableAmount();

        // get user WL minted counter
        uint64 userWhitelistMintedCounter = _getAux(msg.sender);

        if (
            userWhitelistMintedCounter + qty > whitelistSaleConfig.maxPerAddress
        ) revert WLMintMaxQtyPerAddressReached();

        // update user WL minted counter
        _setAux(msg.sender, userWhitelistMintedCounter + qty);

        _mint(msg.sender, qty);
    }

    /// Restricted Functions

    /**
     * Admin mint
     * @param qty batch mint quantity
     */
    function adminMint(uint16 qty) external onlyOwner {
        if (qty > maxQtyPerBatchMint) revert InvalidBatchMintQty();
        if (_totalMinted() + qty > collectionSize) revert ReachedMaxSupply();

        _mint(msg.sender, qty);
    }

    // End or expire whitelist sale
    function endWhitelistSale() external onlyOwner {
        whitelistSaleConfig.startTime = 0;
    }

    /**
     * Sets the paused failsafe. Can only be called by owner
     * @param _setPaused - paused state
     */
    function setPaused(bool _setPaused) external onlyOwner {
        return (_setPaused) ? _pause() : _unpause();
    }

    /**
     * Set base URI for metadata
     * @param uri new uri
     */
    function setBaseURI(string calldata uri) external onlyOwner {
        _baseTokenURI = uri;
    }

    /**
     * Update collection size
     * @param _collectionSize new collection size
     */
    function setCollectionSize(uint16 _collectionSize) external onlyOwner {
        if (_collectionSize < _totalMinted()) revert InvalidCollectionSize();

        collectionSize = _collectionSize;
    }

    /**
     * Update contract uri
     * @param uri new uri
     */
    function setContractURI(string calldata uri) external onlyOwner {
        _contractURI = uri;
    }

    /**
     * Update default token uri
     * @param uri default token uri
     */
    function setDefaultTokenURI(string calldata uri) external onlyOwner {
        _defaultTokenURI = uri;
    }

    /**
     * Update revealed state
     * @param state new state
     */
    function setIsRevealed(bool state) external onlyOwner {
        isRevealed = state;
    }

    /**
     * Update max quantity per batch mint
     * @param _maxQtyPerBatchMint batchm mint quantity
     */
    function setMaxQtyPerBatchMint(uint16 _maxQtyPerBatchMint)
        external
        onlyOwner
    {
        maxQtyPerBatchMint = _maxQtyPerBatchMint;
    }

    /**
     * Update merkle root
     * @param root new root hash
     */
    function setMerkleRoot(bytes32 root) external onlyOwner {
        whitelistSaleConfig.merkleRoot = root;
    }

    /**
     * Update public sale configuration
     * Note: startTime = 0 means sale is expired or ended
     * @param _startTime new start time
     * @param _price new price
     */
    function setPublicSaleConfig(uint256 _startTime, uint256 _price)
        external
        onlyOwner
    {
        publicSaleConfig = PublicSaleConfig({
            startTime: _startTime,
            price: _price
        });
    }

    /**
     * Update treasury address
     * @param _treasuryAddress treasury address
     */
    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    /**
     * Update whitelist sale configuration
     * Note: startTime = 0 means sale is expired or ended
     * @param _merkleRoot new merkle root
     * @param _startTime new start time
     * @param _price new price
     * @param _maxPerAddress new max per address
     */
    function setWhitelistSaleConfig(
        bytes32 _merkleRoot,
        uint256 _startTime,
        uint256 _price,
        uint16 _maxPerAddress
    ) external onlyOwner {
        whitelistSaleConfig = WhitelistSaleConfig({
            merkleRoot: _merkleRoot,
            startTime: _startTime,
            price: _price,
            maxPerAddress: _maxPerAddress
        });
    }

    // Withdraw contract funds to treasury wallet
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = treasuryAddress.call{value: balance}("");

        if (!success) revert WithdrawalFailed();
    }

    /**
     * Check if token exists
     * @param _tokenId token id
     * @return bool
     */
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * Override transfer with Opensea Operator Filter Registry
     * @param from from address
     * @param to to address
     * @param tokenId token id
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        virtual
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * Override safe transfer with Opensea Operator Filter Registry
     * @param from from address
     * @param to to address
     * @param tokenId token id
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        virtual
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * Override safe transfer with Opensea Operator Filter Registry with data
     * @param from from address
     * @param to to address
     * @param tokenId token id
     * @param data data
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        virtual
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * Get contract URI
     * @return string
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * Get token uri
     * @param tokenId token id
     * @return string
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert NonExistentToken();

        if (!isRevealed) {
            return _defaultTokenURI;
        }

        return super.tokenURI(tokenId);
    }

    /**
     * Verify merkle proof for WL sale
     * @param _to address of user
     * @param _proof merkle proof
     * @return bool
     */
    function verifyMerkleProof(address _to, bytes32[] memory _proof)
        public
        view
        returns (bool)
    {
        // construct Merkle tree leaf from the inputs supplied
        bytes32 leaf = keccak256(abi.encodePacked(_to));
        // verify the proof supplied, and return the verification result
        return _proof.verify(whitelistSaleConfig.merkleRoot, leaf);
    }

    /**
     * Override base uri
     * @return string token uri
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * Override start token id to 1
     * @return uint256 start token id
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// Helper Functions

    function _delBuildNumber1() internal pure {} // etherscan trick

    function _isContract(address _addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}