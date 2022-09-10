// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@zoralabs/v3/dist/contracts/modules/ReserveAuction/Finders/ETH/IReserveAuctionFindersEth.sol";

contract ETH_ERC721 is
    OwnableUpgradeable,
    ERC721URIStorageUpgradeable,
    IERC2981Upgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Count of Tokens.
    CountersUpgradeable.Counter internal currentTokenId;

    // Mapping from tokenId to the royalty recipient's address.
    mapping(uint256 => address) internal tokenRoyaltyRecipient;

    bytes32 public whitelistRoot;

    address public zoraERC721TransferHelper;
    address public zoraReserveAuctionFindersEth;

    // Mapping from tokenId to the creators address.
    mapping(uint256 => address) public tokenCreator;

    // Zora Module Manager Address.
    address public zoraModuleManager;

    address internal whitelister;

    event TokenURIUpdated(
        uint256 indexed tokenId,
        string tokenURI,
        address creator
    );

    function initialize(
        string memory _name,
        string memory _symbol,
        bytes32 _whitelistRoot,
        address _zoraERC721TransferHelper,
        address _zoraReserveAuctionFindersEth
    ) public initializer {
        __Ownable_init();
        __ERC721URIStorage_init();
        __ERC721_init(_name, _symbol);
        whitelistRoot = _whitelistRoot;
        zoraERC721TransferHelper = _zoraERC721TransferHelper;
        zoraReserveAuctionFindersEth = _zoraReserveAuctionFindersEth;
    }

    modifier onlyCreator(uint256 _tokenId) {
        require(
            _msgSender() == tokenCreator[_tokenId],
            "Only token creator can call this function"
        );
        _;
    }

    function updateTokenURI(uint256 _tokenId, string memory _uri)
        public
        onlyCreator(_tokenId)
    {
        _setTokenURI(_tokenId, _uri);
        emit TokenURIUpdated(_tokenId, _uri, _msgSender());
    }

    modifier onlyWhitelister() {
        require(
            _msgSender() == owner() || _msgSender() == whitelister,
            "Only whitelisters can call this function"
        );
        _;
    }

    function setWhitelister(address _whitelister) public onlyOwner {
        whitelister = _whitelister;
    }

    function updateWhitelistRoot(bytes32 _whitelistRoot)
        public
        onlyWhitelister
    {
        whitelistRoot = _whitelistRoot;
    }

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _burn(tokenId);
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        uint256 royaltyFee = 100;
        uint256 royaltyPayment = (salePrice * royaltyFee) / 1000;

        return (tokenRoyaltyRecipient[tokenId], royaltyPayment);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}