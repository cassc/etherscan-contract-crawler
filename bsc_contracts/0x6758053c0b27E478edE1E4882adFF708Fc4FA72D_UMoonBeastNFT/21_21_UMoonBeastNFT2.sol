// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract UMoonBeastNFT is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for string;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    // Mapping for list address can opera MoonBeast NFT, eg: Sale Contract need to mint Beast, etc...
    mapping(address => bool) public _approvedOperators;
    bool public paused;
    address public gateway;

    // Base URI
    string private _baseURIExtended;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name, string memory symbol) initializer public {
        __ERC721_init(name, symbol);
        __ERC721Enumerable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        paused = false;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function setGateway(address gateway_) onlyOwner public {
        gateway = gateway_;
    }

    function mint(address account, uint256 tokenId) external onlyGateway {
        require(!paused, "MoonFit Beast and Beauty: Contract is paused");

        _mint(account, tokenId);
    }

    function burn(uint256 tokenId) external onlyGateway {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _burn(tokenId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIExtended = baseURI_;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If item does not have tokenURI and contract has base URI, concatenate the tokenID to the baseURI.
        if (bytes(base).length > 0 && bytes(_tokenURI).length == 0) {
            return string(abi.encodePacked(base, tokenId.toString(), ".json"));
        }
        // Other cases, return tokenURI
        return _tokenURI;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner returns (uint256) {
        _setTokenURI(tokenId, _tokenURI);
        return tokenId;
    }

    function setTokenURIByIdRange(uint256 startId, uint256 endId, string memory baseURI) external onlyOwner {
        require(startId < endId, "MoonBeast: StartID must be less than EndID");
        for (uint256 i = startId; i < endId; i++) {
            string memory concatenatedTokenURI = string(abi.encodePacked(baseURI, i.toString(), ".json"));
            _setTokenURI(i, concatenatedTokenURI);
        }
    }

    function setTokenURIs(uint256[] calldata tokenIds, string memory baseURI) external onlyOwner {
        require(tokenIds.length > 0, "MoonBeast: TokenIDs list is empty");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            string memory concatenatedTokenURI = string(abi.encodePacked(baseURI, tokenIds[i].toString(), ".json"));
            _setTokenURI(tokenIds[i], concatenatedTokenURI);
        }
    }

    function setApprovedOperator(address operator, bool isApproved) external onlyOwner {
        require(operator != address(0), "MoonBeast: operator is the zero address");
        _approvedOperators[operator] = isApproved;
    }

    function withdrawNFT(uint256 tokenId, string memory _tokenURI, address receiver) external onlyOwner returns (uint256) {
        _setTokenURI(tokenId, _tokenURI);
        safeTransferFrom(_msgSender(), receiver, tokenId);
        return tokenId;
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    modifier onlyGateway() {
        require(msg.sender == gateway);
        _;
    }
}