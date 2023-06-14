// contracts/token/ERC721/spaces/RareSpaceNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable-0.7.2/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable-0.7.2/token/ERC721/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable-0.7.2/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable-0.7.2/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable-0.7.2/utils/CountersUpgradeable.sol";
import "../IERC721Creator.sol";
import "../WhitelistUpgradeable.sol";
import "../../../royalty/ERC2981Upgradeable.sol";

/// @author koloz
/// @title RareSpaceNFT
/// @notice The 721 contract for the rarest of spaces.
contract RareSpaceNFT is
    OwnableUpgradeable,
    ERC165Upgradeable,
    ERC721Upgradeable,
    IERC721Creator,
    ERC721BurnableUpgradeable,
    ERC2981Upgradeable,
    WhitelistUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Mapping of token id to the creator of that token.
    mapping(uint256 => address) private tokenCreators;

    // Counter to keep track of the current token id.
    CountersUpgradeable.Counter private tokenIdCounter;

    // Default royalty percentage
    uint256 public defaultRoyaltyPercentage;

    constructor() {}

    function init(
        string memory _name,
        string memory _symbol,
        address _operator
    ) public initializer {
        require(_operator != address(0));
        defaultRoyaltyPercentage = 10;

        __ERC721_init(_name, _symbol);
        __ERC165_init();
        __ERC2981__init();
        __Whitelist_init();

        _registerInterface(calcIERC721CreatorInterfaceId());

        super.transferOwnership(_operator);
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

    function initWhitelist(
        address[] calldata _creators,
        uint256[] calldata _numMints
    ) external onlyOwner {
        require(_creators.length == _numMints.length);

        for (uint256 i = 0; i < _creators.length; i++) {
            updateMintingAllowance(_creators[i], _numMints[i]);
        }
    }

    function addNewToken(string calldata _uri) external canMint(msg.sender, 1) {
        _createToken(_uri, msg.sender, msg.sender, defaultRoyaltyPercentage);
    }

    function batchAddNewToken(string[] calldata _uris)
        external
        canMint(msg.sender, _uris.length)
    {
        require(_uris.length < 2000);

        for (uint16 i = 0; i < _uris.length; i++) {
            _createToken(
                _uris[0],
                msg.sender,
                msg.sender,
                defaultRoyaltyPercentage
            );
        }
    }

    function mintTo(string calldata _uri, address _receiver)
        external
        canMint(msg.sender, 1)
    {
        _createToken(_uri, msg.sender, _receiver, defaultRoyaltyPercentage);
    }

    function mintToWithRoyaltyPercentage(
        string calldata _uri,
        address _receiver,
        uint8 _royaltyPercentage
    ) external canMint(msg.sender, 1) {
        require(_royaltyPercentage <= 100);
        _createToken(_uri, msg.sender, _receiver, _royaltyPercentage);
    }

    function deleteToken(uint256 _tokenId) external onlyTokenOwner(_tokenId) {
        burn(_tokenId);
    }

    function tokenCreator(uint256 _tokenId)
        public
        view
        override
        returns (address payable)
    {
        return payable(tokenCreators[_tokenId]);
    }

    function setRoyaltyReceiver(uint256 _tokenId, address _receiver) external {
        require(msg.sender == tokenCreators[_tokenId], "Not creator");
        _setRoyaltyReceiver(_tokenId, _receiver);
    }

    function _setTokenCreator(uint256 _tokenId, address _creator) internal {
        tokenCreators[_tokenId] = _creator;
    }

    function _createToken(
        string memory _uri,
        address _creator,
        address _receiver,
        uint256 _royaltyPercentage
    ) internal returns (uint256) {
        tokenIdCounter.increment();
        uint256 tokenId = tokenIdCounter.current();
        _mint(_receiver, tokenId);
        _setTokenURI(tokenId, _uri);
        _setTokenCreator(tokenId, _creator);
        _setRoyaltyReceiver(tokenId, _creator);
        _setRoyaltyPercentage(tokenId, _royaltyPercentage);
        _decrementMintingAllowance(msg.sender);
        return tokenId;
    }
}