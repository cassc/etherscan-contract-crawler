// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

interface IERC2981Upgradeable is IERC721Upgradeable {
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

contract Marketplace is
    Initializable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    EIP712Upgradeable
{
    /// @notice EIP712 Domain Name.
    string public domainName;

    /// @notice EIP712 Domain Version.
    string public domainVersion;

    /// @notice Flag to enable/disable royalty payments on secondary sales.
    bool public areRoyaltiesPaid;

    /// @notice Role given to address whose signature is required for a nft sale.
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    /// @dev Order typehash used in EIP712.
    bytes32 private constant _ORDER_TYPEHASH =
        keccak256(
            "Order(address seller,address nftAddress,uint256 nftId,uint256 expiryTime,address[] paymentTokenAddresses,uint256[] paymentTokenAmounts,string voucherCode)"
        );

    struct Order {
        address seller;
        address nftAddress;
        uint256 nftId;
        uint256 expiryTime;
        address[] paymentTokenAddresses;
        uint256[] paymentTokenAmounts;
        string voucherCode;
    }

    /// @notice Mapping to validate payment tokens to be used for buying nfts.
    /// @dev Use zero address to validate and use ether payments.
    mapping(address => bool) public isValidPaymentToken;

    /// @notice Mapping to validate nft collections to be sold by this contract.
    mapping(address => bool) public isNftSupportedForSale;

    /// @notice Mapping to stop double-spending of used signatures.
    mapping(bytes => bool) public isSignatureUsed;

    /// @notice Mapping to stop spending of signatures generated for cancelled listings.
    mapping(bytes => bool) public isSignatureCancelled;

    /// @notice Payment wallet address.
    address public paymentWallet;

    event RoyaltyPaymentsEnabled(address indexed by, uint256 timestamp);

    event RoyaltyPaymentsDisabled(address indexed by, uint256 timestamp);

    event PaymentTokensAdded(address indexed by, address[] tokenAddresses);

    event PaymentTokensRemoved(address indexed by, address[] tokenAddresses);

    event NftSaleSupportAdded(address indexed by, address[] nftAddresses);

    event NftSaleSupportRemoved(address indexed by, address[] nftAddresses);

    event NftSold(
        address indexed paymentTokenAddress,
        address indexed nftAddress,
        address indexed seller,
        address buyer,
        uint256 nftId,
        uint256 nftDbPrimaryId,
        uint256 paymentAmount,
        bytes signatureUsed,
        address[] paymentTokens,
        uint256[] paymentTokenAmounts,
        string voucherCodeUsed,
        uint256 timestamp
    );

    event NftListingRemoved(
        address indexed by,
        address indexed nftAddress,
        uint256 indexed nftId,
        uint256 nftDbPrimaryId,
        bytes signatureCancelled,
        uint256 timestamp
    );

    event PaymentWalletUpdated(
        address indexed by,
        address indexed paymentWallet,
        uint256 timestamp
    );


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract after deployment.
     * @param _defaultAdminAddress Address to be given the DEFAULT_ADMIN_ROLE.
     * @param _signerAddress Address to be given the SIGNER_ROLE
     * @param _paymentTokens Array of addresses to be supported as payment tokens for nft sale.
     * @param _nftAddresses Array of nft collection addresses to be sold on this marketplace.
     * @param _domainName Domain Name to be used for EIP712 signatures.
     * @param _domainVersion Domain Version to be used for EIP712 signatures.
     * @param _payRoyalties Boolean, true: royalties paid, false: royalties not paid.
     */
    function initialize(
        address _defaultAdminAddress,
        address _signerAddress,
        address[] calldata _paymentTokens,
        address[] calldata _nftAddresses,
        string memory _domainName,
        string memory _domainVersion,
        bool _payRoyalties
    ) external initializer {
        require(
            _defaultAdminAddress != address(0),
            "Zero address cannot be admin!"
        );
        require(_signerAddress != address(0), "Zero address cannot be signer!");

        __Ownable_init();
        __AccessControl_init();
        __EIP712_init(_domainName, _domainVersion);
        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdminAddress);
        _grantRole(SIGNER_ROLE, _signerAddress);
        areRoyaltiesPaid = _payRoyalties;
        domainName = _domainName;
        domainVersion = _domainVersion;

        for (uint256 i; i < _paymentTokens.length; ) {
            isValidPaymentToken[_paymentTokens[i]] = true;
            unchecked {
                ++i;
            }
        }

        for (uint256 i; i < _nftAddresses.length; ) {
            isNftSupportedForSale[_nftAddresses[i]] = true;
            unchecked {
                ++i;
            }
        }

        if (_paymentTokens.length > 0) {
            emit PaymentTokensAdded(msg.sender, _paymentTokens);
        }
        if (_nftAddresses.length > 0) {
            emit NftSaleSupportAdded(msg.sender, _nftAddresses);
        }
        if (_payRoyalties) {
            emit RoyaltyPaymentsEnabled(msg.sender, block.timestamp);
        }
    }

    /**
     * @notice Function for owner to enable royalty payments on secondary sales.
     */
    function enableRoyaltyPayments() external onlyOwner {
        areRoyaltiesPaid = true;
        emit RoyaltyPaymentsEnabled(msg.sender, block.timestamp);
    }

    /**
     * @notice Function for owner to disable royalty payments on secondary sales.
     */
    function disableRoyaltyPayments() external onlyOwner {
        areRoyaltiesPaid = false;
        emit RoyaltyPaymentsDisabled(msg.sender, block.timestamp);
    }

    /**
     * @notice Function for owner to add new payment tokens.
     * @param _tokenAddresses Array of addresses to be supported for payments on nft sales.
     */
    function addPaymentTokens(
        address[] calldata _tokenAddresses
    ) external onlyOwner {
        for (uint256 i; i < _tokenAddresses.length; ) {
            isValidPaymentToken[_tokenAddresses[i]] = true;
            unchecked {
                ++i;
            }
        }
        emit PaymentTokensAdded(msg.sender, _tokenAddresses);
    }

    /**
     * @notice Function for owner to remove payment tokens.
     * @param _tokenAddresses Array of addresses to be removed from payments on nft sales.
     */
    function removePaymentTokens(
        address[] calldata _tokenAddresses
    ) external onlyOwner {
        for (uint256 i; i < _tokenAddresses.length; ) {
            isValidPaymentToken[_tokenAddresses[i]] = false;
            unchecked {
                ++i;
            }
        }
        emit PaymentTokensRemoved(msg.sender, _tokenAddresses);
    }

    /**
     * @notice Function for owner to add sale support for nft collections.
     * @param _nftAddresses Array of nft addresses to be supported for sale on marketplace.
     */
    function addNftSaleSupport(
        address[] calldata _nftAddresses
    ) external onlyOwner {
        for (uint256 i; i < _nftAddresses.length; ) {
            isNftSupportedForSale[_nftAddresses[i]] = true;
            unchecked {
                ++i;
            }
        }
        emit NftSaleSupportAdded(msg.sender, _nftAddresses);
    }


    /**
     * @notice Function for owner to update payment wallet, that receives funds from primary sales.
     * @param _paymentWallet Address of new payment wallet.
     */
    function updatePaymentWallet(address _paymentWallet) external onlyOwner {
        require(
            _paymentWallet != address(0),
            "Zero address cannot be payment wallet!"
        );
        paymentWallet = _paymentWallet;
        emit PaymentWalletUpdated(
            msg.sender,
            _paymentWallet,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner to remove sale support for nft collections.
     * @param _nftAddresses Array of nft addresses for which to remove sale support on marketplace.
     */
    function removeNftSaleSupport(
        address[] calldata _nftAddresses
    ) external onlyOwner {
        for (uint256 i; i < _nftAddresses.length; ) {
            isNftSupportedForSale[_nftAddresses[i]] = false;
            unchecked {
                ++i;
            }
        }
        emit NftSaleSupportRemoved(msg.sender, _nftAddresses);
    }

    /**
     * @notice Function for cancelling order signature when seller removes nft listing.
     * @param _order Order struct object, having the order details for which the seller created EIP-712 signature.
     * @param _signature EIP-712 signature generated by nft seller.
     * @param _nftDbPrimaryId Primary Id of nft from db, used in event response.
     */
    function removeNftListing(
        Order memory _order,
        bytes memory _signature,
        uint256 _nftDbPrimaryId
    ) external {
        require(msg.sender == _order.seller, "Not the seller!");
        address signer = _getSigner(_order, _signature);
        require(
            msg.sender == signer || hasRole(SIGNER_ROLE, signer),
            "Invalid signer!"
        );
        isSignatureCancelled[_signature] = true;
        emit NftListingRemoved(
            msg.sender,
            _order.nftAddress,
            _order.nftId,
            _nftDbPrimaryId,
            _signature,
            block.timestamp
        );
    }

    /**
     * @notice Function for buying nft with signature from the nft seller.
     * @param _order Order struct object, having the order details for which the seller created EIP-712 signature.
     * @param _signature EIP-712 signature generated by nft seller.
     * @param _paymentTokenIndex Index of address in paymentTokens array to use for payment.
     * @param _nftDbPrimaryId Primary Id of nft from db, used in event response.
     */
    function buyNFT(
        Order memory _order,
        bytes memory _signature,
        uint256 _paymentTokenIndex,
        uint256 _nftDbPrimaryId
    ) external payable {
        require(
            _paymentTokenIndex < _order.paymentTokenAddresses.length,
            "Invalid token index!"
        );
        address signer = _getSigner(_order, _signature);

        require(
            _order.seller == signer || hasRole(SIGNER_ROLE, signer),
            "Signer is not the seller!"
        );
        require(!isSignatureCancelled[_signature], "Signature cancelled!");
        require(!isSignatureUsed[_signature], "Signature used!");
        require(block.timestamp <= _order.expiryTime, "Signature expired!");
        require(
            isNftSupportedForSale[_order.nftAddress],
            "NFT contract not supported for sale!"
        );
        require(
            isValidPaymentToken[
                _order.paymentTokenAddresses[_paymentTokenIndex]
            ],
            "Payment token not supported!"
        );

        /// @dev Signature used mapping update in storage.
        isSignatureUsed[_signature] = true;

        if (_order.paymentTokenAddresses[_paymentTokenIndex] == address(0)) {
            require(
                msg.value == _order.paymentTokenAmounts[_paymentTokenIndex],
                "Incorrect ether amount sent!"
            );
            /// @dev Ether Payments.
            _buyWithEther(
                _order.seller,
                _order.paymentTokenAmounts[_paymentTokenIndex],
                _order.nftAddress,
                _order.nftId,
                signer
            );
        } else {
            require(msg.value == 0, "Ether sent when buying with ERC20!");
            /// @dev ERC20 Payments.
            _buyWithERC20(
                _order.seller,
                _order.paymentTokenAddresses[_paymentTokenIndex],
                _order.paymentTokenAmounts[_paymentTokenIndex],
                _order.nftAddress,
                _order.nftId,
                signer
            );
        }

        /// @dev NFT Transfer.
        IERC2981Upgradeable(_order.nftAddress).safeTransferFrom(
            _order.seller,
            msg.sender,
            _order.nftId
        );

        emit NftSold(
            _order.paymentTokenAddresses[_paymentTokenIndex],
            _order.nftAddress,
            _order.seller,
            msg.sender,
            _order.nftId,
            _nftDbPrimaryId,
            _order.paymentTokenAmounts[_paymentTokenIndex],
            _signature,
            _order.paymentTokenAddresses,
            _order.paymentTokenAmounts,
            _order.voucherCode,
            block.timestamp
        );
    }

    function _buyWithEther(
        address _seller,
        uint256 _amount,
        address _nftContract,
        uint256 _nftId,
        address _signer
    ) private {
        /**
         * @dev If areRoyaltiesPaid set to true,
         * and signer does not have the SIGNER_ROLE => Secondary sale,
         * Pay the royalties.
         */
        if (areRoyaltiesPaid && !hasRole(SIGNER_ROLE, _signer)) {
            (
                address _royaltyReceiver,
                uint256 _royaltyAmount
            ) = IERC2981Upgradeable(_nftContract).royaltyInfo(_nftId, _amount);
            sendValue(_royaltyReceiver, _royaltyAmount);
            sendValue(_seller, _amount - _royaltyAmount);
        } else if (_seller == owner()) {
            sendValue(paymentWallet, _amount);
        } else {
            sendValue(_seller, _amount);
        }
    }

    function _buyWithERC20(
        address _seller,
        address _paymentToken,
        uint256 _amount,
        address _nftContract,
        uint256 _nftId,
        address _signer
    ) private {
        /**
         * @dev If areRoyaltiesPaid set to true,
         * and signer does not have the SIGNER_ROLE => Secondary sale,
         * Pay the royalties.
         */
        if (areRoyaltiesPaid && !hasRole(SIGNER_ROLE, _signer)) {
            (
                address _royaltyReceiver,
                uint256 _royaltyAmount
            ) = IERC2981Upgradeable(_nftContract).royaltyInfo(_nftId, _amount);
            IERC20Upgradeable(_paymentToken).transferFrom(
                msg.sender,
                _royaltyReceiver,
                _royaltyAmount
            );
            IERC20Upgradeable(_paymentToken).transferFrom(
                msg.sender,
                _seller,
                _amount - _royaltyAmount
            );
        } else if (_seller == owner()) {
            IERC20Upgradeable(_paymentToken).transferFrom(
                msg.sender,
                paymentWallet,
                _amount
            );
        } else {
            IERC20Upgradeable(_paymentToken).transferFrom(
                msg.sender,
                _seller,
                _amount
            );
        }
    }

    function sendValue(address recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Insufficient ether balance!");
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "ETH payment failed!");
    }

    function _getSigner(
        Order memory _order,
        bytes memory _signature
    ) private view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _ORDER_TYPEHASH,
                    _order.seller,
                    _order.nftAddress,
                    _order.nftId,
                    _order.expiryTime,
                    keccak256(abi.encodePacked(_order.paymentTokenAddresses)),
                    keccak256(abi.encodePacked(_order.paymentTokenAmounts)),
                    keccak256(abi.encodePacked(_order.voucherCode))
                )
            )
        );
        address signer = ECDSAUpgradeable.recover(digest, _signature);
        return signer;
    }
}