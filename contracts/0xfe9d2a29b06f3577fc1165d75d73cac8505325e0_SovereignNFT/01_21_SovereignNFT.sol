// contracts/token/ERC721/sovereign/SovereignNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../IERC721Creator.sol";
import "../../../royalty/ERC2981Upgradeable.sol";

contract SovereignNFT is
    OwnableUpgradeable,
    ERC165Upgradeable,
    ERC721Upgradeable,
    IERC721Creator,
    ERC721BurnableUpgradeable,
    ERC2981Upgradeable
{
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bool public disabled;

    // Mapping from token ID to the creator's address
    mapping(uint256 => address) private tokenCreators;

    // Counter to keep track of the current token id.
    CountersUpgradeable.Counter private tokenIdCounter;

    // Default royalty percentage
    uint256 public defaultRoyaltyPercentage;

    event ContractDisabled(address indexed user);

    function init(
        string calldata _name,
        string calldata _symbol,
        address _creator
    ) public initializer {
        require(_creator != address(0));
        defaultRoyaltyPercentage = 10;
        disabled = false;

        __Ownable_init();
        __ERC721_init(_name, _symbol);
        __ERC165_init();
        __ERC2981__init();

        _setDefaultRoyaltyReceiver(_creator);

        _registerInterface(calcIERC721CreatorInterfaceId());

        super.transferOwnership(_creator);
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "Must be owner of token.");
        _;
    }

    modifier ifNotDisabled() {
        require(!disabled, "Contract must not be disabled.");
        _;
    }

    function addNewToken(string memory _uri) public onlyOwner ifNotDisabled {
        _createToken(_uri, msg.sender, msg.sender, defaultRoyaltyPercentage);
    }

    function mintToWithRoyaltyPercentage(
        string memory _uri,
        address _receiver,
        uint256 _royaltyPercentage
    ) public onlyOwner ifNotDisabled {
        _createToken(_uri, msg.sender, _receiver, _royaltyPercentage);
    }

    function batchAddNewToken(string[] calldata _uris)
        public
        onlyOwner
        ifNotDisabled
    {
        require(
            _uris.length < 2000,
            "batchAddNewToken::Cant mint more than 2000 tokens at a time."
        );

        for (uint256 i = 0; i < _uris.length; i++) {
            _createToken(
                _uris[0],
                msg.sender,
                msg.sender,
                defaultRoyaltyPercentage
            );
        }
    }

    function renounceOwnership() public view override onlyOwner {
        revert("unsupported");
    }

    function transferOwnership(address) public view override onlyOwner {
        revert("unsupported");
    }

    function deleteToken(uint256 _tokenId) public onlyTokenOwner(_tokenId) {
        burn(_tokenId);
    }

    function tokenCreator(uint256 _tokenId)
        public
        view
        override
        returns (address payable)
    {
        (address receiver, ) = royaltyInfo(_tokenId, 0);
        return payable(receiver);
    }

    function disableContract() public onlyOwner {
        disabled = true;
        emit ContractDisabled(msg.sender);
    }

    function setDefaultRoyaltyReceiver(address _receiver) external onlyOwner {
        _setDefaultRoyaltyReceiver(_receiver);
    }

    function setRoyaltyReceiverForToken(address _receiver, uint256 _tokenId)
        external
        onlyOwner
    {
        royaltyReceivers[_tokenId] = _receiver;
    }

    function _setTokenCreator(uint256 _tokenId, address _creator) internal {
        tokenCreators[_tokenId] = _creator;
    }

    function _createToken(
        string memory _uri,
        address _creator,
        address _to,
        uint256 _royaltyPercentage
    ) internal returns (uint256) {
        tokenIdCounter.increment();
        uint256 tokenId = tokenIdCounter.current();
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _uri);
        _setTokenCreator(tokenId, _creator);
        _setRoyaltyPercentage(tokenId, _royaltyPercentage);
        return tokenId;
    }
}