// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../BaseCollection.sol";
import "../Redeemables.sol";

contract TokenCollection is
    Redeemables,
    BaseCollection,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address treasury_,
        address royalty_,
        uint96 royaltyFee_
    ) public override initializer {
        __ERC721_init(name_, symbol_);
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC721Burnable_init();

        __BaseCollection_init(treasury_, royalty_, royaltyFee_);
        _tokenIdCounter.increment();
    }

    function mint(
        address to,
        uint256 quantity,
        string memory uri
    ) external onlyOwner {
        _mint(to, quantity, uri);
    }

    function createRedeemable(
        string memory uri,
        uint256 price,
        uint256 maxQuantity,
        uint256 maxPerWallet,
        uint256 maxPerMint
    ) external onlyOwner {
        _createRedeemable(uri, price, maxQuantity, maxPerWallet, maxPerMint);
    }

    function setMerkleRoot(uint256 redeemableId, bytes32 newRoot)
        external
        onlyOwner
    {
        _setMerkleRoot(redeemableId, newRoot);
    }

    function setTokenURI(uint256 tokenId, string memory newUri)
        external
        onlyOwner
    {
        _setTokenURI(tokenId, newUri);
    }

    function invalidate(uint256 redeemableId) external onlyOwner {
        _invalidate(redeemableId);
    }

    function revoke(uint256 redeemableId) external onlyOwner {
        _revoke(redeemableId);
    }

    function redeem(
        uint256 redeemableId,
        uint256 quantity,
        bytes calldata signature,
        bytes32[] calldata proof
    ) external payable {
        Redeemable memory redeemable = redeemableAt(redeemableId);

        unchecked {
            _totalRevenue = _totalRevenue.add(msg.value);
        }
        _niftyKit.addFees(msg.value);
        _mint(_msgSender(), quantity, redeemable.tokenURI);
        _redeem(redeemableId, quantity, signature, owner(), proof);
    }

    function _mint(
        address to,
        uint256 quantity,
        string memory uri
    ) internal {
        for (uint256 i = 0; i < quantity; ) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, uri);
            unchecked {
                i++;
            }
        }
    }

    // The following functions are overrides required by Solidity.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        ERC721URIStorageUpgradeable._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, BaseCollection)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}