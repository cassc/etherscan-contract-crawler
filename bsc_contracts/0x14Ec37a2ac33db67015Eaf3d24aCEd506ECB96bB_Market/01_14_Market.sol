// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IMarket.sol";
import "./interfaces/IZuna.sol";
import "./libraries/Shared.sol";

contract Market is
    IMarket,
    Initializable,
    OwnableUpgradeable,
    EIP712Upgradeable
{
    string private constant SIGNING_DOMAIN = "ZunaverseMarket";
    string private constant SIGNATURE_VERSION = "1";

    address public zunaAddress;

    address public feeAddress;
    uint256 public fee; // 3 decimals: 1 = 0.001%

    mapping(bytes => bool) private _signatures;

    mapping(address => bool) private whitelists;

    address public buybackAddress;
    uint256 public buybackFee; // 3 decimals: 1 = 0.001%

    mapping(uint256 => Shared.Offer) public prices;

    modifier onlyExistingToken(uint256 tokenId) {
        require(
            IERC721Upgradeable(zunaAddress).ownerOf(tokenId) != address(0),
            "Non-existing token"
        );
        _;
    }

    modifier onlyNewSignature(bytes memory signature) {
        require(!_signatures[signature], "Expired signature");
        _;
        _signatures[signature] = true;
    }

    modifier onlyTokenOwnerOrApproved(address caller, uint256 tokenId) {
        IERC721Upgradeable tokenContract = IERC721Upgradeable(zunaAddress);
        address tokenOwner = tokenContract.ownerOf(tokenId);

        require(
            tokenContract.getApproved(tokenId) == caller ||
                tokenContract.isApprovedForAll(tokenOwner, caller) ||
                tokenOwner == caller,
            "Only approved or owner"
        );
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
    }

    function setZunaAddress(address _zunaAddress) external onlyOwner {
        require(_zunaAddress != address(0), "Invalid address");
        zunaAddress = _zunaAddress;
    }

    function setFee(
        uint256 _fee,
        address _feeAddress,
        uint256 _buybackFee,
        address _buybackAddress
    ) external onlyOwner {
        require(
            _feeAddress != address(0) && _buybackAddress != address(0),
            "Invalid address"
        );
        fee = _fee;
        feeAddress = _feeAddress;
        buybackFee = _buybackFee;
        buybackAddress = _buybackAddress;
    }

    function setWhitelist(address user, bool flag) external onlyOwner {
        whitelists[user] = flag;
    }

    function bulkPriceSet(Shared.Offer[] calldata _prices) external override {
        require(_msgSender() == zunaAddress, "Invalid caller");

        uint256[] memory tokenIds = new uint256[](_prices.length);

        for (uint256 i = 0; i < _prices.length; i++) {
            require(
                prices[_prices[i].tokenId].amount == 0,
                "Only for new token"
            );

            if (_prices[i].amount == 0) {
                continue;
            }
            prices[_prices[i].tokenId] = _prices[i];
            tokenIds[i] = _prices[i].tokenId;
        }
        emit BulkPriceSet(tokenIds);
    }

    function removePrice(uint256 tokenId)
        external
        override
        onlyExistingToken(tokenId)
    {
        address tokenOwner = IERC721Upgradeable(zunaAddress).ownerOf(tokenId);

        require(_msgSender() == tokenOwner, "Should be token owner");
        require(prices[tokenId].amount > 0, "Price already not set");

        delete prices[tokenId];

        emit RemovePrice(tokenId);
    }

    function buyOnChain(uint256 tokenId)
        external
        override
        onlyExistingToken(tokenId)
    {
        address buyer = _msgSender();
        address tokenOwner = IERC721Upgradeable(zunaAddress).ownerOf(tokenId);

        require(buyer != tokenOwner, "Cannot buy your ownr token");

        Shared.Offer memory price = prices[tokenId];

        require(price.amount > 0, "Price not set");

        _executeTrade(
            tokenOwner,
            buyer,
            price.tokenId,
            price.amount,
            price.erc20Address
        );
        delete prices[tokenId];

        emit Bought(price.tokenId, tokenOwner, buyer, price);
    }

    function buy(address buyer, Shared.Offer calldata offer)
        external
        override
        onlyExistingToken(offer.tokenId)
        onlyNewSignature(offer.signature)
    {
        require(prices[offer.tokenId].amount == 0, "Invalid Call");
        require(
            buyer == _msgSender() || _msgSender() == zunaAddress,
            "Invalid buyer"
        );

        address seller = _verifyOffer(offer);
        address owner = IERC721Upgradeable(zunaAddress).ownerOf(offer.tokenId);

        require(owner == seller, "Invalid signature");
        require(offer.amount > 0, "Amount should not be 0");

        _executeTrade(
            seller,
            buyer,
            offer.tokenId,
            offer.amount,
            offer.erc20Address
        );

        delete prices[offer.tokenId];

        emit Bought(offer.tokenId, seller, buyer, offer);
    }

    function acceptOffer(address seller, Shared.Offer calldata offer)
        external
        override
        onlyExistingToken(offer.tokenId)
        onlyNewSignature(offer.signature)
    {
        address tokenOwner = IERC721Upgradeable(zunaAddress).ownerOf(
            offer.tokenId
        );
        require(
            seller == tokenOwner &&
                (tokenOwner == _msgSender() || zunaAddress == _msgSender()),
            "Invalid buyer"
        );
        require(offer.amount > 0, "Amount should not be 0");

        address buyer = _verifyOffer(offer);

        _executeTrade(
            seller,
            buyer,
            offer.tokenId,
            offer.amount,
            offer.erc20Address
        );

        delete prices[offer.tokenId];

        emit OfferAccepted(offer.tokenId, seller, buyer, offer);
    }

    function _executeTrade(
        address seller,
        address buyer,
        uint256 tokenId,
        uint256 amount,
        address erc20Address
    ) internal {
        (
            uint256 amountForSeller,
            uint256 feeAmount,
            uint256 buybackAmount,
            uint256 amountForCreator,
            address creator
        ) = getFeeAmounts(seller, amount, tokenId);

        IERC20 erc20 = IERC20(erc20Address);

        if (amountForCreator > 0) {
            erc20.transferFrom(buyer, creator, amountForCreator);
        }

        if (feeAmount > 0) {
            erc20.transferFrom(buyer, feeAddress, feeAmount);
        }

        if (buybackAmount > 0) {
            erc20.transferFrom(buyer, buybackAddress, buybackAmount);
        }
        erc20.transferFrom(buyer, seller, amountForSeller);

        IERC721Upgradeable(zunaAddress).safeTransferFrom(
            seller,
            buyer,
            tokenId
        );
    }

    function getFeeAmounts(
        address seller,
        uint256 amount,
        uint256 tokenId
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address
        )
    {
        (address creator, uint256 royaltyFee) = IZuna(zunaAddress).getTokenInfo(
            tokenId
        );
        uint256 royaltyFeeAmount = (amount * royaltyFee) / 1000 / 100;
        uint256 platformFee = (amount * fee) / 1000 / 100;
        uint256 buybackAmount = (amount * buybackFee) / 1000 / 100;

        if (whitelists[seller]) {
            platformFee = 0;
            buybackAmount = 0;
        }
        uint256 receiveAmount = amount -
            royaltyFeeAmount -
            platformFee -
            buybackAmount;

        return (
            receiveAmount,
            platformFee,
            buybackAmount,
            royaltyFeeAmount,
            creator
        );
    }

    function _verifyOffer(Shared.Offer calldata offer)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "Offer(uint256 tokenId,address erc20Address,uint256 amount,uint256 createdAt)"
                    ),
                    offer.tokenId,
                    offer.erc20Address,
                    offer.amount,
                    offer.createdAt
                )
            )
        );
        return ECDSAUpgradeable.recover(digest, offer.signature);
    }
}