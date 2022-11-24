// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../interfaces/IOmniERC721.sol";
import {CreateParams, Allowlist} from "../structs/erc721/ERC721Structs.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

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

    string public collectionName;
    uint256 public override createdAt;
    uint256 public override maxSupply;
    address public override creator;
    uint256 public override dropFrom;
    uint256 public dropTo;
    string public collectionURI;
    uint256 public override mintPrice;
    string public override assetName;
    mapping(address => uint256[]) public mintedBy;
    address public tokenFactory;
    string public tokensURI;
    string public _notRevealedURI;
    address public owner;
    Allowlist public allowlist;
    mapping(address => bool) allowlistedAddresses;

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
        maxSupply = bytes(tokensURI).length > 0 ? params.maxSupply : 0;
        mintPrice = params.price;
        createdAt = block.timestamp;
        collectionName = params.name;
        collectionURI = params.uri;
        assetName = params.assetName;
        _setDates(params.from, params.to);
        owner = creator;
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
        uint256 startAt = _nextTokenId();
        for (uint256 i = startAt; i < (startAt + _quantity); i++) {
            mintedBy[_owner].push(i);
            emit TokenMinted(address(this), _owner, i);
        }
        _mint(_owner, _quantity);
    }

    /**
     * @notice Validates ERC721 token mint.
     */
    function _validateMint(uint256 _quantity, address _owner) internal view {
        require(msg.sender == tokenFactory);
        if (maxSupply > 0) require(maxSupply >= _totalMinted() + _quantity, "exceeded");
        if (dropFrom > 0) require(block.timestamp >= dropFrom, "!started");
        if (dropTo > 0) require(block.timestamp <= dropTo, "ended");
        if (allowlist.isEnabled) {
            uint256 newMintedBy = getMintedBy(_owner).length + _quantity;

            if (block.timestamp >= allowlist.publicFrom) {
                require(allowlist.maxPerAddressPublic >= newMintedBy, ">maxPerAddressPublic");
            } else {
                require(allowlistedAddresses[_owner], "!isAllowlisted");
                require(allowlist.maxPerAddress >= newMintedBy, ">maxPerAddress");
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
     * @notice Getter of the tokens minted by the address.
     *
     * @param _owner Owner of tokens.
     */
    function getMintedBy(address _owner) public view returns (uint256[] memory) {
        return mintedBy[_owner];
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
        require(msg.sender == owner);
        _notRevealedURI = "";
    }

    function totalMinted() external view override returns (uint256) {
        return _totalMinted();
    }

    function isAllowlisted(address account) external view returns (bool) {
        return allowlistedAddresses[account];
    }

    function setAllowlist(bytes calldata addressesBytes, uint256 maxPerAddress, uint256 maxPerAddressPublic, uint256 publicFrom, bool isEnabled) external {
        require(msg.sender == owner);
        address[] memory addresses = abi.decode(addressesBytes, (address[]));

        for (uint i = 0; i < addresses.length; i++) {
            allowlistedAddresses[addresses[i]] = true;
        }

        allowlist = Allowlist(maxPerAddress, maxPerAddressPublic, publicFrom, isEnabled);
    }
}