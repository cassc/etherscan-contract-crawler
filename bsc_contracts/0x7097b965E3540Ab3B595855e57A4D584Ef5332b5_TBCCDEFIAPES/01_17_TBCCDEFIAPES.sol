// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import 'erc721a/contracts/ERC721A.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import '../lib/ITBCCDEFIAPES.sol';
import '../lib/ITBCCFinanceFeeHandler.sol';

contract TBCCDEFIAPES is ITBCCDEFIAPES, ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    IERC20 public busdToken;
    ITBCCFinanceFeeHandler public feeHandler;

    uint256 public DEFAULT_COST = 1 * 10**uint(18);
    uint256 public DEFAULT_MAX_SUPPLY = 1000000;

    string public uriPrefix = 'ipfs://QmX3VMhbZ29fkBkrUj7ProQEkKefs6L6Zj2mhQ73WkAC7n/';
    string public uriSuffix = '.json';

    uint256 public busdCost;
    uint256 public maxSupply;

    // Used for generating the tokenId of new NFT minted
    uint256 private _tokenIds = 1;

    // Map the nftId for each tokenId
    mapping(uint256 => uint256) private nftIds;

    bool public paused = true;

    event NFTClaimed(address holder, uint256 tokenId);

    // Modifier for max NFT count
    modifier mintCompliance(uint256 _mintAmount) {
        require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
        _;
    }

    // Modifier for the NFT price
    modifier mintPriceCompliance(uint256 _mintAmount, address sender) {
        uint256 balance = busdToken.balanceOf(sender);

        require(balance >= busdCost * _mintAmount, 'Insufficient funds!');
        _;
    }

    // Modifier for NFT holder
    modifier onlyNFTHolder(address sender, uint256 tokenId) {
        require(sender == ownerOf(tokenId), 'Only NFT holder');
        _;
    }

    /**
     * @notice Constructor
     * @param _tokenName: name of the token
     * @param _tokenSymbol: symbol of the token
     */
    constructor(
        IERC20 _busdToken,
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC721A(_tokenName, _tokenSymbol) {
        busdToken = _busdToken;
        busdCost = DEFAULT_COST;
        maxSupply = DEFAULT_MAX_SUPPLY;
    }

    /**
     * @notice Mint NFT
     * @param _mintAmount: NFT amount
     */
    function mintNFT(
        uint256 _mintAmount
    ) external payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount, _msgSender()) {
        require(!paused, 'The contract is paused!');

        // Send Background tokens to this contract
        busdToken.transferFrom(_msgSender(), address(this), busdCost * _mintAmount);

        for (uint256 i; i < _mintAmount; i++) {
            uint256 newId = _tokenIds;
            uint256 _imageId = _random(i);
            _tokenIds = _tokenIds + 1;
            nftIds[newId] = _imageId;
        }

        _safeMint(_msgSender(), _mintAmount);
    }

    /**
     * @notice Mint NFT for Address
     * @param _mintAmount: NFT amount
     * @param _receiver: receiver address
     * @dev Callable by owner
     */
    function mintForAddress(
        uint256 _mintAmount,
        address _receiver
    ) external mintCompliance(_mintAmount) onlyOwner {
        for (uint256 i; i < _mintAmount; i++) {
            uint256 newId = _tokenIds;
            uint256 _imageId = _random(i);
            _tokenIds = _tokenIds + 1;
            nftIds[newId] = _imageId;
        }

        _safeMint(_receiver, _mintAmount);
    }

    /**
     * @notice Get Claim Amount
     */
    function getClaimAmount() external view returns (uint256) {
        return feeHandler.getApesClaimAmount();
    }

    /**
     * @notice Burn NFT
     * @param _tokenId: token id
     */
    function burnNFT(
        uint256 _tokenId
    ) external onlyNFTHolder(_msgSender(), _tokenId) {
        feeHandler.apesClaim(_msgSender(), _tokenId);

        _burn(_tokenId);

        emit NFTClaimed(_msgSender(), _tokenId);
    }

    /**
     * @notice Setting Fee Handler
     * @param _feeHandler: feeHandler address
     */
    function setFeeHandler(
        address _feeHandler
    ) external onlyOwner {
        feeHandler = ITBCCFinanceFeeHandler(_feeHandler);
    }

    /**
     * @notice Getting NFT for Wallet
     * @param _owner: wallet Address
     */
    function walletOfOwner(
        address _owner
    ) external view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            TokenOwnership memory ownership = _ownerships[currentTokenId];

            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    /**
     * @notice Setting start token id
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Getting random number
     * @param _number: index in array
     */
    function _random(
        uint256 _number
    ) internal view virtual returns (uint256) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,
            msg.sender, _number))) % 9;
    }

    /**
     * @notice Getting token URI
     * @param _tokenId: tokenId of the NFT
     */
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        string memory uriName = Strings.toString(nftIds[_tokenId]);
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, uriName, uriSuffix))
        : '';
    }

    /**
     * @notice Setting new NFT cost
     * @param _cost: new cost
     * @dev Callable by owner
     */
    function setCost(
        uint256 _cost
    ) external onlyOwner {
        busdCost = _cost;
    }

    /**
     * @notice Setting new max supply
     * @param _maxSupply: new max supply
     * @dev Callable by owner
     */
    function setMaxSupply(
        uint256 _maxSupply
    ) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Setting new IRI Prefix
     * @param _uriPrefix: new prefix
     * @dev Callable by owner
     */
    function setUriPrefix(
        string memory _uriPrefix
    ) external onlyOwner {
        uriPrefix = _uriPrefix;
    }

    /**
     * @notice Setting new IRI suffix
     * @param _uriSuffix: new suffix
     * @dev Callable by owner
     */
    function setUriSuffix(
        string memory _uriSuffix
    ) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    /**
     * @notice Setting contract pause
     * @param _state: pause state
     * @dev Callable by owner
     */
    function setPaused(
        bool _state
    ) external onlyOwner {
        paused = _state;
    }

    /**
     * @notice Return base URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    /**
     * @notice withdraw
     * @dev Callable by owner
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    /**
     * @notice withdraw BUSD
     * @dev Callable by owner
     */
    function withdrawBUSD() external onlyOwner {
        uint256 balance = busdToken.balanceOf(address(this));

        require(balance > 0, "balance should be > 0");

        busdToken.transfer(owner(), balance);
    }
}