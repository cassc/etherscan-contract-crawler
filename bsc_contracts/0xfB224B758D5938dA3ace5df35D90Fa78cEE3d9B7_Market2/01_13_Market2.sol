// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IMarket2.sol";

contract Market2 is
    IMarket2,
    Initializable,
    OwnableUpgradeable,
    EIP712Upgradeable
{
    string private constant SIGNING_DOMAIN = "ZunaverseMarket";
    string private constant SIGNATURE_VERSION = "1";

    address public feeAddress;
    uint256 public fee; // 3 decimals: 1 = 0.001%

    mapping(bytes => bool) private _signatures;

    mapping(address => bool) private whitelists;

    address public buybackAddress;
    uint256 public buybackFee; // 3 decimals: 1 = 0.001%

    modifier onlyExistingToken(uint256 tokenId, address tokenAddress) {
        require(
            IERC721Upgradeable(tokenAddress).ownerOf(tokenId) != address(0),
            "Non-existing token"
        );
        _;
    }

    modifier onlyNewSignature(bytes memory signature) {
        require(!_signatures[signature], "Expired signature");
        _;
        _signatures[signature] = true;
    }

    modifier onlyTokenOwnerOrApproved(
        address caller,
        address tokenAddress,
        uint256 tokenId
    ) {
        IERC721Upgradeable tokenContract = IERC721Upgradeable(tokenAddress);
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

    function buy(address buyer, Offer calldata offer)
        external
        override
        onlyExistingToken(offer.tokenId, offer.tokenAddress)
        onlyNewSignature(offer.signature)
    {
        require(buyer == _msgSender(), "Invalid buyer");

        address seller = _verifyOffer(offer);
        address owner = IERC721Upgradeable(offer.tokenAddress).ownerOf(
            offer.tokenId
        );

        require(owner == seller, "Invalid signature");
        require(offer.amount > 0, "Amount should not be 0");

        _executeTrade(
            seller,
            buyer,
            offer.tokenId,
            offer.tokenAddress,
            offer.amount,
            offer.erc20Address
        );
        emit Bought(offer.tokenId, offer.tokenAddress, seller, buyer, offer);
    }

    function acceptOffer(address seller, Offer calldata offer)
        external
        override
        onlyExistingToken(offer.tokenId, offer.tokenAddress)
        onlyNewSignature(offer.signature)
    {
        address tokenOwner = IERC721Upgradeable(offer.tokenAddress).ownerOf(
            offer.tokenId
        );
        require(
            seller == tokenOwner && tokenOwner == _msgSender(),
            "Invalid seller"
        );
        require(offer.amount > 0, "Amount should not be 0");

        address buyer = _verifyOffer(offer);

        _executeTrade(
            seller,
            buyer,
            offer.tokenId,
            offer.tokenAddress,
            offer.amount,
            offer.erc20Address
        );

        emit OfferAccepted(
            offer.tokenId,
            offer.tokenAddress,
            seller,
            buyer,
            offer
        );
    }

    function _executeTrade(
        address seller,
        address buyer,
        uint256 tokenId,
        address tokenAddress,
        uint256 amount,
        address erc20Address
    ) internal {
        (
            uint256 amountForSeller,
            uint256 feeAmount,
            uint256 buybackAmount
        ) = getFeeAmounts(seller, amount);

        IERC20 erc20 = IERC20(erc20Address);

        if (feeAmount > 0) {
            erc20.transferFrom(buyer, feeAddress, feeAmount);
        }

        if (buybackAmount > 0) {
            erc20.transferFrom(buyer, buybackAddress, buybackAmount);
        }
        erc20.transferFrom(buyer, seller, amountForSeller);

        IERC721Upgradeable(tokenAddress).safeTransferFrom(
            seller,
            buyer,
            tokenId
        );
    }

    function getFeeAmounts(address seller, uint256 amount)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 platformFee = (amount * fee) / 1000 / 100;
        uint256 buybackAmount = (amount * buybackFee) / 1000 / 100;

        if (whitelists[seller]) {
            platformFee = 0;
            buybackAmount = 0;
        }
        uint256 receiveAmount = amount - platformFee - buybackAmount;

        return (receiveAmount, platformFee, buybackAmount);
    }

    function _verifyOffer(Offer calldata offer)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "Offer(uint256 tokenId,address tokenAddress,address erc20Address,uint256 amount,uint256 createdAt)"
                    ),
                    offer.tokenId,
                    offer.tokenAddress,
                    offer.erc20Address,
                    offer.amount,
                    offer.createdAt
                )
            )
        );
        return ECDSAUpgradeable.recover(digest, offer.signature);
    }
}