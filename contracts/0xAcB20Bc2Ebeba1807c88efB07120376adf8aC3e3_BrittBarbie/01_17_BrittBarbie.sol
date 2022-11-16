//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

/*
 ▄▄▄▄▄▄▄▄▄▄   ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄       ▄▄▄▄▄▄▄▄▄▄   ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░▌ ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░░░░░░░░░░▌ ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌ ▀▀▀▀█░█▀▀▀▀  ▀▀▀▀█░█▀▀▀▀  ▀▀▀▀█░█▀▀▀▀      ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ 
▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌          ▐░▌          ▐░▌          ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌    ▐░▌     ▐░▌          
▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌     ▐░▌          ▐░▌          ▐░▌          ▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌    ▐░▌     ▐░█▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░▌ ▐░░░░░░░░░░░▌     ▐░▌          ▐░▌          ▐░▌          ▐░░░░░░░░░░▌ ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░▌     ▐░▌     ▐░░░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀█░█▀▀      ▐░▌          ▐░▌          ▐░▌          ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀█░█▀▀ ▐░█▀▀▀▀▀▀▀█░▌    ▐░▌     ▐░█▀▀▀▀▀▀▀▀▀ 
▐░▌       ▐░▌▐░▌     ▐░▌       ▐░▌          ▐░▌          ▐░▌          ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌     ▐░▌  ▐░▌       ▐░▌    ▐░▌     ▐░▌          
▐░█▄▄▄▄▄▄▄█░▌▐░▌      ▐░▌  ▄▄▄▄█░█▄▄▄▄      ▐░▌          ▐░▌          ▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌▐░▌      ▐░▌ ▐░█▄▄▄▄▄▄▄█░▌▄▄▄▄█░█▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░▌ ▐░▌       ▐░▌▐░░░░░░░░░░░▌     ▐░▌          ▐░▌          ▐░░░░░░░░░░▌ ▐░▌       ▐░▌▐░▌       ▐░▌▐░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
 ▀▀▀▀▀▀▀▀▀▀   ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀       ▀            ▀            ▀▀▀▀▀▀▀▀▀▀   ▀         ▀  ▀         ▀  ▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀                                                                                                                                                                                                                                                                                                              
 */

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/IERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

contract BrittBarbie is
    ERC721A,
    ERC721AQueryable,
    ERC721ABurnable,
    VRFV2WrapperConsumerBase,
    DefaultOperatorFilterer,
    Pausable,
    Ownable,
    ReentrancyGuard
{
    struct PublicSaleConfig {
        uint256 startTime;
        uint256 price;
    }

    struct VRFRequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
    }

    PublicSaleConfig public publicSaleConfig;
    mapping(uint256 => VRFRequestStatus) public vrfStoredRequests;
    uint256 public collectionSize = 10000;
    uint256 public maxQtyPerBatchMint = 30;
    uint256[] public vrfRequestIds;
    uint256 public vrfLastRequestId;

    string private _baseTokenURI = "https://api.brittbarbieworld.com/metadata/";
    string private _contractURI =
        "ipfs://QmdyKttHBcNNdZMq6MtNrvAu6ewZaThNx93knX8CW7EJYP/contracts/contract_uri";
    address private _linkAddress;
    address private _vrfWrapperAddress;
    uint32 private _vrfCallbackGasLimit = 100000;
    uint32 private _vrfNumWords = 1;
    uint16 private _vrfRequestConfirmations = 3;

    constructor(address linkAddress, address vrfWrapper)
        ERC721A("BrittBarbie", "BrittNFT")
        VRFV2WrapperConsumerBase(linkAddress, vrfWrapper)
    {
        // init configs
        publicSaleConfig = PublicSaleConfig({
            startTime: 1668243735,
            price: 0.078 ether
        });

        // init chainlink
        _linkAddress = linkAddress;
        _vrfWrapperAddress = vrfWrapper;
    }

    error ContractNotAllowed();
    error InvalidPayableAmount();
    error InvalidBatchMintQty();
    error InvalidCollectionSize();
    error NonExistentToken();
    error ProxyNotAllowed();
    error PubMintExpiredOrEnded();
    error PubMintSaleNotStarted();
    error MaxSupplyReached();
    error VRFRequestNotFound();
    error VRFLinkUnableToTransfer();

    event LogVRFRequestSent(uint256 requestId, uint32 numWords);
    event LogVRFRequestFulfilled(
        uint256 requestId,
        uint256[] originalRandomWords,
        uint256[] rangedRandomWords,
        uint256 payment
    );

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
        if (_totalMinted() + qty > collectionSize) revert MaxSupplyReached();
        if (qty * publicSaleConfig.price != msg.value)
            revert InvalidPayableAmount();

        _mint(msg.sender, qty);
    }

    /**
     * Get VRF request status
     @param _requestId - request status id
     */
    function getVRFRequestStatus(uint256 _requestId)
        external
        view
        returns (
            uint256 paid,
            bool fulfilled,
            uint256[] memory randomWords
        )
    {
        if (vrfStoredRequests[_requestId].paid <= 0)
            revert VRFRequestNotFound();

        VRFRequestStatus memory request = vrfStoredRequests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
    }

    /// Restricted Functions

    /**
     * Admin mint
     * @param qty batch mint quantity
     */
    function adminMint(uint16 qty) external onlyOwner {
        if (qty > maxQtyPerBatchMint) revert InvalidBatchMintQty();
        if (_totalMinted() + qty > collectionSize) revert MaxSupplyReached();

        _mint(msg.sender, qty);
    }

    /**
     * VRF request random numbers
     * @return requestId
     */
    function requestRandomNumbers()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        requestId = requestRandomness(
            _vrfCallbackGasLimit,
            _vrfRequestConfirmations,
            _vrfNumWords
        );

        vrfStoredRequests[requestId] = VRFRequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(_vrfCallbackGasLimit),
            randomWords: new uint256[](0),
            fulfilled: false
        });

        vrfRequestIds.push(requestId);
        vrfLastRequestId = requestId;
        emit LogVRFRequestSent(requestId, _vrfNumWords);

        return requestId;
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
     * Set new vrf callback gas limit
     * @param _callbackGasLimit - new callback gas limit
     */
    function setVRFCallbackGasLimit(uint32 _callbackGasLimit)
        external
        onlyOwner
    {
        _vrfCallbackGasLimit = _callbackGasLimit;
    }

    /**
     * Set new vrf number words request
     * @param _numWords - new number words to be set
     */
    function setVRFNumberWords(uint32 _numWords) external onlyOwner {
        _vrfNumWords = _numWords;
    }

    /**
     * Set new vrf request confirms
     * @param _requestConfirmations - max request confirms
     */
    function setVRFRequestConfirms(uint16 _requestConfirmations)
        external
        onlyOwner
    {
        _vrfRequestConfirmations = _requestConfirmations;
    }

    // Withdraw contract funds to contract owner address
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(_linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "VRFLinkUnableToTransfer()"
        );
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

        return super.tokenURI(tokenId);
    }

    /**
     * VRF Fullfill callback function
     * @param _requestId - request randomness id
     * @param _randomNumbers - random numbers result
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomNumbers
    ) internal override {
        if (vrfStoredRequests[_requestId].paid <= 0)
            revert VRFRequestNotFound();

        vrfStoredRequests[_requestId].fulfilled = true;

        // iterate and provide range (min. 1, max. total minted supply)
        uint256[] memory rangedRandomNumbers = new uint256[](
            _randomNumbers.length
        );

        for (uint256 i = 0; i < _randomNumbers.length; i++) {
            rangedRandomNumbers[i] = (_randomNumbers[i] % _totalMinted()) + 1;
        }

        vrfStoredRequests[_requestId].randomWords = rangedRandomNumbers;

        emit LogVRFRequestFulfilled(
            _requestId,
            _randomNumbers,
            rangedRandomNumbers,
            vrfStoredRequests[_requestId].paid
        );
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