// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../interfaces/IOmniERC721.sol";
import "./ERC721A.sol";
import {CreateParams, Allowlist} from "../structs/erc721/ERC721Structs.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title OmniERC721
 * @author Omnisea
 * @custom:version 0.1
 * @notice OmniERC721 is ERC721 contract with mint function restricted for TokenFactory.
 *         The above makes it suited for handling (validation & execution) cross-chain actions.
 */
contract OmniERC721 is IOmniERC721, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    event TokenMinted(address collAddr, address owner, uint256 tokenId);

    address private constant TREASURY = 0x61104fBe07ecc735D8d84422c7f045f8d29DBf15;

    string public collectionName;
    uint256 public override createdAt;
    uint256 public override maxSupply;
    address public override creator;
    uint256 public override dropFrom;
    uint256 public dropTo;
    string public collectionURI;
    uint256 public publicPrice;
    string public override assetName;
    address public tokenFactory;
    string public tokensURI;
    string public _notRevealedURI;
    address public owner;
    Allowlist public allowlist;
    mapping(address => bool) allowlistedAddresses;
    mapping(address => uint256) mintedCount;
    mapping(address => uint256) allowlistMintedCount;
    bool public isZeroIndexed;
    uint256 private preMintedToPlatform;

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
        tokensURI = params.tokensURI;
        maxSupply = params.maxSupply;
        publicPrice = params.price;
        createdAt = block.timestamp;
        collectionName = params.name;
        collectionURI = params.uri;
        assetName = params.assetName;
        isZeroIndexed = params.isZeroIndexed;
        _setDates(params.from, params.to);
        owner = creator;
        _setNextTokenId(isZeroIndexed ? 0 : 1);
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
        require(_exists(tokenId), "!token");

        if (bytes(_notRevealedURI).length > 0) {
            return _notRevealedURI;
        }

        return bytes(tokensURI).length > 0
        ? string(abi.encodePacked(_baseURI(), tokensURI, "/", tokenId.toString(), ".json"))
        : contractURI();
    }

    /**
     * @notice Mints ERC721 token.
     *
     * @param _owner ERC721 token owner.
     * @param _quantity tokens to mint in a batch.
     */
    function mint(address _owner, uint256 _quantity) override external nonReentrant {
        _validateMint(_quantity, _owner);
        _mint(_owner, _quantity);
        emit TokenMinted(address(this), _owner, _nextTokenId());
    }

    /**
     * @notice Validates ERC721 token mint.
     */
    function _validateMint(uint256 _quantity, address _owner) internal {
        require(msg.sender == tokenFactory);
        if (maxSupply > 0) require(maxSupply >= _totalMinted() + _quantity, "exceeded");
        if (dropFrom > 0) require(block.timestamp >= dropFrom, "!started");
        if (dropTo > 0) require(block.timestamp <= dropTo, "ended");

        mintedCount[_owner] += _quantity;
        if (allowlist.isEnabled) {
            if (block.timestamp >= allowlist.publicFrom) {
                uint256 publicMints = mintedCount[_owner] - allowlistMintedCount[_owner];

                require(allowlist.maxPerAddressPublic >= publicMints, ">maxPerAddressPublic");
            } else {
                require(allowlistedAddresses[_owner], "!isAllowlisted");
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
    function setNotRevealedURI(string memory _uri) external {
        require(msg.sender == owner);
        require(_totalMinted() == 0, "tokenIds > 0");
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

    function isAllowlisted(address account) external view returns (bool) {
        return allowlistedAddresses[account];
    }

    function setAllowlist(bytes calldata addressesBytes, uint256 maxPerAddress, uint256 maxPerAddressPublic, uint256 publicFrom, uint256 price, bool isEnabled) external {
        require(msg.sender == owner);
        address[] memory addresses = abi.decode(addressesBytes, (address[]));

        for (uint i = 0; i < addresses.length; i++) {
            allowlistedAddresses[addresses[i]] = true;
        }

        allowlist = Allowlist(maxPerAddress, maxPerAddressPublic, publicFrom, price, isEnabled);
    }

    function preMintToTeam(uint256 _quantity) external {
        require(msg.sender == creator, "!creator");
        if (dropFrom > 0) {
            require(block.timestamp < dropFrom, ">= dropFrom");
        }
        uint256 _minted = _totalMinted();
        require((_minted == 0 || _minted - preMintedToPlatform == 0), "!preMint");

        _mint(creator, _quantity);
    }

    function preMintToPlatform() external {
        require(preMintedToPlatform == 0, "isPreMinted");
        uint256 _quantity = maxSupply < 10000 ? (maxSupply < 100 ? 1 : 3) : 5;
        preMintedToPlatform = _quantity;
        _mint(TREASURY, _quantity);
    }

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal view override returns (uint256) {
        return isZeroIndexed ? 0 : 1;
    }
}