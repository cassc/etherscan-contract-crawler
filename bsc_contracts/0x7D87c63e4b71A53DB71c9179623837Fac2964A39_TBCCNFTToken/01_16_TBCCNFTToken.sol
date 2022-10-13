// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import 'erc721a/contracts/ERC721A.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '../lib/ITBCCNFTToken.sol';

contract TBCCNFTToken is ITBCCNFTToken, ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    IERC20 public tbccToken;

    uint256 public DEFAULT_COST = 100 * 10**uint(18);
    uint256 public DEFAULT_MAX_SUPPLY = 1000;

    string public uriPrefix = 'ipfs://QmceWRwd9vXnYoRao8ZoXAhP7AksXWYaUEwPPTgh8u8fFg/';
    string public uriName = 'tbcc';
    string public uriSuffix = '.json';

    uint256 public tbccCost;
    uint256 public maxSupply;

    bool public paused = true;

    // Modifier for max NFT count
    modifier mintCompliance(uint256 _mintAmount) {
        require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
        _;
    }

    // Modifier for the NFT price
    modifier mintPriceCompliance(uint256 _mintAmount, address sender) {
        uint256 balance = tbccToken.balanceOf(sender);

        require(balance >= tbccCost * _mintAmount, 'Insufficient funds!');
        _;
    }

    /**
     * @notice Constructor
     * @param _tokenName: name of the token
     * @param _tokenSymbol: symbol of the token
     */
    constructor(
        IERC20 _tbccToken,
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC721A(_tokenName, _tokenSymbol) {
        tbccToken = _tbccToken;
        tbccCost = DEFAULT_COST;
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

        // Send TBCC tokens to this contract
        tbccToken.transferFrom(_msgSender(), address(this), tbccCost * _mintAmount);

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
        _safeMint(_receiver, _mintAmount);
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
     * @notice Getting token URI
     * @param _tokenId: tokenId of the NFT
     */
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
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
        tbccCost = _cost;
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
     * @notice Setting new IRI name
     * @param _uriName: new name
     * @dev Callable by owner
     */
    function setUriName(
        string memory _uriName
    ) external onlyOwner {
        uriName = _uriName;
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
     * @notice withdraw TBCC
     * @dev Callable by owner
     */
    function withdrawTBCC() external onlyOwner {
        uint256 balance = tbccToken.balanceOf(address(this));

        require(balance > 0, "balance should be > 0");

        tbccToken.transfer(owner(), balance);
    }
}