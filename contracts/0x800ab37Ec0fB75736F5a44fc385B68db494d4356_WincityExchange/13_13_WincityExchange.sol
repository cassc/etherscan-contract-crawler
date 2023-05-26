// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ITransferManagerNFT} from "./interfaces/ITransferManagerNFT.sol";
import {ITransferSelectorNFT} from "./interfaces/ITransferSelectorNFT.sol";

import {OrderTypes} from "./libraries/OrderTypes.sol";
import {SignatureChecker} from "./libraries/SignatureChecker.sol";

/**
 *  __          _______ _   _  _____ _____ _________     __
 *  \ \        / /_   _| \ | |/ ____|_   _|__   __\ \   / /
 *   \ \  /\  / /  | | |  \| | |      | |    | |   \ \_/ /
 *    \ \/  \/ /   | | | . ` | |      | |    | |    \   /
 *     \  /\  /   _| |_| |\  | |____ _| |_   | |     | |
 *      \/  \/   |_____|_| \_|\_____|_____|  |_|     |_|
 *
 * @author Wincity | Antoine Duez
 * @title WincityExchange
 * @notice Allow users to list and buy tokens of the Wincity collections
 */
contract WincityExchange is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    using OrderTypes for OrderTypes.ItemListing;

    // unique identifier for Wincity exchange
    bytes32 public immutable DOMAIN_SEPARATOR;

    // address payable private feeAccount;
    address payable public protocolFeeRecipient;
    uint16 public feePercentage;

    ITransferSelectorNFT public transferSelectorNFT;

    mapping(address => uint256) public userMinOrderNonce;
    // mapping of sellers to a mapping of nonces and their status (true --> executed or cancelled / false --> listed)
    mapping(address => mapping(uint256 => bool))
        private _isUserOrderNonceExecutedOrCancelled;

    // Events
    event CancelMultipleListings(address indexed user, uint256[] orderNonces);
    event NewTransferSelectorNFT(address indexed transferSelectorNFT);

    event CancelAllListings(address seller, uint256 minNonce);

    event ItemBought(
        bytes32 listingHash,
        uint256 listingNonce,
        address indexed seller,
        address indexed buyer,
        address indexed collection,
        uint256 tokenId,
        uint256 price
    );

    /**
     * @notice Constructor
     * @param _protocolFeeRecipient protocol fee recipient
     */
    constructor(address payable _protocolFeeRecipient) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                0xc352ab58b66980d7f9b09ff787fb14db806d3d900ccee4910d82224c04360bd9, // keccak256("WincityExchange")
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
                block.chainid,
                address(this)
            )
        );

        protocolFeeRecipient = _protocolFeeRecipient;
        feePercentage = 500;
    }

    /**
     * @notice Cancel all listings below nonce passed as parameter
     * @param _minNonce minimum user nonce
     */
    function cancelAllItemListingsForSender(uint256 _minNonce) external {
        require(
            _minNonce > userMinOrderNonce[msg.sender],
            "Cancel: Order nonce lower than current"
        );
        require(
            _minNonce < userMinOrderNonce[msg.sender] + 10000,
            "Cancel: Cannot cancel more listings"
        );
        userMinOrderNonce[msg.sender] = _minNonce;

        emit CancelAllListings(msg.sender, _minNonce);
    }

    /**
     * @notice Cancel the listed items using their order nonces
     * @param _orderNonces list of listed items to be canceled
     */
    function cancelMultipleItemListings(
        uint256[] calldata _orderNonces
    ) external {
        require(
            _orderNonces.length > 0,
            "Cancel: Order nonces cannot be empty"
        );

        for (uint256 index = 0; index < _orderNonces.length; index++) {
            require(
                _orderNonces[index] >= userMinOrderNonce[msg.sender],
                "Cancel: Order nonce must be higher than current"
            );
            _isUserOrderNonceExecutedOrCancelled[msg.sender][
                _orderNonces[index]
            ] = true;
        }

        emit CancelMultipleListings(msg.sender, _orderNonces);
    }

    /**
     * @notice Buy a listed item using ETH
     * @param _purchase purchase informations
     * @param _listing listing informations
     */
    function purchaseItemFromListing(
        OrderTypes.ItemPurchase calldata _purchase,
        OrderTypes.ItemListing calldata _listing
    ) external payable nonReentrant {
        require(
            (_listing.isOrderAsk) && (!_purchase.isOrderAsk),
            "Order: Wrong sides"
        );
        // require(
        //     _listing.tokenId == _purchase.tokenId,
        //     "Order: purchase token doesn't match listed item"
        // );
        require(
            msg.sender == _purchase.taker,
            "Order: Taker parameter must be the sender"
        );

        // Check the seller listing
        bytes32 listingHash = _listing.hash();
        _validateListing(_listing, listingHash);

        // Check buyer sent enough ETH
        require(
            msg.value >= _listing.price,
            "Order: Buyer must send enough ETH to match the seller's price"
        );

        // Update listing status (prevents replay)
        _isUserOrderNonceExecutedOrCancelled[_listing.signer][
            _listing.nonce
        ] = true;

        // Execution 1/2 - Transfer NFT to buyer
        _transferNonFungibleToken(
            _listing.collection,
            _listing.signer,
            _purchase.taker,
            _listing.tokenId
        );

        // Execution 2/2 - Transfer funds to seller
        _transferFeesAndFunds(_listing.signer, _listing.price);

        emit ItemBought(
            listingHash,
            _listing.nonce,
            _listing.signer,
            _purchase.taker,
            _listing.collection,
            _listing.tokenId,
            _listing.price
        );
    }

    /**
     * @notice Update transfer selector NFT
     * @param _transferSelectorNFT address of the new transfer selector
     */
    function updateTransferSelectorNFT(
        address _transferSelectorNFT
    ) external onlyOwner {
        require(
            _transferSelectorNFT != address(0),
            "Owner: Transfer selector cannot be null address"
        );
        transferSelectorNFT = ITransferSelectorNFT(_transferSelectorNFT);

        emit NewTransferSelectorNFT(_transferSelectorNFT);
    }

    /**
     * @notice Return the listing nonce status (executed/cancelled or not)
     * @param user address of the user
     * @param nonce nonce of the listing
     * @return bool the status
     */
    function isUserOrderNonceExecutedOrCancelled(
        address user,
        uint256 nonce
    ) public view returns (bool) {
        return _isUserOrderNonceExecutedOrCancelled[user][nonce];
    }

    /**
     * @notice Tranfer fees to feeRecipient and funds to seller
     * @param _to address of the seller
     * @param _amount total funds amount to be computed
     */
    function _transferFeesAndFunds(
        address payable _to,
        uint256 _amount
    ) internal {
        uint256 finalSellerAmount = _amount;

        // Execution 1/2 - Protocol fee
        {
            uint256 protocolFeeAmount = _calculateProtocolFee(_amount);

            if (
                (protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)
            ) {
                Address.sendValue(protocolFeeRecipient, protocolFeeAmount);
                finalSellerAmount -= protocolFeeAmount;
            }
        }

        // Execution 2/2 - Seller payout
        Address.sendValue(_to, finalSellerAmount);
    }

    /**
     * @notice Update the fee recipient with a new address
     * @param _newRecipient address of the new fee recipient
     */
    function updateFeeRecipient(
        address payable _newRecipient
    ) external onlyOwner {
        protocolFeeRecipient = _newRecipient;
    }

    /**
     * @notice Update the fee percentage of the exchange
     * @param _newFeePercentage new percentage
     * @dev As we treat with unsigned int, values must be without floating point such as 320 stands for 3.20%
     */
    function updateFeePercentage(uint16 _newFeePercentage) external onlyOwner {
        require(
            _newFeePercentage <= 500,
            "Owner: Fee percentage must be comprised between 0 and 500"
        );

        feePercentage = _newFeePercentage;
    }

    /**
     * @notice Transfer NFT
     * @param _collection address of the token collection
     * @param _from address of the seller
     * @param _to address of the buyer
     * @param _tokenId id of the token
     */
    function _transferNonFungibleToken(
        address _collection,
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        address transferManager = transferSelectorNFT
            .transferManagerSelectorForCollection(_collection);

        require(
            transferManager != address(0),
            "Transfer: This collection isn't supported by Wincity Exchange"
        );

        ITransferManagerNFT(transferManager).transferNFT(
            _collection,
            _from,
            _to,
            _tokenId
        );
    }

    function _calculateProtocolFee(
        uint256 _amount
    ) public view returns (uint256) {
        return ((_amount * feePercentage) / 10000);
    }

    /**
     * @notice Verify that the listing is valid
     * @param _listing listing informations
     * @param _listingHash computed hash for the listing
     */
    function _validateListing(
        OrderTypes.ItemListing calldata _listing,
        bytes32 _listingHash
    ) internal view {
        // Verify that the listing nonce is still valid
        require(
            (
                !_isUserOrderNonceExecutedOrCancelled[_listing.signer][
                    _listing.nonce
                ]
            ) && (_listing.nonce >= userMinOrderNonce[_listing.signer]),
            "Order: Listing expired"
        );

        // Verify the signer is not address(0)
        require(_listing.signer != address(0), "Order: Invalid signer");

        // Verify the amount is not 0
        require(_listing.price > 0, "Order: Amount cannot be 0");

        // Verify the validity of the signature
        require(
            SignatureChecker.verify(
                _listingHash,
                _listing.signer,
                _listing.v,
                _listing.r,
                _listing.s,
                DOMAIN_SEPARATOR
            ),
            "Order: Signature is invalid"
        );
    }
}