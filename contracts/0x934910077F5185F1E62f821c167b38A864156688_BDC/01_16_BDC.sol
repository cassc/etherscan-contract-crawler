//SPDX-License-Identifier: MIT
//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BDC is ERC721A, Ownable, ReentrancyGuard, ERC2981 {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private tokenCounter;

    string private baseURI;
    address private walletAddress;

    uint256 private maxBadDogs;
    bool public paused = true;

    uint256 public PUBLIC_SALE_PRICE = 0.2 ether;

    address private openSeaProxyRegistryAddress;
    bool private isOpenSeaProxyActive = true;

    mapping(address => bool) public claimed;

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier canMintBDCs(uint256 numberOfTokens) {
        require(
            _nextTokenId() + numberOfTokens <= maxBadDogs + 1,
            "Not enough BDCs remaining to mint"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent value is "
        );
        _;
    }

    constructor(
        string memory _baseURI,
        address _openSeaProxyRegistryAddress,
        uint256 _maxBadDogs,
        address _walletAddress
        // uint256 _maxWLSaleBDCs
    ) ERC721A("Bad Dogs Company", "BDC") {
        baseURI = _baseURI;
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
        maxBadDogs = _maxBadDogs;
        walletAddress = _walletAddress;
        // Set default royalty to 7.5% in basis points (bips)
        _setDefaultRoyalty(msg.sender , 750);
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    function mint(address to, uint256 numberOfTokens)
        external
        payable
        nonReentrant
        isCorrectPayment(PUBLIC_SALE_PRICE, numberOfTokens)
        canMintBDCs(numberOfTokens)
    {
        require(
            numberOfTokens <= 5,
            "Max BDCs you can mint at one time is five"
        );

        if (!paused) {
            _mint(to, numberOfTokens);
        }
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function getOpenSeaProxyAddress() external view returns (address) {
        return openSeaProxyRegistryAddress;
    }

    function getWalletAddress() external view returns (address) {
        return walletAddress;
    }

    function getStartingIndex() external view returns (uint256) {
        return _nextTokenId();
    }

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function getLastTokenId() external view returns (uint256) {
        return _totalMinted();
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function claim(address to, uint256 numberOfTokens)
        external
        onlyOwner
        canMintBDCs(numberOfTokens)
    {
        _mint(to, numberOfTokens);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function removeRoyaltyInfo() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(uint256 _tokenId, address _receiver, uint96 _feeNumerator) public onlyOwner {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    function resetTokenRoyalty(uint256 _tokenId) public onlyOwner {
        _resetTokenRoyalty(_tokenId);
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setOpenSeaProxyAddress(address _openSeaProxyRegistryAddress) external onlyOwner {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
    }

    function setWalletAddress(address _walletAddress) external onlyOwner {
        walletAddress = _walletAddress;
    }

    function setPublicMintPrice(uint256 newMintPrice) external onlyOwner {
        PUBLIC_SALE_PRICE = newMintPrice;
    }

    function withdrawMoney() public onlyOwner {
        require(address(this).balance > 0, "No balance.");
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawMoneyToWallet() public onlyOwner {
        require(address(this).balance > 0, "No balance.");
        (bool success, ) = payable(walletAddress).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /**
     * @dev Function to disable gasless listings for security
     */
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
        external
        onlyOwner
    {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    // ============ SUPPORTING FUNCTIONS ============

    function nextTokenId() private view returns (uint256) {
        return _nextTokenId() + 1;
    }

    /**
     * @dev Override _startTokenId so that the tokenID start at one
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     */
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

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return
            string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json"));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC721A, ERC2981) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
}

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}