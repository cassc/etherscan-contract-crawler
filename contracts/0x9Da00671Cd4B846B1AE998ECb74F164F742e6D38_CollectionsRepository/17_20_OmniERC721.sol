// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../interfaces/IOmniERC721.sol";
import "./ERC721A.sol";
import {CreateParams, Allowlist} from "../structs/erc721/ERC721Structs.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title OmniERC721
 * @author Omnisea
 * @custom:version 1.1
 * @notice OmniERC721 is ERC721 contract with mint function restricted for TokenFactory.
 *         The above makes it suited for handling (validation & execution) cross-chain actions.
 */
contract OmniERC721 is IOmniERC721, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    event TokenMinted(address collAddr, address owner, uint256 tokenId);

    modifier isBeforeMint() {
        uint256 _minted = _totalMinted();
        require((_minted == 0 || (_minted - preMintedToPlatform - preMintedToTeam) == 0), "!isBeforeMint");
        _;
    }

    modifier onlyTokenFactory() {
        require(msg.sender == tokenFactory);
        _;
    }

    address private constant TREASURY = 0x61104fBe07ecc735D8d84422c7f045f8d29DBf15;

    string public collectionName;
    uint256 public override createdAt;
    uint256 public override maxSupply;
    address public override creator;
    uint256 public override dropFrom;
    uint256 public override points;
    uint256 public dropTo;
    string public collectionURI;
    uint256 public publicPrice;
    string public override assetName;
    address public tokenFactory;
    string public tokensURI;
    mapping(uint256 => string) public tokenURIMap;
    uint256 public mintLimit;
    uint256[] public tokenURIIndexFrom;
    string public _notRevealedURI;
    address public owner;
    Allowlist public allowlist;
    mapping(address => uint256) mintedCount;
    mapping(address => uint256) allowlistMintedCount;
    bool public isZeroIndexed;
    uint256 private preMintedToPlatform;
    uint256 private preMintedToTeam;

    /**
     * @notice Sets the TokenFactory, and creates ERC721 collection contract.
     *
     * @param _symbol A collection symbol.
     * @param params See CreateParams struct in ERC721Structs.sol.
     * @param _creator A collection creator.
     * @param _tokenFactoryAddress Address of the TokenFactory linked with CollectionRepository.
     */
    constructor(
        string memory _symbol,
        CreateParams memory params,
        address _creator,
        address _tokenFactoryAddress
    ) ERC721A(params.name, _symbol) {
        tokenFactory = _tokenFactoryAddress;
        creator = _creator;
        owner = creator;
        tokensURI = params.tokensURI;
        maxSupply = params.maxSupply;
        publicPrice = params.price;
        createdAt = block.timestamp;
        collectionName = params.name;
        collectionURI = params.uri;
        assetName = params.assetName;
        isZeroIndexed = params.isZeroIndexed;
        _setDates(params.from, params.to);
        _setNextTokenId(isZeroIndexed ? 0 : 1);

        if (params.points > 0) {
            _addPoints(params.points);
        }
    }

    /**
     * @notice Returns the baseURI for the IPFS-restricted tokenURI creation.
     */
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    /**
     * @notice Returns contract-level metadata URI.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), collectionURI));
    }

    /**
     * @notice Returns metadata URI of a specific token.
     *
     * @param tokenId ID of a token.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (bytes(_notRevealedURI).length > 0) {
            return _notRevealedURI;
        }

        return string(abi.encodePacked(_baseURI(), _getTokenURI(tokenId), "/", tokenId.toString(), ".json"));
    }

    /**
     * @notice Mints ERC721 token.
     *
     * @param _owner ERC721 token owner.
     * @param _quantity tokens to mint in a batch.
     */
    function mint(address _owner, uint256 _quantity, bytes32[] memory _merkleProof) override external nonReentrant {
        _validateMint(_quantity, _owner, _merkleProof);
        _mint(_owner, _quantity);
        emit TokenMinted(address(this), _owner, _nextTokenId());
    }

    /**
     * @notice Validates ERC721 token mint.
     */
    function _validateMint(uint256 _quantity, address _owner, bytes32[] memory _merkleProof) internal onlyTokenFactory {
        uint256 _newTotalMinted = _totalMinted() + _quantity;
        if (maxSupply > 0) require(maxSupply >= _newTotalMinted, ">maxSupply");
        if (dropFrom > 0) require(block.timestamp >= dropFrom, "!started");
        if (dropTo > 0) require(block.timestamp <= dropTo, "ended");
        if (mintLimit > 0) require(mintLimit >= _newTotalMinted, ">mintLimit");

        mintedCount[_owner] += _quantity;
        if (allowlist.isEnabled) {
            if (block.timestamp >= allowlist.publicFrom) {
                uint256 publicMints = mintedCount[_owner] - allowlistMintedCount[_owner];

                require(allowlist.maxPerAddressPublic >= publicMints, ">maxPerAddressPublic");
            } else {
                require(isAllowlisted(_owner, _merkleProof), "!allowlisted");
                allowlistMintedCount[_owner] += _quantity;
                require(allowlist.maxPerAddress >= allowlistMintedCount[_owner], ">maxPerAddress");
            }
        }
    }

    /**
     * @notice Validates and sets minting dates.
     *
     * @param from Minting start date.
     * @param to Minting end date.
     */
    function _setDates(uint256 from, uint256 to) internal {
        if (from > 0) {
            require(from >= (block.timestamp - 1 days));
            dropFrom = from;
        }
        if (to > 0) {
            require(to > from && to > block.timestamp);
            dropTo = to;
        }
    }

    /**
     * @notice Sets Metadata URI as non-revealable.
     *
     * @param _uri notRevealedURI.
     */
    function setNotRevealedURI(string memory _uri) external isBeforeMint {
        require(msg.sender == owner);
        _notRevealedURI = _uri;
    }

    /**
     * @notice Removes notRevealedURI making collection's metadata revealed.
     */
    function reveal() external {
        require(msg.sender == owner || msg.sender == TREASURY);
        _notRevealedURI = "";
    }

    function totalMinted() external view override returns (uint256) {
        return _totalMinted();
    }

    function mintPrice() public view override returns (uint256) {
        if (allowlist.isEnabled && allowlist.price > 0 && block.timestamp < allowlist.publicFrom) {
            return allowlist.price;
        }

        return publicPrice;
    }

    function isAllowlisted(address _account, bytes32[] memory _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_account));

        return MerkleProof.verify(_merkleProof, allowlist.merkleRoot, leaf);
    }

    function setAllowlist(bytes32 merkleRoot, uint256 maxPerAddress, uint256 maxPerAddressPublic, uint256 publicFrom, uint256 price, bool isEnabled) external {
        require(msg.sender == owner);

        allowlist = Allowlist(maxPerAddress, maxPerAddressPublic, publicFrom, price, merkleRoot, isEnabled);
    }

    function toggleAllowlist(bool _isEnabled) external {
        require(msg.sender == owner);
        allowlist.isEnabled = _isEnabled;
    }

    function preMintToTeam(uint256 _quantity) external isBeforeMint {
        require(msg.sender == creator, "!creator");
        if (dropFrom > 0) {
            require(block.timestamp < dropFrom, ">= dropFrom");
        }
        preMintedToTeam += _quantity;
        _mint(creator, _quantity);
    }

    function preMintToPlatform() external {
        require(preMintedToPlatform == 0, "isPreMinted");
        uint256 _quantity = maxSupply < 10000 ? (maxSupply < 100 ? 1 : 3) : 5;
        preMintedToPlatform = _quantity;
        _mint(TREASURY, _quantity);
    }

    function addPoints(uint256 quantity) external override onlyTokenFactory {
        _addPoints(quantity);
    }

    function setNextTokenURI(uint256 _fromTokenId, string memory _nextTokenURI, uint256 _mintLimit) external {
        require(msg.sender == owner);
        require(_fromTokenId <= maxSupply, "from>maxSupply");
        require(_mintLimit <= maxSupply, "to>maxSupply");

        if (tokenURIIndexFrom.length > 0) {
            require(tokenURIIndexFrom[tokenURIIndexFrom.length - 1] < _fromTokenId, "!new");
        }

        tokenURIIndexFrom.push(_fromTokenId);
        uint256 tokenURIsCount = tokenURIIndexFrom.length;
        tokenURIMap[tokenURIsCount] = _nextTokenURI;
        mintLimit = _mintLimit;
    }

    function _getTokenURI(uint256 tokenId) internal view returns (string memory) {
        uint256 tokenURIsCount = tokenURIIndexFrom.length;

        if (tokenURIsCount == 0) {
            return tokensURI;
        }

        for (uint256 i = tokenURIsCount; i >= 1; i--) {
            if (tokenId >= tokenURIIndexFrom[i - 1]) {
                return tokenURIMap[i];
            }
        }

        return tokensURI;
    }

    function _addPoints(uint256 _quantity) internal {
        require(_quantity > 0, "!quantity");
        require(maxSupply > 0, "!pointable");
        points += _quantity;
    }

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal view override returns (uint256) {
        return isZeroIndexed ? 0 : 1;
    }
}