// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PlatformOwnable.sol";
import "./BalenseaReferral.sol";
import "./IDistribution.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract BalenseaMarketplace is EIP712, Ownable, PlatformOwnable {
    string private constant SIGNING_DOMAIN = "Marketplace_Signature";
    string private constant SIGNATURE_VERSION = "1";
    BalenseaReferral private referralSystem;

    // NFT contract address => creator address
    mapping(address => address) public creators;

    event AddCollection(address nftAddress, address creator);
    event RemoveCollection(address nftAddress);
    event BuyOrder(
        address buyer,
        address seller,
        address collection,
        uint256 tokenId
    );
    event InitialDistribution(
        address owner,
        uint256 commissionAmount,
        address creator,
        uint256 royaltyAmount,
        address master,
        uint256 masterAmount,
        address l1,
        uint256 l1Amount,
        address l2,
        uint256 l2Amount,
        address seller,
        uint256 sellerAmount
    );
    event KOLDistribution(
        address owner,
        uint256 commissionAmount,
        address creator,
        uint256 royaltyAmount,
        address master,
        uint256 masterAmount,
        address kol,
        uint256 kolAmount,
        address seller,
        uint256 sellerAmount
    );
    event SubDistribution(
        address owner,
        uint256 commissionAmount,
        address seller,
        uint256 sellerAmount
    );

    modifier validateOrder(List calldata _listing) {
        require(_listing.collection != address(0), "invalid nft address");
        require(
            creators[_listing.collection] != address(0),
            "nft not support by marketplace"
        );
        address signer = _verify(_listing);
        require(signer == _listing.owner, "signature signed by wrong owner");
        require(
            IERC721(_listing.collection).ownerOf(_listing.tokenId) == signer,
            "tokenId does not belongs to sender"
        );
        require(
            IERC721(_listing.collection).isApprovedForAll(
                _listing.owner,
                address(this)
            ),
            "owner does not approve operator"
        );
        require(
            IERC20(_listing.paymentToken).allowance(
                _msgSender(),
                address(this)
            ) >= _listing.price,
            "insufficient allowance"
        );
        require(
            IERC20(_listing.paymentToken).balanceOf(_msgSender()) >=
                _listing.price,
            "insufficient fund"
        );
        _;
    }

    struct List {
        string orderId;
        address collection;
        uint256 tokenId;
        address owner;
        uint256 price;
        address paymentToken;
        bool isKOL;
        bool isInitial;
        bytes signature;
    }

    constructor(address _platformOwner, address _referralSystem)
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
        PlatformOwnable(_platformOwner)
    {
        require(
            _referralSystem != address(0),
            "invalid referral system contract"
        );
        referralSystem = BalenseaReferral(_referralSystem);
    }

    // register NFT collection address to get supported
    function addCollection(address _nft, address _creator)
        external
        onlyPlatformOwner
    {
        require(_nft != address(0), "invalid nft address");
        require(_creator != address(0), "invalid creator address");

        creators[_nft] = _creator;

        emit AddCollection(_nft, _creator);
    }

    // runregister a NFT colelction
    function removeCollection(address _nft) external onlyPlatformOwner {
        require(_nft != address(0), "invalid nft address");

        delete creators[_nft];

        emit RemoveCollection(_nft);
    }

    // marketplace buy nft
    function buyNFT(List calldata _listing) external validateOrder(_listing) {
        // Case 1 : KOL initial
        if (_listing.isKOL) {
            _kolDistribution(_listing);
        }

        // Case 2 : Initial sale (normal buyer)
        if (_listing.isInitial && !_listing.isKOL) {
            _initialDistribution(_listing);
        }

        // Case 3 : Sub sale
        if (!_listing.isInitial) {
            _subDistribution(_listing);
        }

        // transfer NFT ownership
        IERC721(_listing.collection).safeTransferFrom(
            _listing.owner,
            _msgSender(),
            _listing.tokenId
        );

        emit BuyOrder(
            _msgSender(),
            _listing.owner,
            _listing.collection,
            _listing.tokenId
        );
    }

    function _kolDistribution(List calldata _listing) internal {
        IDistribution.KOL memory kol = referralSystem.getKolDistributions(
            creators[_listing.collection],
            _msgSender(),
            _listing.price
        );

        address token = _listing.paymentToken;

        // distribute to platform owner
        IERC20(token).transferFrom(
            _msgSender(),
            kol.owner,
            kol.commissionPayment
        );

        // distribute to creator
        IERC20(token).transferFrom(
            _msgSender(),
            kol.creator,
            kol.royaltyPayment + kol.sellerPayment
        );

        // distribute to master
        IERC20(token).transferFrom(_msgSender(), kol.master, kol.masterPayment);

        // distribute to kol
        IERC20(token).transferFrom(_msgSender(), kol.kol, kol.kolPayment);

        emit KOLDistribution(
            kol.owner,
            kol.commissionPayment,
            kol.creator,
            kol.royaltyPayment,
            kol.master,
            kol.masterPayment,
            kol.kol,
            kol.kolPayment,
            kol.seller,
            kol.sellerPayment
        );
    }

    function _initialDistribution(List calldata _listing) internal {
        IDistribution.Initial memory initial = referralSystem
            .getInitialDistributions(
                creators[_listing.collection],
                _msgSender(),
                _listing.price
            );

        address token = _listing.paymentToken;

        // distribute to platform owner
        IERC20(token).transferFrom(
            _msgSender(),
            initial.owner,
            initial.commissionPayment
        );
        // distribute to creator
        IERC20(token).transferFrom(
            _msgSender(),
            initial.creator,
            initial.royaltyPayment + initial.sellerPayment
        );

        // distribute to master
        IERC20(token).transferFrom(
            _msgSender(),
            initial.master,
            initial.masterPayment
        );

        // distribute to layer 1 referral
        if (initial.l1 != address(0) && initial.l1Payment > 0) {
            IERC20(token).transferFrom(
                _msgSender(),
                initial.l1,
                initial.l1Payment
            );
        }

        // distribute to layer 2 referral
        if (initial.l2 != address(0) && initial.l2Payment > 0) {
            IERC20(token).transferFrom(
                _msgSender(),
                initial.l2,
                initial.l2Payment
            );
        }

        emit InitialDistribution(
            initial.owner,
            initial.commissionPayment,
            initial.creator,
            initial.royaltyPayment,
            initial.master,
            initial.masterPayment,
            initial.l1,
            initial.l1Payment,
            initial.l2,
            initial.l2Payment,
            initial.seller,
            initial.sellerPayment
        );
    }

    function _subDistribution(List calldata _listing) internal {
        IDistribution.Sub memory sub = referralSystem.getSubDistributions(
            _listing.owner,
            _msgSender(),
            _listing.price
        );

        address token = _listing.paymentToken;

        // distribute to platform owner
        IERC20(token).transferFrom(
            _msgSender(),
            sub.owner,
            sub.commissionPayment
        );

        // transfer remaining to seller
        IERC20(token).transferFrom(_msgSender(), sub.seller, sub.sellerPayment);

        emit SubDistribution(
            sub.owner,
            sub.commissionPayment,
            sub.seller,
            sub.sellerPayment
        );
    }

    function _verify(List calldata _list) internal view returns (address) {
        bytes32 digest = _hash(_list);
        return ECDSA.recover(digest, _list.signature);
    }

    function _hash(List calldata _list) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "List(string orderId,address collection,uint256 tokenId,address owner,uint256 price,address paymentToken,bool isKOL,bool isInitial)"
                        ),
                        keccak256(abi.encodePacked(_list.orderId)),
                        _list.collection,
                        _list.tokenId,
                        _list.owner,
                        _list.price,
                        _list.paymentToken,
                        _list.isKOL,
                        _list.isInitial
                    )
                )
            );
    }
}