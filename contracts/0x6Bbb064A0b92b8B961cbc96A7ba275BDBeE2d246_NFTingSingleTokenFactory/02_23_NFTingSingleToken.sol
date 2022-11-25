// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../utilities/PreAuthorization.sol";
import "../interface/INFTingConfig.sol";

contract NFTingSingleToken is
    ERC721Royalty,
    ERC721Burnable,
    ERC721Enumerable,
    PreAuthorization
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public MAX_SUPPLY = 10000;
    uint256 public constant MAX_BATCH_MINT = 3;

    string public baseURI;

    INFTingConfig public config;

    Counters.Counter private currentTokenId;
    mapping(bytes32 => uint256) public URI2ID;
    mapping(uint256 => bytes32) public ID2URI;

    event BaseURIUpdated(string indexed _baseURI);
    event MaxSupplyUpdated(uint256 MAX_SUPPLY);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address _nftingConfig
    ) ERC721(_name, _symbol) {
        if (_nftingConfig == address(0)) revert ZeroAddress();
        config = INFTingConfig(_nftingConfig);
        baseURI = _initBaseURI;
    }

    modifier isTokenExist(uint256 _tokenId) {
        if (!_exists(_tokenId)) {
            revert InvalidTokenId(_tokenId);
        }

        _;
    }

    modifier isApprovedOrOwner(uint256 _tokenId) {
        if (!_isApprovedOrOwner(_msgSender(), _tokenId)) {
            revert NotApprovedOrOwner();
        }

        _;
    }

    modifier isMaxSupplyLimit(uint256 _quantity) {
        if (_quantity + totalSupply() > MAX_SUPPLY) {
            revert MaxMintLimitExceeded();
        }

        _;
    }

    modifier isMaxBatchMintLimit(uint256 _quantity) {
        if (_quantity > MAX_BATCH_MINT) revert MaxBatchMintLimitExceeded();

        _;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        if (_newMaxSupply == 0) {
            revert InvalidArgumentsProvided();
        }
        MAX_SUPPLY = _newMaxSupply;
        emit MaxSupplyUpdated(_newMaxSupply);
    }

    function _publicMint(bytes32 metadataId, uint96 royaltyFraction) internal {
        if (royaltyFraction > config.maxRoyaltyFee()) {
            revert InvalidArgumentsProvided();
        }
        currentTokenId.increment();
        uint256 curTokenId = currentTokenId.current();

        URI2ID[metadataId] = curTokenId;
        ID2URI[curTokenId] = metadataId;

        _setTokenRoyalty(
            curTokenId,
            _msgSender(),
            (_feeDenominator() * royaltyFraction) / 100
        );

        _safeMint(_msgSender(), curTokenId);
    }

    function publicMint(bytes32 _metadataId, uint96 _royaltyFraction)
        external
        isMaxSupplyLimit(1)
    {
        _publicMint(_metadataId, _royaltyFraction);
    }

    function publicBatchMint(
        bytes32[] calldata metadataIds,
        uint96[] calldata royaltyFractions
    )
        external
        isMaxBatchMintLimit(metadataIds.length)
        isMaxSupplyLimit(metadataIds.length)
    {
        if (
            metadataIds.length == 0 ||
            metadataIds.length != royaltyFractions.length
        ) {
            revert InvalidArgumentsProvided();
        }

        for (uint256 i; i < metadataIds.length; i++) {
            _publicMint(metadataIds[i], royaltyFractions[i]);
        }
    }

    function _burn(uint256 _tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(_tokenId);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        if (bytes(_newBaseURI)[bytes(_newBaseURI).length - 1] != bytes1("/"))
            revert NoTrailingSlash(_newBaseURI);

        baseURI = _newBaseURI;

        emit BaseURIUpdated(_newBaseURI);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        isTokenExist(_tokenId)
        returns (string memory)
    {
        return string(abi.encodePacked(_baseURI(), "token/", ID2URI[_tokenId]));
    }

    function withdraw() external onlyOwner {
        if (!payable(_msgSender()).send(address(this).balance)) {
            revert WithdrawalFailed();
        }
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Royalty, ERC721Enumerable)
        returns (bool)
    {
        return
            _interfaceId == type(IERC2981).interfaceId ||
            ERC721Enumerable.supportsInterface(_interfaceId);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        return super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    /**
     * Override isApprovedForAll to whitelist the trusted accounts to enable gas-free listings.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override(ERC721, IERC721)
        returns (bool)
    {
        if (_isAuthorizedOperator(_operator)) {
            return true;
        }
        return super.isApprovedForAll(_owner, _operator);
    }
}