// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "./interfaces/IZuna.sol";
import "./interfaces/IMarket.sol";
import "./libraries/Shared.sol";

contract Zuna is
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable,
    OwnableUpgradeable,
    EIP712Upgradeable,
    IZuna
{
    struct NFTVoucher {
        uint256 tokenId;
        uint256 royaltyFee; // 3 decimal places, 1000 = 1%, 100 = 0.1%
        uint256 collectionId;
        string tokenUri;
        bytes signature;
    }

    string private constant SIGNING_DOMAIN = "Zunaverse";
    string private constant SIGNATURE_VERSION = "1";

    mapping(uint256 => address) private _creators;
    mapping(uint256 => uint256) private _royaltyFees; // 3 decimal places
    mapping(uint256 => uint256) public collectionIds;

    address public marketAddress;

    event AddedToCollection(uint256 collectionId, uint256 tokenId);

    function initialize() public initializer {
        __ERC721_init("Zunaverse", "ZUNA");
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __Ownable_init();
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
    }

    function lazyBuyMint(
        uint256 tokenId,
        NFTVoucher calldata voucher,
        Shared.Offer calldata offer
    ) external {
        _mint(tokenId, voucher);

        IMarket(marketAddress).buy(_msgSender(), offer);
    }

    function lazyAcceptOfferMint(
        uint256 tokenId,
        NFTVoucher calldata voucher,
        Shared.Offer calldata offer
    ) external {
        _mint(tokenId, voucher);

        IMarket(marketAddress).acceptOffer(_msgSender(), offer);
    }

    function bulkMint(
        uint256[] calldata tokenIds,
        uint256[] calldata royaltyFees,
        string[] calldata tokenUris,
        uint256 collectionId,
        address[] calldata erc20Addresses,
        uint256[] calldata amounts
    ) external {
        require(
            tokenIds.length == royaltyFees.length &&
                tokenIds.length == tokenUris.length &&
                tokenIds.length == erc20Addresses.length &&
                tokenIds.length == amounts.length,
            "Invalid data length"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(!_exists(tokenIds[i]), "Existing tokenId");
            require(royaltyFees[i] < 1000 * 100, "Royalty Fee is invalid");

            _creators[tokenIds[i]] = msg.sender;
            _royaltyFees[tokenIds[i]] = royaltyFees[i];
            collectionIds[tokenIds[i]] = collectionId;
            _safeMint(msg.sender, tokenIds[i]);
            _setTokenURI(tokenIds[i], tokenUris[i]);
        }

        if (!isApprovedForAll(msg.sender, marketAddress)) {
            setApprovalForAll(marketAddress, true);
        }
        IMarket(marketAddress).bulkPriceSet(tokenIds, erc20Addresses, amounts);
    }

    function _mint(uint256 tokenId, NFTVoucher calldata voucher) private {
        require(!_exists(tokenId), "Existing tokenId");
        require(voucher.royaltyFee < 1000 * 100, "Royalty Fee is invalid");

        address minter = _verify(voucher);
        _creators[tokenId] = minter;
        _royaltyFees[tokenId] = voucher.royaltyFee;
        collectionIds[tokenId] = voucher.collectionId;
        _safeMint(minter, tokenId);
        _setTokenURI(tokenId, voucher.tokenUri);
    }

    function setMarketAddress(address _marketAddress) external onlyOwner {
        require(_marketAddress != address(0));
        marketAddress = _marketAddress;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    function getTokenInfo(uint256 tokenId)
        external
        view
        override
        returns (address, uint256)
    {
        return (_creators[tokenId], _royaltyFees[tokenId]);
    }

    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher to hash.
    function _hash(NFTVoucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NFTVoucher(uint256 tokenId,uint256 royaltyFee,uint256 collectionId,string tokenUri)"
                        ),
                        voucher.tokenId,
                        voucher.royaltyFee,
                        voucher.collectionId,
                        keccak256(bytes(voucher.tokenUri))
                    )
                )
            );
    }

    /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An NFTVoucher describing an unminted NFT.
    function _verify(NFTVoucher calldata voucher)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hash(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        ERC721URIStorageUpgradeable._burn(tokenId);
    }

    function bulkBurn(uint256[] calldata tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            burn(tokenIds[i]);
        }
    }

    function burn(uint256 tokenId) public override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Caller is not owner nor approved"
        );
        _burn(tokenId);
    }
}